defmodule BlackMirror.HTTP do
  def get(url) do
    case Finch.request(Finch.build(:get, url), BlackMirror.Finch) do
      {:ok, resp} -> {:ok, resp}
      _ -> :error
    end
  end
end
