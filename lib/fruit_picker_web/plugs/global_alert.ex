defmodule FruitPickerWeb.Plugs.GlobalAlert do
  @behaviour Plug

  @alert """
  Our program ends on October 6, 2023. Thanks for a great season and see you next year!
  <br> If you'd like to contact us, please email: <a class="link green hover-dark-green" href="mailto:info@notfarfromthetree.org">info@notfarfromthetree.org</a>
  """
  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    if @alert do
      conn
      |> Phoenix.Controller.put_flash(:info, @alert)
    else
      conn
    end
  end
end
