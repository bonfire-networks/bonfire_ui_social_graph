defmodule Bonfire.UI.Social.Graph.EditAliasesLive do
  use Bonfire.UI.Common.Web, :stateless_component
  # import Bonfire.Common.Media

  prop selected_tab, :any

  def render(assigns) do
    current_user = current_user(assigns[:__context__])
    # debug(assigns)
    # should be loading this only once per persistent session, or when we open the composer
    assigns
    |> assign(
      :aliases,
      if(current_user,
        do:
          Bonfire.Social.Graph.Aliases.list_my_aliases(current_user)
          |> debug("list_my_aliases")
          |> e(:edges, []),
        else: []
      )
    )
    |> render_sface()
  end
end
