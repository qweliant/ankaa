defmodule Ankaa.RedisTest do
  use ExUnit.Case
  alias Ankaa.Redis

  test "Redis connection and Pub/Sub" do
    # Test Redis command
    assert {:ok, "PONG"} = Redis.command(["PING"])

    # Test Pub/Sub
    :ok = Redis.subscribe("data_stream")
    :ok = Redis.publish("data_stream", "Hello, Redis!")

    # Wait for the message to be received
    Process.sleep(100)
  end
end
