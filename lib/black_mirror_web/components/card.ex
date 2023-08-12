defmodule BlackMirrorWeb.CardComponent do
  use Phoenix.Component

  slot(:inner_block)

  def card(assigns) do
    ~H"""
      <div class="block bg-white rounded shadow-md p-4 border-gray-100"><%= render_slot(@inner_block) %></div>
    """
  end
end
