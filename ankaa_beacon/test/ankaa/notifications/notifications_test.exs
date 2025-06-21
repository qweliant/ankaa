defmodule Ankaa.NotificationsTest do
  use Ankaa.DataCase

  alias Ankaa.Notifications
  alias Ankaa.Alerts
  alias Ankaa.AccountsFixtures
  alias Ankaa.Patients
  alias Ankaa.Notifications.Alert

  describe "alerts" do
    setup do
      user = AccountsFixtures.patient_fixture()
      patient = user.patient
      nurse = AccountsFixtures.nurse_fixture()
      device = AccountsFixtures.device_fixture(patient)

      # Create the patient association between nurse and patient
      Patients.create_patient_association(nurse, patient, "nurse")

      {:ok, patient: patient, nurse: nurse}

      %{
        patient: patient,
        nurse: nurse,
        device: device
      }
    end

    test "create_alert/1 persists alert", %{patient: patient} do
      attrs = %{
        type: "threshold_violation",
        message: "BP too low",
        patient_id: patient.id,
        severity: "high"
      }

      assert {:ok, %Alert{} = alert} = Alerts.create_alert(attrs)
      assert alert.type == "threshold_violation"
      assert alert.message =~ "BP too low"
      assert alert.severity == "high"
      assert alert.patient_id == patient.id
    end

    test "broadcast_device_alerts/3 creates alerts for violations", %{patient: patient, device: device} do
      # Mock violations (like what would come from ThresholdViolation)
      violations = [
        %{
          parameter: :systolic,
          value: 190,
          threshold: 180,
          severity: :critical,
          message: "🩸 High systolic pressure (190 mmHg)"
        },
        %{
          parameter: :heart_rate,
          value: 110,
          threshold: 100,
          severity: :high,
          message: "💓 High heart rate (110 bpm)"
        }
      ]

      # Mock reading (minimal data needed)
      reading = %{device_id: device.device_id}

      assert :ok = Alerts.broadcast_device_alerts(device.device_id, reading, violations)

      # Check that alerts were created
      alerts = Repo.all(Alert)
      assert length(alerts) == 2

      critical_alert = Enum.find(alerts, &(&1.severity == "critical"))
      high_alert = Enum.find(alerts, &(&1.severity == "high"))

      assert critical_alert.message =~ "High systolic pressure"
      assert high_alert.message =~ "High heart rate"
    end

    test "broadcast_device_alerts/3 handles unknown device", %{} do
      violations = [%{severity: :high, message: "Test"}]

      assert {:error, :patient_not_found} =
        Alerts.broadcast_device_alerts("unknown_device", %{}, violations)
    end
  end
end
