defmodule Bonfire.UI.Social.Graph.ProfileFollowsLive do
  use Bonfire.UI.Common.Web, :stateless_component

  declare_extension("UI for social graph",
    icon: "fluent:people-community-48-filled",
    emoji: "🫂",
    description:
      l(
        "User interfaces for following users, managing aliases, importing/exporting follows, and the like."
      )
  )

  prop user, :map
  prop selected_tab, :any, default: nil
  prop feed, :list, default: []
  prop page_info, :any, default: nil
  prop showing_within, :atom, default: :profile
  prop hide_tabs, :boolean, default: false

  # slot header
end
