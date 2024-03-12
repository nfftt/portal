defmodule FruitPicker.Repo do
  use Ecto.Repo,
    otp_app: :fruit_picker,
    adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 20

  require Ecto.Query

  def count(query) do
    one(Ecto.Query.from(r in query, select: count(r.id)))
  end
end
