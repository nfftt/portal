defmodule FruitPicker.Mailer do
  @moduledoc """
  Sends email via apropriate adapaters.
  """
  use Bamboo.Mailer, otp_app: :fruit_picker
end
