defmodule Ankaa.NotificationsTest do
  use Ankaa.DataCase

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

      Patients.create_patient_association(nurse_user, patient_user.patient, "nurse", :contributor, :nurse)

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
               Alerts.dismiss_alert(alert.id, nurse, "Test dismissal")

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
