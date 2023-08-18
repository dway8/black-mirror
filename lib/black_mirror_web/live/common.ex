defmodule BlackMirrorWeb.Common do
  alias Phoenix.LiveView.JS

  def fade_out() do
    JS.hide(
      transition:
        {"transition-all transform ease-in duration-300", "opacity-100 scale-100",
         "opacity-0 scale-95"}
    )
  end
end
