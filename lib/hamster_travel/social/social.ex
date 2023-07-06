defmodule HamsterTravel.Social do
  @moduledoc """
  The Social context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias HamsterTravel.Repo
  alias HamsterTravel.Social.Friendship

  @spec list_friend_ids(String) :: list(String)
  @doc """
  Returns a list of friend ids for given user identified by user_id

  ## Examples

    iex> list_friends_ids(user.id)
    ["id1", "id2", ...]
  """
  def list_friend_ids(user_id) do
    from(f in Friendship, select: f.friend_id, where: f.user_id == ^user_id)
    |> Repo.all()
  end

  @spec add_friends(String, String) :: {:ok, any} | {:error, atom, any, any}
  def add_friends(user1_id, user2_id) do
    Multi.new()
    |> Multi.insert(
      :user1_to_2,
      Friendship.changeset(%Friendship{user_id: user1_id, friend_id: user2_id}, %{})
    )
    |> Multi.insert(
      :user2_to_1,
      Friendship.changeset(%Friendship{user_id: user2_id, friend_id: user1_id}, %{})
    )
    |> Repo.transaction()
  end

  @spec remove_friends(String, String) :: {:ok, any} | {:error, atom, any, any}
  def remove_friends(user1_id, user2_id) do
    Multi.new()
    |> Multi.delete(:user1_to_2, Repo.get_by!(Friendship, user_id: user1_id, friend_id: user2_id))
    |> Multi.delete(:user2_to_1, Repo.get_by!(Friendship, user_id: user2_id, friend_id: user1_id))
    |> Repo.transaction()
  end

  def user_in_friends_circle?(current_user, user_id) do
    current_user
    |> extract_policy_user_ids()
    |> Enum.member?(user_id)
  end

  def extract_policy_user_ids(user) do
    [user.id] ++ Enum.map(user.friendships, fn fr -> fr.friend_id end)
  end

  @spec get_friendship!(String) :: Friendship.t()
  @doc """
  Gets a single friendship.

  Raises `Ecto.NoResultsError` if the Friendship does not exist.

  ## Examples

      iex> get_friendship!(123)
      %Friendship{}

      iex> get_friendship!(456)
      ** (Ecto.NoResultsError)

  """
  def get_friendship!(id), do: Repo.get!(Friendship, id)
end
