defmodule HamsterTravelWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component, global_prefixes: ~w(x- data-)
  use HamsterTravelWeb, :verified_routes

  import PetalComponents.Icon
  use Gettext, backend: HamsterTravelWeb.Gettext

  alias Phoenix.LiveView.JS

  def plans_nav_item, do: :plans
  def drafts_nav_item, do: :drafts
  def backpacks_nav_item, do: :backpacks
  def home_nav_item, do: :home

  def trip_url(slug), do: ~p"/trips/#{slug}"
  def trip_url(slug, :show), do: trip_url(slug)
  def trip_url(slug, :edit), do: ~p"/trips/#{slug}/edit"
  def trip_url(slug, :itinerary), do: ~p"/trips/#{slug}?tab=itinerary"
  def trip_url(slug, :activities), do: ~p"/trips/#{slug}?tab=activities"
  def trip_url(slug, _), do: trip_url(slug)

  def plans_url, do: ~p"/plans"

  def backpack_url(slug), do: ~p"/backpacks/#{slug}"
  def backpack_url(slug, :show), do: backpack_url(slug)
  def backpack_url(slug, :edit), do: ~p"/backpacks/#{slug}/edit"
  def backpack_url(id, :copy), do: ~p"/backpacks/new?copy=#{id}"

  def backpacks_url, do: ~p"/backpacks"

  def placeholder_image(id) when is_binary(id) do
    id
    |> :erlang.phash2()
    |> rem(9)
    |> placeholder_image_url()
  end

  def placeholder_image(id) when is_integer(id) do
    id
    |> rem(9)
    |> placeholder_image_url()
  end

  def build_class(classes) do
    classes
    |> Enum.filter(fn class -> class != nil && class != "" end)
    |> Enum.uniq()
    |> Enum.join(" ")
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
       This is a modal.
     </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
       This is another modal.
     </.modal>

  """
  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{})
  slot(:inner_block, required: true)

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

   ## Examples

       <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr(:id, :string, default: "flash", doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:title, :string, default: nil)
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

   ## Examples

       <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
    <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
    <.flash
      id="disconnected"
      kind={:error}
      title={gettext("We can't find the internet")}
      phx-disconnected={show("#disconnected")}
      phx-connected={hide("#disconnected")}
      hidden
    >
      <%= gettext("Attempting to reconnect") %>
      <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

   ## Examples

       <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  slot :col, required: true do
    attr(:label, :string)
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pr-6 pb-4 font-normal"><%= col[:label] %></th>
            <th class="relative p-0 pb-4"><span class="sr-only"><%= gettext("Actions") %></span></th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

   ## Examples

       <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr(:title, :string, required: true)
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  attr(:wide, :boolean, default: false)
  attr(:nomargin, :boolean, default: false)
  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)

  def container(assigns) do
    ~H"""
    <section class={
      build_class([
        "mx-auto max-w-screen-md lg:max-w-screen-lg xl:max-w-screen-lg",
        container_margins(assigns),
        container_width(assigns),
        @class
      ])
    }>
      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  defp container_margins(%{nomargin: true}), do: ""
  defp container_margins(_), do: "p-6 mt-6"

  defp container_width(%{wide: true}), do: "2xl:max-w-screen-2xl"
  defp container_width(_), do: "2xl:max-w-screen-xl"

  slot(:inner_block, required: true)

  def form_container(assigns) do
    ~H"""
    <div class="flex min-h-full items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div class="w-full max-w-md space-y-8">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:id, :string, default: nil)
  attr(:class, :string, default: nil)

  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div
      id={@id}
      class={
        build_class([
          "flex flex-row bg-zinc-50 dark:bg-zinc-900 dark:border dark:border-zinc-600 shadow-md rounded-lg hover:shadow-lg hover:bg-white hover:dark:bg-zinc-800",
          @class
        ])
      }
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:class, :string, default: "w-5 h-5")
  attr(:rest, :global)

  def icon_text(assigns) do
    ~H"""
    <.icon name={@icon} class={@class} {@rest} />
    <span class="hidden sm:inline ml-2">
      <%= @label %>
    </span>
    """
  end

  attr(:href, :string, required: true)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  def ht_link(assigns) do
    ~H"""
    <.link
      href={@href}
      class="underline text-indigo-500 hover:text-indigo-900 dark:text-indigo-300 dark:hover:text-indigo-100"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  attr(:link, :string, required: true)

  def external_link(assigns) do
    ~H"""
    <.ht_link href={@link}>
      <%= URI.parse(@link).host %>
    </.ht_link>
    """
  end

  attr(:links, :list, required: true)

  def external_links(assigns) do
    ~H"""
    <%= for link <- @links do %>
      <.external_link link={link} />
    <% end %>
    """
  end

  attr(:country, :string, required: true)
  attr(:size, :integer, required: true, values: [16, 24, 32, 48])
  attr(:class, :string, default: "")

  def flag(assigns) do
    ~H"""
    <img
      class={@class}
      src={~p"/images/flags/#{@size}/#{@country <> ".png"}"}
      alt={"Country #{@country}"}
      style={"width: #{@size}px;  height: #{@size}px"}
    />
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800 dark:text-zinc-300">
          <%= render_slot(@inner_block) %>
          <span
            :if={@subtitle != []}
            class="ml-2 font-light leading-6 text-zinc-600 dark:text-zinc-400"
          >
            <%= render_slot(@subtitle) %>
          </span>
        </h1>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="pc-label">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  attr(:tag, :string, default: "p")
  attr(:italic, :boolean, default: true)
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def secondary(%{tag: "div"} = assigns) do
    ~H"""
    <div class={build_class([secondary_component_class(assigns), @class])}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def secondary(%{tag: "p"} = assigns) do
    ~H"""
    <p class={build_class([secondary_component_class(assigns), @class])}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  defp secondary_component_class(assigns) do
    "text-zinc-400 #{secondary_italic_class(assigns)}"
  end

  defp secondary_italic_class(%{italic: true}), do: "italic"
  defp secondary_italic_class(_), do: ""

  attr(:wrap, :boolean, default: false)
  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def inline(assigns) do
    ~H"""
    <div class={build_class([inline_component_class(assigns), @class])}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(HamsterTravelWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(HamsterTravelWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  defp inline_component_class(assigns) do
    "flex flex-row gap-2 items-center block #{inline_wrap(assigns)}"
  end

  defp inline_wrap(%{wrap: true}), do: "flex-wrap"
  defp inline_wrap(_), do: ""

  defp placeholder_image_url(number) do
    image_name = "placeholder-#{number}.jpg"

    ~p"/images/#{image_name}"
  end
end
