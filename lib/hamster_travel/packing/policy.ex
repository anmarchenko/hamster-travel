defmodule HamsterTravel.Packing.Policy do
  import Ecto.Query, warn: false

  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Packing.Backpack

  def authorized?(:edit, %Backpack{} = backpack, %User{} = user) do
    backpack.user_id == user.id
  end

  def authorized?(:delete, %Backpack{} = backpack, %User{} = user) do
    backpack.user_id == user.id
  end

  def authorized?(:copy, %Backpack{} = backpack, %User{} = user) do
    backpack.user_id == user.id
  end

  def user_scope(query, %User{} = user) do
    from(b in query, where: b.user_id == ^user.id)
  end
end
