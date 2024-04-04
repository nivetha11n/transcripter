defmodule TranscripterWeb.PagetwoLive do
  use TranscripterWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:recording_status, nil)
      |> assign(:transcription_result, "test")
      |> assign(:error, nil)

    {:ok, socket}
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do

    ~H"""
    <div>
      <.button phx-click="start_recording">Start Recording</.button>
      <.button phx-click="stop_recording">Stop Recording</.button>

    </div>

    <p><%= @recording_status %></p>
    <p><%= @transcription_result %></p>
    """
  end

  def handle_event("start_recording", _params, socket) do

    streaming_task = Task.async(fn ->
      TranscripterWeb.StreamingTranscribe.stream_audio_and_transcribe(self())
    end)


    socket = assign(socket, :streaming_task, streaming_task)
    socket = assign(socket, :recording_status, "Recording...")

    {:noreply, socket}
  end

  def handle_event("stop_recording", _params, socket) do

    streaming_task = socket.assigns[:streaming_task]
    if streaming_task do
      Task.shutdown(streaming_task, :brutal_kill)
    end

    socket = assign(socket, :streaming_task, nil)
    socket = assign(socket, :recording_status, "Stopped Recording")

    {:noreply, socket}
  end

  def handle_info({:transcription_result, transcription}, socket) do

    new_transcription = socket.assigns.transcription_result <> " " <> transcription
    {:noreply, assign(socket, :transcription_result, new_transcription)}
  end

  def handle_info(msg, socket) do
    IO.inspect(msg, label: "Unhandled message in PagetwoLive")
    {:noreply, socket}
  end


end
