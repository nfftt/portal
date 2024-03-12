defmodule FruitPicker.Repo.Migrations.AddPersonRole do
  use Ecto.Migration
  alias FruitPicker.Accounts.Person.RoleEnum

  def up do
    RoleEnum.create_type()
    alter table(:people) do
      add(:role, RoleEnum.type(), default: "user")
    end
  end

  def down do
    alter table(:people) do
      remove(:role)
    end
    RoleEnum.drop_type()
  end
end
