defmodule Bonfire.UI.Social.Graph.FollowButtonLive do
  use Bonfire.UI.Common.Web, :stateful_component

  prop object_id, :string, required: true

  prop path, :string, default: nil

  prop class, :css_class, default: nil
  prop icon_class, :css_class, default: nil
  prop label, :string, default: nil
  prop title, :any, default: nil
  prop disabled, :boolean, default: false
  prop hide_icon, :boolean, default: false
  prop hide_text, :boolean, default: false

  prop verb, :string, default: nil
  prop verb_already, :string, default: nil
  prop verb_undo, :string, default: nil

  prop my_follow, :boolean, default: nil
  prop follows_me, :boolean, default: false
  prop object_boundary, :any, default: nil

  slot if_followed

  def update_many(assigns_sockets),
    do:
      Bonfire.Social.Graph.Follows.LiveHandler.update_many(assigns_sockets,
        caller_module: __MODULE__
      )
end
