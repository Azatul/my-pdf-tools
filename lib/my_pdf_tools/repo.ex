defmodule MyPdfTools.Repo do
  use Ecto.Repo,
    otp_app: :my_pdf_tools,
    adapter: Ecto.Adapters.Postgres
end
