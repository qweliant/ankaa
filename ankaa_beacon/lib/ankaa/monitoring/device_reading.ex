defmodule Ankaa.Monitoring.DeviceReading do
  @moduledoc """
  Parent module for all device readings with common functions
  """

  @callback from_mqtt(map()) :: struct()
  @callback check_thresholds(struct()) :: [Ankaa.Monitoring.ThresholdViolation.t()]
end
