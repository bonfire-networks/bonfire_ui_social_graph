defmodule Bonfire.UI.Social.Graph.FollowSomeoneElseOnPageTest do
  @moduledoc """
  A Follow button for someone other than what the page is about: the people taking part in a thread, on that thread's page. The click names who to follow by id, and the page also holds an object of its own (the post), so following must use the one the click names.
  """
  use Bonfire.UI.Social.Graph.ConnCase, async: false
  @moduletag :ui

  alias Bonfire.Social.Graph.Follows

  test "following someone taking part in a thread follows them, not the post" do
    account = fake_account!()
    me = fake_user!(account)
    alice = fake_user!()
    carol = fake_user!()

    {:ok, post} =
      Bonfire.Posts.publish(
        current_user: alice,
        post_attrs: %{post_content: %{html_body: "alice starts a thread"}},
        boundary: "public"
      )

    {:ok, _reply} =
      Bonfire.Posts.publish(
        current_user: carol,
        post_attrs: %{post_content: %{html_body: "carol joins in"}, reply_to_id: post.id},
        boundary: "public"
      )

    refute Follows.following?(me, carol)

    conn(user: me, account: account)
    |> visit("/post/#{post.id}")
    |> wait_async()
    # what a Follow button for carol sends when its event reaches the page's LiveView (no target of its own), as from the participants widget: only her id, to a socket whose `object` is the post
    |> unwrap(fn view ->
      Phoenix.LiveViewTest.render_hook(view, "Bonfire.Social.Graph.Follows:follow", %{
        "id" => carol.id
      })
    end)

    assert Follows.following?(me, carol), "the click named carol"
    refute Follows.following?(me, alice)
  end
end
