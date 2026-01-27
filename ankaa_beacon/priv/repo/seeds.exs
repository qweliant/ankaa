alias Ankaa.Accounts
alias Ankaa.Communities
alias Ankaa.Patients

IO.puts("🌱 Seeding database...")

IO.puts("   -> Creating organizations...")

{:ok, clinic_org} =
  Communities.create_organization(%{
    name: "Romdeau General Hospital",
    type: "clinic",
    npi_number: "1999999999",
    description:
      "A major hospital in the city of Romdeau, providing comprehensive healthcare services to the community.",
    is_public: false
  })

{:ok, commune_org} =
  Communities.create_organization(%{
    name: "The Commune Support Group",
    type: "community_center",
    npi_number: nil,
    description:
      "A community organization focused on providing support and resources to patients and caregivers outside the Romdeau walls.",
    is_public: true
  })

create_staff = fn attrs, role, org_id, org_role ->
  user = Accounts.get_user_by_email(attrs.email)

  user =
    if user do
      user
    else
      {:ok, new_user} = Accounts.register_user(attrs)
      {:ok, named_user} = Accounts.update_user_profile(new_user, attrs)
      {:ok, role_user} = Accounts.assign_role(named_user, role)
      role_user
    end

  if org_id do
    case Communities.add_member(user, org_id, org_role) do
      {:ok, _} ->
        IO.puts("     - Linked #{attrs.first_name} to Org as #{org_role}")

      {:error, _} ->
        IO.puts("     - #{attrs.first_name} is already a member")
    end
  end

  {:ok, user}
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
      npi_number: "1111111111",
      practice_state: "Romdeau"
    },
    "doctor",
    clinic_org.id,
    "admin"
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
    clinic_org.id,
    "moderator"
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
    clinic_org.id,
    "member"
  )

# Social Worker (In Clinic) - Pino supports the patients
{:ok, worker_pino} =
  create_staff.(
    %{
      email: "pino.companion@example.com",
      password: "password1234",
      first_name: "Pino",
      last_name: "Creed",
      npi_number: "3333333333",
      practice_state: "Romdeau"
    },
    "social_worker",
    clinic_org.id,
    "member"
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
    commune_org.id,
    "admin"
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
    nil,
    nil
  )

IO.puts("   -> Creating patients...")

{:ok, user_rel} =
  Accounts.register_user(%{email: "rel.mayer@example.com", password: "password1234", first_name: "Re-l", last_name: "Mayer"})

{:ok, _} = Accounts.update_user_name(user_rel, %{first_name: "Re-l", last_name: "Mayer"})

patient_attrs_rel = %{name: "Re-l Mayer", date_of_birth: ~D[2000-01-01], timezone: "Etc/UTC"}
{:ok, patient_rel} = Patients.create_patient(patient_attrs_rel, user_rel)
Communities.add_member(user_rel, clinic_org.id, "member")

{:ok, user_vincent} =
  Accounts.register_user(%{email: "vincent.law@example.com", password: "password1234", first_name: "Vincent", last_name: "Law"})

{:ok, _} = Accounts.update_user_name(user_vincent, %{first_name: "Vincent", last_name: "Law"})

patient_attrs_vincent = %{name: "Vincent Law", date_of_birth: ~D[1995-05-05], timezone: "Etc/UTC"}
{:ok, patient_vincent} = Patients.create_patient(patient_attrs_vincent, user_vincent)
Communities.add_member(user_vincent, commune_org.id, "member")
Communities.add_member(worker_pino, commune_org.id, "member")
Communities.add_member(user_rel, commune_org.id, "member")

IO.puts("   -> Building care networks...")

# Re-l's Network
Patients.create_patient_association(dr_daedalus, patient_rel, "doctor", :admin, :doctor)
Patients.create_patient_association(support_iggy, patient_rel, "caresupport", :viewer, :caresupport)
Patients.create_patient_association(tech_raul, patient_rel, "clinic_technician", :contributor, :tech)

# Vincent's Network
Patients.create_patient_association(dr_daedalus, patient_vincent, "doctor", :admin, :doctor)
Patients.create_patient_association(nurse_kristeva, patient_vincent, "nurse", :moderator, :nurse)
Patients.create_patient_association(coord_hoody, patient_vincent, "community_coordinator", :viewer, :community_coordinator)
Patients.create_patient_association(worker_pino, patient_vincent, "social_worker", :contributor, :social_worker)
Patients.create_patient_association(support_iggy, patient_vincent, "caresupport", :viewer, :caresupport)

