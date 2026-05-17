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
      conn()
      |> visit("/@#{alice.character.username}/followers")
      # The first page lists the newest followers
      |> assert_has("[data-id=profile_name]", text: "follower #{total}")
      # The no-JS guest fallback link must be present (this is the bug: it isn't)
      |> assert_has("a[data-id=next_page]", text: "Next page")
      # Following it must show the NEXT followers, not a blank page nor the same ones
      |> click_link("a[data-id=next_page]", "Next page")
      |> refute_has("[data-id=profile_name]", text: "follower #{total}")
      |> assert_has("[data-id=profile_name]", text: "follower #{total - limit}")
    end
  end
end
