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

    # One getting-started step, declared here because following people is this extension's feature. The widget that shows it holds no steps of its own, and this list merges with what every other extension declares. The copy is compiled here so `mix gettext.extract` sees it.
    config :bonfire_ui_common, Bonfire.UI.Common.WidgetGettingStartedLive,
      actions_registry: [
        first_follow: %{
          title: l("Follow someone"),
          rationale: l("Your feed comes alive once you follow a few people. Start with one."),
          cta_label: l("Find people"),
          cta_path: "/users",
          needs: Bonfire.Social.Graph.Follows,
          done?: &Bonfire.Social.Graph.Follows.any_by_subject?/1
        }
      ]

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
          followed: l("Following")
        ],
        my_network: [
          followers: l("Followers"),
          # requests: "Follower requests",
          followed: l("Following")
          # requested: "Pending"
        ]
      ]
  end
end
