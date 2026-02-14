defmodule HamsterTravel.AccountsTest do
  use HamsterTravel.DataCase, async: true

  alias HamsterTravel.Accounts
  alias HamsterTravel.Geo
  alias HamsterTravel.Social
  alias HamsterTravel.Social.Friendship

  import HamsterTravel.AccountsFixtures
  import HamsterTravel.GeoFixtures
  import ExUnit.CaptureLog
  alias HamsterTravel.Accounts.{User, UserAvatar, UserCover, UserToken}

  describe "get_user_by_session_token/1" do
    setup do
      geonames_fixture()
      france = country_fixture()
      region = region_fixture(france)
      city = city_fixture(france, region)

      user = user_fixture(%{home_city_id: city.id})
      friend = user_fixture()
      Social.add_friends(user.id, friend.id)
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token, city: city}
    end

    test "returns user by token and preload friendships", %{user: user, token: token, city: city} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
      assert [%Friendship{}] = session_user.friendships
      assert session_user.home_city.id == city.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(Ecto.UUID.generate())
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(valid_user_attributes(email: email))
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end

    test "registers optional settings fields" do
      geonames_fixture()
      france = country_fixture()
      region = region_fixture(france)
      city = city_fixture(france, region)

      {:ok, user} =
        Accounts.register_user(
          valid_user_attributes(default_currency: "USD", home_city_id: city.id)
        )

      assert user.default_currency == "USD"
      assert user.home_city_id == city.id
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:name, :password, :email]
    end

    test "allows fields to be set" do
      email = unique_user_email()
      password = valid_user_password()

      changeset =
        Accounts.change_user_registration(
          %User{},
          valid_user_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "change_user_settings/2" do
    test "returns a user settings changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_settings(%User{})
      assert changeset.required == [:locale, :default_currency]
    end
  end

  describe "update_user_settings/2" do
    setup do
      geonames_fixture()
      country = country_fixture()
      region = region_fixture(country)
      city = city_fixture(country, region)

      %{user: user_fixture(), city: city}
    end

    test "updates locale, currency and home city", %{user: user, city: city} do
      {:ok, updated_user} =
        Accounts.update_user_settings(user, %{
          locale: "ru",
          default_currency: "USD",
          home_city_id: city.id
        })

      assert updated_user.locale == "ru"
      assert updated_user.default_currency == "USD"
      assert updated_user.home_city_id == city.id
      assert updated_user.home_city.id == city.id
    end

    test "validates locale", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_settings(user, %{locale: "de", default_currency: "EUR"})

      assert %{locale: ["is invalid"]} = errors_on(changeset)
    end

    test "validates currency format", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_settings(user, %{locale: "en", default_currency: "EURO"})

      assert %{default_currency: ["has invalid format"]} = errors_on(changeset)
    end
  end

  describe "visited cities" do
    setup do
      geonames_fixture()
      france = country_fixture()
      region = region_fixture(france)
      paris = city_fixture(france, region)

      %{
        user: user_fixture(),
        other_user: user_fixture(),
        berlin: Geo.find_city_by_geonames_id("2950159"),
        paris: paris
      }
    end

    test "create_visited_city/2 and list_visited_cities/1 return preloaded city", %{
      user: user,
      berlin: berlin
    } do
      assert {:ok, visited_city} = Accounts.create_visited_city(user, %{city_id: berlin.id})

      assert [%{id: id, city: %{id: city_id}}] = Accounts.list_visited_cities(user)
      assert id == visited_city.id
      assert city_id == berlin.id
    end

    test "create_visited_city/2 enforces uniqueness per user", %{user: user, berlin: berlin} do
      assert {:ok, _visited_city} = Accounts.create_visited_city(user, %{city_id: berlin.id})
      assert {:error, changeset} = Accounts.create_visited_city(user, %{city_id: berlin.id})

      errors =
        changeset
        |> errors_on()
        |> Map.values()
        |> List.flatten()

      assert "has already been added" in errors
    end

    test "update_visited_city/2 changes the city", %{user: user, berlin: berlin, paris: paris} do
      assert {:ok, visited_city} = Accounts.create_visited_city(user, %{city_id: berlin.id})

      assert {:ok, updated_visited_city} =
               Accounts.update_visited_city(visited_city, %{city_id: paris.id})

      assert updated_visited_city.city_id == paris.id
    end

    test "delete_visited_city/2 deletes only owned records", %{
      user: user,
      other_user: other_user,
      berlin: berlin
    } do
      assert {:ok, visited_city} = Accounts.create_visited_city(user, %{city_id: berlin.id})

      assert {:error, :not_found} = Accounts.delete_visited_city(other_user, visited_city.id)
      assert {:ok, _deleted} = Accounts.delete_visited_city(user, visited_city.id)
      assert Accounts.list_visited_cities(user) == []
    end

    test "change_visited_city/2 returns a changeset", %{user: user} do
      changeset = Accounts.change_visited_city(%Accounts.VisitedCity{user_id: user.id})
      assert changeset.required == [:user_id, :city_id]
    end
  end

  describe "update_user_avatar/2" do
    setup do
      %{user: user_fixture()}
    end

    test "stores avatar and updates avatar_url", %{user: user} do
      upload = %Plug.Upload{
        path: Path.expand("../support/fixtures/files/cover.jpg", __DIR__),
        filename: "avatar.jpg",
        content_type: "image/jpeg"
      }

      assert {:ok, %User{} = updated_user} = Accounts.update_user_avatar(user, upload)

      assert updated_user.avatar_url =~
               "/uploads/trips/users/#{user.id}/avatar/avatar_thumb.jpg?v="

      assert updated_user.avatar_url == Accounts.get_user!(user.id).avatar_url
    end

    test "returns error for unsupported extension", %{user: user} do
      upload = %Plug.Upload{
        path: Path.expand("../support/fixtures/files/cover.jpg", __DIR__),
        filename: "avatar.txt",
        content_type: "text/plain"
      }

      capture_log(fn ->
        assert {:error, _reason} = Accounts.update_user_avatar(user, upload)
      end)
    end
  end

  describe "remove_user_avatar/1" do
    setup do
      %{user: user_fixture()}
    end

    test "clears avatar_url", %{user: user} do
      avatar_url = UserAvatar.url({"avatar.jpg", user}, :thumb)

      user =
        user
        |> Ecto.Changeset.change(avatar_url: avatar_url)
        |> Repo.update!()

      assert {:ok, %User{} = updated_user} = Accounts.remove_user_avatar(user)
      assert is_nil(updated_user.avatar_url)
      assert is_nil(Accounts.get_user!(user.id).avatar_url)
    end
  end

  describe "update_user_cover/2" do
    setup do
      %{user: user_fixture()}
    end

    test "stores cover and updates cover_url", %{user: user} do
      upload = %Plug.Upload{
        path: Path.expand("../support/fixtures/files/cover.jpg", __DIR__),
        filename: "cover.jpg",
        content_type: "image/jpeg"
      }

      assert {:ok, %User{} = updated_user} = Accounts.update_user_cover(user, upload)

      assert updated_user.cover_url =~
               "/uploads/trips/users/#{user.id}/cover/cover_hero.jpg?v="

      assert updated_user.cover_url == Accounts.get_user!(user.id).cover_url
    end

    test "returns error for unsupported extension", %{user: user} do
      upload = %Plug.Upload{
        path: Path.expand("../support/fixtures/files/cover.jpg", __DIR__),
        filename: "cover.txt",
        content_type: "text/plain"
      }

      capture_log(fn ->
        assert {:error, _reason} = Accounts.update_user_cover(user, upload)
      end)
    end
  end

  describe "remove_user_cover/1" do
    setup do
      %{user: user_fixture()}
    end

    test "clears cover_url", %{user: user} do
      cover_url = UserCover.url({"cover.jpg", user}, :hero)

      user =
        user
        |> Ecto.Changeset.change(cover_url: cover_url)
        |> Repo.update!()

      assert {:ok, %User{} = updated_user} = Accounts.remove_user_cover(user)
      assert is_nil(updated_user.cover_url)
      assert is_nil(Accounts.get_user!(user.id).cover_url)
    end
  end

  describe "update_user_email/3" do
    setup do
      %{user: user_fixture()}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.update_user_email(user, valid_user_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_email(user, valid_user_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_email(user, valid_user_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: email} = user_fixture()
      password = valid_user_password()

      {:error, changeset} = Accounts.update_user_email(user, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_email(user, "invalid", %{email: unique_user_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the email", %{user: user} do
      email = unique_user_email()
      {:ok, user} = Accounts.update_user_email(user, valid_user_password(), %{email: email})
      assert user.email == email
      assert Accounts.get_user!(user.id).email == email
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(%User{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "invalid", %{password: valid_user_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "new valid password"
        })

      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, _} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_reset_password_token/1" do
    setup do
      user = user_fixture()

      token = user_token_fixture(user, "reset_password")

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user} do
      refute Accounts.get_user_by_reset_password_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} = Accounts.reset_user_password(user, %{password: "new valid password"})
      assert is_nil(updated_user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)
      {:ok, _} = Accounts.reset_user_password(user, %{password: "new valid password"})
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "count_users/0" do
    test "returns the number of users" do
      initial_count = Accounts.count_users()
      user_fixture()
      assert Accounts.count_users() == initial_count + 1
      user_fixture()
      assert Accounts.count_users() == initial_count + 2
    end
  end
end
