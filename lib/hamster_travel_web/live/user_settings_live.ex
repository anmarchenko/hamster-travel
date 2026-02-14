defmodule HamsterTravelWeb.UserSettingsLive do
  use HamsterTravelWeb, :live_view

  alias HamsterTravel.Accounts
  alias HamsterTravelWeb.CityInput
  alias HamsterTravelWeb.Cldr

  def render(assigns) do
    ~H"""
    <.form_container>
      <div class="space-y-10">
        <div class="space-y-6">
          <.section_header
            icon="hero-cog-6-tooth"
            label={gettext("General settings")}
            class="border-t-0 pt-0 mt-0"
          />
          <.form for={@general_form} id="general_form" phx-submit="update_settings" class="space-y-6">
            <.field
              type="select"
              field={@general_form[:locale]}
              label={gettext("Language")}
              options={[
                {gettext("English"), "en"},
                {gettext("Russian"), "ru"}
              ]}
              required
            />

            <.field
              type="select"
              field={@general_form[:default_currency]}
              options={Cldr.all_currencies()}
              label={gettext("Default currency")}
              required
            />

            <.live_component
              id="home-city-settings-input"
              module={CityInput}
              field={@general_form[:home_city]}
              validated_field={@general_form[:home_city_id]}
              label={gettext("Home city")}
            />

            <.button phx-disable-with="Saving...">
              {gettext("Save settings")}
            </.button>
          </.form>
        </div>

        <div class="space-y-6">
          <.section_header icon="hero-envelope" label={gettext("Email settings")} />
          <.form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
            class="space-y-6"
          >
            <.field field={@email_form[:email]} type="email" label={gettext("Email")} required />
            <.field
              field={@email_form[:current_password]}
              name="current_password"
              id="current_password_for_email"
              type="password"
              label={gettext("Current password")}
              value={@email_form_current_password}
              required
            />
            <.button phx-disable-with="Changing...">
              {gettext("Change Email")}
            </.button>
          </.form>
        </div>

        <div class="space-y-6">
          <.section_header icon="hero-key" label={gettext("Password settings")} />
          <.form
            for={@password_form}
            id="password_form"
            action={~p"/users/log_in?_action=password_updated"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
            class="space-y-6"
          >
            <.field
              field={@password_form[:email]}
              type="hidden"
              id="hidden_user_email"
              value={@current_email}
            />
            <.field
              field={@password_form[:password]}
              type="password"
              label={gettext("New password")}
              required
            />
            <.field
              field={@password_form[:password_confirmation]}
              type="password"
              label={gettext("Confirm new password")}
            />
            <.field
              field={@password_form[:current_password]}
              name="current_password"
              type="password"
              label={gettext("Current password")}
              id="current_password_for_password"
              value={@current_password}
              required
            />
            <.button phx-disable-with="Changing...">
              {gettext("Change Password")}
            </.button>
          </.form>
        </div>
      </div>
    </.form_container>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    settings_changeset = Accounts.change_user_settings(settings_form_user(user))

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:general_form, to_form(settings_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_email(user, password, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Email changed successfully."))
         |> push_navigate(to: ~p"/profile")}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("update_settings", %{"user" => user_params}, socket) do
    settings_params = CityInput.process_selected_value_on_submit(user_params, "home_city")
    user = socket.assigns.current_user

    case Accounts.update_user_settings(user, settings_params) do
      {:ok, user} ->
        locale_changed = user.locale != socket.assigns.current_user.locale

        {:noreply,
         if(locale_changed,
           do:
             socket
             |> put_flash(:info, gettext("Settings updated successfully."))
             |> redirect(to: ~p"/profile"),
           else:
             socket
             |> put_flash(:info, gettext("Settings updated successfully."))
             |> push_navigate(to: ~p"/profile")
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :general_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  defp settings_form_user(user) do
    if is_nil(user.default_currency) do
      %{user | default_currency: "EUR"}
    else
      user
    end
  end
end
