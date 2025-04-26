defmodule Ankaa.Workers.MQTTConsumer do
  @moduledoc """
  Consumes messages from MQTT broker and processes them.
  """
  use GenServer
  alias Ankaa.Monitoring.{DialysisDeviceReading, BPDeviceReading}
  alias Ankaa.Notifications
  require Logger

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server Callbacks
  @impl true
  def init(_opts) do
    # MQTT connection configuration
    client_id = "ankaa_consumer_#{System.unique_integer([:positive])}"
    mqtt_config = Application.get_env(:ankaa, :mqtt)

    # Start the MQTT client with options seen here: https://github.com/emqx/emqtt?tab=readme-ov-file#option
    {:ok, client} =
      :emqtt.start_link([
        {:host, String.to_charlist(mqtt_config[:host])},
        {:port, mqtt_config[:port]},
        {:clientid, String.to_charlist(client_id)},
        {:clean_start, true},
        {:keepalive, 30},
        # Use MQTT 5.0
        {:proto_ver, :v5},
        # MQTT 5.0 properties
        {:properties, %{}},
        # Add debug logging
        {:debug, true}
      ])

    # Connect to the broker
    case :emqtt.connect(client) do
      {:ok, _} ->
        Logger.info("🔌 Connected to MQTT broker at #{mqtt_config[:host]}:#{mqtt_config[:port]}")
        # Subscribe to topics
        :emqtt.subscribe(client, [
          # Match all device telemetry
          {"devices/+/telemetry", 0}
        ])

        {:ok, %{client: client}}

      {:error, reason} ->
        Logger.error("❌ Failed to connect to MQTT broker: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_info({:publish, %{topic: topic, payload: payload} = message}, state) do
    Logger.info("📥 Received MQTT message:")
    Logger.info("   Topic: #{topic}")
    Logger.info("   Payload: #{payload}")
    Logger.debug("   Full message: #{inspect(message, pretty: true)}")

    process_message(topic, payload)
    {:noreply, state}
  end

  @impl true
  def handle_info({:disconnected, reason}, state) do
    Logger.warning("⚠️ Disconnected from MQTT broker: #{inspect(reason)}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:connected, _}, state) do
    Logger.info("🔌 Reconnected to MQTT broker")
    {:noreply, state}
  end

  @doc """
  Processes an incoming MQTT message based on topic
  """
  def process_message(topic, payload) do
    case topic do
      "devices/" <> rest ->
        [device_id, "telemetry"] = String.split(rest, "/")
        data = Jason.decode!(payload)

        Logger.info("""
        📊 Processing telemetry:
        ├─ Device: #{device_id}
        ├─ Topic: #{topic}
        └─ Data:
           #{inspect(data, pretty: true)}
        """)

        cond do
          String.starts_with?(device_id, "dialysis_") ->
            Logger.info("💉 Processing dialysis reading")
            # Convert Rust struct to our schema format
            reading_data = %{
              "device_id" => data["device_id"],
              "timestamp" => parse_timestamp(data["timestamp"]),
              "mode" => data["mode"],
              "status" => data["status"],
              "time_in_alarm" => data["time_in_alarm"],
              "time_in_treatment" => data["time_in_treatment"],
              "time_remaining" => data["time_remaining"],
              "dfv" => data["dfv"],
              "dfr" => data["dfr"],
              "ufv" => data["ufv"],
              "ufr" => data["ufr"],
              "bfr" => data["bfr"],
              "ap" => data["ap"],
              "vp" => data["vp"],
              "ep" => data["ep"]
            }

            reading = DialysisDeviceReading.from_mqtt(reading_data)
            save_reading(reading)
            process_reading(reading)

          String.starts_with?(device_id, "bp_") ->
            Logger.info("🫀 Processing blood pressure reading")
            # Convert Rust struct to our schema format
            reading_data = %{
              "device_id" => data["device_id"],
              "timestamp" => parse_timestamp(data["timestamp"]),
              "mode" => data["mode"],
              "status" => data["status"],
              "systolic" => data["systolic"],
              "diastolic" => data["diastolic"],
              "heart_rate" => data["heart_rate"],
              "mean_arterial_pressure" => data["mean_arterial_pressure"],
              "pulse_pressure" => data["pulse_pressure"],
              "irregular_heartbeat" => data["irregular_heartbeat"]
            }

            reading = BPDeviceReading.from_mqtt(reading_data)
            save_reading(reading)
            process_reading(reading)

          true ->
            Logger.warning("❓ Unknown device type: #{device_id}")
            {:error, :unknown_device_type}
        end

      _ ->
        Logger.warning("❓ Unknown topic: #{topic}")
        {:error, :unknown_topic}
    end
  end

  defp parse_timestamp(timestamp) when is_binary(timestamp) do
    {:ok, dt, _} = DateTime.from_iso8601(timestamp)
    dt
  end

  defp save_reading(reading) do
    Logger.debug("💾 Saving reading")

    case reading do
      %DialysisDeviceReading{} ->
        Ankaa.Monitoring.DialysisReadings.create_dialysis_reading(Map.from_struct(reading))

      %BPDeviceReading{} ->
        Ankaa.Monitoring.BPReadings.create_bp_reading(Map.from_struct(reading))
    end
  end

  defp process_reading(reading) do
    violations = reading.__struct__.check_thresholds(reading)

    Enum.each(violations, fn violation ->
      Logger.warning("""
      ⚠️ Threshold violation detected:
      ├─ Device: #{reading.device_id}
      ├─ Parameter: #{violation.parameter}
      ├─ Value: #{violation.value}
      ├─ Threshold: #{violation.threshold}
      ├─ Severity: #{violation.severity}
      └─ Message: #{violation.message}
      """)

      # Broadcast via PubSub
      Phoenix.PubSub.broadcast(
        Ankaa.PubSub,
        "#{reading.__struct__ |> Module.split() |> List.last() |> String.downcase() |> String.replace(".", "_")}_readings",
        {:new_reading, reading, violations}
      )
    end)
  end
end
