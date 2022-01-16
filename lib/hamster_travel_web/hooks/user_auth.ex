defmodule HamsterTravelWeb.Hooks.UserAuth do
  @moduledoc """
  User authentication live view hooks
  """
  import Phoenix.LiveView

  def on_mount(:set_current_user, _params, _session, socket) do
    user = %{
      name: "Andrey Marchenko",
      avatar_url: "https://d2fetf4i8a4kn6.cloudfront.net/2014/09/30/11/27/53/591/2014_nizh.png",
      locale: "ru"
    }

    Gettext.put_locale(HamsterTravelWeb.Gettext, user.locale)

    socket = socket |> assign(:current_user, user)

    {:cont, socket}
  end
end
