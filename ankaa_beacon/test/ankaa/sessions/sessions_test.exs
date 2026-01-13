defmodule Ankaa.SessionsTest do
  use Ankaa.DataCase, async: true

  alias Ankaa.Sessions
  alias Ankaa.Sessions.Session
  alias Ankaa.AccountsFixtures
  alias Ankaa.Devices

  setup do
    patient_user = AccountsFixtures.patient_fixture()
    patient = patient_user.patient

    {:ok, device} = Devices.create_device(%{
      model: "Fresenius 5008",
      type: "dialysis",
      patient_id: patient.id,
      simulation_scenario: "Normal"
    })

    %{patient: patient, device: device}
  end

  describe "sessions lifecycle" do
    test "create_session/1 starts a new ongoing session", %{patient: patient} do
      attrs = %{
        patient_id: patient.id,
        start_time: DateTime.utc_now(),
        status: "ongoing"
      }

      assert {:ok, %Session{} = session} = Sessions.create_session(attrs)
      assert session.status == "ongoing"
      assert session.patient_id == patient.id
    end

    test "create_session/1 fails with invalid data" do
      assert {:error, %Ecto.Changeset{}} = Sessions.create_session(%{status: nil})
    end
  end

  describe "active session retrieval" do
    test "get_active_session_for_patient/1 returns the ongoing session", %{patient: patient} do
      {:ok, _created} = Sessions.create_session(%{
        patient_id: patient.id,
        start_time: DateTime.utc_now(),
        status: "ongoing"
      })

      active = Sessions.get_active_session_for_patient(patient.id)

      assert active.status == "ongoing"
      assert active.patient_id == patient.id
    end

    test "get_active_session_for_patient/1 returns nil if session is completed", %{patient: patient} do
      {:ok, _created} = Sessions.create_session(%{
        patient_id: patient.id,
        start_time: DateTime.utc_now(),
        end_time: DateTime.utc_now(),
        status: "completed"
      })

      result = Sessions.get_active_session_for_patient(patient.id)
      assert result == nil
    end
  end

  describe "session management" do
    setup %{patient: patient} do
      {:ok, session} = Sessions.create_session(%{
        patient_id: patient.id,
        start_time: DateTime.utc_now(),
        status: "ongoing"
      })
      %{session: session}
    end

    test "update_session/2 updates fields", %{session: session} do
      update_attrs = %{notes: "Patient feeling better"}
      assert {:ok, %Session{} = updated} = Sessions.update_session(session, update_attrs)
      assert updated.notes == "Patient feeling better"
    end

    test "end_session/1 sets status to completed and sets end_time", %{session: session} do
      assert {:ok, %Session{} = ended} = Sessions.end_session(session)

      assert ended.status == "completed"
      refute is_nil(ended.end_time)

      assert nil == Sessions.get_active_session_for_patient(session.patient_id)
    end

    test "end_session/2 allows overriding end attributes", %{session: session} do
      custom_end_time = DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.truncate(:second)
      assert {:ok, %Session{} = ended} =
        Sessions.end_session(session, %{end_time: custom_end_time, notes: "Ended early"})

      assert ended.status == "completed"
      assert ended.notes == "Ended early"
      # Compare ISO strings to ensure time was set correctly
      assert DateTime.to_iso8601(ended.end_time) == DateTime.to_iso8601(custom_end_time)
    end

    test "delete_session/1 deletes the session", %{session: session} do
      assert {:ok, %Session{}} = Sessions.delete_session(session)
      assert_raise Ecto.NoResultsError, fn -> Sessions.get_session!(session.id) end
    end
  end

  describe "historical queries" do
    test "list_sessions_for_patient/1 returns history newest first", %{patient: p1} do
      {:ok, s1} = Sessions.create_session(%{
        patient_id: p1.id,
        status: "completed",
        start_time: DateTime.add(DateTime.utc_now(), -2, :hour)
      })

      {:ok, s2} = Sessions.create_session(%{
        patient_id: p1.id,
        status: "completed",
        start_time: DateTime.utc_now()
      })

      sessions = Sessions.list_sessions_for_patient(p1.id)

      assert [first, second] = sessions
      assert first.id == s2.id
      assert second.id == s1.id
    end

    test "get_latest_session_for_patient/1 returns only the most recent one", %{patient: p1} do
      Sessions.create_session(%{patient_id: p1.id, start_time: DateTime.add(DateTime.utc_now(), -10, :day)})
      {:ok, new_session} = Sessions.create_session(%{patient_id: p1.id, start_time: DateTime.utc_now()})

      latest = Sessions.get_latest_session_for_patient(p1)
      assert latest.id == new_session.id
    end
  end
end
