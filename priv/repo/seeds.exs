# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     FruitPicker.Repo.insert!(%FruitPicker.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias FruitPicker.{Accounts,Repo}

# Clean Slate
Repo.delete_all Accounts.Profile
Repo.delete_all Accounts.Person

Accounts.create_person(%{
  "email" => "jeff@jeffjewiss.com",
  "first_name" => "Jeff",
  "last_name" => "Jewiss",
  "password" => "pass1234",
  "password_confirmation" => "pass1234",
  "is_picker" => true,
  "is_tree_owner" => true,
  "role" => "admin",
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "admin")

Accounts.create_person(%{
  "email" => "alex@d-n.io",
  "first_name" => "Alex",
  "last_name" => "Doris",
  "password" => "pass1234",
  "password_confirmation" => "pass1234",
  "is_picker" => true,
  "is_tree_owner" => true,
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "admin")

Accounts.create_person(%{
  "email" => "volunteer1@nfftt.com",
  "first_name" => "Apple",
  "last_name" => "Picker",
  "password" => "pass1234",
  "password_confirmation" => "pass1234",
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "fruit_picker")

Accounts.create_person(%{
  "email" => "volunteer2@nfftt.com",
  "first_name" => "Pear",
  "last_name" => "Picker",
  "password" => "pass1234",
  "password_confirmation" => "pass1234",
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "fruit_picker")

Accounts.create_person(%{
  "email" => "volunteer3@nfftt.com",
  "first_name" => "Blueberry",
  "last_name" => "Picker",
  "password" => "pass1234",
  "password_confirmation" => "pass1234",
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "fruit_picker")

Accounts.create_person(%{
  "email" => "volunteer4@nfftt.com",
  "first_name" => "Orange",
  "last_name" => "Picker",
  "password" => "pass1234",
  "password_confirmation" => "pass1234",
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "fruit_picker")

Accounts.create_person(%{
  "email" => "volunteer5@nfftt.com",
  "first_name" => "Cherry",
  "last_name" => "Picker",
  "password" => "pass1234",
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "fruit_picker")

Accounts.create_person(%{
  "email" => "volunteer6@nfftt.com",
  "first_name" => "Banana",
  "last_name" => "Picker",
  "password" => "pass1234",
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "fruit_picker")

Accounts.create_person(%{
  "email" => "volunteer7@nfftt.com",
  "first_name" => "Lemon",
  "last_name" => "Picker",
  "password" => "pass1234",
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "fruit_picker")

Accounts.create_person(%{
  "email" => "volunteer8@nfftt.com",
  "first_name" => "Lime",
  "last_name" => "Picker",
  "password" => "pass1234",
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "fruit_picker")

Accounts.create_person(%{
  "email" => "volunteer9@nfftt.com",
  "first_name" => "Kiwi",
  "last_name" => "Picker",
  "password" => "pass1234",
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "fruit_picker")

Accounts.create_person(%{
  "email" => "volunteer10@nfftt.com",
  "first_name" => "Pineapple",
  "last_name" => "Picker",
  "password" => "pass1234",
  "profile" => %{
    "phone_number" => "416-555-5555",
    "secondary_phone_number" => "416-555-5555",
    "address_street" => "123 Fake St.",
    "address_postal_code" => "M5V 0K2",
    "address_city" => "Toronto",
    "address_province" => "Ontario",
  },
}, "fruit_picker")
