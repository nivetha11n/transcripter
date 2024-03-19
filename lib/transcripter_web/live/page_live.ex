defmodule TranscripterWeb.PageLive do
  use TranscripterWeb, :live_view


  def mount(_params, _session, socket) do
   socket = socket |> assign(:uploaded_file, []) |> allow_upload(:audio, accept: ["audio/mpeg", "audio/wav"], max_entries: 1)
   {:ok, assign(socket, form: to_form(%{}))}
  end

  def render(assigns) do
    ~H"""
     <.simple_form for = {@form} phx-submit = "convert_to_text">
     <.live_file_input upload={@uploads.audio} />
     <.button type = "submit">convert_to_text</.button>
     </.simple_form>
    """
  end

  def handle_event("convert_to_text", _params, socket) do
    audio_upload = Map.get(socket.assigns.uploads, :audio)
    if audio_upload do
      Task.start(fn -> process_audio(audio_upload) end)
    end
    {:noreply, socket}
  end

  defp process_audio(uploaded_audio) do
    IO.inspect(uploaded_audio, label: "Received audio file , okay bye")
  end

end
