defmodule Bonfire.Social.Graph.Aliases.LiveHandler do
  use Bonfire.UI.Common.Web, :live_handler
  import Untangle
  # alias Bonfire.Boundaries.Circles

  def handle_event("move_in", %{"actor" => actor}, socket) do
    handle_event(
      "add_alias",
      %{
        "actor" => actor,
        "ok_msg" =>
          l(
            "Added the alias! You can now proceed with moving your profile, by triggering the migration on your old instance."
          )
      },
      socket
    )
  end

  def handle_event("add_alias", %{"actor" => actor} = params, socket) do
    with {:ok, _added} <- Bonfire.Social.Graph.Aliases.add(current_user_required!(socket), actor) do
      {
        :noreply,
        socket
        |> assign_flash(:info, params["ok_msg"] || l("Added the alias!"))
        |> redirect_to(current_url(socket))
      }
    end
  end

  def handle_event("add_alias_to", %{"actor" => actor}, socket) do
    current_user = current_user_required!(socket)

    handle_event(
      "add_alias",
      %{
        "actor" => actor,
        "ok_msg" =>
          l(
            "Added the alias! If you have also added this user (%{username}) as an alias on the instance you want to migrate to, you can proceed by clicking the big red *Migrate* button.",
            username: Bonfire.Me.Characters.display_username(current_user, true, true)
          )
      },
      socket
    )
  end

  def handle_event("move_away", %{"user" => target, "password" => password}, socket) do
    current_user = current_user_auth!(socket, password)

    with {:ok, _added} <- Bonfire.Social.Graph.Aliases.move(current_user, target) do
      {
        :noreply,
        socket
        |> assign_flash(
          :info,
          l("The move is underway... Followers will be transferred over the next few hours...")
        )
      }
    else
      {:error, :not_in_also_known_as} ->
        {
          :noreply,
          socket
          |> assign_flash(
            :error,
            l(
              "You need to first add this user (%{username}) as an alias on the instance you want to migrate to. If you have already done so please try again in an hour or so.",
              username: Bonfire.Me.Characters.display_username(current_user, true, true)
            )
          )
          |> redirect_to(current_url(socket))
        }
    end
  end
end
