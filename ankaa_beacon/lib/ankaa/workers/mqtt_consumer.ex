defmodule Ankaa.Workers.MQTTConsumer do
  @moduledoc """
  Consumes messages from MQTT broker and processes them.
  """
  use GenServer
  alias Ankaa.Monitoring.{DialysisReading, BPReading}
  alias Ankaa.Notifications

  # GenServer implementation

  @doc """
  Processes an incoming MQTT message based on topic
  """
  def process_message(topic, payload) do
    case topic do
      "dialysis/" <> device_id ->
        data = Jason.decode!(payload)
        reading = DialysisReading.from_mqtt(data)
        save_reading(reading)
        process_reading(reading)

      "bp/" <> device_id ->
        data = Jason.decode!(payload)
        reading = BPReading.from_mqtt(data)
        save_reading(reading)
        process_reading(reading)

      _ ->
        # Unknown topic
        {:error, :unknown_topic}
    end
  end

  defp save_reading(reading) do
    case reading do
      %DialysisReading{} ->
        Ankaa.Repo.insert(reading)

      # You might also want to store in a time-series DB like InfluxDB/TimescaleDB

      %BPReading{} ->
        Ankaa.Repo.insert(reading)
        # You might also want to store in a time-series DB like InfluxDB/TimescaleDB
    end
  end

  defp process_reading(reading) do
    # Check for threshold violations
    violations = reading.__struct__.check_thresholds(reading)

    # Create alerts for violations
    Enum.each(violations, fn violation ->
      # Get patient from device_id
      patient = get_patient_from_device(reading.device_id)

      # Create alert
      alert_params = %{
        patient_id: patient.id,
        title: violation.message,
        message: format_violation_message(violation, reading),
        severity: violation.severity,
        source: reading.__struct__.__name__
      }

      Notifications.create_alert(alert_params)
    end)
  end

  defp format_violation_message(violation, reading) do
    # Format a detailed message based on the violation and reading
  end

  defp get_patient_from_device(device_id) do
    # Lookup patient from device_id
  end
end
