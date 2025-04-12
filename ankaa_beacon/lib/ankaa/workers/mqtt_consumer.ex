defmodule Ankaa.Workers.MQTTConsumer do
  @moduledoc """
  Consumes messages from MQTT broker and processes them.
  """
  use GenServer
  alias Ankaa.Monitoring.{DialysisReading, BPReading}
  alias Ankaa.Notifications
  alias Ankaa.Repo
  alias Ankaa.TimescaleRepo
  alias Ankaa.Accounts
  require Logger

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server Callbacks
  @impl true
  def init(opts) do
    if Keyword.get(opts, :test_mode, false) do
      if Keyword.get(opts, :force_connection_error, false) do
        {:stop, :connection_failed}
      else
        {:ok, %{client: self()}}
      end
    else
      # MQTT connection configuration
      client_id = "ankaa_consumer_#{System.unique_integer([:positive])}"

      # Start the MQTT client with options seen here: https://github.com/emqx/emqtt?tab=readme-ov-file#option
      {:ok, client} =
        :emqtt.start_link([
          {:host, "localhost"},
          {:port, 1883},
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
          Logger.info("🔌 Connected to MQTT broker at localhost:1883")
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
            reading = DialysisReading.from_mqtt(data)
            save_reading(reading)
            process_reading(reading)
            {:ok, reading}

          String.starts_with?(device_id, "bp_") ->
            Logger.info("🫀 Processing blood pressure reading")
            reading = BPReading.from_mqtt(data)
            save_reading(reading)
            process_reading(reading)
            {:ok, reading}

          true ->
            Logger.warning("❓ Unknown device type: #{device_id}")
            {:error, :unknown_device_type}
        end

      _ ->
        Logger.warning("❓ Unknown topic: #{topic}")
        {:error, :unknown_topic}
    end
  end

  defp save_reading(reading) do
    Logger.info("💾 Saving reading for device: #{reading.device_id}")

    case TimescaleRepo.insert(reading) do
      {:ok, saved_reading} ->
        Logger.info("✅ Successfully saved reading")
        saved_reading

      {:error, changeset} ->
        Logger.error("❌ Failed to save reading: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  defp process_reading(reading) do
    Logger.info("🔍 Checking thresholds for reading")
    violations = reading.__struct__.check_thresholds(reading)

    if Enum.any?(violations) do
      Logger.warning("⚠️ Threshold violations detected: #{length(violations)}")

      Enum.each(violations, fn violation ->
        case get_patient_from_device(reading.device_id) do
          {:ok, patient} ->
            alert_params = %{
              patient_id: patient.id,
              title: violation.message,
              message: format_violation_message(violation, reading),
              severity: violation.severity,
              source: reading.__struct__.__name__
            }

            case Notifications.create_alert(alert_params) do
              {:ok, alert} ->
                Logger.info("📢 Created alert: #{alert.title}")

              {:error, reason} ->
                Logger.error("❌ Failed to create alert: #{inspect(reason)}")
            end

          {:error, reason} ->
            Logger.error("❌ Failed to find patient for device: #{reason}")
        end
      end)
    else
      Logger.info("✅ No threshold violations detected")
    end
  end

  defp format_violation_message(violation, reading) do
    """
    Device: #{reading.device_id}
    Parameter: #{violation.parameter}
    Value: #{violation.value}
    Threshold: #{violation.threshold}
    Time: #{reading.timestamp}
    """
  end

  defp get_patient_from_device(device_id) do
    case Accounts.get_user_by_device_id(device_id) do
      nil -> {:error, :patient_not_found}
      user -> {:ok, user}
    end
  end
end
