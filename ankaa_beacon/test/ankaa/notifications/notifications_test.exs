defmodule Ankaa.NotificationsTest do
  use Ankaa.DataCase

  import ExUnit.CaptureLog

  alias Ankaa.Alerts
  alias Ankaa.AccountsFixtures
  alias Ankaa.Patients
  alias Ankaa.Notifications.Alert

  describe "alerts" do
    setup do
      # Start the registry once for this test's process
      # start_supervised!({Registry, keys: :unique, name: Ankaa.Notifications.AlertRegistry})

      # Create all the fixtures needed for the tests
      patient_user = AccountsFixtures.patient_fixture()
      nurse_user = AccountsFixtures.nurse_fixture()
      doctor_user = AccountsFixtures.doctor_fixture()
      unrelated_patient_user = AccountsFixtures.patient_fixture()
      device = AccountsFixtures.device_fixture(patient_user.patient)

      Patients.create_patient_association(nurse_user, patient_user.patient, "nurse")

      # Return everything in a single context map
      %{
        patient: patient_user.patient,
        nurse: nurse_user,
        doctor: doctor_user,
        device: device,
        unrelated_patient: unrelated_patient_user.patient
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

    test "broadcast_device_alerts/3 creates alerts for violations", %{
      device: device
    } do
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

      log_output =
        capture_log(fn ->
          assert {:error, :patient_not_found} =
                   Alerts.broadcast_device_alerts("unknown_device", %{}, violations)
        end)

      assert log_output =~ "No patient found for device_id: \"unknown_device\""
    end

    test "get_active_alerts_for_user/1 returns only alerts for the provider's patients", %{
      nurse: nurse,
      patient: patient,
      unrelated_patient: unrelated_patient
    } do
      Alerts.create_alert(%{
        message: "Nurse should see this",
        patient_id: patient.id,
        type: "test",
        severity: "high"
      })

      Alerts.create_alert(%{
        message: "Nurse should NOT see this",
        patient_id: unrelated_patient.id,
        type: "test",
        severity: "high"
      })

      alerts_for_nurse = Alerts.get_active_alerts_for_user(nurse)

      assert length(alerts_for_nurse) == 1
      assert hd(alerts_for_nurse).alert.message == "Nurse should see this"
    end

    test "dismiss_alert/3 updates the alert's status and audit fields", %{
      nurse: nurse,
      patient: patient
    } do
      {:ok, alert} =
        Alerts.create_alert(%{
          message: "To be dismissed",
          patient_id: patient.id,
          type: "test",
          severity: "high"
        })

      # Pass the full `alert` and `nurse` structs, not their IDs
      assert {:ok, %Alert{} = dismissed_alert} =
               Alerts.dismiss_alert(alert, nurse, "Test dismissal")

      assert dismissed_alert.status == "dismissed"
      assert dismissed_alert.dismissed_by_user_id == nurse.id
      assert dismissed_alert.dismissal_reason == "Test dismissal"
      assert dismissed_alert.dismissed_at
    end

    test "acknowledge_critical_alert/2 updates the flag and stops the timer", %{
      doctor: doctor,
      patient: patient
    } do
      {:ok, alert} =
        Alerts.create_alert(%{
          message: "To be acknowledged",
          patient_id: patient.id,
          type: "test",
          severity: "critical"
        })

      assert Registry.whereis_name({Ankaa.Notifications.AlertRegistry, alert.id}) != :undefined
      assert {:ok, %Alert{} = acked_alert} = Alerts.acknowledge_critical_alert(alert, doctor.id)
      assert acked_alert.acknowledged == true
      assert Registry.whereis_name({Ankaa.Notifications.AlertRegistry, alert.id}) == :undefined
    end
  end
end
