defmodule HamsterTravel.Accounts.UserAvatarTest do
  use HamsterTravel.DataCase

  import HamsterTravel.AccountsFixtures

  alias HamsterTravel.Accounts.UserAvatar

  test "validates allowed file extensions" do
    user = user_fixture()

    assert UserAvatar.validate({%{file_name: "avatar.jpg"}, user})
    assert UserAvatar.validate({%{file_name: "avatar.webp"}, user})
    refute UserAvatar.validate({%{file_name: "avatar.txt"}, user})
  end

  test "builds the storage directory per user" do
    user = user_fixture()

    assert UserAvatar.storage_dir(:thumb, {"avatar.jpg", user}) ==
             "uploads/trips/users/#{user.id}/avatar"
  end
end
