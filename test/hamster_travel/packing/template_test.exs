defmodule HamsterTravel.Packing.TemplateTest do
  use HamsterTravel.DataCase, async: true

  alias HamsterTravel.Packing.Item
  alias HamsterTravel.Packing.List
  alias HamsterTravel.Packing.Template

  test "it parses a template and returns a list of backpack lists" do
    assert {:ok,
            [
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
              %List{name: "Clothes", items: [%Item{name: "Shirts", count: 2}]}
            ]} = Template.execute("test", %{days: 3, nights: 2})
  end

  test "it parses predefined templates" do
    assert {:ok, _} = Template.execute("default", %{days: 3, nights: 2})
  end

  test "when file does not exist it returns an error" do
    assert {:error, _} = Template.execute("non_existing")
  end

  test "when file is not a correct yaml it returns an error" do
    assert {:error, ["invalid template format"]} = Template.execute("test_not_yaml")
  end

  test "when file does not contain a single root list backpack it returns an error" do
    assert {:error, ["invalid template format"]} = Template.execute("test_invalid_format")
  end

  test "when file has several expression errors" do
    assert {:error, _} = Template.execute("test_invalid_expression")
  end
end
