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

  # Venous Pressure (mmHg)
  @vp_high_critical 250
  @vp_low_critical 50

  # Blood Flow Rate (ml/min)
  @bfr_low_warning 200

  # ============================================================================
  # BP DEVICE CHECK
  # ============================================================================
  def check(%Ankaa.Monitoring.BPDeviceReading{} = reading, custom_thresholds) do
    []
    |> check_systolic(reading, custom_thresholds)
    |> check_diastolic(reading, custom_thresholds)
    |> check_heart_rate(reading, custom_thresholds)
    |> check_irregular_heartbeat(reading)
  end

  # ============================================================================
  # DIALYSIS DEVICE CHECK (NEW)
  # ============================================================================
  def check(%Ankaa.Monitoring.DialysisDeviceReading{} = reading, custom_thresholds) do
    []
    |> check_venous_pressure(reading, custom_thresholds)
    |> check_blood_flow_rate(reading, custom_thresholds)
  end

  # BP CHECK HELPERS
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

  # DIALYSIS CHECK HELPERS
  defp check_venous_pressure(violations, reading, custom) do
    # Venous Pressure (VP) indicates resistance returning blood to the patient.
    # High VP = possible blockage/infiltration. Low VP = possible disconnection (dangerous).

    max_threshold = get_in(custom, ["venous_pressure", "max_value"]) || @vp_high_critical
    min_threshold = get_in(custom, ["venous_pressure", "min_value"]) || @vp_low_critical

    cond do
      reading.venous_pressure > max_threshold ->
        [
          %ThresholdViolation{
            parameter: :venous_pressure,
            value: reading.venous_pressure,
            threshold: max_threshold,
            severity: :critical,
            message:
              "⚠️ High Venous Pressure (#{reading.venous_pressure} mmHg) - Check access site"
          }
          | violations
        ]

      reading.venous_pressure < min_threshold ->
        [
          %ThresholdViolation{
            parameter: :venous_pressure,
            value: reading.venous_pressure,
            threshold: min_threshold,
            severity: :critical,
            message:
              "⚠️ Low Venous Pressure (#{reading.venous_pressure} mmHg) - Check for line disconnection"
          }
          | violations
        ]

      true ->
        violations
    end
  end

  defp check_blood_flow_rate(violations, reading, custom) do
    # BFR ensures adequate cleaning. Too low means inefficient treatment.
    min_threshold = get_in(custom, ["blood_flow_rate", "min_value"]) || @bfr_low_warning

    if reading.blood_flow_rate < min_threshold do
      [
        %ThresholdViolation{
          parameter: :blood_flow_rate,
          value: reading.blood_flow_rate,
          threshold: min_threshold,
          # Or :warning depending on your severity levels
          severity: :high,
          message: "📉 Low Blood Flow Rate (#{reading.blood_flow_rate} ml/min)"
        }
        | violations
      ]
    else
      violations
    end
  end
end
