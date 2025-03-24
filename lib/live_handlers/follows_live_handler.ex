defmodule Bonfire.Social.Graph.Follows.LiveHandler do
  use Bonfire.UI.Common.Web, :live_handler
  import Untangle
  # alias Bonfire.Boundaries.Circles

  def handle_event("follow", %{"id" => id} = params, socket) do
    # debug(socket)

    if String.contains?(id, ",") do
      # batch follow
      if current_user = current_user(socket) do
        Bonfire.Social.Graph.Follows.batch_follow(current_user, String.split(id, ","))
        |> debug("batch follow result")

        # TODO: handle errors

        {:noreply, socket |> assign_flash(:info, l("Attempted to follow them all..."))}
      end
    else
      set = [
        my_follow: true
      ]

      with {:ok, current_user} <- current_user_or_remote_interaction(socket, l("follow"), id),
           {:ok, _follow} <- Bonfire.Social.Graph.Follows.follow(current_user, id) do
        ComponentID.send_assigns(
          e(params, "component", Bonfire.UI.Social.Graph.FollowButtonLive),
          id,
          set,
          socket
        )
      else
        e ->
          debug(e)
          {:error, "Could not follow"}
      end
    end
  end

  def handle_event("unfollow", %{"id" => id} = params, socket) do
    with _ <- Bonfire.Social.Graph.Follows.unfollow(current_user_required!(socket), id) do
      set = [
        my_follow: false
      ]

      ComponentID.send_assigns(
        e(params, "component", Bonfire.UI.Social.Graph.FollowButtonLive),
        id,
        set,
        socket
      )

      # TODO: handle errors
    end
  end

  def handle_event("accept", %{"id" => id} = _params, socket) do
    # debug(socket)

    with {:ok, _follow} <-
           Bonfire.Social.Graph.Follows.accept(id, current_user: current_user_required!(socket)) do
      {:noreply, socket}
    else
      e ->
        error(e, l("There was an error when trying to accept the request"))
    end
  end

  def update_many(assigns_sockets, opts \\ []) do
    {first_assigns, _socket} = List.first(assigns_sockets)

    update_many_async(
      assigns_sockets,
      update_many_opts(
        opts ++
          [
            id:
              e(first_assigns, :user, :character, :username, nil) ||
                e(first_assigns, :feed_name, nil) || e(first_assigns, :feed_id, nil) ||
                e(first_assigns, :thread_id, nil) || id(first_assigns)
          ]
      )
    )
  end

  def update_many_opts(opts \\ []) do
    opts ++
      [
        skip_if_set: :my_follow,
        assigns_to_params_fn: &assigns_to_params/1,
        preload_fn: &do_preload/3
      ]
  end

  defp assigns_to_params(assigns) do
    object = e(assigns, :object, nil)

    %{
      component_id: assigns.id,
      object: object,
      object_id: e(assigns, :object_id, nil) || uid(object),
      previous_value: e(assigns, :my_follow, nil)
    }
  end

  defp do_preload(list_of_components, list_of_ids, current_user) do
    # # Here we're checking if the user is ghosted / silenced by user or instance
    # ghosted? = Bonfire.Boundaries.Blocks.is_blocked?(List.first(list_of_ids), :ghost, current_user: current_user) |> debug("ghosted?")
    # ghosted_instance_wide? = Bonfire.Boundaries.Blocks.is_blocked?(List.first(list_of_ids), :ghost, :instance_wide) |> debug("ghosted_instance_wide?")
    # silenced? = Bonfire.Boundaries.Blocks.is_blocked?(List.first(list_of_ids), :silence, current_user: current_user) |> debug("silenced?")
    # silenced_instance_wide? = Bonfire.Boundaries.Blocks.is_blocked?(List.first(list_of_ids), :silence, :instance_wide) |> debug("silenced_instance_wide?")

    my_follows =
      if current_user,
        do:
          Bonfire.Social.Graph.Follows.get!(current_user, List.wrap(list_of_ids),
            preload: false,
            skip_boundary_check: true
          )
          |> Map.new(fn l -> {e(l, :edge, :object_id, nil), true} end),
        else: %{}

    debug(my_follows, "my_follows")

    followed_ids = Map.keys(my_follows)

    remaining_ids =
      Enum.reject(list_of_ids, &(&1 in followed_ids))
      |> debug("remaining_ids")

    my_requests =
      if current_user,
        do:
          Bonfire.Social.Requests.get!(
            current_user,
            Bonfire.Data.Social.Follow,
            remaining_ids,
            preload: false,
            skip_boundary_check: true
          )
          |> Map.new(fn l -> {e(l, :edge, :object_id, nil), true} end),
        else: %{}

    debug(my_requests, "my_requests")

    list_of_components
    |> Map.new(fn component ->
      disable? =
        (Bonfire.Social.is_local?(component.object) == false and
           !Bonfire.Social.federating?(current_user))
        |> debug("disable follow?")

      {component.component_id,
       %{
         my_follow:
           if(Map.get(my_requests, component.object_id), do: :requested) ||
             Map.get(my_follows, component.object_id) || component.previous_value || false,
         disabled: disable?,
         title: if(disable?, do: l("Cannot follow a remote actor when federation is disabled."))
         # ghosted?: ghosted?,
         # ghosted_instance_wide?: ghosted_instance_wide?,
         # silenced?: silenced?,
         # silenced_instance_wide?: silenced_instance_wide?
       }}
    end)
  end

  def load_network("followed" = tab, user, params, socket) do
    user = user || e(assigns(socket), :user, nil)
    current_user = current_user(assigns(socket))
    pagination = input_to_atoms(params)

    requested =
      if id(user) == id(current_user), do: list_requested(current_user, pagination), else: []

    #  TODO: use FeedLoader
    followed =
      Bonfire.Social.Graph.Follows.list_followed(
        user,
        pagination: pagination,
        current_user: current_user
      )
      |> debug("followed_listed")

    [
      loading: false,
      selected_tab: tab,
      back: "/@#{e(user, :character, :username, nil)}",
      feed: requested ++ e(followed, :edges, []),
      page_info: e(followed, :page_info, []),
      previous_page_info: e(assigns(socket), :page_info, nil)
    ]
  end

  def load_network("followers" = tab, user, params, socket) do
    user = user || e(assigns(socket), :user, nil)
    current_user = current_user(assigns(socket))
    pagination = input_to_atoms(params)

    requests =
      if id(user) == id(current_user), do: list_requests(current_user, pagination), else: []

    #  TODO: use FeedLoader
    followers =
      Bonfire.Social.Graph.Follows.list_followers(user,
        pagination: pagination,
        current_user: current_user
      )
      |> debug("followers_listed")

    [
      loading: false,
      selected_tab: tab,
      back: "/@#{e(user, :character, :username, nil)}",
      feed: requests ++ e(followers, :edges, []),
      page_info: e(followers, :page_info, []),
      previous_page_info: e(assigns(socket), :page_info, nil)
    ]
  end

  def load_network(tab, user, params, socket) when tab in ["members"] do
    user = user || e(assigns(socket), :user, nil)
    current_user = current_user(assigns(socket))
    pagination = input_to_atoms(params)

    requests =
      if id(user) == id(current_user), do: list_requests(current_user, pagination), else: []

    #  TODO: use FeedLoader
    followers =
      Bonfire.Social.Graph.Follows.list_followers(
        user,
        pagination: pagination,
        current_user: current_user
      )
      |> debug("followers in feeed")

    [
      loading: false,
      back: "/&#{e(user, :character, :username, nil)}",
      selected_tab: tab,
      feed: requests ++ e(followers, :edges, []),
      page_info: e(followers, :page_info, []),
      previous_page_info: e(assigns(socket), :page_info, nil)
    ]
  end

  def load_network("requested" = tab, _user, params, socket) do
    requested = list_requested(current_user(assigns(socket)), input_to_atoms(params))

    [
      loading: false,
      selected_tab: tab,
      back: "/@#{e(current_user(assigns(socket)), :character, :username, nil)}",
      feed: requested
      # TODO: pagination
      # page_info: e(requested, :page_info, [])
    ]
  end

  def load_network("requests" = tab, _user, params, socket) do
    requests = list_requests(current_user(assigns(socket)), input_to_atoms(params))

    [
      loading: false,
      back: "/@#{e(current_user(assigns(socket)), :character, :username, nil)}",
      selected_tab: tab,
      feed: requests
      # page_info: e(requested, :page_info, [])
    ]
  end

  def list_requested(current_user, pagination) do
    # TODO: apply boundaries to Requests and then be able to view someone's requests/requested that involve me
    # TODO: pagination
    # user,
    Utils.maybe_apply(
      Bonfire.Social.Requests,
      :list_my_requested,
      [pagination: pagination, current_user: current_user, type: Bonfire.Data.Social.Follow],
      fallback_return: []
    )
    |> debug("requested")
  end

  def list_requests(current_user, pagination) do
    # TODO: apply boundaries to Requests and then be able to view someone's requests/requested that involve me
    # TODO: pagination
    # user,
    Utils.maybe_apply(
      Bonfire.Social.Requests,
      :list_my_requesters,
      [pagination: pagination, current_user: current_user],
      fallback_return: []
    )
    |> debug("requests")
  end
end
