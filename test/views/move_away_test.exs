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

    {:ok, conn: conn, me: me, account: account}
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

  test "migrate form submits to the alias handler", %{conn: conn, me: me, account: account} do
    alias_a = fake_user!()
    assert {:ok, _} = Aliases.add(me, alias_a)

    # the target never added `me` back as an alias, so reaching this domain error proves the event was handled
    conn
    |> visit("/settings/user/export")
    |> wait_async()
    |> within("#migrate_away_modal_#{alias_a.id}", &click_button(&1, "Migrate"))
    |> fill_in("For security purposes please enter the password of your account",
      with: account.credential.password
    )
    |> click_button("Migrate to")
    |> assert_has("[role=alert]", text: "You need to first add")
  end

  test "add alias form adds the alias", %{conn: conn, me: me} do
    alias_a = fake_user!()
    assert [] = Aliases.list_my_aliases(me) |> e(:edges, [])

    # the input has a placeholder but no label, so PhoenixTest's fill_in can't target it
    {:ok, view, _html} = live(conn, "/settings/user/export")

    # success redirects with a reload, so the render result itself isn't asserted
    view
    |> form("form[phx-submit$=':add_alias_to']", %{
      "actor" => Bonfire.Me.Characters.display_username(alias_a, true, true)
    })
    |> render_submit()

    assert [%{edge: %{object_id: object_id}}] = Aliases.list_my_aliases(me) |> e(:edges, [])
    assert object_id == alias_a.id
  end
end
