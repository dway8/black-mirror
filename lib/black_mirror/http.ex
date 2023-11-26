defmodule BlackMirror.HTTP do
  def get(url, headers \\ []) do
    Finch.request(Finch.build(:get, url, headers), BlackMirror.Finch)
  end
end
