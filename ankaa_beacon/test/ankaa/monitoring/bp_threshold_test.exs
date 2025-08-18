defmodule Ankaa.Monitoring.BPThresholdCheckerTest do
  use Ankaa.DataCase

  alias Ankaa.Monitoring.BPDeviceReading
  alias Ankaa.Monitoring.ThresholdChecker
  alias Ankaa.Monitoring.ThresholdViolation

  describe "check/2 for BP readings" do
    setup do
      normal_reading = %BPDeviceReading{
        systolic: 120,
        diastolic: 80,
        heart_rate: 70,
        irregular_heartbeat: false
      }

      %{normal_reading: normal_reading}
    end

    test "returns an empty list for normal readings", %{normal_reading: reading} do
      assert ThresholdChecker.check(reading, %{}) == []
    end

    test "returns a critical violation for high systolic pressure", %{normal_reading: reading} do
      high_bp_reading = %{reading | systolic: 190}
      violations = ThresholdChecker.check(high_bp_reading, %{})

      assert [%ThresholdViolation{severity: :critical, parameter: :systolic}] = violations
    end

    test "returns a high violation for low systolic pressure", %{normal_reading: reading} do
      low_bp_reading = %{reading | systolic: 85}
      violations = ThresholdChecker.check(low_bp_reading, %{})

      assert [%ThresholdViolation{severity: :high, parameter: :systolic}] = violations
    end

    test "returns a critical violation for high diastolic pressure", %{normal_reading: reading} do
      high_bp_reading = %{reading | diastolic: 130}
      violations = ThresholdChecker.check(high_bp_reading, %{})

      assert [%ThresholdViolation{severity: :critical, parameter: :diastolic}] = violations
    end

    test "returns a high violation for low diastolic pressure", %{normal_reading: reading} do
      low_bp_reading = %{reading | diastolic: 55}
      violations = ThresholdChecker.check(low_bp_reading, %{})

      assert [%ThresholdViolation{severity: :high, parameter: :diastolic}] = violations
    end



    test "returns a high violation for high heart rate", %{normal_reading: reading} do
      high_hr_reading = %{reading | heart_rate: 110}
      violations = ThresholdChecker.check(high_hr_reading, %{})

      assert [%ThresholdViolation{severity: :high, parameter: :heart_rate}] = violations
    end

    test "returns a high violation for low heart rate", %{normal_reading: reading} do
      low_hr_reading = %{reading | heart_rate: 45}
      violations = ThresholdChecker.check(low_hr_reading, %{})

      assert [%ThresholdViolation{severity: :high, parameter: :heart_rate}] = violations
    end

    test "returns a high violation for irregular heartbeat", %{normal_reading: reading} do
      irregular_reading = %{reading | irregular_heartbeat: true}
      violations = ThresholdChecker.check(irregular_reading, %{})

      assert [%ThresholdViolation{severity: :high, parameter: :irregular_heartbeat}] = violations
    end

    test "returns multiple violations when applicable", %{normal_reading: reading} do
      bad_reading = %{reading | systolic: 190, heart_rate: 115}
      violations = ThresholdChecker.check(bad_reading, %{})

      assert length(violations) == 2
      assert Enum.any?(violations, &(&1.parameter == :systolic))
      assert Enum.any?(violations, &(&1.parameter == :heart_rate))
    end

    test "uses custom thresholds when provided", %{normal_reading: reading} do
      reading_with_custom_violation = %{reading | heart_rate: 95}

      custom_thresholds = %{
        "heart_rate" => %{"max_value" => 90.0}
      }

      violations = ThresholdChecker.check(reading_with_custom_violation, custom_thresholds)

      assert [
        %ThresholdViolation{
          severity: :high,
          parameter: :heart_rate,
          threshold: 90.0,
          value: 95
        }
      ] = violations
    end
  end
end
