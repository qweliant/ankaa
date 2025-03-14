defmodule Ankaa.MockDataTest do
  use ExUnit.Case
  alias Ankaa.{Redis, MockData}

  setup do
    # Subscribe to test channels before each test
    Redis.subscribe("bp_readings")
    Redis.subscribe("dialysis_readings")

    # Start the MockData process
    {:ok, pid} = MockData.start_link([])

    # Cleanup after test
    on_exit(fn -> Process.exit(pid, :normal) end)

    :ok
  end

  test "MockData publishes BP & dialysis readings to Redis" do
    # Wait for the first round of mock data to be published
    Process.sleep(6000)

    # Get messages from Redis
    assert {:ok, bp_message} = Redis.command(["GET", "bp_readings"])
    assert {:ok, dialysis_message} = Redis.command(["GET", "dialysis_readings"])

    # Check that messages contain expected fields
    assert String.contains?(bp_message, "systolic")
    assert String.contains?(dialysis_message, "fluid_level")
  end
end
