defmodule Bonfire.UI.Social.Graph.ProfileFollowIndicator do
  use Bonfire.UI.Common.Web, :stateless_component
  # import Bonfire.UI.Me

  prop user, :map

  prop follows_me, :boolean, default: nil
end
