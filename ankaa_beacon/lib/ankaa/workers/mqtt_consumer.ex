defmodule Ankaa.Workers.MQTTConsumer do
  @moduledoc """
  Consumes messages from MQTT broker and processes them.
  """
  use GenServer
  alias Ankaa.Monitoring.{DialysisReading, BPReading}
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
        {:properties, %{}}
      ])

    # Connect to the broker
    case :emqtt.connect(client) do
      {:ok, _} ->
        Logger.info("Connected to MQTT broker at localhost:1883")
        # Subscribe to topics
        :emqtt.subscribe(client, [
          # Match all device telemetry
          {"devices/+/telemetry", 0}
        ])

        {:ok, %{client: client}}

      {:error, reason} ->
        Logger.error("Failed to connect to MQTT broker: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_info({:publish, topic, payload}, state) do
    Logger.info("Received message on topic: #{topic}")
    Logger.info("Message payload: #{inspect(payload)}")
    process_message(topic, payload)
    {:noreply, state}
  end

  @impl true
  def handle_info({:disconnected, reason}, state) do
    Logger.warning("Disconnected from MQTT broker: #{inspect(reason)}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:connected, _}, state) do
    Logger.info("Reconnected to MQTT broker")
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
        Processing message:
        Topic: #{topic}
        Device ID: #{device_id}
        Data: #{inspect(data, pretty: true)}
        """)

        cond do
          String.starts_with?(device_id, "dialysis_") ->
            Logger.info("Processing dialysis reading")

          # reading = DialysisReading.from_mqtt(data)
          # save_reading(reading)
          # process_reading(reading)

          String.starts_with?(device_id, "bp_") ->
            Logger.info("Processing blood pressure reading")

          # reading = BPReading.from_mqtt(data)
          # save_reading(reading)
          # process_reading(reading)

          true ->
            Logger.warning("Unknown device type: #{device_id}")
            {:error, :unknown_device_type}
        end

      _ ->
        Logger.warning("Unknown topic: #{topic}")
        {:error, :unknown_topic}
    end
  end

  # Commented out for now - we'll implement these later
  # defp save_reading(reading) do
  #   IO.inspect(reading, label: "Saving reading")
  #   case reading do
  #     %DialysisReading{} ->
  #       Ankaa.Repo.insert(reading)
  #
  #     %BPReading{} ->
  #       Ankaa.Repo.insert(reading)
  #   end
  # end
  #
  # defp process_reading(reading) do
  #   violations = reading.__struct__.check_thresholds(reading)
  #
  #   Enum.each(violations, fn violation ->
  #     patient = get_patient_from_device(reading.device_id)
  #
  #     alert_params = %{
  #       patient_id: patient.id,
  #       title: violation.message,
  #       message: format_violation_message(violation, reading),
  #       severity: violation.severity,
  #       source: reading.__struct__.__name__
  #     }
  #
  #     Notifications.create_alert(alert_params)
  #   end)
  # end
  #
  # defp format_violation_message(violation, reading) do
  #   # Format a detailed message based on the violation and reading
  # end
  #
  # defp get_patient_from_device(device_id) do
  #   # Lookup patient from device_id
  # end
end
