defmodule Bonfire.UI.Social.Graph.FollowButtonLive do
  use Bonfire.UI.Common.Web, :stateful_component

  prop object_id, :string, default: nil
  prop object_ids, :list, default: []

  @doc "The object itself, when the caller already has it. Optional: several callers pass only `object_id`, and the event carries an id either way. Declared because passing it lets the handler skip re-fetching what the parent already loaded, `Follows.follow/3` answers both `:follow` and `:request` in one query when given a struct, but has to fetch first when given an id."
  prop object, :any, default: nil

  prop path, :string, default: nil

  prop container_class, :css_class, default: "flex items-center gap-2 w-full"
  prop class, :css_class, default: nil
  prop loading_class, :css_class, default: "skeleton h-8 w-24 rounded-full"

  @doc "Class for the already-following/requested states (falls back to `class`), so the resting CTA can be solid while the done-state is quieter"
  prop class_already, :css_class, default: nil
  prop icon_class, :css_class, default: nil
  prop icon, :string, default: "ph:user-plus-fill"
  prop icon_already, :string, default: "ph:user-minus-fill"
  prop label, :string, default: nil
  prop title, :any, default: nil
  prop title_already, :any, default: nil
  prop disabled, :boolean, default: false
  prop hide_icon, :boolean, default: false
  prop hide_text, :boolean, default: false

  prop verb, :string, default: nil
  prop verb_already, :string, default: nil
  prop verb_undo, :string, default: nil

  prop my_follow, :any, default: nil
  prop follows_me, :atom, default: false
  prop object_boundary, :any, default: nil

  @doc "Also show the bell (\"notify me about their new posts\") beside the button, when `bonfire_notify` is enabled: once following, or straight away for a local person or group, whose posts are here without a follow."
  prop with_bell, :boolean, default: true

  slot if_followed

  @doc "Where a guest's Follow goes: the remote-follow deeplink when another server can reach the object, otherwise signing in here, the only way to follow something that does not federate."
  def guest_follow_path(path, object_id) do
    if maybe_apply(
         Bonfire.Federate.ActivityPub.AdapterUtils,
         :remotely_reachable?,
         [object_id],
         fallback_return: false
       ) == true,
      do: "#{path}/interact/follow",
      else: "/login?go=#{path}"
  end

  def update_many(assigns_sockets),
    do:
      Bonfire.Social.Graph.Follows.LiveHandler.update_many(assigns_sockets,
        caller_module: __MODULE__
      )
end
