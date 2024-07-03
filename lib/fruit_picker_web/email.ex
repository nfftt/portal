defmodule FruitPickerWeb.Email do
  use Bamboo.Phoenix, view: FruitPickerWeb.EmailView

  alias FruitPickerWeb.{EmailView, PickView, SharedView}

  import Logger

  @system_email "picks@notfarfromthetree.org"
  @system_user {"NFFTT Portal", "picks@notfarfromthetree.org"}

  def password_reset(token_value, person) do
    Logger.info(
      "Sending password reset token email to #{person.first_name} #{person.last_name} (#{person.id})."
    )

    # we want to send the password reset emails even if they declined portal communications
    person = %{person | accepts_portal_communications: true}

    bot_email()
    |> to(person)
    |> subject("Password Reset Link for NFFTT")
    |> assign(:person, person)
    |> assign(:token_value, token_value)
    |> render(:password_reset)
  end

  def new_registration(admin, person, role) do
    Logger.info(
      "Sending new registration email to #{admin.first_name} #{admin.last_name} (#{admin.id}) for person #{person.id}."
    )

    bot_email()
    |> to(admin)
    |> subject("NFFTT New Registration (#{role})")
    |> assign(:person, person)
    |> assign(:admin, admin)
    |> assign(:role, role)
    |> render(:new_registration)
  end

  def new_public_pick(person, pick) do
    Logger.info(
      "Sending new public pick email to #{person.first_name} #{person.last_name} (#{person.id}) for pick #{pick.id}."
    )

    bot_email()
    |> to(person)
    |> subject("New Pick Available on NFFTT!")
    |> assign(:person, person)
    |> assign(:pick, pick)
    |> render(:new_public_pick)
  end

  def home_owner_pick_is_scheduled(pick) do
    subject =
      "#{pick.id}: Your Pick has been scheduled for #{SharedView.short_date(pick.scheduled_date)} from #{SharedView.twelve_hour_time(pick.scheduled_start_time)} to #{SharedView.twelve_hour_time(pick.scheduled_end_time)}"

    person = pick.requester

    Logger.info(
      "Sending tree owner pick is scheduled email to #{person.first_name} #{person.last_name} (#{person.id}) for pick #{pick.id}."
    )

    bot_email()
    |> to(person)
    |> subject(subject)
    |> assign(:pick, pick)
    |> render(:home_owner_pick_scheduled)
  end

  def agency_pick_is_scheduled(pick, agency) do
    subject =
      "#{pick.id}: #{PickView.tree_type(pick)} Delivery – #{SharedView.short_date(pick.scheduled_date)} shortly after #{SharedView.twelve_hour_time(pick.scheduled_end_time)}"

    if agency.contact_email do
      bot_email()
      |> to({agency.contact_name, agency.contact_email})
      |> subject(subject)
      |> assign(:pick, pick)
      |> assign(:agency, agency)
      |> render(:agency_pick_scheduled)
    else
      Logger.info(
        "Could not send agency pick scheduled email to #{agency.name} for pick #{pick.id} because there is no contact email."
      )
    end
  end

  def pick_request_confirmation(person, pick) do
    Logger.info(
      "Sending pick request confirmation email to #{person.first_name} #{person.last_name} (#{person.id}) for pick #{pick.id}."
    )

    bot_email()
    |> to(person)
    |> subject("Pick request confirmation")
    |> assign(:person, person)
    |> assign(:pick, pick)
    |> render(:pick_request_confirmation)
  end

  def fruit_picker_payment_email(person) do
    Logger.info(
      "Sending fruit picker payment email to #{person.first_name} #{person.last_name} (#{person.id})."
    )

    bot_email()
    |> to(person)
    |> subject("Registration Confirmed!")
    |> assign(:person, person)
    |> render(:registration_confirmed_picker)
  end

  def tree_owner_payment_email(person) do
    Logger.info(
      "Sending tree owner payment email to #{person.first_name} #{person.last_name} (#{person.id})."
    )

    bot_email()
    |> to(person)
    |> subject("Registration Confirmed!")
    |> assign(:person, person)
    |> render(:registration_confirmed_tree_owner)
  end

  def daily_picks_available_email(person, picks) do
    Logger.info(
      "Sending daily picks available email to #{person.first_name} #{person.last_name} (#{person.id})."
    )

    bot_email()
    |> to(person)
    |> subject("Fruit picks are available to join!")
    |> assign(:person, person)
    |> assign(:picks, picks)
    |> render(:picks_available_to_join)
  end

  def lead_picker_removed(person, pick) do
    Logger.info(
      "Sending lead picker removed from pick email to #{person.first_name} #{person.last_name}."
    )

    bot_email()
    |> to(person)
    |> subject("You have been removed from a pick")
    |> assign(:person, person)
    |> assign(:pick, pick)
    |> render(:lead_picker_removed)
  end

  def picker_removed(person, pick) do
    Logger.info(
      "Sending picker removed from pick email to #{person.first_name} #{person.last_name}."
    )

    bot_email()
    |> to(person)
    |> subject("You have been removed from a pick")
    |> assign(:person, person)
    |> assign(:pick, pick)
    |> render(:picker_removed)
  end

  def admin_report_issue(admin, pick) do
    Logger.info(
      "Sending pick report issue email to #{admin.first_name} #{admin.last_name} (#{admin.id}) for pick #{pick.id}."
    )

    bot_email()
    |> to(admin)
    |> subject("New Pick Report with an Issue")
    |> assign(:person, admin)
    |> assign(:pick, pick)
    |> render(:report_issue)
  end

  def admin_new_pick(admin, pick) do
    Logger.info(
      "Sending new pick email to #{admin.first_name} #{admin.last_name} for pick #{pick.id}"
    )

    bot_email()
    |> to(admin)
    |> subject("A new pick has been requested")
    |> assign(:admin, admin)
    |> assign(:pick, pick)
    |> render(:admin_new_pick_request)
  end

  def pick_cancelation_admin(admin, pick, canceler, reason) do
    Logger.info("Sending admin pick cancelation email to #{admin.email} for pick #{pick.id}")

    bot_email()
    |> to(admin)
    |> subject("Pick #{pick.id} canceled by #{canceler.first_name} #{canceler.last_name}")
    |> assign(:admin, admin)
    |> assign(:pick, pick)
    |> assign(:reason, reason)
    |> assign(:canceler, canceler)
    |> render(:pick_cancelation_admin)
  end

  def pick_cancelation_lead_picker(person, pick, reason) do
    Logger.info(
      "Sending lead picker pick cancelation email to #{person.email} for pick #{pick.id}"
    )

    bot_email()
    |> to(person)
    |> subject("Pick #{pick.id} has been canceled")
    |> assign(:person, person)
    |> assign(:reason, reason)
    |> assign(:pick, pick)
    |> render(:pick_cancelation_lead_picker)
  end

  def pick_cancelation_picker(person, pick) do
    Logger.info("Sending picker pick cancelation email to #{person.email} for pick #{pick.id}")

    bot_email()
    |> to(person)
    |> subject("Pick #{pick.id}: The pick you're attending has been cancelled!")
    |> assign(:person, person)
    |> assign(:pick, pick)
    |> render(:pick_cancelation_picker)
  end

  def pick_cancelation_tree_owner(person, pick) do
    Logger.info(
      "Sending tree owner pick cancelation email to #{person.email} for pick #{pick.id}"
    )

    bot_email()
    |> to(person)
    |> subject("Apologies, our pick leader had to cancel your pick #{pick.id}!")
    |> assign(:person, person)
    |> assign(:pick, pick)
    |> render(:pick_cancelation_tree_owner)
  end

  def pick_cancelation_agency(agency, pick) do
    if agency.contact_email do
      Logger.info(
        "Sending agency pick cancelation email to #{agency.contact_email} for pick #{pick.id}"
      )

      bot_email()
      |> to({agency.contact_name, agency.contact_email})
      |> subject("Pick: #{pick.id} fruit delivery canceled")
      |> assign(:agency, agency)
      |> assign(:pick, pick)
      |> render(:pick_cancelation_agency)
    else
      Logger.info(
        "Could not send agency pick cancelation email to #{agency.name} for pick #{pick.id} because there is no contact email."
      )
    end
  end

  def outstanding_report_reminder_email(pick, lead_picker) do
    Logger.info(
      "Sending oustanding pick report (pick ##{pick.id}) to lead picker #{lead_picker.first_name} #{lead_picker.last_name}"
    )

    bot_email()
    |> to(lead_picker)
    |> subject("#{pick.id}: You have an outstanding Post Pick Report to complete!")
    |> assign(:person, lead_picker)
    |> assign(:pick, pick)
    |> render(:pick_report_reminder)
  end

  def tree_owner_pick_reminder(person, pick) do
    Logger.info("Sending tree owner reminder email about pick ##{pick.id} to #{person.email}")

    bot_email()
    |> to(person)
    |> subject("#{pick.id} Your #{PickView.tree_type(pick)} Pick is tomorrow!")
    |> assign(:person, person)
    |> assign(:pick, pick)
    |> render(:tree_owner_pick_reminder)
  end

  def picker_pick_reminder(person, pick) do
    Logger.info("Sending picker reminder email about pick ##{pick.id} to #{person.email}")

    bot_email()
    |> to(person)
    |> subject(
      "#{pick.id}: You are attending a #{PickView.tree_type(pick)} Pick tomorrow from #{SharedView.twelve_hour_time(pick.scheduled_start_time)} to #{SharedView.twelve_hour_time(pick.scheduled_end_time)}"
    )
    |> assign(:person, person)
    |> assign(:pick, pick)
    |> render(:picker_pick_reminder)
  end

  def agency_pick_reminder(agency, pick) do
    Logger.info("Sending agency reminder email about pick ##{pick.id} to #{agency.contact_email}")

    bot_email()
    |> to({agency.contact_name, agency.contact_email})
    |> subject(
      "#{pick.id}: Reminder - #{PickView.tree_type(pick)} Delivery - #{SharedView.short_date(pick.scheduled_date)} shortly after #{SharedView.twelve_hour_time(pick.scheduled_end_time)}"
    )
    |> assign(:agency, agency)
    |> assign(:pick, pick)
    |> render(:agency_pick_reminder)
  end

  def deactivated_accounts_notifier(admin, people) do
    bot_email()
    |> to(admin)
    |> subject("NFFTT Deactivated Accounts")
    |> assign(:admin, admin)
    |> assign(:people, people)
    |> render(:deactivated_accounts)
  end

  def pick_completion_tree_owner_email(pick) do
    bot_email()
    |> to(pick.requester)
    |> subject("Thank you for sharing your fruit tree with NFFTT")
    |> assign(:pick, pick)
    |> render(:pick_completion_tree_owner)
  end

  defp bot_email do
    new_email()
    |> from(@system_user)
    |> put_header("Reply-To", @system_email)
    |> put_html_layout({FruitPickerWeb.LayoutView, "email_bot.html"})
  end

  defimpl Bamboo.Formatter, for: FruitPicker.Accounts.Person do
    def format_email_address(person, _opts) do
      # Only send emails to people who accept portal communications
      if person.accepts_portal_communications do
        {person.first_name <> person.last_name, person.email}
      end
    end
  end
end
