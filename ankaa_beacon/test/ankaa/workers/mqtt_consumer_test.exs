defmodule Ankaa.Workers.MQTTConsumerTest do
  use ExUnit.Case, async: false
  alias Ankaa.Workers.MQTTConsumer
  alias Ankaa.Monitoring.{BPReading, DialysisReading}
  require Logger

  setup do
    # Start the MQTT consumer in test mode
    {:ok, pid} = MQTTConsumer.start_link(test_mode: true)
    {:ok, %{consumer: pid}}
  end

  describe "process_message/2" do
    test "processes blood pressure readings correctly", %{consumer: _pid} do
      topic = "devices/bp_001/telemetry"

      payload =
        %{
          "device_id" => "bp_001",
          "timestamp" => "2025-04-12T18:18:34.008976007+00:00",
          "systolic" => 123.63846,
          "diastolic" => 92.80848,
          "heart_rate" => 56,
          "risk_level" => "medium"
        }
        |> Jason.encode!()

      assert {:ok, %BPReading{}} = MQTTConsumer.process_message(topic, payload)
    end

    test "processes dialysis readings correctly", %{consumer: _pid} do
      topic = "devices/dialysis_001/telemetry"

      payload =
        %{
          "device_id" => "dialysis_001",
          "timestamp" => "2025-04-12T18:18:34.008976007+00:00",
          "fluid_level" => 75,
          "flow_rate" => 200,
          "clot_detected" => false
        }
        |> Jason.encode!()

      assert {:ok, %DialysisReading{}} = MQTTConsumer.process_message(topic, payload)
    end

    test "returns error for unknown device type", %{consumer: _pid} do
      topic = "devices/unknown_001/telemetry"
      payload = %{"device_id" => "unknown_001"} |> Jason.encode!()

      assert {:error, :unknown_device_type} = MQTTConsumer.process_message(topic, payload)
    end

    test "returns error for unknown topic", %{consumer: _pid} do
      topic = "unknown/topic"
      payload = %{} |> Jason.encode!()

      assert {:error, :unknown_topic} = MQTTConsumer.process_message(topic, payload)
    end
  end

  describe "handle_info/2" do
    test "handles MQTT publish messages", %{consumer: pid} do
      topic = "devices/bp_001/telemetry"

      payload =
        %{
          "device_id" => "bp_001",
          "timestamp" => "2025-04-12T18:18:34.008976007+00:00",
          "systolic" => 123.63846,
          "diastolic" => 92.80848,
          "heart_rate" => 56,
          "risk_level" => "medium"
        }
        |> Jason.encode!()

      message = {:publish, %{topic: topic, payload: payload}}
      state = %{client: self()}

      assert {:noreply, ^state} = MQTTConsumer.handle_info(message, state)
    end

    test "handles MQTT disconnect messages", %{consumer: pid} do
      message = {:disconnected, :network_error}
      state = %{client: self()}

      assert {:noreply, ^state} = MQTTConsumer.handle_info(message, state)
    end

    test "handles MQTT connect messages", %{consumer: pid} do
      message = {:connected, %{}}
      state = %{client: self()}

      assert {:noreply, ^state} = MQTTConsumer.handle_info(message, state)
    end
  end

  describe "init/1" do
    test "initializes with test mode", %{consumer: _pid} do
      opts = [test_mode: true]
      assert {:ok, %{client: _}} = MQTTConsumer.init(opts)
    end

    test "handles connection errors", %{consumer: _pid} do
      opts = [test_mode: true, force_connection_error: true]
      assert {:stop, :connection_failed} = MQTTConsumer.init(opts)
    end
  end
end
