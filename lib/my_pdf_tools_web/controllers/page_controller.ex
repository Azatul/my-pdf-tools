defmodule MyPdfToolsWeb.PageController do
  use MyPdfToolsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
