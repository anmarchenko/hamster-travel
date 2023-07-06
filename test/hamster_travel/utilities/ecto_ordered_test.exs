defmodule HamsterTravel.EctoOrderedTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Packing.List
  alias HamsterTravel.Repo

  import Ecto.Query
  import HamsterTravel.PackingFixtures

  def ranked_ids(model, scope) do
    from(
      m in model,
      select: m.id,
      where: m.backpack_id == ^scope,
      order_by: m.rank
    )
    |> Repo.all()
  end

  test "scoped: inserting item with no position" do
    backpacks = [
      backpack_fixture(%{name: "Paris"}),
      backpack_fixture(%{name: "London"}),
      backpack_fixture(%{name: "Berlin"})
    ]

    for b <- backpacks, i <- 0..9 do
      list =
        List.changeset(%List{backpack_id: b.id, name: Integer.to_string(i)}, %{})
        |> Repo.insert!()

      assert list.rank != nil
    end

    for b <- backpacks do
      lists =
        from(l in List,
          select: [l.name, l.rank],
          order_by: [asc: :name],
          where: l.backpack_id == ^b.id
        )
        |> Repo.all()

      assert lists == Enum.sort_by(lists, &Enum.at(&1, 1))
    end
  end

  test "scoped: inserting item with a correct appending position" do
    paris = backpack_fixture(%{name: "Paris"})
    berlin = backpack_fixture(%{name: "Berlin"})

    List.changeset(
      %List{backpack_id: paris.id, name: "item with no position, going to be #1"},
      %{}
    )
    |> Repo.insert!()

    List.changeset(
      %List{backpack_id: berlin.id, name: "item #2"},
      %{}
    )
    |> Repo.insert()

    list =
      List.changeset(%List{backpack_id: paris.id, name: "item #2"}, %{position: 2})
      |> Repo.insert!()

    assert from(l in List,
             where: l.backpack_id == ^paris.id,
             select: l.id,
             offset: 1,
             order_by: [asc: :rank]
           )
           |> Repo.one() ==
             list.id
  end

  test "scoped: inserting item with an inserting position" do
    paris = backpack_fixture(%{name: "Paris"})

    model1 =
      List.changeset(%List{backpack_id: paris.id, name: "no position, going to be #1"}, %{})
      |> Repo.insert!()

    model2 =
      List.changeset(%List{backpack_id: paris.id, name: "no position, going to be #2"}, %{})
      |> Repo.insert!()

    model3 =
      List.changeset(%List{backpack_id: paris.id, name: "no position, going to be #3"}, %{})
      |> Repo.insert!()

    model =
      List.changeset(%List{backpack_id: paris.id, name: "item #2"}, %{position: 1})
      |> Repo.insert!()

    assert ranked_ids(List, paris.id) == [model1.id, model.id, model2.id, model3.id]
  end

  test "scoped: inserting item with an inserting position at #1" do
    paris = backpack_fixture(%{name: "Paris"})

    model1 =
      List.changeset(%List{backpack_id: paris.id, name: "no position, going to be #1"}, %{})
      |> Repo.insert!()

    model2 =
      List.changeset(%List{backpack_id: paris.id, name: "no position, going to be #2"}, %{})
      |> Repo.insert!()

    model3 =
      List.changeset(%List{backpack_id: paris.id, name: "no position, going to be #3"}, %{})
      |> Repo.insert!()

    model =
      List.changeset(%List{backpack_id: paris.id, name: "item #2"}, %{position: 0})
      |> Repo.insert!()

    assert ranked_ids(List, paris.id) == [model.id, model1.id, model2.id, model3.id]
  end

  # Moving
  test "scoped: updating item with the same position" do
    paris = backpack_fixture(%{name: "Paris"})

    model =
      List.changeset(%List{backpack_id: paris.id, name: "no position"}, %{})
      |> Repo.insert!()

    model1 =
      List.changeset(model, %{name: "item with a position", backpack_id: paris.id})
      |> Repo.update!()

    assert model.rank == model1.rank
  end

  test "scoped: replacing an item below" do
    paris = backpack_fixture(%{name: "Paris"})

    model1 = List.changeset(%List{backpack_id: paris.id, name: "item #1"}, %{}) |> Repo.insert!()
    model2 = List.changeset(%List{backpack_id: paris.id, name: "item #2"}, %{}) |> Repo.insert!()
    model3 = List.changeset(%List{backpack_id: paris.id, name: "item #3"}, %{}) |> Repo.insert!()
    model4 = List.changeset(%List{backpack_id: paris.id, name: "item #4"}, %{}) |> Repo.insert!()
    model5 = List.changeset(%List{backpack_id: paris.id, name: "item #5"}, %{}) |> Repo.insert!()

    model2 |> List.changeset(%{position: 3}) |> Repo.update()

    assert ranked_ids(List, paris.id) == [model1.id, model3.id, model4.id, model2.id, model5.id]
  end

  test "scoped: replacing an item above" do
    paris = backpack_fixture(%{name: "Paris"})

    model1 = List.changeset(%List{backpack_id: paris.id, name: "item #1"}, %{}) |> Repo.insert!()
    model2 = List.changeset(%List{backpack_id: paris.id, name: "item #2"}, %{}) |> Repo.insert!()
    model3 = List.changeset(%List{backpack_id: paris.id, name: "item #3"}, %{}) |> Repo.insert!()
    model4 = List.changeset(%List{backpack_id: paris.id, name: "item #4"}, %{}) |> Repo.insert!()
    model5 = List.changeset(%List{backpack_id: paris.id, name: "item #5"}, %{}) |> Repo.insert!()

    model4 |> List.changeset(%{position: 1}) |> Repo.update()

    assert ranked_ids(List, paris.id) == [model1.id, model4.id, model2.id, model3.id, model5.id]
  end

  test "scoped: updating item with a tail position" do
    paris = backpack_fixture(%{name: "Paris"})

    model1 = List.changeset(%List{backpack_id: paris.id, name: "item #1"}, %{}) |> Repo.insert!()
    model2 = List.changeset(%List{backpack_id: paris.id, name: "item #2"}, %{}) |> Repo.insert!()
    model3 = List.changeset(%List{backpack_id: paris.id, name: "item #3"}, %{}) |> Repo.insert!()

    model2 |> List.changeset(%{position: 4}) |> Repo.update()

    assert ranked_ids(List, paris.id) == [model1.id, model3.id, model2.id]
  end

  test "scoped: moving between scopes" do
    paris = backpack_fixture(%{name: "Paris"})
    berlin = backpack_fixture(%{name: "Berlin"})

    scope1_model1 =
      List.changeset(%List{backpack_id: paris.id, name: "item #1"}, %{}) |> Repo.insert!()

    scope1_model2 =
      List.changeset(%List{backpack_id: paris.id, name: "item #2"}, %{}) |> Repo.insert!()

    scope1_model3 =
      List.changeset(%List{backpack_id: paris.id, name: "item #3"}, %{}) |> Repo.insert!()

    scope2_model1 =
      List.changeset(%List{backpack_id: berlin.id, name: "item #1"}, %{}) |> Repo.insert!()

    scope2_model2 =
      List.changeset(%List{backpack_id: berlin.id, name: "item #2"}, %{}) |> Repo.insert!()

    scope2_model3 =
      List.changeset(%List{backpack_id: berlin.id, name: "item #3"}, %{}) |> Repo.insert!()

    scope1_model2 |> List.changeset(%{position: 4, backpack_id: berlin.id}) |> Repo.update()

    assert Repo.get(List, scope1_model1.id).backpack_id == paris.id
    assert Repo.get(List, scope1_model3.id).backpack_id == paris.id
    assert ranked_ids(List, paris.id) == [scope1_model1.id, scope1_model3.id]

    assert ranked_ids(List, berlin.id) == [
             scope2_model1.id,
             scope2_model2.id,
             scope2_model3.id,
             scope1_model2.id
           ]
  end

  ## Deletion

  test "scoped: deleting an item" do
    paris = backpack_fixture(%{name: "Paris"})

    model1 = List.changeset(%List{backpack_id: paris.id, name: "item #1"}, %{}) |> Repo.insert!()
    model2 = List.changeset(%List{backpack_id: paris.id, name: "item #2"}, %{}) |> Repo.insert!()
    model3 = List.changeset(%List{backpack_id: paris.id, name: "item #3"}, %{}) |> Repo.insert!()
    model4 = List.changeset(%List{backpack_id: paris.id, name: "item #4"}, %{}) |> Repo.insert!()
    model5 = List.changeset(%List{backpack_id: paris.id, name: "item #5"}, %{}) |> Repo.insert!()

    model2 |> Repo.delete()

    assert ranked_ids(List, paris.id) == [model1.id, model3.id, model4.id, model5.id]
  end
end
