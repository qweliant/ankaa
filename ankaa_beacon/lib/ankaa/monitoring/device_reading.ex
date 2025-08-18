defmodule Ankaa.Monitoring.DeviceReading do
  @moduledoc """
  A behaviour that defines the contract for all device reading types.
  """

  alias Ankaa.Monitoring.ThresholdViolation

  @callback from_mqtt(map()) :: struct()
  @callback check_thresholds(struct(), map()) :: [ThresholdViolation.t()]
end
