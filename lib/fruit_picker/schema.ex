defmodule FruitPicker.Schema do
  @moduledoc """
  A base set of functionality for all modules responsible for
  managing a database table.
  """

  defmacro __using__(opts) do
    opts = Keyword.merge([default_sort: :inserted_at], opts)

    quote do
      use Ecto.Schema
      use Arc.Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2]
      import EctoEnum, only: [defenum: 3]

      alias FruitPicker.Repo

      def any?(query), do: Repo.count(query) > 0

      def by_position(query \\ __MODULE__), do: from(q in query, order_by: q.position)
      def limit(query \\ __MODULE__, count), do: from(q in query, limit: ^count)
      def newest_first(query \\ __MODULE__, field \\ unquote(opts[:default_sort])), do: from(q in query, order_by: [desc: ^field])
      def newest_last(query \\ __MODULE__, field \\ unquote(opts[:default_sort])), do: from(q in query, order_by: [asc: ^field])

      def newer_than(query \\ __MODULE__, date_or_time)
      def newer_than(query, date = %Date{}), do: from(q in query, where: q.inserted_at > ^Timex.to_datetime(date))
      def newer_than(query, time = %DateTime{}), do: from(q in query, where: q.inserted_at > ^time)

      def older_than(query \\ __MODULE__, date_or_time)
      def older_than(query, date = %Date{}), do: from(q in query, where: q.inserted_at < ^Timex.to_datetime(date))
      def older_than(query, time = %DateTime{}), do: from(q in query, where: q.inserted_at < ^time)

      defp now_in_seconds, do: Timex.now() |> DateTime.truncate(:second)
    end
  end
end
