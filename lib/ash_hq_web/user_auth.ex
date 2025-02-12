defmodule AshHqWeb.UserAuth do
  @moduledoc """
  Helpers for authenticating, logging in and logging out users.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias AshHq.Accounts
  alias AshHqWeb.Router.Helpers, as: Routes
  require Ash.Query

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_reference_live_app_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_user(conn, user, params \\ %{}) do
    token = create_token_for_user(user)

    log_in_with_token(conn, token, params["remember_me"] == "true")
  end

  def log_in_with_token(conn, token, remember_me?, return_to \\ nil) do
    user_return_to = return_to || get_session(conn, :user_return_to) || "/"

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, remember_me?)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  @doc """
  Gets a token for a user, effectively "logging them in".

  This is used in liveviews, after which the token is sent to
  the session creation endpoint, which stores the token in the session.
  """
  def create_token_for_user(user) do
    Accounts.UserToken
    |> Ash.Changeset.for_create(:build_session_token, %{user: user.id}, authorize?: false)
    |> Accounts.create!()
    |> Map.get(:token)
  end

  defp maybe_write_remember_me_cookie(conn, token, true) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)

    if user_token do
      {:ok, query} =
        AshHq.Accounts.UserToken
        |> Ash.Query.filter(token == ^user_token and context == "session")
        |> Ash.Query.data_layer_query()

      AshHq.Repo.delete_all(query)
    end

    if live_socket_id = get_session(conn, :live_socket_id) do
      AshHqWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: Routes.app_view_path(AshHqWeb.Endpoint, :home))
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)

    assign(conn, :current_user, user_for_session_token(user_token))
  end

  @doc """
  Gets the user corresponding to a given session token.

  If the session token is nil or does not exist, then `nil` is returned.
  """
  def user_for_session_token(nil), do: nil

  def user_for_session_token(user_token) do
    AshHq.Accounts.User
    |> Ash.Query.for_read(:by_token, %{token: user_token, context: "session"}, authorize?: false)
    |> AshHq.Accounts.read_one!()
  end

  defp ensure_user_token(conn) do
    if user_token = get_session(conn, :user_token) do
      {user_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if user_token = conn.cookies[@remember_me_cookie] do
        {user_token, put_session(conn, :user_token, user_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: Routes.app_view_path(conn, :log_in))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: "/"

  def put_session_layout(conn, _opts) do
    conn
    |> put_layout(false)
    |> put_root_layout({AshHqWeb.LayoutView, :session})
  end
end
