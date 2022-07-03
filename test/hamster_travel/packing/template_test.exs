defmodule HamsterTravel.Packing.TemplateTest do
  use HamsterTravel.DataCase

  alias HamsterTravel.Packing.Item
  alias HamsterTravel.Packing.List
  alias HamsterTravel.Packing.Template

  test "it parses a template and returns a list of backpack lists" do
    assert [
             %List{
               name: "Hygiene",
               items: [
                 %Item{
                   name: "Napkins",
                   count: 2
                 },
                 %Item{
                   name: "Toothpaste",
                   count: 3
                 },
                 %Item{
                   name: "Toothbrush",
                   count: 7
                 }
               ]
             },
             %List{
               name: "Docs",
               items: [%Item{name: "Passports", count: 2}, %Item{name: "Insurance", count: 3}]
             },
             %List{name: "Clothes"}
           ] = Template.execute("test", %{days: 3, people: 2})
  end

  test "when file does not exists it returns an error" do
    assert {:error,
            [
              "Failed to open file \"lib/hamster_travel/packing/templates/non_existing.yml\": no such file or directory"
            ]} = Template.execute("non_existing")
  end

  test "when file is not a correct yaml it returns an error" do
    assert {:error, ["invalid template format"]} = Template.execute("test_not_yaml")
  end

  test "when file does not cotnain a single root list backpack it returns an error" do
    assert {:error, ["invalid template format"]} = Template.execute("test_invalid_format")
  end
end
