# defmodule Bonfire.Social.Notifications.Follows.Test do
#   use Bonfire.UI.Social.Graph.ConnCase, async: true
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
#       assert feed = Floki.find(doc, ".feed")
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
#       assert feed = Floki.find(doc, ".feed")
#       refute Floki.text(feed) =~ me.profile.name
#     end
#   end
# end

defmodule Bonfire.Social.Notifications.FollowsTest do
  use Bonfire.UI.Social.Graph.ConnCase, async: true
  alias Bonfire.Social.Graph.Follows

  describe "show" do
    test "when someone follows me in my notifications" do
      # Create two users - one to do the following, one to receive it
      some_account = fake_account!()
      someone = fake_user!(some_account)

      me = fake_user!(some_account)

      # Set up the follow relationship
      assert {:ok, _follow} = Follows.follow(me, someone)
      assert true == Follows.following?(me, someone)

      # Visit notifications as the user who was followed
      conn = conn(user: me, account: some_account)

      conn
      |> visit("/notifications")
      |> PhoenixTest.open_browser()
      |> assert_has(".feed", text: someone.profile.name)
      |> assert_has(".feed", text: "followed")
    end
  end

  describe "DO NOT show" do
    test "when I follow someone in my notifications" do
      # Create two users
      some_account = fake_account!()
      someone = fake_user!(some_account)

      me = fake_user!()

      # Set up the follow relationship - this time someone follows me
      assert {:ok, _follow} = Follows.follow(me, someone)
      assert true == Follows.following?(me, someone)

      # Visit notifications as the user who did the following
      conn = conn(user: someone, account: some_account)

      conn
      |> visit("/notifications")
      |> refute_has(".feed", text: me.profile.name)
    end
  end
end
