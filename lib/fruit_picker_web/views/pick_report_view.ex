defmodule FruitPickerWeb.PickReportView do
  use FruitPickerWeb, :view

  alias FruitPickerWeb.SharedView
  alias FruitPicker.Activities.PickReport

  def fruit_quality_options do
    [
      {"Perfect", "perfect"},
      {"Good", "good"},
      {"Okay", "okay"},
      {"Has Imperfections", "has imperfections"},
      {"Poor", "poor"}
    ]
  end

  def get_field(form, field) do
    Ecto.Changeset.get_field(form.source, String.to_existing_atom(field))
  end

  def report_has_issue?(%PickReport{} = report) do
    report.has_equipment_set_issue or
    not report.has_fruit_delivered_to_agency or
    report.has_issues_on_site
  end
end
