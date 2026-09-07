defmodule Bonfire.Social.Graph.Aliases.LiveHandlerTest do
  @moduledoc """
  The move_away event requires the account password: a wrong or missing password raises before any domain logic runs, a correct one reaches `Aliases.move/2`.
  """
  use Bonfire.UI.Social.Graph.DataCase, async: false

  import Bonfire.Me.Fake

  alias Bonfire.Social.Graph.Aliases.LiveHandler

  setup do
    account = fake_account!()
    user = fake_user!(account)
    target = fake_user!()
    {:ok, account: account, user: user, target: target}
  end

  defp socket_for(user) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        flash: %{},
        __changed__: %{},
        current_user: user,
        # the handler's error branch redirects back to the current URL
        current_url: "/settings/user/export",
        __context__: %{current_user: user}
      }
    }
  end

  describe "move_away password gate" do
    test "refuses a wrong password before any domain logic", %{user: user, target: target} do
      assert_raise Bonfire.Fail.Auth, fn ->
        LiveHandler.handle_event(
          "move_away",
          %{"user" => target.id, "password" => "not-the-password"},
          socket_for(user)
        )
      end
    end

    test "refuses an empty password", %{user: user, target: target} do
      assert_raise Bonfire.Fail.Auth, fn ->
        LiveHandler.handle_event(
          "move_away",
          %{"user" => target.id, "password" => ""},
          socket_for(user)
        )
      end
    end

    test "a correct password passes the gate and reaches the domain", %{
      account: account,
      user: user,
      target: target
    } do
      # the target is not an alias, so reaching the domain error proves the password gate passed
      assert {:noreply, socket} =
               LiveHandler.handle_event(
                 "move_away",
                 %{"user" => target.id, "password" => account.credential.password},
                 socket_for(user)
               )

      assert socket.assigns.flash["error"] =~ "You need to first add"
    end
  end
end
