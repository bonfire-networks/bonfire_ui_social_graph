defmodule Bonfire.UI.Social.Graph.Routes do
  @behaviour Bonfire.UI.Common.RoutesModule

  defmacro __using__(_) do
    quote do
      # pages anyone can view
      scope "/", Bonfire.UI.Social.Graph do
        pipe_through(:browser)
      end

      # pages you need to view as a user
      scope "/", Bonfire.UI.Social.Graph do
        pipe_through(:browser)
        pipe_through(:user_required)

        live("/settings/import_history", ImportHistoryLive, as: :import_history)
      end

      # pages you need an account to view
      scope "/", Bonfire.UI.Social.Graph do
        pipe_through(:browser)
        pipe_through(:account_required)
      end
    end
  end
end
