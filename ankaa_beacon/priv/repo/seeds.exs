# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Ankaa.Repo.insert!(%Ankaa.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Ankaa.Accounts
alias Ankaa.Patients

IO.puts("🌱 Seeding database...")

# Define an anonymous function for creating providers
# Generic helper to create a user (provider or staff)
create_user = fn attrs, role ->
  with {:ok, user} <- Accounts.register_user(attrs),
       {:ok, user_with_name} <- Accounts.update_user_name(user, attrs),
       {:ok, user_with_role} <- Accounts.assign_role(user_with_name, role) do
    IO.puts("     - Created #{role}: #{user_with_role.email}")
    {:ok, user_with_role}
  else
    {:error, reason} ->
      IO.puts("     - FAILED to create #{role} (#{attrs[:email]}):")
      IO.inspect(reason)
      {:error, reason}
  end
end

IO.puts("   -> Creating care team...")

{:ok, dr_daedalus} =
  create_user.(
    %{
      email: "daedalus.yumeno@example.com",
      password: "password1234",
      first_name: "Daedalus",
      last_name: "Yumeno"
    },
    "doctor"
  )

{:ok, nurse_kristeva} =
  create_user.(
    %{
      email: "kristeva.unit@example.com",
      password: "password1234",
      first_name: "Kristeva",
      last_name: "Unit"
    },
    "nurse"
  )

{:ok, support_iggy} =
  create_user.(
    %{
      email: "iggy.autoreiv@example.com",
      password: "password1234",
      first_name: "Iggy",
      last_name: "Autoreiv"
    },
    "caresupport"
  )

{:ok, tech_raul} =
  create_user.(
    %{
      email: "raul.creed@example.com",
      password: "password1234",
      first_name: "Raul",
      last_name: "Creed"
    },
    "clinic_technician"
  )

{:ok, coord_hoody} =
  create_user.(
    %{
      email: "hoody.commune@example.com",
      password: "password1234",
      first_name: "Hoody",
      last_name: "Commune"
    },
    "community_coordinator"
  )

{:ok, worker_pino} =
  create_user.(
    %{
      email: "pino.companion@example.com",
      password: "password1234",
      first_name: "Pino",
      last_name: "Cast"
    },
    "social_worker"
  )

IO.puts("   -> Creating patients...")

{:ok, user_rel} =
  Accounts.register_user(%{email: "rel.mayer@example.com", password: "password1234", first_name: "Re-l", last_name: "Mayer"})
patient_attrs_rel = %{name: "Re-l Mayer", date_of_birth: ~D[2000-01-01], timezone: "Etc/UTC"}
{:ok, patient_rel} = Patients.create_patient(patient_attrs_rel, user_rel)

{:ok, user_vincent} =
  Accounts.register_user(%{email: "vincent.law@example.com", password: "password1234", first_name: "Vincent", last_name: "Law"})
patient_attrs_vincent = %{name: "Vincent Law", date_of_birth: ~D[1995-05-05], timezone: "Etc/UTC"}
{:ok, patient_vincent} = Patients.create_patient(patient_attrs_vincent, user_vincent)

IO.puts("   -> Building care networks...")
Patients.create_patient_association(dr_daedalus, patient_rel, "doctor")
Patients.create_patient_association(support_iggy, patient_rel, "caresupport")
Patients.create_patient_association(tech_raul, patient_rel, "clinic_technician")

Patients.create_patient_association(dr_daedalus, patient_vincent, "doctor")
Patients.create_patient_association(nurse_kristeva, patient_vincent, "nurse")
Patients.create_patient_association(coord_hoody, patient_vincent, "community_coordinator")
Patients.create_patient_association(worker_pino, patient_vincent, "social_worker")
Patients.create_patient_association(support_iggy, patient_vincent, "caresupport")
IO.puts("✅ Database seeding complete.")
