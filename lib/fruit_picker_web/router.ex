defmodule FruitPickerWeb.Router do
  use FruitPickerWeb, :router

  alias FruitPickerWeb.{
    Plugs,
    Policies,
    LayoutView
  }

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(Plugs.Auth, repo: Repo)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Plugs.GlobalAlert)
  end

  pipeline :authenticated do
    plug(Policies, :current_person)
    plug(:put_layout, {LayoutView, :authenticated})
  end

  pipeline :admin do
    plug(Policies, :is_admin)
  end

  pipeline :tree_owner do
    plug(Policies, :is_tree_owner)
    plug(Policies, :waiver_consent_tree_owner)
  end

  pipeline :lead_picker do
    plug(Policies, :is_lead_picker)
  end


  pipeline :lead_picker_or_admin do
    plug(Policies, :is_lead_picker_or_admin)
  end

  pipeline :agency do
    plug(Policies, :is_agency)
  end

  pipeline :picker do
    plug(Policies, :not_agency)
    plug(Policies, :waiver_consent_picker)
  end

  pipeline :membership do
    plug(Policies, :active_membership)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :webhook do
    plug :accepts, ["json"]
  end

  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  scope "/admin", FruitPickerWeb.Admin, as: :admin do
    pipe_through([
      :browser,
      :authenticated,
      :admin
    ])

    resources("/picks", PickController, except: [:delete])
    get("/partners/export", AgencyController, :export)
    resources("/partners", AgencyController)
    resources("/equipment", EquipmentSetController)
    get("/users/export", PersonController, :export)
    resources("/users", PersonController)
    get("/reports", ReportController, :index)
    resources("/reports/attendance", ReportAttendanceController, only: [:new, :create])
    get("/equipment/:id/activate", EquipmentSetController, :activate)
    get("/equipment/:id/deactivate", EquipmentSetController, :deactivate)
    get("/picks/:pick_id/activate", PickController, :request_activate)
    put("/picks/:pick_id/activate", PickController, :activate)
    get("/picks/:pick_id/cancel", PickController, :request_cancel)
    get("/picks/:pick_id/make_private", PickController, :make_private)
    get("/picks/:pick_id/assign_lead_picker", PickController, :assign_lead_picker)
    put("/picks/:pick_id/cancel", PickController, :cancel)
    get("/picks/:pick_id/reschedule", PickController, :request_reschedule)
    put("/picks/:pick_id/reschedule", PickController, :reschedule)
    get("/picks/:pick_id/claim", PickController, :request_claim)
    put("/picks/:pick_id/claim", PickController, :claim)
    delete("/picks/:pick_id", PickController, :delete)
    put("/picks/:pick_id/remove_lead_picker", PickController, :remove_lead_picker)
    delete("/picks/:pick_id/remove/:person_id", PickController, :remove_picker)
    get("/picks/:pick_id/edit_pick_report", PickController, :edit_pick_report)
    get("/picks/:pick_id/edit_pick_attendance", PickController, :edit_pick_attendance)
    put("/picks/:pick_id/edit_pick_attendance", PickController, :update_pick_attendance)
    get("/picks/:pick_id/edit_pick_fruits", PickController, :edit_pick_fruits)
    put("/picks/:pick_id/edit_pick_fruits", PickController, :update_pick_fruits)
    post("/users/:id", PersonController, :deactivate)
    get("/users/:id/payment", PaymentController, :new)
    post("/users/:id/payment", PaymentController, :create)
    get("/users/:id/stats", PersonController, :stats)
    get("/users/:id/property", PropertyController, :show)
    get("/users/:id/property/setup", PropertyController, :setup)
    put("/users/:id/property", PropertyController, :update)
    post("/users/:id/property", PropertyController, :create)
    get("/users/:id/property/edit", PropertyController, :edit)
    get("/users/:id/request_pick", RequestPickController, :new)
    post("/users/:id/request_pick", RequestPickController, :create)
    get("/users/:user_id/trees/:tree_id", TreeController, :show)
    put("/users/:user_id/trees/:tree_id", TreeController, :update)
    get("/users/:user_id/trees/:tree_id/edit", TreeController, :edit)
    get("/users/:user_id/trees/:tree_id/deactivate", TreeController, :request_deactivate)
    put("/users/:user_id/trees/:tree_id/deactivate", TreeController, :deactivate)
  end

  # Tree owner
  scope "/", FruitPickerWeb do
    pipe_through([
      :browser,
      :authenticated,
      :tree_owner
    ])

    get("/property", PropertyController, :index)
    get("/property/setup", PropertyController, :new)
    post("/property/setup", PropertyController, :create)
    get("/property/edit", PropertyController, :edit)
    put("/property/edit", PropertyController, :update)
    resources("/trees", TreeController, except: [:index, :delete])
    get("/trees", PropertyController, :index)
    get("/trees/:id/deactivate", TreeController, :request_deactivate)
    put("/trees/:id/deactivate", TreeController, :deactivate)
  end

  # Tree owner (paid)
  scope "/", FruitPickerWeb do
    pipe_through([
      :browser,
      :authenticated,
      :membership,
      :tree_owner
    ])

    get("/trees/:id/deactivate", TreeController, :request_deactivate)
    put("/trees/:id/deactivate", TreeController, :deactivate)
    resources("/picks", PickController, except: [:index, :delete, :show])
    get("/picks/:pick_id/tree_update", PickController, :next_tree)
    get("/picks/:pick_id/tree_update/:tree_id", PickController, :tree_info)
    post("/picks/:pick_id/tree_update/:tree_id", PickController, :tree_update)
    get("/picks/:pick_id/confirm_details", PickController, :confirm_details)
    put("/picks/:pick_id/confirm_details", PickController, :update_details)
    get("/picks/:pick_id/thank_you", PickController, :thank_you)
    get("/picks/:pick_id/reschedule", PickController, :request_reschedule)
    put("/picks/:pick_id/reschedule", PickController, :reschedule)
    get("/picks/:pick_id/cancel", PickController, :request_cancel)
    put("/picks/:pick_id/cancel", PickController, :cancel)
  end

  # Lead Pickers
  scope "/", FruitPickerWeb do
    pipe_through([
      :browser,
      :authenticated,
      :lead_picker
    ])

    get("/picks/:pick_id/claim", PickController, :request_claim)
    put("/picks/:pick_id/claim", PickController, :claim)
  end

  # Lead Pickers or admins
  scope "/", FruitPickerWeb do
    pipe_through([
      :browser,
      :authenticated,
      :lead_picker_or_admin
    ])

    get("/picks/:pick_id/report", PickReportController, :new)
    post("/picks/:pick_id/report", PickReportController, :create)
    get("/picks/:pick_id/report/fruit", PickReportController, :fruit)
    put("/picks/:pick_id/report/fruit", PickReportController, :report_fruit)
  end

  scope "/", FruitPickerWeb do
    pipe_through([
      :browser,
      :authenticated,
      :agency
    ])
  end

  # Volunteers (not agency partners)
  scope "/", FruitPickerWeb do
    pipe_through([
      :browser,
      :authenticated,
      :picker,
      :membership
    ])

    resources("/picks", PickController, only: [:show])
    get("/picks/:pick_id/join", PickController, :request_join)
    put("/picks/:pick_id/join", PickController, :join)
    get("/picks/:pick_id/leave", PickController, :leave)
    put("/picks/:pick_id/leave", PickController, :leave)
  end

  # Logged in users
  scope "/", FruitPickerWeb do
    pipe_through([:browser, :authenticated])

    resources("/agency", AgencyController)
    get("/my_agency", AgencyController, :mine)
    get("/", DashboardController, :index)
    get("/profile", ProfileController, :show)
    get("/profile/edit", ProfileController, :edit)
    get("/profile/setup", ProfileController, :setup)
    put("/profile", ProfileController, :update)
    get("/profile/avatar", AvatarController, :edit)
    put("/profile/avatar", AvatarController, :update)
    get("/profile/payment", ProfileController, :payment_thanks)
    delete("/profile/avatar/:id", AvatarController, :delete)
    get("/stats", StatsController, :index)
  end

  # Public to all
  scope "/", FruitPickerWeb do
    pipe_through :browser

    get("/donate", DonationController, :index)
    get("/register", RegisterController, :new)
    post("/register", RegisterController, :create)
    get("/signin", AuthController, :request)
    post("/signin", AuthController, :signin)
    delete("/signout/:id", AuthController, :signout)
    get("/password-reset", AuthController, :forgot)
    post("/password-reset", AuthController, :forgot_request)
    get("/password-reset/:token_value", AuthController, :new_password)
    post("/password-reset/:token_value", AuthController, :create_password)
    put("/password-reset/:token_value", AuthController, :create_password)
  end

  scope "/webhooks", FruitPickerWeb do
    pipe_through :webhook

    post("/stripe", WebhookController, :create)
  end

  # Other scopes may use custom stacks.
  # scope "/api", FruitPickerWeb do
  #   pipe_through :api
  # end
end
