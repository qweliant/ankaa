defmodule Ankaa.Monitoring.ThresholdChecker do
  @moduledoc """
  Checks device readings against defined thresholds to identify violations.
  """
  alias Ankaa.Monitoring.ThresholdViolation

  @systolic_critical 180
  @systolic_low 90
  @diastolic_critical 120
  @diastolic_low 60
  @hr_high 100
  @hr_low 50

  def check(%Ankaa.Monitoring.BPDeviceReading{} = reading, custom_thresholds) do
    []
    |> check_systolic(reading, custom_thresholds)
    |> check_diastolic(reading, custom_thresholds)
    |> check_heart_rate(reading, custom_thresholds)
    |> check_irregular_heartbeat(reading)
  end

  defp check_systolic(violations, reading, custom) do
    max_threshold = get_in(custom, ["systolic", "max_value"]) || @systolic_critical
    min_threshold = get_in(custom, ["systolic", "min_value"]) || @systolic_low

    cond do
      reading.systolic > max_threshold ->
        [
          %ThresholdViolation{
            parameter: :systolic,
            value: reading.systolic,
            threshold: max_threshold,
            severity: :critical,
            message: "🩸 High systolic pressure (#{reading.systolic} mmHg)"
          }
          | violations
        ]

      reading.systolic < min_threshold ->
        [
          %ThresholdViolation{
            parameter: :systolic,
            value: reading.systolic,
            threshold: min_threshold,
            severity: :high,
            message: "🩸 Low systolic pressure (#{reading.systolic} mmHg)"
          }
          | violations
        ]

      true ->
        violations
    end
  end

  defp check_diastolic(violations, reading, custom) do
    max_threshold = get_in(custom, ["diastolic", "max_value"]) || @diastolic_critical
    min_threshold = get_in(custom, ["diastolic", "min_value"]) || @diastolic_low

    cond do
      reading.diastolic > max_threshold ->
        [
          %ThresholdViolation{
            parameter: :diastolic,
            value: reading.diastolic,
            threshold: max_threshold,
            severity: :critical,
            message: "🩸 High diastolic pressure (#{reading.diastolic} mmHg)"
          }
          | violations
        ]

      reading.diastolic < min_threshold ->
        [
          %ThresholdViolation{
            parameter: :diastolic,
            value: reading.diastolic,
            threshold: min_threshold,
            severity: :high,
            message: "🩸 Low diastolic pressure (#{reading.diastolic} mmHg)"
          }
          | violations
        ]

      true ->
        violations
    end
  end

  defp check_heart_rate(violations, reading, custom) do
    max_threshold = get_in(custom, ["heart_rate", "max_value"]) || @hr_high
    min_threshold = get_in(custom, ["heart_rate", "min_value"]) || @hr_low

    cond do
      reading.heart_rate > max_threshold ->
        [
          %ThresholdViolation{
            parameter: :heart_rate,
            value: reading.heart_rate,
            threshold: max_threshold,
            severity: :high,
            message: "💓 High heart rate (#{reading.heart_rate} bpm)"
          }
          | violations
        ]

      reading.heart_rate < min_threshold ->
        [
          %ThresholdViolation{
            parameter: :heart_rate,
            value: reading.heart_rate,
            threshold: min_threshold,
            severity: :high,
            message: "💔 Low heart rate (#{reading.heart_rate} bpm)"
          }
          | violations
        ]

      true ->
        violations
    end
  end

  defp check_irregular_heartbeat(violations, reading) do
    if reading.irregular_heartbeat do
      [
        %ThresholdViolation{
          parameter: :irregular_heartbeat,
          value: true,
          threshold: false,
          severity: :high,
          message: "Irregular heartbeat detected"
        }
        | violations
      ]
    else
      violations
    end
  end
end
