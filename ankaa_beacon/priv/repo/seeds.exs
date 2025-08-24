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

# Note: It's best practice to run `mix ecto.reset` before seeding to ensure
# you start with a clean, empty database.
IO.puts("🌱 Seeding database with Ergo Proxy theme...")

# --------------------------------------------------------------------------
# 1. Create the Care Team
# --------------------------------------------------------------------------
IO.puts("   -> Creating care team...")

{:ok, dr_daedalus} =
  Accounts.register_user(%{
    email: "daedalus.yumeno@example.com",
    password: "password1234",
    first_name: "Daedalus",
    last_name: "Yumeno"
  })
|> elem(1) |> Accounts.assign_role("doctor")

IO.puts("     - Dr. Daedalus Yumeno (doctor)")

{:ok, nurse_kristeva} =
  Accounts.register_user(%{
    email: "kristeva.unit@example.com",
    password: "password1234",
    first_name: "Kristeva",
    last_name: ""
  })
|> elem(1) |> Accounts.assign_role("nurse")

IO.puts("     - Kristeva (nurse)")

{:ok, support_iggy} =
  Accounts.register_user(%{
    email: "iggy.autoreiv@example.com",
    password: "password1234",
    first_name: "Iggy",
    last_name: ""
  })
|> elem(1) |> Accounts.assign_role("caresupport")

IO.puts("     - Iggy (caresupport)")

# --------------------------------------------------------------------------
# 2. Create the Patients
# --------------------------------------------------------------------------
IO.puts("   -> Creating patients...")

# --- Patient 1: Re-l Mayer ---
{:ok, user_rel} =
  Accounts.register_user(%{
    email: "rel.mayer@example.com",
    password: "password1234"
  })

patient_attrs_rel = %{
  name: "Re-l Mayer",
  date_of_birth: ~D[2000-01-01],
  timezone: "Etc/UTC"
}

{:ok, patient_rel} = Patients.create_patient(patient_attrs_rel, user_rel)
IO.puts("     - Patient 'Re-l Mayer' created.")

# --- Patient 2: Vincent Law ---
{:ok, user_vincent} =
  Accounts.register_user(%{
    email: "vincent.law@example.com",
    password: "password1234"
  })

patient_attrs_vincent = %{
  name: "Vincent Law",
  date_of_birth: ~D[1995-05-05],
  timezone: "Etc/UTC"
}

{:ok, patient_vincent} = Patients.create_patient(patient_attrs_vincent, user_vincent)
IO.puts("     - Patient 'Vincent Law' created.")

# --------------------------------------------------------------------------
# 3. Link the Care Team to the Patients
# --------------------------------------------------------------------------
IO.puts("   -> Building care networks...")

# Dr. Daedalus manages both patients
Patients.create_patient_association(dr_daedalus, patient_rel, "doctor")
IO.puts("     - Linked Dr. Daedalus to Re-l Mayer")
Patients.create_patient_association(dr_daedalus, patient_vincent, "doctor")
IO.puts("     - Linked Dr. Daedalus to Vincent Law")

# Nurse Kristeva is assigned to Vincent
Patients.create_patient_association(nurse_kristeva, patient_vincent, "nurse")
IO.puts("     - Linked Nurse Kristeva to Vincent Law")

# Iggy is Re-l's care support
Patients.create_patient_association(support_iggy, patient_rel, "caresupport")
IO.puts("     - Linked Iggy to Re-l Mayer")


IO.puts("✅ Database seeding complete.")
