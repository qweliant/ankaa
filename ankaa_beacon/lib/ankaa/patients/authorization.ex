defmodule Ankaa.Patients.Authorization do
  alias Ankaa.Patients.CareNetwork

  # Map Roles to Permissions
  # :owner -> everything
  # :admin -> edit settings, manage members
  # :contributor -> add logs, view data
  # :viewer -> read only

  def can?(%CareNetwork{role: :owner}, _action), do: true

  def can?(%CareNetwork{role: :admin}, action) when action in [:edit_patient, :invite_member, :add_log, :view_dashboard], do: true

  def can?(%CareNetwork{role: :contributor}, action) when action in [:add_log, :view_dashboard], do: true

  def can?(%CareNetwork{role: :viewer}, :view_dashboard), do: true

  def can?(_, _), do: false
end
