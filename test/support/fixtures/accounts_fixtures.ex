defmodule HamsterTravel.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HamsterTravel.Accounts` context.
  """

  alias HamsterTravel.Accounts.UserToken
  alias HamsterTravel.Repo

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"
  def valid_user_name, do: "John Doe"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: valid_user_name(),
      email: unique_user_email(),
      password: valid_user_password(),
      locale: "en"
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> HamsterTravel.Accounts.register_user()

    user
  end

  def user_token_fixture(user, context \\ "reset_password", sent_to \\ nil) do
    {token, user_token} = UserToken.build_email_token(user, context)
    user_token = %{user_token | sent_to: sent_to || user.email}
    Repo.insert!(user_token)
    token
  end
end
