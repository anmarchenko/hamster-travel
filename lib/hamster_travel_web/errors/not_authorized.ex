defmodule HamsterTravelWeb.Errors.NotAuthorized do
  defexception message: "not authorized", plug_status: 404
end
