defmodule Bonfire.UI.Social.Graph.ImportHistoryLive do
  use Bonfire.UI.Common.Web, :surface_live_view

  on_mount {LivePlugs, [Bonfire.UI.Me.LivePlugs.LoadCurrentUser]}

  def mount(_params, _session, socket) do
    current_user = current_user(socket)

    if current_user do
      jobs = fetch_import_jobs(current_user)
      stats = fetch_import_stats(current_user)

      {:ok,
       assign(
         socket,
         page_title: l("Import History"),
         page: "import_history",
         back: true,
         selected_tab: :import_history,
         nav_items: Bonfire.Common.ExtensionModule.default_nav(),
         jobs: jobs,
         stats: stats
       )}
    else
      throw(l("You need to log in to view import history"))
    end
  end

  def handle_event("refresh", _attrs, socket) do
    current_user = current_user(socket)
    jobs = fetch_import_jobs(current_user)
    stats = fetch_import_stats(current_user)

    {:noreply, assign(socket, jobs: jobs, stats: stats)}
  end

  defp fetch_import_jobs(current_user) do
    user_id = id(current_user)

    try do
      jobs = Bonfire.Common.ObanHelpers.list_jobs_queue_for_user(repo(), "import", user_id)

      # Extract all identifiers for batch user lookup
      identifiers =
        jobs
        |> debug("jjjo")
        |> Enum.map(&get_in(&1.args, ["identifier"]))
        |> debug("idds")
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()

      # Batch fetch users to avoid N+1
      users_by_identifier = fetch_users_by_identifiers(identifiers)

      jobs
      |> Enum.map(&format_job(&1, users_by_identifier))
    rescue
      error ->
        debug(error, "Error fetching import jobs")
        []
    end
  end

  defp fetch_users_by_identifiers(identifiers) when identifiers != [] do
    # Try to fetch users by username first
    users_by_username =
      Bonfire.Me.Characters.by_usernames(identifiers)
      |> debug("lsited")
      |> Map.new(fn user -> {e(user, :username, nil), user} end)
      |> debug("maopped")

    # # For remaining identifiers, try fetching by AP ID or other methods
    # remaining_identifiers = identifiers -- Map.keys(users_by_username)

    # users_by_ap_id = 
    #   if remaining_identifiers != [] do
    #     remaining_identifiers
    #     |> Enum.map(fn identifier ->
    #       case Bonfire.Federate.ActivityPub.AdapterUtils.get_by_url_ap_id_or_username(identifier) do
    #         {:ok, user} -> {identifier, user}
    #         _ -> nil
    #       end
    #     end)
    #     |> Enum.reject(&is_nil/1)
    #     |> Map.new()
    #   else
    #     %{}
    #   end

    users_by_username
    # |> Map.merge(users_by_ap_id)
  end

  defp fetch_users_by_identifiers([]), do: %{}

  defp fetch_import_stats(current_user) do
    user_id = id(current_user)

    try do
      Bonfire.Common.ObanHelpers.import_job_stats_for_user(repo(), user_id)
    rescue
      _error ->
        %{}
    end
  end

  defp format_job(job, users_by_identifier \\ %{}) do
    op_type = get_in(job.args, ["op"]) |> format_operation_type()
    identifier = get_in(job.args, ["identifier"])
    target_user = if identifier, do: Map.get(users_by_identifier, identifier)

    %{
      id: job.id,
      operation: op_type,
      identifier: identifier,
      context: get_in(job.args, ["context"]),
      target_user: target_user,
      state: job.state,
      inserted_at: job.inserted_at,
      completed_at: job.completed_at,
      attempted_at: job.attempted_at,
      errors: job.errors,
      attempt: job.attempt,
      max_attempts: job.max_attempts
    }
  end

  defp format_operation_type("follows_import"), do: l("Follow Import")
  defp format_operation_type("blocks_import"), do: l("Block Import")
  defp format_operation_type("silences_import"), do: l("Silence Import")
  defp format_operation_type("ghosts_import"), do: l("Ghost Import")
  defp format_operation_type("bookmarks_import"), do: l("Bookmark Import")
  defp format_operation_type("circles_import"), do: l("Circle Import")
  defp format_operation_type(other), do: other

  defp format_state("completed"), do: {l("Completed"), "text-success"}
  defp format_state("failed"), do: {l("Failed (will attempt again)"), "text-error"}
  defp format_state("executing"), do: {l("Running"), "text-warning"}
  defp format_state("available"), do: {l("Queued"), "text-info"}
  defp format_state("scheduled"), do: {l("Scheduled"), "text-info"}
  defp format_state("retryable"), do: {l("Retrying"), "text-warning"}
  defp format_state("cancelled"), do: {l("Cancelled"), "text-base-content/60"}
  defp format_state("discarded"), do: {l("Failed"), "text-error"}
  defp format_state(other), do: {other, "text-base-content"}

  defp format_errors(errors) when is_list(errors) do
    errors
    |> Enum.map_join("\n", fn
      %{"error" => error} -> extract_core_error(error)
      error when is_binary(error) -> extract_core_error(error)
      error -> inspect(error)
    end)
  end

  defp format_errors(errors), do: extract_core_error(errors)

  defp extract_core_error(error) when is_binary(error) do
    case Regex.run(~r/failed with (.+)$/, error) do
      [_, core_error] ->
        core_error
        |> String.trim_leading("{")
        |> String.trim_trailing("}")
        |> String.replace(":error, ", "")
        |> String.replace("\"", "")
        |> Types.maybe_to_atom()
        |> Bonfire.Common.Errors.error_msg({:error, ...})

      _ ->
        error
    end
  end

  defp extract_core_error(error), do: inspect(error)
end
