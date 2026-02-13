defmodule HamsterTravel.Accounts.UserCoverTest do
  use HamsterTravel.DataCase

  import HamsterTravel.AccountsFixtures

  alias HamsterTravel.Accounts.UserCover

  test "validates allowed file extensions" do
    user = user_fixture()

    assert UserCover.validate({%{file_name: "cover.jpg"}, user})
    assert UserCover.validate({%{file_name: "cover.webp"}, user})
    refute UserCover.validate({%{file_name: "cover.txt"}, user})
  end

  test "builds the storage directory per user" do
    user = user_fixture()

    assert UserCover.storage_dir(:hero, {"cover.jpg", user}) ==
             "uploads/trips/users/#{user.id}/cover"
  end
end
