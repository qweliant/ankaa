defmodule AnkaaWeb.RoleAuth do
  import Phoenix.LiveView
  import Phoenix.Component
  use AnkaaWeb, :verified_routes

  def on_mount(:require_role, roles, _params, _session, socket) do
    socket = mount_current_user(socket)

    if socket.assigns.current_user && socket.assigns.current_user.role in roles do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You are not authorized to access this page.")
        |> redirect(to: ~p"/")

      {:halt, socket}
    end
  end

  def on_mount(:require_doctor, _params, _session, socket) do
    on_mount(:require_role, ["doctor", "admin"], nil, nil, socket)
  end

  def on_mount(:require_nurse, _params, _session, socket) do
    on_mount(:require_role, ["nurse", "admin"], nil, nil, socket)
  end

  def on_mount(:require_clinical_staff, _params, _session, socket) do
    on_mount(:require_role, ["doctor", "nurse", "clinic_technician", "admin"], nil, nil, socket)
  end

  def on_mount(:require_doctor_or_nurse, _params, _session, socket) do
    on_mount(:require_role, ["doctor", "nurse", "clinic_technician", "admin"], nil, nil, socket)
  end

  def on_mount(:require_caresupport, _params, _session, socket) do
    on_mount(:require_role, ["caresupport"], nil, nil, socket)
  end

  def on_mount(:require_technical_support, _params, _session, socket) do
    on_mount(:require_role, ["technical_support", "admin"], nil, nil, socket)
  end

  def on_mount(:require_clinic_technician, _params, _session, socket) do
    on_mount(:require_role, ["clinic_technician", "admin"], nil, nil, socket)
  end

  def on_mount(:require_community_coordinator, _params, _session, socket) do
    on_mount(:require_role, ["community_coordinator", "admin"], nil, nil, socket)
  end

  def on_mount(:require_social_worker, _params, _session, socket) do
    on_mount(:require_role, ["social_worker", "admin"], nil, nil, socket)
  end

  def on_mount(:require_patient, _params, _session, socket) do
    socket = mount_current_user(socket)

    if socket.assigns.current_user && Ankaa.Accounts.User.patient?(socket.assigns.current_user) do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You must be a patient to access this page.")
        |> redirect(to: ~p"/register")

      {:halt, socket}
    end
  end


  def on_mount(:require_community_access, _params, _session, socket) do
    socket = mount_current_user(socket)
    user = socket.assigns.current_user

    has_role =
      user &&
        user.role in [
          "doctor",
          "nurse",
          "clinic_technician",
          "social_worker",
          "community_coordinator",
          "admin"
        ]

    is_patient = user && Ankaa.Accounts.User.patient?(user)

    if has_role or is_patient do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "Unauthorized. You must be a Peer Mentor to access this page.")
        |> redirect(to: ~p"/")

      {:halt, socket}
    end
  end

  defp mount_current_user(socket) do
    # Get the session from assigns if available
    session = socket.assigns[:session] || %{}

    assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        Ankaa.Accounts.get_user_by_session_token(user_token)
      end
    end)
  end
end