IO.puts("   -> Seeding Community Content (Feature Parity Check)...")

Communities.create_post(%{
  "organization_id" => commune_org.id,
  "author_id" => coord_hoody.id,
  "title" => "Petition: Better Water Quality",
  "body" =>
    "The water pressure in Sector 4 is dropping again. We need to email the maintenance bureau.",
  "type" => "action_item",
  "action_label" => "Email Bureau",
  "action_target" => "maintenance@romdeau.gov",
  "action_subject" => "Sector 4 Water Pressure",
  "action_script" => "To whom it may concern..."
})

Communities.create_post(%{
  "organization_id" => commune_org.id,
  "author_id" => coord_hoody.id,
  "title" => "Weekly Gathering Moved",
  "body" => "We are meeting in the lower atrium this week due to repairs.",
  "type" => "announcement",
  "is_pinned" => true
})

Communities.create_resource(%{
  "organization_id" => commune_org.id,
  "title" => "Traveling with Home Dialysis",
  "url" => "https://example.com/travel-guide",
  "category" => "Lifestyle",
  "description" => "Tips for packing your cycler and fluids."
})

Communities.create_board_item(%{
  "organization_id" => commune_org.id,
  "user_id" => user_vincent.id,
  "item_name" => "Drain Bags (5L)",
  "description" => "Running low on drain bags, shipment delayed. Can anyone spare a box?",
  "type" => "requesting",
  "status" => "approved"
})

Communities.create_post(%{
  "organization_id" => clinic_org.id,
  "author_id" => dr_daedalus.id,
  "title" => "Mandatory Cytogene Scanning Phase 4",
  "body" => "All citizens of Class B and C must report to the Medical Bureau for genetic stability checks. We have detected minor deviations in the WombSys output. Your cooperation ensures the stability of the Dome.",
  "type" => "announcement",
  "is_pinned" => true
})

Communities.create_post(%{
  "organization_id" => clinic_org.id,
  "author_id" => tech_raul.id,
  "title" => "Security Alert: AutoReiv Malfunctions",
  "body" => "Reports of 'self-aware' behavior in medical AutoReivs are increasing. If your Entourage unit begins asking philosophical questions or ignoring commands, it may be infected with the Cogito virus. Isolate immediately.",
  "type" => "announcement",
  "is_pinned" => false
})


Communities.create_post(%{
  "organization_id" => clinic_org.id,
  "author_id" => tech_raul.id,
  "title" => "Report Unregistered Immigrants",
  "body" => "The purity of Romdeau depends on strict population control. Report any sightings of individuals from the Commune attempting to bypass health checkpoints.",
  "type" => "action_item",
  "action_label" => "Report Violation",
  "action_target" => "security@bureau.romdeau.gov",
  "action_subject" => "Sector Violation Report",
  "action_script" => "I have witnessed an unauthorized entry at Sector..."
})

Communities.create_resource(%{
  "organization_id" => clinic_org.id,
  "title" => "Entourage Unit Maintenance Guide",
  "url" => "https://example.com/autoreiv-maintenance",
  "category" => "Technical",
  "description" => "Standard operating procedures for Entourage-type AutoReivs. Includes Turing Application reset codes."
})

Communities.create_resource(%{
  "organization_id" => clinic_org.id,
  "title" => "WombSys: Infant Care Protocols",
  "url" => "https://example.com/wombsys",
  "category" => "Lifestyle",
  "description" => "Guidelines for citizens receiving new assignments from the artificial womb system."
})

Communities.create_board_item(%{
  "organization_id" => clinic_org.id,
  "user_id" => dr_daedalus.id,
  "item_name" => "Amrita Cell Samples",
  "description" => "Requiring high-purity Amrita cells for Project Proxy. Level 5 Clearance required.",
  "type" => "requesting",
  "status" => "approved"
})

Communities.create_board_item(%{
  "organization_id" => clinic_org.id,
  "user_id" => worker_pino.id,
  "item_name" => "Rabbit Drawing",
  "description" => "I drew a picture of a rabbit! It is free.",
  "type" => "offering",
  "status" => "pending" # Daedalus probably hasn't approved this yet because it's "inefficient"
})

IO.puts("✅ Database seeding complete.")
