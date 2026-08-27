defmodule Bonfire.UI.Social.Graph.FollowButtonLiveTest do
  use Bonfire.UI.Social.Graph.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Bonfire.UI.Social.Graph.FollowButtonLive

  test "supports a fixed loading footprint without changing the shared default" do
    current_user_id = Needle.UID.generate()
    object_id = Needle.UID.generate()

    custom_assigns =
      Bonfire.UI.Common.Web.apply_surface_prop_defaults(FollowButtonLive, %{
        id: "compact_follow",
        myself: nil,
        object_id: object_id,
        my_follow: nil,
        loading_class: "skeleton h-8 w-[76px] rounded-[9px]",
        __context__: %{current_user: %{id: current_user_id}}
      })

    custom_html =
      custom_assigns
      |> Map.put(:__changed__, %{})
      |> FollowButtonLive.render()
      |> rendered_to_string()

    loading_prop = Enum.find(FollowButtonLive.__props__(), &(&1.name == :loading_class))

    assert custom_html =~ ~s(class="skeleton h-8 w-[76px] rounded-[9px]")
    assert loading_prop.opts[:default] == "skeleton h-8 w-24 rounded-full"
  end
end
