defmodule HamsterTravelWeb.UserLoginLive do
  use HamsterTravelWeb, :live_view

  def render(assigns) do
    ~H"""
    <.form_container>
      <div>
        <h2 class="mt-6 text-center text-3xl font-bold tracking-tight">
          <%= gettext("Sign in to your account") %>
        </h2>
        <p class="mt-2 text-center text-sm hidden">
          Or
          <a href="#" class="font-medium text-indigo-600 hover:text-indigo-500">
            start your 14-day free trial
          </a>
        </p>
      </div>

      <.form
        id="login-form"
        class="mt-8 space-y-6"
        for={@form}
        action={~p"/users/log_in"}
        phx-update="ignore"
      >
        <div class="-space-y-px rounded-md shadow-sm">
          <div>
            <label for="email-address" class="sr-only">Email address</label>
            <.field
              type="email"
              autocomplete="email"
              class="relative block w-full appearance-none rounded-none rounded-t-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
              field={@form[:email]}
              placeholder={gettext("Email")}
              required={true}
            />
          </div>
          <div>
            <label for="password" class="sr-only">Password</label>
            <.field
              type="password"
              autocomplete="current-password"
              class="relative block w-full appearance-none rounded-none rounded-b-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
              field={@form[:password]}
              placeholder={gettext("Password")}
              required={true}
            />
          </div>
        </div>

        <div class="flex items-center justify-between hidden">
          <div class="text-sm">
            <a href="#" class="font-medium text-indigo-600 hover:text-indigo-500">
              Forgot your password?
            </a>
          </div>
        </div>

        <div>
          <.button
            color="primary"
            class="group relative flex w-full justify-center rounded-md border border-transparent py-2 px-4 text-sm font-medium text-white focus:outline-none focus:ring-2 focus:ring-offset-2"
          >
            <span class="absolute inset-y-0 left-0 flex items-center pl-3">
              <!-- Heroicon name: mini/lock-closed -->
              <svg
                class="h-5 w-5 text-indigo-300 group-hover:text-indigo-400"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 20 20"
                fill="currentColor"
                aria-hidden="true"
              >
                <path
                  fill-rule="evenodd"
                  d="M10 1a4.5 4.5 0 00-4.5 4.5V9H5a2 2 0 00-2 2v6a2 2 0 002 2h10a2 2 0 002-2v-6a2 2 0 00-2-2h-.5V5.5A4.5 4.5 0 0010 1zm3 8V5.5a3 3 0 10-6 0V9h6z"
                  clip-rule="evenodd"
                />
              </svg>
            </span>
            <%= gettext("Log in") %>
          </.button>
        </div>
      </.form>
    </.form_container>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
