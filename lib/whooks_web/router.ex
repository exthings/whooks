defmodule WhooksWeb.Router do
  use WhooksWeb, :router

  import WhooksWeb.Plugs.{Auth, UISharedProps}

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WhooksWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Inertia.Plug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/v1", WhooksWeb.V1 do
    pipe_through :api

    resources "/organizations", OrganizationController, only: [:index, :create, :show]
    resources "/consumers", ConsumerController, only: [:index, :create, :show]
    resources "/projects", ProjectController, only: [:index, :create, :show]
    resources "/topics", TopicController, only: [:index, :create, :show]
    resources "/endpoints", EndpointController, only: [:index, :create, :show]
    resources "/events", EventController, only: [:index, :create, :show]
  end

  scope "/ui", WhooksWeb.UI do
    pipe_through [:browser, :fetch_current_scope_for_user]

    scope "/auth", Auth do
      resources "/registration", UserRegistrationController, only: [:index, :create]
      resources "/login", UserLoginController, only: [:index, :create]
      delete "/logout", UserLoginController, :delete
    end

    scope "/admin", Admin do
      pipe_through [:require_authenticated_user, :require_manager_user, :fetch_organizations]

      get "/home", HomeController, :home
      post "/organizations", OrganizationController, :create

      scope "/:organization_id" do
        resources "/organizations", OrganizationController, only: [:index]
        resources "/projects", ProjectController, only: [:index, :show]
        resources "/consumers", ConsumerController, only: [:index, :show, :create]
        post "/consumers/:id/portal-link", ConsumerController, :create_portal_link
        resources "/endpoints", EndpointController, only: [:show, :create]
        resources "/topics", TopicController, only: [:create]

        scope "/events" do
          resources "/", EventController, only: [:index, :show]
          post "/:id/resend", EventController, :resend
        end
      end
    end

    scope "/consumers", Consumer do
      pipe_through [:fetch_current_scope_for_consumer]

      get "/", HomeController, :index
      get "/login/:token", ConsumerSessionController, :confirm

      scope "/events" do
        resources "/", EventController, only: [:index, :show]
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", WhooksWeb do
  #   pipe_through :api
  # end'

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:whooks, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WhooksWeb.Telemetry
    end
  end

  ## Authentication routes

  scope "/", WhooksWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", WhooksWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", WhooksWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
