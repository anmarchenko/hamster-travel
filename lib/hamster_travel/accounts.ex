defmodule HamsterTravel.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  require Logger

  alias HamsterTravel.Repo

  alias HamsterTravel.Accounts.{User, UserAvatar, UserCover, UserToken}
  alias HamsterTravel.Geo

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
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  @doc """
  Updates the user email.

  ## Examples

      iex> update_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> update_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_email(user, password, attrs) do
    changeset =
      user
      |> User.email_changeset(attrs)
      |> User.validate_current_password(password)

    Repo.update(changeset)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing general user settings.

  ## Examples

      iex> change_user_settings(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_settings(user, attrs \\ %{}) do
    User.settings_changeset(user, attrs)
  end

  @doc """
  Updates user general settings.
  """
  def update_user_settings(user, attrs) do
    user
    |> User.settings_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_user} ->
        {:ok, Repo.preload(updated_user, home_city: Geo.city_preloading_query())}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Stores a user avatar and updates user avatar URL.

  Returns `{:ok, %User{}}` or `{:error, reason}`.
  """
  def update_user_avatar(%User{} = user, %Plug.Upload{} = upload) do
    case UserAvatar.store({upload, user}) do
      {:ok, file_name} ->
        avatar_url = UserAvatar.url({file_name, user}, :thumb)

        user
        |> Ecto.Changeset.change(avatar_url: "#{avatar_url}?v=#{System.system_time(:second)}")
        |> Repo.update()
        |> case do
          {:ok, updated_user} ->
            {:ok, user_preloading(updated_user)}

          {:error, changeset} = error ->
            Logger.error(
              "Failed to persist avatar URL: user_id=#{user.id} file=#{upload.filename} errors=#{inspect(changeset.errors)}"
            )

            error
        end

      {:error, reason} = error ->
        Logger.error(
          "Failed to store avatar in Waffle: user_id=#{user.id} file=#{upload.filename} content_type=#{upload.content_type} reason=#{inspect(reason)}"
        )

        error
    end
  end

  @doc """
  Removes a user avatar URL.
  """
  def remove_user_avatar(%User{} = user) do
    user
    |> Ecto.Changeset.change(avatar_url: nil)
    |> Repo.update()
    |> case do
      {:ok, updated_user} ->
        {:ok, user_preloading(updated_user)}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Stores a user cover and updates user cover URL.

  Returns `{:ok, %User{}}` or `{:error, reason}`.
  """
  def update_user_cover(%User{} = user, %Plug.Upload{} = upload) do
    case UserCover.store({upload, user}) do
      {:ok, file_name} ->
        cover_url = UserCover.url({file_name, user}, :hero)

        user
        |> Ecto.Changeset.change(cover_url: "#{cover_url}?v=#{System.system_time(:second)}")
        |> Repo.update()
        |> case do
          {:ok, updated_user} ->
            {:ok, user_preloading(updated_user)}

          {:error, changeset} = error ->
            Logger.error(
              "Failed to persist cover URL: user_id=#{user.id} file=#{upload.filename} errors=#{inspect(changeset.errors)}"
            )

            error
        end

      {:error, reason} = error ->
        Logger.error(
          "Failed to store cover in Waffle: user_id=#{user.id} file=#{upload.filename} content_type=#{upload.content_type} reason=#{inspect(reason)}"
        )

        error
    end
  end

  @doc """
  Removes a user cover URL.
  """
  def remove_user_cover(%User{} = user) do
    user
    |> Ecto.Changeset.change(cover_url: nil)
    |> Repo.update()
    |> case do
      {:ok, updated_user} ->
        {:ok, user_preloading(updated_user)}

      {:error, changeset} ->
        {:error, changeset}
    end
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
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
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

    query
    |> Repo.one()
    |> user_preloading()
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
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
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def count_users do
    users_count = Repo.aggregate(User, :count, :id)
    :telemetry.execute([:hamster_travel, :accounts, :users], %{count: users_count})
    users_count
  end

  defp user_preloading(user) do
    Repo.preload(user, friendships: [], home_city: Geo.city_preloading_query())
  end
end
