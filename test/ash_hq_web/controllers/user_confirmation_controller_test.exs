defmodule AshHqWeb.UserConfirmationControllerTest do
  use AshHqWeb.ConnCase, async: true

  alias AshHq.Accounts
  alias AshHq.Repo
  import AshHq.AccountsFixtures

  setup do
    user = user_fixture()
    %{user: user}
  end

  describe "POST /users/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns[:flash], :info) =~ "If your email is in our system"
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "confirm"
    end

    test "does not send confirmation token if account is confirmed", %{conn: conn, user: user} do
      Repo.delete_all(Accounts.UserToken)

      user
      |> Ash.Changeset.for_update(:confirm, %{}, authorize?: false)
      |> Accounts.update!()

      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns[:flash], :info) =~ "If your email is in our system"
      refute Repo.get_by(Accounts.UserToken, user_id: user.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      Repo.delete_all(Accounts.UserToken)

      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns[:flash], :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "GET /users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        user
        |> Ash.Changeset.for_update(:deliver_user_confirmation_instructions, %{},
          authorize?: false
        )
        |> Accounts.update!()
        |> Map.get(:__metadata__)
        |> Map.get(:token)

      conn = get(conn, Routes.user_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns[:flash], :info) &&
               Phoenix.Flash.get(conn.assigns[:flash], :info) =~ "Account confirmed successfully"

      assert Accounts.get!(Accounts.User, user.id, authorize?: false).confirmed_at

      refute get_session(conn, :user_token)
      assert Repo.all(Accounts.UserToken) == []

      # When not logged in
      conn = get(conn, Routes.user_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns[:flash], :error) =~
               "Account confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_user(user)
        |> get(Routes.user_confirmation_path(conn, :confirm, token))

      assert redirected_to(conn) == "/"
      refute Phoenix.Flash.get(conn.assigns[:flash], :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_confirmation_path(conn, :confirm, "oops"))
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns[:flash], :error) =~
               "Account confirmation link is invalid or it has expired"

      refute Accounts.get!(Accounts.User, user.id, authorize?: false).confirmed_at
    end
  end
end
