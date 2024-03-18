defmodule TranscripterWeb.PageLive do
  use TranscripterWeb, :live_view


  def mount(_params, _session, socket) do
   {:ok, assign(socket, number: 7)}
  end

  def render(assigns) do
    ~H"""
    <%= assigns.number %>
    <.button phx-click = "add">Add</.button>
    """
  end

  def handle_event("add", _params, socket) do
    current_number = socket.assigns.number
    new_number = current_number + 1

    {:noreply, assign(socket, :number, new_number)}
  end


end
