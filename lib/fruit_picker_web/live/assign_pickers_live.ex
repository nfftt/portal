defmodule FruitPickerWeb.AssignPickersLive do
  use FruitPickerWeb, :live_view

  alias FruitPicker.Activities

  alias FruitPicker.Activities.{
    PickPerson,
    Pick
  }

  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.Person

  def mount(_, %{"pick" => pick}, socket) do
    changeset = Person.changeset(%Person{}, %{})
    pickers = Accounts.list_available_pickers(pick.id) |> generate_options()

    {:ok,
     assign(socket,
       changeset: changeset,
       pickers: pickers,
       pick: pick
     )}
  end

  def handle_event("submit", %{"person" => person_params}, socket) do
    person = %Person{id: person_params["id"]}

    case Activities.join_pick(socket.assigns.pick, person) do
      {:error, message} ->
        {:noreply, socket}

      {:ok, pick} ->
        updated_pick = Activities.get_pick!(pick.id)
        pickers = Accounts.list_available_pickers(pick.id) |> generate_options()
        {:noreply, assign(socket, pick: updated_pick, pickers: pickers)}
    end
  end

  defp generate_options(list) do
    Enum.map(list, &{"#{&1.first_name} #{&1.last_name}", &1.id})
  end
end
