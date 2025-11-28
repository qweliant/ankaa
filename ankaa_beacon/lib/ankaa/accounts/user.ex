defmodule Ankaa.Accounts.User do
  @moduledoc """
  The user schema and changesets.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @roles [
      "admin",
      "doctor",
      "nurse",
      "caresupport",
      "technical_support",
      "clinic_technician",
      "community_coordinator",
      "social_worker"
    ]
  schema "users" do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:password, :string, virtual: true, redact: true)
    field(:hashed_password, :string, redact: true)
    field(:current_password, :string, virtual: true, redact: true)
    field(:confirmed_at, :utc_datetime)
    field(:role, :string)
    field(:npi_number, :string)
    field(:practice_state, :string)

    has_one(:patient, Ankaa.Patients.Patient)
    has_many(:care_network, Ankaa.Patients.CareNetwork)
    has_many(:associated_patients, through: [:care_network, :patient])
    has_many(:alerts_resolved, Ankaa.Notifications.Alert, foreign_key: :resolved_by_id)
    has_many(:alerts_dismissed, Ankaa.Notifications.Alert, foreign_key: :dismissed_by_user_id)

    has_many(:notifications, Ankaa.Notifications.Notification)

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  def name_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name])
    |> validate_required([:first_name, :last_name])
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Ankaa.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Ankaa.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  A changeset for updating a user's role.
  """
  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> validate_inclusion(:role, @roles)
    |> foreign_key_constraint(:role, name: :users_role_fkey, message: "is not a valid role")
  end

  @doc """
  Assigns a role to a user.
  """
  def assign_role(user, role) when is_binary(role) do
    user
    |> role_changeset(%{role: role})
    |> Ankaa.Repo.update()
    |> case do
      {:ok, user} -> {:ok, user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Checks if a user has a specific role.
  """
  def has_role?(%__MODULE__{role: user_role}, role) when is_binary(role) do
    user_role == role
  end

  # Role checking functions
  def doctor?(user), do: has_role?(user, "doctor")
  def nurse?(user), do: has_role?(user, "nurse")
  def admin?(user), do: has_role?(user, "admin")
  def caresupport?(user), do: has_role?(user, "caresupport")
  def technical_support?(user), do: has_role?(user, "technical_support")
  def clinic_technician?(user), do: has_role?(user, "clinic_technician")
  def community_coordinator?(user), do: has_role?(user, "community_coordinator")
  def social_worker?(user), do: has_role?(user, "social_worker")

  def patient?(%__MODULE__{patient: %Ankaa.Patients.Patient{}}), do: true
  def patient?(_), do: false

  @doc """
  Changeset for updating provider profile details (Name + NPI).
  """
def provider_profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :npi_number, :practice_state])
    |> validate_required([:first_name, :last_name])
    |> validate_format(:npi_number, ~r/^\d{10}$/, message: "must be a valid 10-digit NPI")
    |> unique_constraint(:npi_number, message: "this NPI is already registered")
  end
end
