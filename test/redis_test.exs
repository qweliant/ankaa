defmodule Ankaa.RedisTest do
  use ExUnit.Case
  alias Ankaa.Redis

  test "Redis connection" do
    # Test Redis Conneting
    assert {:ok, "PONG"} = Redis.command(["PING"])
  end

  test "Redis Topics" do
    # Test Redis command
    Ankaa.Redis.command(["SET", "test_key", "Hello, Ankaa!"])
    assert {:ok, "Hello, Ankaa!"} = Ankaa.Redis.command(["GET", "test_key"])
  end

  test "Redis Pub Sub" do
    # Test Pub/Sub
    Ankaa.Redis.subscribe("alerts")
    Ankaa.Redis.publish("alerts", "Low BP detected for patient 12345!")

    # Wait for the message to be received
    Process.sleep(100)

    # Unsubscribe from the channel
    Redis.unsubscribe("alerts")

    # Wait for the unsubscribe to complete
    Process.sleep(100)
  end
end
