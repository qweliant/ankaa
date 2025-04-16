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
    on_mount(:require_role, ["nurse", "doctor", "admin"], nil, nil, socket)
  end

  def on_mount(:require_doctor_or_nurse, _params, _session, socket) do
    on_mount(:require_role, ["doctor", "nurse", "admin"], nil, nil, socket)
  end

  def on_mount(:require_caregiver, _params, _session, socket) do
    on_mount(:require_role, ["caregiver", "nurse", "doctor", "admin"], nil, nil, socket)
  end

  def on_mount(:require_technical_support, _params, _session, socket) do
    on_mount(:require_role, ["technical_support", "admin"], nil, nil, socket)
  end

  def on_mount(:require_patient, _params, _session, socket) do
    socket = mount_current_user(socket)

    if socket.assigns.current_user && Ankaa.Accounts.User.is_patient?(socket.assigns.current_user) do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You must be a patient to access this page.")
        |> redirect(to: ~p"/register")

      {:halt, socket}
    end
  end

  defp mount_current_user(socket) do
    assign_new(socket, :current_user, fn ->
      if user_token = get_connect_params(socket)["user_token"] do
        Ankaa.Accounts.get_user_by_session_token(user_token)
      end
    end)
  end
end
