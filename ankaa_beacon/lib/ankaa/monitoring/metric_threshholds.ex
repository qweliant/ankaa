defmodule Ankaa.Monitoring.ThresholdViolation do
  @moduledoc """
  Structure for threshold violations
  """
  @type t :: %__MODULE__{
          parameter: atom(),
          value: any(),
          threshold: any(),
          severity: :low | :medium | :high | :critical,
          message: String.t()
        }

  defstruct [:parameter, :value, :threshold, :severity, :message]
end
