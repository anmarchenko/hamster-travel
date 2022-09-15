defmodule HamsterTravelWeb.Icons.Taxi do
  @moduledoc """
  Taxi icon
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  def taxi(assigns) do
    assigns
    |> extend_class("", prefix_replace: false)
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <svg
      width="18"
      height="18"
      style="fill: currentColor;"
      viewBox="0 0 1024 1024"
      version="1.1"
      xmlns="http://www.w3.org/2000/svg"
      {@heex_class}
    >
      <path
        d="M341.333333 170.666667c-3.413333 0-6.826667 0-10.24-3.413334-6.826667-3.413333-10.24-13.653333-3.413333-23.893333L375.466667 64.853333c6.826667-17.066667 27.306667-30.72 51.2-30.72h167.253333c23.893333 0 44.373333 13.653333 54.613333 34.133334l51.2 78.506666c6.826667 6.826667 3.413333 17.066667-3.413333 23.893334-13.653333 3.413333-23.893333 0-27.306667-6.826667l-51.2-78.506667c-6.826667-10.24-13.653333-17.066667-23.893333-17.066666h-167.253333c-10.24 0-17.066667 6.826667-23.893334 13.653333l-47.786666 78.506667c-3.413333 6.826667-6.826667 10.24-13.653334 10.24zM256 716.8H68.266667c-10.24 0-17.066667-6.826667-17.066667-17.066667s6.826667-17.066667 17.066667-17.066666h170.666666c-6.826667-37.546667-30.72-68.266667-64.853333-68.266667h-102.4c-10.24 0-17.066667-6.826667-17.066667-17.066667s6.826667-17.066667 17.066667-17.066666h102.4C228.693333 580.266667 273.066667 634.88 273.066667 699.733333c0 10.24-6.826667 17.066667-17.066667 17.066667zM645.12 750.933333h-262.826667c-6.826667 0-17.066667-6.826667-17.066666-13.653333l-20.48-136.533333c0-3.413333 0-10.24 3.413333-13.653334 3.413333-3.413333 6.826667-6.826667 13.653333-6.826666h307.2c3.413333 0 10.24 3.413333 13.653334 6.826666 3.413333 3.413333 3.413333 10.24 3.413333 13.653334l-20.48 136.533333c-6.826667 6.826667-13.653333 13.653333-20.48 13.653333z m-249.173333-34.133333h235.52l17.066666-102.4h-266.24l13.653334 102.4zM109.226667 443.733333c-3.413333 0-3.413333 0 0 0-44.373333-6.826667-109.226667-20.48-109.226667-58.026666 0-27.306667 10.24-51.2 27.306667-64.853334 34.133333-23.893333 81.92-13.653333 85.333333-13.653333 3.413333 0 6.826667 3.413333 10.24 6.826667l44.373333 78.506666c3.413333 10.24 3.413333 13.653333 3.413334 20.48 0 3.413333-3.413333 6.826667-10.24 10.24l-44.373334 20.48h-6.826666z m-27.306667-102.4c-10.24 0-23.893333 3.413333-34.133333 10.24-10.24 6.826667-13.653333 17.066667-13.653334 34.133334 3.413333 6.826667 37.546667 17.066667 71.68 20.48l23.893334-10.24-34.133334-54.613334h-13.653333z"
        fill=""
      />
      <path
        d="M505.173333 443.733333c-92.16 0-354.986667-20.48-368.64-20.48-10.24 0-17.066667-10.24-17.066666-17.066666s10.24-17.066667 17.066666-17.066667c3.413333 0 273.066667 20.48 365.226667 20.48s361.813333-20.48 365.226667-20.48c10.24 0 17.066667 6.826667 17.066666 17.066667s-6.826667 17.066667-17.066666 17.066666c-6.826667 0-269.653333 20.48-361.813334 20.48zM955.733333 716.8h-187.733333c-10.24 0-17.066667-6.826667-17.066667-17.066667 0-64.853333 44.373333-119.466667 98.986667-119.466666h102.4c10.24 0 17.066667 6.826667 17.066667 17.066666s-6.826667 17.066667-17.066667 17.066667h-102.4c-30.72 0-58.026667 30.72-64.853333 68.266667h170.666666c10.24 0 17.066667 6.826667 17.066667 17.066666s-6.826667 17.066667-17.066667 17.066667z"
        fill=""
      />
      <path
        d="M914.773333 443.733333h-6.826666l-44.373334-20.48-10.24-10.24v-13.653333l44.373334-78.506667c3.413333-3.413333 6.826667-6.826667 10.24-6.826666 3.413333 0 51.2-13.653333 85.333333 13.653333 17.066667 13.653333 27.306667 34.133333 27.306667 64.853333 3.413333 30.72-61.44 44.373333-105.813334 51.2 3.413333 0 3.413333 0 0 0z m-20.48-44.373333l23.893334 10.24c34.133333-6.826667 68.266667-17.066667 71.68-23.893333 0-13.653333-3.413333-27.306667-13.653334-34.133334-13.653333-10.24-37.546667-10.24-47.786666-10.24l-34.133334 58.026667zM853.333333 989.866667h-34.133333c-37.546667 0-68.266667-30.72-68.266667-68.266667v-71.68c0-10.24 6.826667-17.066667 13.653334-17.066667l23.893333-3.413333 112.64-17.066667c3.413333 0 10.24 0 13.653333 3.413334 3.413333 3.413333 6.826667 6.826667 6.826667 10.24V921.6c0 37.546667-30.72 68.266667-68.266667 68.266667z m-68.266666-122.88V921.6c0 20.48 13.653333 34.133333 34.133333 34.133333h34.133333c20.48 0 34.133333-13.653333 34.133334-34.133333v-71.68l-92.16 13.653333-10.24 3.413334zM204.8 989.866667H170.666667c-37.546667 0-68.266667-30.72-68.266667-68.266667v-85.333333-6.826667c0-3.413333 3.413333-10.24 6.826667-13.653333 3.413333-3.413333 6.826667-3.413333 13.653333-3.413334l112.64 17.066667s10.24 0 23.893333 3.413333c10.24 0 13.653333 6.826667 13.653334 17.066667V921.6c0 37.546667-30.72 68.266667-68.266667 68.266667z m-68.266667-139.946667V921.6c0 20.48 13.653333 34.133333 34.133334 34.133333h34.133333c20.48 0 34.133333-13.653333 34.133333-34.133333v-54.613333h-10.24L136.533333 849.92z"
        fill=""
      />
      <path
        d="M512 887.466667c-122.88 0-279.893333-20.48-283.306667-20.48l-129.706666-20.48c-3.413333 0-6.826667-3.413333-10.24-3.413334-34.133333-40.96-54.613333-133.12-54.613334-204.8 0-85.333333 40.96-184.32 95.573334-238.933333 30.72-95.573333 109.226667-211.626667 157.013333-238.933333 27.306667-13.653333 129.706667-23.893333 225.28-23.893334s197.973333 10.24 221.866667 23.893334c51.2 23.893333 126.293333 139.946667 157.013333 238.933333 58.026667 54.613333 95.573333 157.013333 95.573333 238.933333 0 71.68-20.48 167.253333-58.026666 201.386667-3.413333 3.413333-6.826667 3.413333-10.24 3.413333l-129.706667 20.48c3.413333 3.413333-153.6 23.893333-276.48 23.893334zM112.64 812.373333l122.88 20.48s157.013333 20.48 276.48 20.48 276.48-20.48 276.48-20.48l122.88-20.48c23.893333-27.306667 44.373333-102.4 44.373333-174.08 0-75.093333-37.546667-170.666667-88.746666-218.453333-3.413333-3.413333-3.413333-3.413333-3.413334-6.826667-30.72-102.4-105.813333-204.8-143.36-221.866666C703.146667 180.906667 614.4 170.666667 512 170.666667s-191.146667 10.24-208.213333 20.48c-34.133333 17.066667-109.226667 119.466667-143.36 221.866666 0 3.413333-3.413333 6.826667-3.413334 6.826667C105.813333 467.626667 68.266667 559.786667 68.266667 638.293333c0 68.266667 20.48 143.36 44.373333 174.08z"
        fill=""
      />
    </svg>
    """
  end
end
