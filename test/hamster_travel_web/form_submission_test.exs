defmodule HamsterTravelWeb.FormSubmissionTest do
  use ExUnit.Case, async: true

  alias HamsterTravelWeb.FormSubmission
  alias Phoenix.LiveView.Socket

  test "runs only the first submission while it is in flight" do
    socket = FormSubmission.init(%Socket{})

    {:noreply, submitting_socket} =
      FormSubmission.submit_once(socket, fn socket ->
        send(self(), :submitted)
        {:noreply, socket}
      end)

    assert_receive :submitted
    assert submitting_socket.assigns.submitting

    assert {:noreply, ^submitting_socket} =
             FormSubmission.submit_once(submitting_socket, fn socket ->
               send(self(), :submitted_again)
               {:noreply, socket}
             end)

    refute_receive :submitted_again
  end

  test "allows another submission after a validation failure resets the guard" do
    {:noreply, submitting_socket} =
      %Socket{}
      |> FormSubmission.init()
      |> FormSubmission.submit_once(&{:noreply, &1})

    socket = FormSubmission.reset(submitting_socket)

    refute socket.assigns.submitting

    assert {:noreply, submitting_socket} =
             FormSubmission.submit_once(socket, &{:noreply, &1})

    assert submitting_socket.assigns.submitting
  end
end
