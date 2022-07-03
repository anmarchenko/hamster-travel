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

  # test "when file does not exists it returns an error" do
  #   assert {:error, "no template"} = Template.execute("non_existing")
  # end
end
