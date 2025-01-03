defmodule ClientWeb.Router do
  use ClientWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ClientWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ClientWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", ClientWeb do
    pipe_through :api

    post "/shutdown", PageController, :shutdown
    post "/list-local-files", PageController, :list_local_files
    post "/commit", PageController, :commit
    get "/files/stream", PageController, :stream_files
    post "/get-file", PageController, :get_file
    post "/receive-file", PageController, :receive_file
    post "/pull-recent", PageController, :pull_recent
    post "/pull-specific", PageController, :pull_specific
  end

  # Other scopes may use custom stacks.
  # scope "/api", ClientWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:client, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ClientWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
