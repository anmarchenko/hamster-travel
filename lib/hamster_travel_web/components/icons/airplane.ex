defmodule HamsterTravelWeb.Icons.Airplane do
  @moduledoc """
  Airplane icon
  """
  use HamsterTravelWeb, :component
  import PhxComponentHelpers

  def airplane(assigns) do
    assigns
    |> extend_class("", prefix_replace: false)
    |> render()
  end

  defp render(assigns) do
    ~H"""
    <svg
      width="20"
      height="20"
      stroke-width="1.5"
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      {@heex_class}
    >
      <path
        d="M10.5 4.5V9.16745C10.5 9.37433 10.3934 9.56661 10.218 9.67625L2.782 14.3237C2.60657 14.4334 2.5 14.6257 2.5 14.8325V15.7315C2.5 16.1219 2.86683 16.4083 3.24552 16.3136L9.75448 14.6864C10.1332 14.5917 10.5 14.8781 10.5 15.2685V18.2277C10.5 18.4008 10.4253 18.5654 10.2951 18.6793L8.13481 20.5695C7.6765 20.9706 8.03808 21.7204 8.63724 21.6114L11.8927 21.0195C11.9636 21.0066 12.0364 21.0066 12.1073 21.0195L15.3628 21.6114C15.9619 21.7204 16.3235 20.9706 15.8652 20.5695L13.7049 18.6793C13.5747 18.5654 13.5 18.4008 13.5 18.2277V15.2685C13.5 14.8781 13.8668 14.5917 14.2455 14.6864L20.7545 16.3136C21.1332 16.4083 21.5 16.1219 21.5 15.7315V14.8325C21.5 14.6257 21.3934 14.4334 21.218 14.3237L13.782 9.67625C13.6066 9.56661 13.5 9.37433 13.5 9.16745V4.5C13.5 3.67157 12.8284 3 12 3C11.1716 3 10.5 3.67157 10.5 4.5Z"
        stroke="currentColor"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </svg>
    """
  end
end
