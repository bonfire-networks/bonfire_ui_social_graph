defmodule Bonfire.UI.Social.Graph.ProfileFollowIndicatorLive do
  use Bonfire.UI.Common.Web, :stateful_component
  # import Bonfire.UI.Me
  # import Bonfire.Common.Media

  prop user, :map

  prop follows_me, :boolean, default: nil

  def update_many(%{follows_me: follows_me} = assigns, socket) when is_boolean(follows_me) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  def update_many(_assigns, %{assigns: %{follows_me: follows_me}} = socket)
      when is_boolean(follows_me) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    user = e(assigns(socket), :user, nil)
    current_user = current_user(assigns(socket))
    current_user_id = id(current_user)

    {:ok,
     socket
     |> assign(
       follows_me:
         current_user_id && current_user_id != id(user) &&
           module_enabled?(Bonfire.Social.Graph.Follows, current_user) &&
           Utils.maybe_apply(
             Bonfire.Social.Graph.Follows,
             :follow_status,
             [user, current_user]
           )
           |> debug("any_follow?")
     )}
  end

  # TODO: to avoid n+1
  # def update_many([{%{skip_preload: true}, _}] = assigns_sockets) do
  #   assigns_sockets
  # end
  # def update_many(assigns_sockets) do
  #   Bonfire.Boundaries.Blocks.LiveHandler.update_many(assigns_sockets, caller_module: __MODULE__)
  #   |> debug("any_blocks?")
  # end
end
