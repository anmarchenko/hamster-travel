defmodule HamsterTravelWeb.FormSubmission do
  @moduledoc false

  alias Phoenix.LiveView.Socket

  @spec init(Socket.t()) :: Socket.t()
  def init(socket) do
    Phoenix.Component.assign_new(socket, :submitting, fn -> false end)
  end

  @spec submit_once(Socket.t(), (Socket.t() -> {:noreply, Socket.t()})) ::
          {:noreply, Socket.t()}
  def submit_once(%Socket{assigns: %{submitting: true}} = socket, _submit),
    do: {:noreply, socket}

  def submit_once(socket, submit) do
    socket
    |> Phoenix.Component.assign(:submitting, true)
    |> submit.()
  end

  @spec reset(Socket.t()) :: Socket.t()
  def reset(socket), do: Phoenix.Component.assign(socket, :submitting, false)
end
