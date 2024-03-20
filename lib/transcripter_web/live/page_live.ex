defmodule TranscripterWeb.PageLive do
  use TranscripterWeb, :live_view


  def mount(_params, _session, socket) do
   socket = socket
   |> assign(transcription: nil)|> assign(:uploaded_file, []) |> allow_upload(:audio, accept: ["audio/mpeg", "audio/wav"], max_entries: 1,auto_upload: true)
   {:ok, assign(socket, form: to_form(%{}))}
  end

  def render(assigns) do
    ~H"""
     <div>
     <.simple_form for = {@form} phx-submit = "convert_to_text">
     <.live_file_input upload={@uploads.audio} />
     <.button type = "submit">convert_to_text</.button>
     </.simple_form>
     </div>

     <p><%= @transcription %></p>
   """
  end

  def handle_event_2("convert_to_text", _params, socket) do
    audio_upload = Map.get(socket.assigns.uploads, :audio)
    if audio_upload do
      Task.start(fn -> speech_to_text(:audio, self()) end)

      {:noreply, socket}
    end
  end

  def handle_event("convert_to_text", _params, socket) do
    # Directly update the transcription for testing
    {:noreply, assign(socket, :transcription, "This is a test transcription.")}
  end

  defp speech_to_text(upload, live_view_pid) do
    result = "This is a sample transcription."
    send(live_view_pid, {:transcription_completed, result})
  end


  defp process_audio(uploaded_audio, socket) do
    IO.inspect(uploaded_audio, label: "Received audio file , okay bye")

    {socket}
  end

  def handle_info({:transcription_completed, transcription_text}, socket) do
    {:noreply, assign(socket, :transcription, transcription_text)}
  end



end
