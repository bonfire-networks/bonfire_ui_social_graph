defmodule Bonfire.UI.Social.Graph.FollowRejectedButtonTest do
  @moduledoc """
  The Follow button on the profile of someone elsewhere who approves followers by hand: "Requested" until they answer, and Follow again after they reject.
  """
  use Bonfire.UI.Social.Graph.ConnCase, async: false
  @moduletag :ui

  import Tesla.Mock
  alias ActivityPub.Federator.Transformer
  alias Bonfire.Federate.ActivityPub.Simulate, as: APSimulate
  alias Bonfire.Social.Graph.Follows

  @remote "https://mocked.local/users/locked"

  setup do
    Process.put(:federating, true)

    doc = APSimulate.actor_json(@remote, "locked", %{"manuallyApprovesFollowers" => true})

    mock(fn
      %{method: :get, url: @remote} -> json(doc)
      %{method: :post} -> %Tesla.Env{status: 202, body: ""}
      %{method: :get} -> %Tesla.Env{status: 404, body: ""}
    end)

    {:ok, remote} = Bonfire.Federate.ActivityPub.Adapter.maybe_create_remote_actor(doc)

    account = fake_account!()
    me = fake_user!(account)
    {:ok, remote: remote, me: me, conn: conn(user: me, account: account)}
  end

  # control: a decline here (Ignore) stays silent to the requester, whose button goes on showing the request
  test "after a local Ignore the requester still sees Requested", %{conn: conn, me: me} do
    locked = fake_user!(%{}, %{}, request_before_follow: true)
    assert {:ok, request} = Follows.follow(me, locked)
    assert Follows.requested?(me, locked), "control: a request"

    assert {:ok, _} = Follows.ignore(request, current_user: locked)

    conn
    |> visit(Bonfire.Common.URIs.path(locked))
    |> wait_async()
    |> assert_has("button", text: "Requested")
  end

  test "Requested until they answer, and Follow again after they reject", %{
    conn: conn,
    remote: remote,
    me: me
  } do
    {:ok, follow} = Follows.follow(me, remote)
    assert {:ok, follow_activity} = Bonfire.Federate.ActivityPub.Outgoing.push_now!(follow)
    assert Follows.requested?(me, remote), "control: a request"

    conn
    |> visit(Bonfire.Common.URIs.path(remote))
    |> wait_async()
    |> assert_has("button", text: "Requested")

    assert {:ok, _} =
             Transformer.handle_incoming(%{
               "@context" => "https://www.w3.org/ns/activitystreams",
               "type" => "Reject",
               "id" => "#{@remote}/reject/#{System.unique_integer([:positive])}",
               "actor" => @remote,
               "object" => follow_activity.data["id"],
               "to" => [follow_activity.data["actor"]]
             })

    refute Follows.requested?(me, remote)

    conn
    |> visit(Bonfire.Common.URIs.path(remote))
    |> wait_async()
    |> assert_has("button", text: "Follow", exact: true)
    |> refute_has("button", text: "Requested")
  end
end
