defmodule Bonfire.UI.Social.Graph.MoveAwayTest do
  @moduledoc """
  The export settings page lists the user's aliases, each with its own "Migrate" modal. Every modal is a stateful component, so each needs a unique id or the LiveView crashes when the user has two or more aliases.
  """
  use Bonfire.UI.Social.Graph.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"
  use Bonfire.Common.E

  alias Bonfire.Social.Graph.Aliases

  @moduletag :ui

  setup do
    account = fake_account!()
    me = fake_user!(account)

    conn = conn(user: me, account: account)

    {:ok, conn: conn, me: me}
  end

  test "export page renders a migrate option for a single alias", %{conn: conn, me: me} do
    alias_a = fake_user!()
    assert {:ok, _} = Aliases.add(me, alias_a)
    assert [_] = Aliases.list_my_aliases(me) |> e(:edges, [])

    conn
    |> visit("/settings/user/export")
    |> wait_async()
    |> assert_has("[data-role=open_modal]", text: "Migrate")
  end

  test "export page renders a separate migrate option per alias", %{conn: conn, me: me} do
    alias_a = fake_user!()
    alias_b = fake_user!()
    assert {:ok, _} = Aliases.add(me, alias_a)
    assert {:ok, _} = Aliases.add(me, alias_b)
    assert [_, _] = Aliases.list_my_aliases(me) |> e(:edges, [])

    conn
    |> visit("/settings/user/export")
    |> wait_async()
    |> assert_has("#migrate_away_modal_#{alias_a.id} [data-role=open_modal]", text: "Migrate")
    |> assert_has("#migrate_away_modal_#{alias_b.id} [data-role=open_modal]", text: "Migrate")
  end
end
