defmodule Bonfire.UI.Social.Graph.FollowsGuestPaginationTest do
  use Bonfire.UI.Social.Graph.ConnCase, async: System.get_env("TEST_UI_ASYNC") != "no"
  use Bonfire.Common.Config
  alias Bonfire.Social.Graph.Follows

  describe "guest pagination on a profile's followers list (without JavaScript)" do
    setup do
      limit = Bonfire.Common.Config.get(:default_pagination_limit, 2)

      alice = fake_user!("alice followed")

      # More than one page worth of followers. Listing is reverse
      # chronological, so the last follower is newest (first page).
      total = limit * 2 + 1

      for n <- 1..total do
        follower = fake_user!("follower #{n}")
        {:ok, _} = Follows.follow(follower, alice)
      end

      %{alice: alice, limit: limit, total: total}
    end

    test "clicking 'Next page' as a guest shows the next followers, not the same ones", %{
      alice: alice,
      limit: limit,
      total: total
    } do
      # a guest has no LiveView socket, so the page they get is the static render, which `visit` does not give (it connects a LiveView)
      first_page =
        conn()
        |> get_conn_render("/@#{alice.character.username}/followers")
        # The first page lists the newest followers
        |> assert_has("[data-id=profile_name]", text: "follower #{total}")
        # The no-JS guest fallback link is on the static render
        |> assert_has("a[data-id=next_page]", text: "Next page")

      # Following it must show the NEXT followers, not a blank page nor the same ones
      conn()
      |> get_conn_render(static_href(first_page, "a[data-id=next_page]"))
      |> refute_has("[data-id=profile_name]", text: "follower #{total}")
      |> assert_has("[data-id=profile_name]", text: "follower #{total - limit}")
    end
  end
end
