defmodule Ankaa.Workers.MqttConsumer do
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

  @mqtt_config Application.compile_env(:ankaa, :mqtt)

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server Callbacks
  @impl true
  def init(opts) do
    test_mode = Keyword.get(opts, :test_mode, false)
    force_error = Keyword.get(opts, :force_error, false)

    state = %{
      client: nil,
      test_mode: test_mode
    }

    if not test_mode do
      if force_error do
        {:error, :connection_failed}
      else
        # TODO: Implement actual MQTT connection
        {:ok, state}
      end
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_call({:test_handle_info, message}, _from, state) do
    case handle_info(message, state) do
      {:noreply, new_state} -> {:reply, {:noreply, new_state}, new_state}
      other -> {:reply, other, state}
    end
  end

  @impl true
  def handle_info({:publish, %{topic: topic, payload: payload}}, state) do
    payload = Jason.decode!(payload)
    _ = process_message(topic, payload)
    {:noreply, state}
  end

  @impl true
  def handle_info({:disconnect, reason}, state) do
    Logger.warning("MQTT client disconnected: #{inspect(reason)}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:connect}, state) do
    Logger.info("MQTT client connected")
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  @doc """
  Process an MQTT message based on its topic and payload.
  """
  def process_message(topic, payload) when is_map(payload) do
    case payload do
      %{"type" => "blood_pressure"} ->
        Logger.info("Processing blood pressure reading from #{topic}")
        # TODO: Implement blood pressure reading storage
        :ok

      %{"type" => "dialysis"} ->
        Logger.info("Processing dialysis reading from #{topic}")
        # TODO: Implement dialysis reading storage
        :ok

      %{"type" => type} ->
        Logger.warning("Unknown device type: #{type}")
        {:error, :unknown_device_type}
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

  defp connect do
    # Implementation pending
    :ok
  end
end
