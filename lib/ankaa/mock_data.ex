defmodule Ankaa.MockData do
  use GenServer
  alias Ankaa.Redis

  @moduledoc """
  A GenServer that simulates real-time BP and dialysis machine data.
  """

  # Start the mock data generator
  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_next_reading()
    {:ok, state}
  end

  # Generate and publish mock BP & dialysis data every 5 seconds
  def handle_info(:generate_data, state) do
    # Simulate BP reading
    bp_data = %{
      patient_id: "12345",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      systolic: Enum.random(90..140),
      diastolic: Enum.random(60..90),
      heart_rate: Enum.random(60..100)
    }
    Redis.publish("bp_readings", Jason.encode!(bp_data))

    # Simulate dialysis reading
    dialysis_data = %{
      patient_id: "12345",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      fluid_level: Enum.random(400..600),
      flow_rate: Enum.random(200..350),
      clot_detected: Enum.random([true, false])
    }
    Redis.publish("dialysis_readings", Jason.encode!(dialysis_data))

    IO.puts("Published mock BP & dialysis data to Redis.")

    schedule_next_reading()
    {:noreply, state}
  end

  defp schedule_next_reading do
    Process.send_after(self(), :generate_data, 2_000)  # Every 5 seconds
  end
end
