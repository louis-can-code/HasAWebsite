defmodule HasAWebsiteWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  Reconstructured from the generated core components file, avoiding use of DaisyUI.
  The foundation for styling is TailwindCSS, a utility-first CSS framework.
  Here are useful references:

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.
  """
  use Phoenix.Component
  use Gettext, backend: HasAWebsiteWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices

  ## Examples

    <.flash kind={:info} flash={@flash} />
    <.flash kind-{:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="fixed top-4 right-4 flex flex-col gap-0.5 z-50"
      {@rest}
    >
      <div class={[
        "p-4 mb-4 text-sm text-white/80 rounded-lg w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "bg-info/80 hover: bg-info/40",
        @kind == :error && "bg-error/80 hover:bg-error/40"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0 bg-info" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0 bg-error" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1">
          <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
            <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="soft">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :string
  attr :variant, :string, values: ~w(soft primary)

  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{
      "soft" => "bg-green-300 text-green-800 hover:bg-green-300/70 hover:text-green-800/70",
      "primary" => "bg-error hover:bg-error/70 border-base-content",
      nil => "bg-gray-200 hover:bg-gray-400"
    }

    base_class = "shadow-md hover:cursor-pointer py-1 px-2 rounded"

    class =
      [assigns[:class], base_class, Map.fetch!(variants, assigns[:variant])]
      |> Enum.filter(& &1)

    assigns = assign(assigns, :class, class)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox colour date datetime-local email file month number password
               search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, e.g. @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checked inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :string, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  # TODO: input daisyui classes
  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="border border-gray-300 rounded-lg p-6 mb-2">
      <label class="cursor-pointer">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <span class="flex-1 text-sm font-semibold text-gray-700">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "h-5 w-5 rounded shadow-sm focus:ring-purple-400 text-purple-500"}
            {@rest}
          />
          {@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="border border-gray-300 rounded-lg p-4 mb-2 space-y-2">
      <label>
        <span :if={@label} class="flex-1 text-sm font-semibold text-gray-700 mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[
            @class ||
              "w-full px-4 py-3 rounded-lg bg-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500 hover:border-gray-400",
            @errors != [] &&
              (@error_class ||
                 "bg-red-50 focus:ring-error focus:border-error hover:border-error/60 focus:outline-none")
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @error}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="border border-gray-300 rounded-lg p-2 mb-2">
      <label>
        <span :if={@label} class="flex-1 text-sm font-semibold text-gray-700 mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class ||
              "w-full px-4 py-3 border border-gray-300 rounded-lg bg-white focus:ring-2 focus:ring-blue-500
              focus:border-blue-500 hover:border-gray-400 transition-colors resize-y placeholder-gray-400 min-h-24",
            @errors != [] &&
              (@error_class ||
                 "border-error bg-red-50 focus:border-error focus:ring-1 focus:ring-error focus:outline-none")
          ]}
          {@rest}
        >
          {Phoenix.HTML.Form.normalize_value("textarea", @value)}
        </textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other types of input are handled here
  def input(assigns) do
    ~H"""
    <div class="border border-gray-300 rounded-lg p-4 mb-2">
      <label>
        <span :if={@label} class="flex-1 text-sm font-semibold text-gray-700 mb-1">{@label}</span>
        <input
          id={@id}
          name={@name}
          type={@type}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || "w-full border shadow-md border-gray-400",
            @errors != [] &&
              (@error_class ||
                 "border-error bg-red-50 focus:border-error focus:ring-1 focus:ring-error focus:outline-none")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a card with generic styling
  """
  attr :title, :string, required: true
  attr :label, :string

  attr :rest, :global, ~w(
    accept autocomplete capture cols disabled form list max maxlength min minlength
    multiple pattern placeholder readonly required rows size step phx-click
  )

  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div
      class="w-44 h-50 text-wrap border border-gray-300 shadow-lg text-base-content
            hover:cursor-pointer flex flex-col group transition delay-50 duration-200 ease-in-out hover:-translate-y-1 hover:scale-110 overflow-hidden"
      {@rest}
    >
      <div class="bg-amber-600 w-full p-2 grow group-hover:grow-0 delay-75 group-hover:delay-50 group-hover:origin-top duration-500">
        <h2 class="font-bold group-hover:text-sm group-hover:truncate transition-all ease-in-out duration-300">
          {@title}
        </h2>
        <p
          :if={@label}
          class="text-base-content/80 text-sm group-hover:text-xs transition-all ease-out delay-75 duration-200 overflow-ellipsis overflow-hidden"
        >
          {@label}
        </p>
      </div>
      <div class="h-5 px-1 align-top group-hover:max-h-40 group-hover:origin-bottom duration-400">
        <p class="leading-snug line-clamp-1 group-hover:line-clamp-7 transition-all text-sm delay-100 duration-300">
          {render_slot(@inner_block)}
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Renders a table with generic styling
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the `:col` and `:action` slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="odd:bg-purple-300 even:bg-purple-100 shadow min-w-full divide-y divide-white">
      <thead>
        <tr class="bg-purple-500 flex justify-between p-1">
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="flex flex-col bg-white rounded-lg border border-gray-200 divide-y divide-gray-200 shadow-sm">
      <li :for={item <- @item} class="px-4 py-3 hover:bg-gray-50 transition-colors duration-200">
        <div class="flex justify-between items-center gap-4">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a divider with generic styling

  ## Examples

      <.divider />
      <.divider>example<./divider>
      <.divider line_colour="border-violet-400" text_colour="text-blue-700">example</.divider>
  """
  attr :text_colour, :string, doc: "Set custom colour for text. e.g. `text-example-colour`"

  attr :line_colour, :string,
    doc: "Set custom colour for divider lines. e.g. `border-example-colour`"

  slot :inner_block, doc: "Optional text content to display in the divider"

  def divider(assigns) do
    assigns = assign_new(assigns, :line_colour, fn -> "border-gray-300" end)

    if Enum.empty?(assigns[:inner_block]) do
      ~H"""
      <div role="separator" class={["h-0 my-4 border-t", @line_colour]} />
      """
    else
      assigns = assign_new(assigns, :text_colour, fn -> "text-gray-400" end)

      ~H"""
      <div role="separator" class="flex my-2 justify-between items-center">
        <div class={["flex-1 h-0 border-t", @line_colour]} />
        <p class={["px-3 font-semibold", @text_colour]}>{render_slot(@inner_block)}</p>
        <div class={["flex-1 h-0 border-t", @line_colour]} />
      </div>
      """
    end
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three different styles - outline, solid and mini.
  By default, the outline style is used, but solid and mini may be
  applied by using the `-solid` and `-mini` suffix.

  You can customise the size and colors of the icons by setting
  width, height, and background colour classes.

  Icons are extracted from the `deps/heroicons` directory and bundled
  within your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """

  attr :name, :string, required: true
  attr :class, :string, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(HasAWebsiteWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(HasAWebsiteWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
