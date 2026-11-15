defmodule Bonfire.UI.Social.Graph.RequestEventsPermissionsTest do
  @moduledoc """
  A follow request is answered by the person asked, and no one else. The accept and ignore events name the request by id, so the handler has to check who sends them, as the requester can send them too.
  """
  use Bonfire.UI.Social.Graph.ConnCase, async: false
  @moduletag :ui
  @moduletag capture_log: true

  alias Bonfire.Data.Social.Follow
  alias Bonfire.Social.Graph.Follows
  alias Bonfire.Social.Requests

  setup do
    account = fake_account!()
    requester = fake_user!(account)
    locked = fake_user!(%{}, %{}, request_before_follow: true)

    assert {:ok, request} = Follows.follow(requester, locked)
    assert Follows.requested?(requester, locked), "control: a pending request"
    refute Follows.following?(requester, locked)

    {:ok, view, _html} =
      Phoenix.LiveViewTest.live(conn(user: requester, account: account), "/feed/local")

    {:ok, view: view, requester: requester, locked: locked, request: request}
  end

  test "the requester can't accept their own request", ctx do
    Phoenix.LiveViewTest.render_hook(ctx.view, "Bonfire.Social.Graph.Follows:accept", %{
      "id" => ctx.request.id
    })

    refute Follows.following?(ctx.requester, ctx.locked),
           "the requester approved their own follow request"
  end

  test "the requester can't mark their own request ignored", ctx do
    Phoenix.LiveViewTest.render_hook(ctx.view, "Bonfire.Social.Graph.Follows:ignore", %{
      "id" => ctx.request.id
    })

    assert {:ok, request} =
             Requests.get(ctx.requester, Follow, ctx.locked, skip_boundary_check: true)

    assert is_nil(request.ignored_at),
           "the requester changed the state of their own follow request"
  end
end
