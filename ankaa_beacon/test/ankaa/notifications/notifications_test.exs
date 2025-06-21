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
        patient_id: patient.id
      }

      assert {:ok, %Alert{} = alert} = Alerts.create_alert(attrs)
      assert alert.type == "threshold_violation"
      assert alert.message =~ "BP too low"
      assert alert.patient_id == patient.id
    end

    test "broadcast_alerts/2 creates alerts and sends notifications", %{
      device: device,
      patient: patient
    } do
      reading = %{device_id: device.device_id}

      violations = [
        %{
          parameter: :systolic,
          value: 60,
          threshold: 80,
          severity: :high,
          message: "Systolic pressure is too low"
        }
      ]

      Alerts.broadcast_alerts(reading, violations)

      alerts = Repo.all(Alert)
      assert length(alerts) == 1
      assert hd(alerts).patient_id == patient.id
      assert hd(alerts).message =~ "Systolic"
    end
  end
end
