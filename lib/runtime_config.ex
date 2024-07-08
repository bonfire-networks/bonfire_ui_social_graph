defmodule Bonfire.UI.Social.Graph.RuntimeConfig do
  use Bonfire.Common.Localise

  @behaviour Bonfire.Common.ConfigModule
  def config_module, do: true

  @doc """
  NOTE: you can override this default config in your app's `runtime.exs`, by placing similarly-named config keys below the `Bonfire.Common.Config.LoadExtensionsConfig.load_configs()` line
  """
  def config do
    import Config

    # config :bonfire_ui_social_graph,
    #   modularity: :disabled

    config :bonfire, :ui,
      profile: [
        # TODO: make dynamic based on active extensions
        sections: [
          followers: Bonfire.UI.Social.Graph.ProfileFollowsLive,
          followed: Bonfire.UI.Social.Graph.ProfileFollowsLive,
          requested: Bonfire.UI.Social.Graph.ProfileFollowsLive,
          requests: Bonfire.UI.Social.Graph.ProfileFollowsLive
        ],
        # navigation: [
        #   followed: l("Network")
        # ],
        network: [
          followers: l("Followers"),
          followed: l("Followed")
        ],
        my_network: [
          followers: l("Followers"),
          # requests: "Follower requests",
          followed: l("Followed")
          # requested: "Pending"
        ]
      ]
  end
end
