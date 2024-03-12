defmodule FruitPicker.Accounts.Avatar do
  @moduledoc """
  Handles storing and transforming user avatars.
  """

  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original, :small, :medium]
  @types [:jpg, :jpeg, :png]

  def default_url(_version, _scope), do: "/images/defaults/avatar.jpg"

  def expanded_dir(path) do
    Application.fetch_env!(:arc, :storage_dir) <> path
  end

  def validate({file, _}) do
    Enum.member?(@types, file_type(file))
  end

  def storage_dir(_version, {_file, scope}) do
    hashed_id = FruitPicker.Hashid.encode(scope.id)
    "#{Application.fetch_env!(:arc, :storage_dir)}/avatars/#{hashed_id}"
  end

  def mime_type(file) do
    case file_type(file) do
      :jpg  -> "image/jpg"
      :jpeg -> "image/jpg"
      :png  -> "image/png"
      :gif  -> "image/gif"
    end
  end

  def filename(version, _) do
    "avatar_#{version}"
  end

  def transform(:original, _), do: :noaction

  def transform(:small, _) do
    {:convert, "-strip -resize 100x100^ -gravity center -extent 100x100 -limit area 10MB -limit disk 10MB", :png}
  end

  def transform(:medium, _) do
    {:convert, "-strip -resize 300x300^ -gravity center -extent 300x300 -limit area 10MB -limit disk 10MB", :png}
  end


  defp file_type(file) do
    file.file_name
    |> Path.extname
    |> String.replace(".", "")
    |> String.downcase
    |> String.to_existing_atom
  end

  defp file_ext(file) do
    file.file_name |> Path.extname |> String.downcase
  end

  defp dimensions(:small), do: "100x100"
  defp dimensions(:medium), do: "300x300"

  defp source(scope), do: scope.__meta__.source
end
