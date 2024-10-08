defmodule HamsterTravelWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use HamsterTravelWeb, :controller
      use HamsterTravelWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """
  def static_paths,
    do:
      ~w(assets fonts images favicon.ico robots.txt manifest.json favicon-16x16.png favicon-32x32.png android-chrome-512x512.png android-chrome-192x192.png apple-touch-icon.png)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: HamsterTravelWeb.Layouts]

      import Plug.Conn
      use Gettext, backend: HamsterTravelWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {HamsterTravelWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import HamsterTravelWeb.CoreComponents
      use Gettext, backend: HamsterTravelWeb.Gettext

      # use PETAL components
      import PetalComponents.Alert
      import PetalComponents.Avatar
      import PetalComponents.Button
      import PetalComponents.Form
      import PetalComponents.Field
      import PetalComponents.Input
      import PetalComponents.Tabs
      import PetalComponents.Icon

      # I18n format for everything
      alias HamsterTravelWeb.Cldr, as: Formatter

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: HamsterTravelWeb.Endpoint,
        router: HamsterTravelWeb.Router,
        statics: HamsterTravelWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
