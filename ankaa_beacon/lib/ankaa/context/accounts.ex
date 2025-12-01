defmodule Ankaa.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Ankaa.Repo

  alias Ankaa.Accounts.{User, UserToken, UserNotifier, UserRole}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates a user's first and last name.
  """
  def update_user_name(user, attrs) do
    user
    |> User.name_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  @dialyzer {:nowarn_function, update_user_email: 2}
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  @dialyzer {:nowarn_function, user_email_multi: 2}
  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)

    Repo.one(query)
    |> case do
      nil -> nil
      user -> Repo.preload(user, :patient)
    end
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Creates a new user role.

  ## Examples

      iex> create_user_role(%{value: "doctor", description: "Medical professional"})
      {:ok, %UserRole{}}

      iex> create_user_role(%{value: "doctor"})
      {:error, %Ecto.Changeset{}}
  """
  def create_user_role(attrs \\ %{}) do
    %UserRole{}
    |> UserRole.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Assigns a role to a user.

  ## Examples

      iex> assign_role(user, "doctor")
      {:ok, %User{}}

      iex> assign_role(user, "invalid_role")
      {:error, %Ecto.Changeset{}}
  """
  def assign_role(%User{} = user, role) when is_binary(role) do
    User.assign_role(user, role)
  end

  @doc """
  Checks if a user has a specific role.

  ## Examples

      iex> has_role?(user, "doctor")
      true

      iex> has_role?(user, "nurse")
      false
  """
  def has_role?(%User{} = user, role) when is_binary(role) do
    User.has_role?(user, role)
  end

  @doc """
  Returns `true` if the given user has the "doctor" role.

  This check delegates to `has_role?(user, "doctor")` and expects a user struct or map that `has_role?/2` can inspect.
  """
  def doctor?(user), do: has_role?(user, "doctor")

  @doc """
  Returns `true` if the given user has the "nurse" role.

  This check delegates to `has_role?(user, "nurse")` and expects a user struct or map that `has_role?/2` can inspect.
  """
  def nurse?(user), do: has_role?(user, "nurse")

  @doc """
  Returns `true` if the given user has the "admin" role.

  This check delegates to `has_role?(user, "admin")` and expects a user struct or map that `has_role?/2` can inspect.
  """
  def admin?(user), do: has_role?(user, "admin")

  @doc """
  Returns `true` if the given user has the "caresupport" role.

  This check delegates to `has_role?(user, "caresupport")` and expects a user struct or map that `has_role?/2` can inspect.
  """
  def caresupport?(user), do: has_role?(user, "caresupport")

  @doc """
  Returns `true` if the given user has the "technical_support" role.

  This check delegates to `has_role?(user, "technical_support")` and expects a user struct or map that `has_role?/2` can inspect.
  """
  def technical_support?(user), do: has_role?(user, "technical_support")

  @doc """
  Returns `true` if the given user is considered a patient.

  This delegates to `User.patient?/1`, so the concrete determination of "patient" is implemented on the `User` module.
  """
  def patient?(user), do: User.patient?(user)

  @doc """
  Generates a short-lived, single-use token to log a user in.
  This uses the existing hashed token system.
  """
  def generate_temporary_login_token(%User{} = user) do
    {raw_token, user_token} = UserToken.build_email_token(user, "login")

    Repo.insert!(user_token)

    raw_token
  end

  @doc """
  Verifies the temporary login token and consumes it.
  """
  def get_user_by_temporary_login_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "login"),
         %User{} = user <- Repo.one(query) do
      # For security, delete all "login" tokens for this user after one is used.
      Repo.delete_all(UserToken.by_user_and_contexts_query(user, ["login"]))
      {:ok, user}
    else
      _ -> {:error, :not_found}
    end
  end

  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.provider_profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Assigns an existing user to an organization.
  """
  def assign_organization(%User{} = user, organization_id) do
    user
    |> User.organization_changeset(%{organization_id: organization_id})
    |> Repo.update()
  end

  @doc """
  Creates a new organization.
  (Useful for the first Doctor registering a clinic)
  """
  def create_organization(attrs \\ %{}) do
    %Ankaa.Accounts.Organization{}
    |> Ankaa.Accounts.Organization.changeset(attrs)
    |> Repo.insert()
  end
end
