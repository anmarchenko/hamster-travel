defmodule HamsterTravel.Packing.Policy do
  alias HamsterTravel.Accounts.User
  alias HamsterTravel.Packing.Backpack

  def authorized?(:edit, %Backpack{} = backpack, %User{} = user) do
    backpack.user_id == user.id
  end

  def authorized?(:delete, %Backpack{} = backpack, %User{} = user) do
    backpack.user_id == user.id
  end
end
