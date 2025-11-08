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
create_provider = fn attrs, role ->
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
  create_provider.(
    %{
      email: "daedalus.yumeno@example.com",
      password: "password1234",
      first_name: "Daedalus",
      last_name: "Yumeno"
    },
    "doctor"
  )

{:ok, nurse_kristeva} =
  create_provider.(
    %{
      email: "kristeva.unit@example.com",
      password: "password1234",
      first_name: "Kristeva",
      last_name: "Unit"
    },
    "nurse"
  )

{:ok, support_iggy} =
  create_provider.(
    %{
      email: "iggy.autoreiv@example.com",
      password: "password1234",
      first_name: "Iggy",
      last_name: "Autoreiv"
    },
    "caresupport"
  )


IO.puts("   -> Creating patients...")
{:ok, user_rel} = Accounts.register_user(%{email: "rel.mayer@example.com", password: "password1234"})
patient_attrs_rel = %{name: "Re-l Mayer", date_of_birth: ~D[2000-01-01], timezone: "Etc/UTC"}
{:ok, patient_rel} = Patients.create_patient(patient_attrs_rel, user_rel)

{:ok, user_vincent} = Accounts.register_user(%{email: "vincent.law@example.com", password: "password1234"})
patient_attrs_vincent = %{name: "Vincent Law", date_of_birth: ~D[1995-05-05], timezone: "Etc/UTC"}
{:ok, patient_vincent} = Patients.create_patient(patient_attrs_vincent, user_vincent)

IO.puts("   -> Building care networks...")
Patients.create_patient_association(dr_daedalus, patient_rel, "doctor")
Patients.create_patient_association(dr_daedalus, patient_vincent, "doctor")
Patients.create_patient_association(nurse_kristeva, patient_vincent, "nurse")
Patients.create_patient_association(support_iggy, patient_rel, "caresupport")

IO.puts("✅ Database seeding complete.")
