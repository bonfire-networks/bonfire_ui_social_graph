defmodule Bonfire.UI.Social.Graph.ProfileFollowsLive do
  use Bonfire.UI.Common.Web, :stateless_component

  prop user, :map
  prop selected_tab, :any, default: nil
  prop feed, :list, default: []
  prop page_info, :any, default: nil
  prop showing_within, :atom, default: :profile
  prop hide_tabs, :boolean, default: false

  # slot header
end
