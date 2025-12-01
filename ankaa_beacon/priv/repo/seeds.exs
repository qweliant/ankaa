alias Ankaa.Accounts
alias Ankaa.Patients

IO.puts("🌱 Seeding database...")

IO.puts("   -> Creating organizations...")

{:ok, clinic_org} = Accounts.create_organization(%{
  name: "Romdeau General Hospital",
  type: "clinic",
  npi_number: "1999999999" # Fake Org NPI (Type 2)
})

{:ok, commune_org} = Accounts.create_organization(%{
  name: "The Commune Support Group",
  type: "community_center",
  npi_number: nil
})


create_staff = fn attrs, role, org_id ->
  with {:ok, user} <- Accounts.register_user(attrs),
       {:ok, user_with_name} <- Accounts.update_user_profile(user, attrs),
       {:ok, user_with_role} <- Accounts.assign_role(user_with_name, role) do

    if org_id do
      Accounts.assign_organization(user_with_role, org_id)
    end

    IO.puts("     - Created #{role}: #{user_with_role.email} (#{attrs[:first_name]})")
    {:ok, user_with_role}
  else
    {:error, reason} ->
      IO.puts("     - FAILED to create #{role} (#{attrs[:email]}):")
      IO.inspect(reason)
      {:error, reason}
  end
end

IO.puts("   -> Creating care team...")

# Doctor (In Clinic)
{:ok, dr_daedalus} =
  create_staff.(
    %{
      email: "daedalus.yumeno@example.com",
      password: "password1234",
      first_name: "Daedalus",
      last_name: "Yumeno",
      npi_number: "1111111111", # Fake NPI
      practice_state: "Romdeau"
    },
    "doctor",
    clinic_org.id
  )

# Nurse (In Clinic)
{:ok, nurse_kristeva} =
  create_staff.(
    %{
      email: "kristeva.unit@example.com",
      password: "password1234",
      first_name: "Kristeva",
      last_name: "Unit",
      npi_number: "2222222222",
      practice_state: "Romdeau"
    },
    "nurse",
    clinic_org.id
  )

# Tech (In Clinic) - Raul manages the systems
{:ok, tech_raul} =
  create_staff.(
    %{
      email: "raul.creed@example.com",
      password: "password1234",
      first_name: "Raul",
      last_name: "Creed"
    },
    "clinic_technician",
    clinic_org.id
  )

# Social Worker (In Clinic) - Pino supports the patients
{:ok, worker_pino} =
  create_staff.(
    %{
      email: "pino.companion@example.com",
      password: "password1234",
      first_name: "Pino",
      last_name: "Cast",
      npi_number: "3333333333",
      practice_state: "Romdeau"
    },
    "social_worker",
    clinic_org.id
  )

# Community Coordinator (In Commune) - Hoody is separate from the hospital
{:ok, coord_hoody} =
  create_staff.(
    %{
      email: "hoody.commune@example.com",
      password: "password1234",
      first_name: "Hoody",
      last_name: "Commune"
    },
    "community_coordinator",
    commune_org.id
  )

# Care Support (Independent) - Iggy belongs to the patient, not an org
{:ok, support_iggy} =
  create_staff.(
    %{
      email: "iggy.autoreiv@example.com",
      password: "password1234",
      first_name: "Iggy",
      last_name: "Autoreiv"
    },
    "caresupport",
    nil
  )

IO.puts("   -> Creating patients...")

{:ok, user_rel} =
  Accounts.register_user(%{email: "rel.mayer@example.com", password: "password1234"})
{:ok, _} = Accounts.update_user_name(user_rel, %{first_name: "Re-l", last_name: "Mayer"})

patient_attrs_rel = %{name: "Re-l Mayer", date_of_birth: ~D[2000-01-01], timezone: "Etc/UTC"}
{:ok, patient_rel} = Patients.create_patient(patient_attrs_rel, user_rel)

{:ok, user_vincent} =
  Accounts.register_user(%{email: "vincent.law@example.com", password: "password1234"})
{:ok, _} = Accounts.update_user_name(user_vincent, %{first_name: "Vincent", last_name: "Law"})

patient_attrs_vincent = %{name: "Vincent Law", date_of_birth: ~D[1995-05-05], timezone: "Etc/UTC"}
{:ok, patient_vincent} = Patients.create_patient(patient_attrs_vincent, user_vincent)


IO.puts("   -> Building care networks...")

# Re-l's Network
Patients.create_patient_association(dr_daedalus, patient_rel, "doctor")
Patients.create_patient_association(support_iggy, patient_rel, "caresupport")
Patients.create_patient_association(tech_raul, patient_rel, "clinic_technician")

# Vincent's Network
Patients.create_patient_association(dr_daedalus, patient_vincent, "doctor")
Patients.create_patient_association(nurse_kristeva, patient_vincent, "nurse")
Patients.create_patient_association(coord_hoody, patient_vincent, "community_coordinator")
Patients.create_patient_association(worker_pino, patient_vincent, "social_worker")
Patients.create_patient_association(support_iggy, patient_vincent, "caresupport")

IO.puts("✅ Database seeding complete.")
