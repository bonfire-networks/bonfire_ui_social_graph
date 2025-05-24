defmodule Bonfire.Social.Graph.FollowsTest do
  use Bonfire.UI.Social.Graph.ConnCase, async: true
  alias Bonfire.Social.Graph.Follows

  setup do
    account = fake_account!()
    me = fake_user!(account)

    conn = conn(user: me, account: account)

    {:ok, conn: conn, account: account, me: me}
  end

  test "I can follow someone from their profile", %{conn: conn, me: me} do
    # Create the profile to follow
    some_account = fake_account!()
    someone = fake_user!(some_account)

    # Navigate to their profile
    conn
    |> visit(Bonfire.Common.URIs.path(someone))
    |> click_link("[data-id=follow]", "Follow")
    # |> PhoenixTest.open_browser()
    |> assert_has("[data-id=unfollow]", text: "Following")

    # Verify that we're now following
    assert true == Follows.following?(me, someone)
  end

  test "I can unfollow someone from their profile", %{conn: conn, me: me} do
    # Create the profile to unfollow
    some_account = fake_account!()
    someone = fake_user!(some_account)

    # First make sure we're following them
    {:ok, _follow} = Follows.follow(me, someone)
    assert true == Follows.following?(me, someone)

    # Navigate to their profile and unfollow
    conn
    |> visit(Bonfire.Common.URIs.path(someone))
    |> click_link("[data-id=unfollow]", "Following")
    |> assert_has("[data-id=follow]", text: "Follow")

    # Verify that we're no longer following
    assert false == Follows.following?(me, someone)
  end
end

# defmodule Bonfire.Social.Graph.Follows.Test do
#   use Bonfire.UI.Social.Graph.ConnCase, async: true
#   alias Bonfire.Social.Fake
#   alias Bonfire.Posts
#   alias Bonfire.Social.Graph.Follows

#   describe "follow" do
#     test "when I click follow on someone's profile" do
#       some_account = fake_account!()
#       someone = fake_user!(some_account)

#       my_account = fake_account!()
#       me = fake_user!(my_account)

#       conn = conn(user: me, account: my_account)
#       next = Bonfire.Common.URIs.path(someone)
#       # |> IO.inspect
#       {view, doc} = floki_live(conn, next)

#       assert follow =
#                view
#                |> element("[data-id='follow']")
#                |> render_click()

#       assert true == Follows.following?(me, someone)

#       # Note: the html returned by render_click isn't updated to show the change (probably because it uses ComponentID and pubsub) even though this works in the browser, so we wait for after pubsub events are received
#       live_async_wait(view)

#       assert view
#              |> render()
#              ~> Floki.find("[data-id=unfollow]")
#              |> Floki.text() =~ "Following"
#     end
#   end

#   describe "unfollow" do
#     test "when I click unfollow on someone's profile" do
#       some_account = fake_account!()
#       someone = fake_user!(some_account)

#       my_account = fake_account!()
#       me = fake_user!(my_account)

#       assert {:ok, follow} = Follows.follow(me, someone)
#       # assert true == Follows.following?(me, someone)

#       conn = conn(user: me, account: my_account)
#       next = Bonfire.Common.URIs.path(someone) |> info("path")
#       # |> IO.inspect
#       {view, doc} = floki_live(conn, next)

#       assert unfollow = view |> element("[data-id='unfollow']") |> render_click()
#       assert false == Follows.following?(me, someone)

#       live_async_wait(view)

#       assert view
#              |> render()
#              ~> Floki.find("[data-id=follow]")
#              |> Floki.text() =~ "Follow"
#     end
#   end
# end
