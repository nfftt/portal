defmodule FruitPickerWeb.UserTableLive do
  use FruitPickerWeb, :live_view

  alias FruitPicker.Accounts

  def mount(
        _params,
        _session,
        socket
      ) do
    {:ok, assign(socket, people: [], input: "")}
  end

  def render(assigns) do
    ~L"""
        <section class="flex items-center justify-between">
          <form phx-change="search" phx-submit="search" class="ml-auto" >
            <label class="flex items-center">
              <span class="mr2 dark-gray">Search Users</span>
    <input value="<%= @input %>" name="search-input" type="search" autocomplete="off" phx-debounce="500" class="w5 input-reset flex justify-center h50px ph3 br2 ba br0 bg-white b--light-gray">
            </label>
          </form>
        </section>

    <section class="w-100 mxh5 overflow-y-scroll overflow-x-visible-l absolute top-0 right-0 mt5 bg-white <%= if String.length(@input) > 0, do: "shadow-1" %>">
          <table class="w-100 f6 dark-gray collapse">
            <tbody class="w-100 fw3 bt bl br b--moon-gray br2">
              <%= if Enum.any?(@people) do %>
                <%= for person <- @people do %>
                  <tr class="bb b--moon-gray">
                    <td class="pv2" colspan="6">
                      <a  
                        class="pl4 flex h-100 items-center link dark-gray"
                        href="<%= Routes.admin_person_path(@socket, :show, person) %>"
                      >
                        <div class="pr1 truncate"><%= person.first_name %></div>
                      </a>
                    </td>
                    <td class="pv2" colspan="6">
                      <a  
                        class="pl4 flex h-100 items-center link dark-gray"
                        href="<%= Routes.admin_person_path(@socket, :show, person) %>"
                      >
                        <div class="pr1 truncate"><%= person.last_name %></div>
                      </a>
                    </td>
                    <td class="pv2" colspan="6">
                      <a  
                        class="pl4 flex h-100 items-center link dark-gray"
                        href="<%= Routes.admin_person_path(@socket, :show, person) %>"
                      >
                        <div class="pr1 truncate"><%= person.email %></div>
                      </a>
                    </td>
                  </tr>
                <% end %>
                <% else %>
                <%= if String.length(@input) > 0 do %>
                  <tr class="bb b--moon-gray">
                    <td class="pv2" colspan="6">
                      <p class="tc">No Result Found</p>
                    </td>
                  </tr>
                  <% end %>
              <% end %>
            </tbody>
          </table>
        </section>
    """
  end

  def handle_event("search", %{"search-input" => input}, socket) do
    input = String.trim(input)

    case String.length(input) do
      0 ->
        {:noreply, assign(socket, people: [], input: "")}

      _ ->
        people = Accounts.list_people_like(input)
        {:noreply, assign(socket, people: people, input: input)}
    end
  end
end
