defmodule Ankaa.Workers.MqttConsumerTest do
  use Ankaa.DataCase, async: false
  alias Ankaa.Workers.MqttConsumer

  setup do
    consumer = start_supervised!({MqttConsumer, [test_mode: true]})
    %{consumer: consumer}
  end

  describe "process_message/2" do
    test "processes blood pressure readings" do
      topic = "devices/bp_123/telemetry"

      payload = %{
        "type" => "blood_pressure",
        "systolic" => 120,
        "diastolic" => 80,
        "pulse" => 72,
        "timestamp" => "2024-03-21T10:00:00Z"
      }

      assert :ok = MqttConsumer.process_message(topic, payload)
    end

    test "processes dialysis readings" do
      topic = "devices/dialysis_456/telemetry"

      payload = %{
        "type" => "dialysis",
        "flow_rate" => 300,
        "pressure" => 120,
        "temperature" => 37.0,
        "timestamp" => "2024-03-21T10:00:00Z"
      }

      assert :ok = MqttConsumer.process_message(topic, payload)
    end

    test "handles unknown device types" do
      topic = "devices/unknown_789/telemetry"

      payload = %{
        "type" => "unknown",
        "value" => 123
      }

      assert {:error, :unknown_device_type} = MqttConsumer.process_message(topic, payload)
    end
  end

  describe "handle_info/2" do
    test "handles MQTT publish messages", %{consumer: pid} do
      message =
        {:publish,
         %{
           topic: "devices/bp_123/telemetry",
           payload:
             Jason.encode!(%{
               "type" => "blood_pressure",
               "systolic" => 120,
               "diastolic" => 80
             })
         }}

      assert {:noreply, _state} = GenServer.call(pid, {:test_handle_info, message})
    end

    test "handles disconnect messages", %{consumer: pid} do
      message = {:disconnect, :network_error}
      assert {:noreply, _state} = GenServer.call(pid, {:test_handle_info, message})
    end

    test "handles connect messages", %{consumer: pid} do
      message = {:connect}
      assert {:noreply, _state} = GenServer.call(pid, {:test_handle_info, message})
    end
  end
end
