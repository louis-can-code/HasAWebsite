defmodule HasAWebsite.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          # Required fields
          id: integer(),
          email: String.t(),
          username: String.t(),
          role: atom(),
          confirmed_at: DateTime.t(),

          # Nullable fields
          promoted_at: DateTime.t() | nil,
          promoted_by_id: integer() | nil,

          # Virtual fields
          password: String.t() | nil,
          hashed_password: String.t() | nil,
          authenticated_at: DateTime.t() | nil,

          # Associations
          promoted_by: __MODULE__.t() | Ecto.Association.NotLoaded.t() | nil,
          posts: [HasAWebsite.Blog.Post.t()] | Ecto.Association.NotLoaded.t() | nil,

          # Timestamps
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "users" do
    field :email, :string
    field :username, :string
    field :role, Ecto.Enum, values: [:user, :creator, :admin], default: :user
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true
    field :promoted_at, :utc_datetime

    belongs_to :promoted_by, __MODULE__

    has_many :posts, HasAWebsite.Blog.Post, foreign_key: :author_id

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registering a user.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :username])
    |> validate_email(opts)
    |> validate_user_username()
  end

  @reserved_usernames ~w(
    admin administrator root moderator staff
    support system api unknown official
    anonymous null test guest sudo
    )
  defp validate_user_username(changeset) do
    changeset =
      changeset
      |> validate_required([:username])
      |> validate_length(:username, min: 3, max: 36)
      |> validate_format(:username, ~r/^[a-z0-9_-]+$/i,
        message: "can only contain numbers, letters, underscores, and/or hyphens"
      )
      |> validate_format(:username, ~r/^[a-z0-9][a-z0-9_-]*[a-z0-9]$/i,
        message: "must not start or end with a hyphen or underscore"
      )
      |> validate_format(:username, ~r/^(?!.*[_-][_-]).*$/,
        message: "can not contain consecutive special characters"
      )
      |> validate_format(:username, ~r/^[^\s]*$/, message: "can not contain whitespace")
      |> validate_change(:username, fn :username, username ->
        if Enum.any?(@reserved_usernames, &(String.downcase(username) == &1)) do
          [username: "username is reserved"]
        else
          []
        end
      end)

    original_username = changeset.data.username
    new_username = get_field(changeset, :username)

    # maintains case insensitive unique constraint, while allowing users
    # to change the case of their own username
    cond do
      is_nil(original_username) ||
          String.downcase(original_username) != String.downcase(new_username) ->
        changeset
        |> unsafe_validate_unique(:username, HasAWebsite.Repo)
        |> unique_constraint(:username)

      original_username == new_username ->
        add_error(changeset, :username, "did not change")

      true ->
        changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, HasAWebsite.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  A user changeset for promoting a user to the creator role
  """
  def creator_promotion_changeset(promoter, user) do
    user
    |> change()
    |> put_change(:role, :creator)
    |> put_change(:promoted_by_id, promoter.id)
    |> put_change(:promoted_at, DateTime.utc_now(:second))
    |> assoc_constraint(:promoted_by)
  end

  @doc """
  A user changeset for registering creators
  """
  def creator_registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :username])
    |> validate_required([:email, :password, :username])
    |> validate_email(opts)
    |> validate_user_username()
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
    |> put_change(:role, :creator)
  end

  @doc """
  A user changeset for registering admins
  """
  def admin_registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :username])
    |> validate_required([:email, :password, :username])
    |> validate_email(opts)
    |> validate_user_username()
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
    |> put_change(:role, :admin)
  end

  @doc """
  A user changeset for changing the username

  It requires the username to change otherwise an error is added.
  """
  def username_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_user_username()
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

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

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: "at least one digit or punctuation character"
    )
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

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%HasAWebsite.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
