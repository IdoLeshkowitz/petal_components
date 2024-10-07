defmodule PetalComponents.ButtonGroup do
  use Phoenix.Component
  alias PetalComponents.Helpers

  @doc """
  Renders a button group. Group buttons are configured by defining multiple `:button` slots.

  Note: Phoenix LiveView >= 0.20.17 is required to prevent arbitrary attributes like phx-*
  given to `:button` slots emitting development warnings.

  ## Examples

  ### Buttons

      <.button_group aria_label="My actions" size="md">
        <:button phx-click="beep" phx-value-boop="bop">Action 1</:button>
        <:button phx-click="boop" phx-value-bop="beep">Action 2</:button>
        <:button label="Action 3" phx-click="bop" phx-value-beep="boop" disabled={@action_disabled?} />
      </.button_group>

  ### Links

      <.button_group aria_label="My links" size="md">
        <:button kind="link" patch={~p"/path-one"}>Link 1</:button>
        <:button kind="link" patch={~p"/path-two"}>Link 2</:button>
        <:button label="Link 3" kind="link" navigate={~p"/other"} />
      </.button_group>

  """
  attr :id, :string, default: nil
  attr :aria_label, :string, required: true, doc: "the ARIA label for the button group"
  attr :size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"]

  attr :container_class, :string,
    default: "pc-button-group",
    doc: "class to apply to the group container"

  attr :font_weight_class, :string,
    default: "font-medium",
    doc: "the font weight class to apply to all buttons - defaults to font-medium"

  # We mark validate_attrs false so passing phx-click etc. does not emit warnings
  slot :button, required: true, validate_attrs: false do
    attr :class, :string, doc: "classes in addition to those already configured"
    attr :label, :string, doc: "a button label, rendered if you don't provide an inner block"

    attr :kind, :string,
      values: ["button", "link"],
      doc: "determines whether we render a button or a <.link />"

    attr :disabled, :boolean,
      doc: "disables the button - will turn an <a> into a <button> (<a> tags can't be disabled)"
  end

  def button_group(assigns) do
    ~H"""
    <div
      aria-label={@aria_label}
      role="group"
      id={@id || Helpers.uniq_id("button-group")}
      class={@container_class}
    >
      <.group_button
        :for={{group_btn_assigns, idx} <- Enum.with_index(@button)}
        idx={idx}
        last_idx={length(@button) - 1}
        size={@size}
        font_weight_class={@font_weight_class}
        {group_btn_assigns}
      >
        <%= if is_function(group_btn_assigns.inner_block) do %>
          <%= render_slot(group_btn_assigns) %>
        <% else %>
          <%= group_btn_assigns.label %>
        <% end %>
      </.group_button>
    </div>
    """
  end

  attr :class, :string, default: ""
  attr :label, :string
  attr :kind, :string, default: "button", values: ["button", "link"]
  attr :disabled, :boolean, default: false
  attr :font_weight_class, :string, required: true
  attr :size, :string, required: true, values: ["xs", "sm", "md", "lg", "xl"]
  attr :idx, :integer, required: true
  attr :last_idx, :integer, required: true

  attr :rest, :global,
    include:
      ~w(patch navigate method download hreflang ping referrerpolicy rel target type value name form)

  slot :inner_block, doc: "The inner block of the button.", required: true

  defp group_button(%{kind: "button"} = assigns) do
    ~H"""
    <button
      disabled={@disabled}
      aria-disabled={@disabled}
      class={[@class | group_btn_class(assigns)]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  # Anchor tags can't be disabled - renders a disabled button
  defp group_button(%{kind: "link", disabled: true} = assigns) do
    assigns = update_in(assigns.rest, &Map.drop(&1, [:"phx-click"]))

    ~H"""
    <button disabled aria-disabled class={[@class | group_btn_class(assigns)]} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp group_button(%{kind: "link"} = assigns) do
    ~H"""
    <.link class={[@class | group_btn_class(assigns)]} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp group_btn_class(%{idx: 0, last_idx: 0} = opts),
    do: ["pc-button-group__button--first-and-only" | group_btn_base_class(opts)]

  defp group_btn_class(%{idx: 0, last_idx: _length} = opts),
    do: ["pc-button-group__button--first" | group_btn_base_class(opts)]

  defp group_btn_class(%{idx: last_idx, last_idx: last_idx} = opts),
    do: ["pc-button-group__button--last" | group_btn_base_class(opts)]

  defp group_btn_class(opts),
    do: ["pc-button-group__button--middle" | group_btn_base_class(opts)]

  defp group_btn_base_class(opts) do
    [
      "pc-button-group__button",
      "pc-button-group__button--size-#{opts.size}",
      font_weight_class(opts.font_weight_class)
    ]
  end

  defp font_weight_class("font-normal"), do: "pc-button-group__button--font-weight-normal"
  defp font_weight_class("font-medium"), do: "pc-button-group__button--font-weight-medium"
  defp font_weight_class("font-semibold"), do: "pc-button-group__button--font-weight-semibold"
  defp font_weight_class("font-bold"), do: "pc-button-group__button--font-weight-bold"
  defp font_weight_class(custom_class), do: custom_class
end