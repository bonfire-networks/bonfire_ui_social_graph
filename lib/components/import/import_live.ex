defmodule Bonfire.UI.Social.Graph.ImportLive do
  use Bonfire.UI.Common.Web, :stateful_component

  prop selected_tab, :any
  prop scope, :atom, default: nil
  prop type, :atom, default: nil

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       trigger_submit: false,
       uploaded_files: [],
       page_title: "Blocks Import"
     )
     |> allow_upload(:file,
       accept: ~w(.csv),
       # TODO: make extensions & size configurable
       max_file_size: 500_000_000,
       max_entries: 1,
       auto_upload: true
       #  progress: &handle_progress/3
     )}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("import", %{"type" => type} = params, socket) do
    current_user = current_user_required!(socket)
    #  TODO check permission
    scope = e(assigns(socket), :scope, nil) || id(current_user)

    case uploaded_entries(socket, :file) |> debug() do
      {[_ | _] = entries, []} ->
        with [%{ok: queued}] <-
               (for entry <- entries do
                  maybe_consume_uploaded_entry(socket, entry, fn %{path: path} ->
                    debug(path)
                    # debug(entry)
                    # with %{ok: num} <-
                    # do
                    Bonfire.Social.Graph.Import.import_from_csv_file(
                      maybe_to_atom(type),
                      scope,
                      path
                    )

                    #   {:ok, "#{num}"}
                    # end
                  end)
                end) do
          {
            :noreply,
            socket
            |> assign_flash(:info, "#{queued} items queued for import :-)")
            # |> update(:uploaded_files, &(&1 ++ uploaded_files))
          }
        else
          e ->
            error(e)

            {
              :noreply,
              socket
              |> assign_error("No items queued for import")
            }
        end

      _ ->
        {:noreply, socket}
    end
  end

  # def handle_progress(
  #       type,
  #       entry,
  #       socket
  #     ),
  #     do:
  #       Bonfire.UI.Common.LiveHandlers.handle_progress(
  #         type,
  #         entry,
  #         socket,
  #         __MODULE__,
  #         Bonfire.Files.LiveHandler
  #       )

  def options_list(:instance_wide, :blocks, _),
    do: %{
      "" => nil,
      l("List of profiles/instances to ghost (instance-wide)") => :ghosts,
      l("List of profiles/instances to silence (instance-wide)") => :silences,
      l("List of profiles/instances to block (instance-wide)") => :blocks
    }

  def options_list(_, type, federating?) when type == :blocks or federating? == false,
    do: %{
      "" => nil,
      l("List of profiles/instances to ghost") => :ghosts,
      l("List of profiles/instances to silence") => :silences,
      l("List of profiles/instances to block") => :blocks
    }

  def options_list(_, _, _),
    do: %{
      "" => nil,
      l("List of profiles to follow") => :following,
      l("List of profiles/instances to ghost") => :ghosts,
      l("List of profiles/instances to silence") => :silences,
      l("List of profiles/instances to block") => :blocks
    }
end
