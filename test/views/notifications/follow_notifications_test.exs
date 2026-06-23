defmodule Bonfire.Social.Notifications.FollowsTest do
  use Bonfire.UI.Social.Graph.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"
  alias Bonfire.Social.Graph.Follows

  describe "show" do
    test "when someone follows me in my notifications" do
      # Create two users - one to do the following, one to receive it
      some_account = fake_account!()
      someone = fake_user!(some_account)

      me = fake_user!(some_account)

      # Set up the follow relationship
      assert {:ok, _follow} = Follows.follow(someone, me)
      assert true == Follows.following?(someone, me)

      # Visit notifications as the user who was followed
      conn = conn(user: me, account: some_account)

      conn
      |> visit("/notifications")
      # |> PhoenixTest.open_browser()
      |> assert_has("[data-id=feed] article", text: someone.profile.name)
      |> assert_has("[data-id=feed] article", text: "followed")
    end

    @tag :skip_ci
    test "when I accept a follow request, the live-pushed activity shows the follower (not me) as the actor" do
      # Regression for bonfire-app#1907/#1906/#1659: clicking Accept live-pushes the new Follow
      # activity to my open notifications via PubSub. Its actor must be the FOLLOWER — with the
      # bug it was created with subject = current_user (the accepter, i.e. me), so the pushed
      # activity showed the wrong/invalid actor until a refresh. This asserts the rendered,
      # real-time UI (not just the DB row, which is covered in bonfire_social_graph).
      some_account = fake_account!()
      someone = fake_user!(some_account, %{}, request_before_follow: true)

      me = fake_user!(some_account, %{}, request_before_follow: true)

      # someone requests to follow me (my follow boundary requires approval)
      assert {:ok, request} = Follows.follow(someone, me)
      assert true == Follows.requested?(someone, me)

      # I open my notifications page (subscribes to my notifications feed via PubSub)
      conn = visit(conn(user: me, account: some_account), "/notifications")

      # I accept the request (simulate the click from another session); this pushes the activity
      Task.start(fn -> Follows.accept(request, current_user: me) end)

      # the live-pushed Follow must render the FOLLOWER as the actor — not me, the accepter
      conn
      # |> PhoenixTest.open_browser()
      |> assert_has_or_open_browser("[data-id=feed] article", text: "followed", timeout: 3000)
      |> assert_has_or_open_browser("[data-role=subject]", text: someone.profile.name)
      |> refute_has("[data-role=subject]", text: me.profile.name)
    end
  end

  describe "DO NOT show" do
    test "when I follow someone in my own notifications" do
      # Create two users
      some_account = fake_account!()
      someone = fake_user!(some_account)

      me = fake_user!()

      # Set up the follow relationship - this time someone follows me
      assert {:ok, _follow} = Follows.follow(me, someone)
      assert true == Follows.following?(me, someone)

      # Visit notifications as the user who did the following
      conn = conn(user: me)

      conn
      |> visit("/notifications")
      |> refute_has("[data-id=feed] article", text: someone.profile.name)
    end
  end
end

# defmodule Bonfire.Social.Notifications.Follows.Test do
#   use Bonfire.UI.Social.Graph.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"
#   alias Bonfire.Social.Fake
#   alias Bonfire.Posts
#   alias Bonfire.Social.Graph.Follows

#   describe "show" do
#     test "when someone follows me in my notifications" do
#       some_account = fake_account!()
#       someone = fake_user!(some_account)

#       me = fake_user!()
#       assert {:ok, follow} = Follows.follow(me, someone)
#       assert true == Follows.following?(me, someone)

#       conn = conn(user: someone, account: some_account)
#       next = "/notifications"
#       # |> IO.inspect
#       {view, doc} = floki_live(conn, next)
#       assert feed = Floki.find(doc, "[data-id=feed]")
#       assert Floki.text(feed) =~ me.profile.name
#       # FIXME
#       assert Floki.text(feed) =~ "followed"
#     end
#   end

#   describe "DO NOT show" do
#     test "when I follow someone in my notifications" do
#       some_account = fake_account!()
#       someone = fake_user!(some_account)

#       me = fake_user!()
#       assert {:ok, follow} = Follows.follow(someone, me)
#       assert true == Follows.following?(someone, me)

#       conn = conn(user: someone, account: some_account)
#       next = "/notifications"
#       # |> IO.inspect
#       {view, doc} = floki_live(conn, next)
#       assert feed = Floki.find(doc, "[data-id=feed]")
#       refute Floki.text(feed) =~ me.profile.name
#     end
#   end
# end
