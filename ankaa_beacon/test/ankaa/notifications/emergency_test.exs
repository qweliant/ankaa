defmodule Ankaa.EmergencyTest do
  use Ankaa.DataCase, async: true

  alias Ankaa.Emergency
  alias Ankaa.Emergency.Incident
  alias Ankaa.Alerts
  alias Ankaa.AccountsFixtures

  setup do
    patient_user = AccountsFixtures.patient_fixture()
    patient = patient_user.patient

    # Create a critical alert (usually required to trigger EMS)
    {:ok, alert} = Alerts.create_alert(%{
      patient_id: patient.id,
      type: "fall_detected",
      severity: "critical",
      message: "Patient fell hard"
    })

    %{patient: patient, alert: alert}
  end

  describe "emergency escalation" do
    test "trigger_ems/2 calls dispatcher and creates an Incident record", %{patient: patient, alert: alert} do
      {:ok, dispatch_id} = Emergency.trigger_ems(patient, alert)

      # Assert Dispatch ID format (based on your mock logic)
      # this would change if you switch to a real adapter, so adjust as needed
      assert is_binary(dispatch_id)
      assert String.starts_with?(dispatch_id, "mock_dispatch_")

      incident = Repo.get_by!(Incident, dispatch_id: dispatch_id)

      assert incident.patient_id == patient.id
      assert incident.alert_id == alert.id
      assert incident.status == "dispatched"
      assert incident.trigger_reason == "fall_detected"
      # Check that the snapshot captured the message
      assert incident.vital_snapshot["message"] == "Patient fell hard"
    end

    test "cancel_ems/1 calls the adapter to cancel", %{alert: _alert} do
      # We just need a fake ID since the mock adapter doesn't check if it exists
      dispatch_id = "mock_dispatch_123"

      assert {:ok, "cancelled"} = Emergency.cancel_ems(dispatch_id)
    end
  end
end
