defmodule TranscripterWeb.PagestreamLive do
  use TranscripterWeb, :live_view

  @ffmpeg_command "ffmpeg"
  @folder_path "/Users/nivethanagarajan/audiostream"
  @args [
    "-f", "avfoundation",
    "-i", ":1",
    "-ar", "16000",
    "-acodec", "libmp3lame",
    "-f", "segment",
    "-segment_time", "10",
    "-segment_list", "#{@folder_path}/playlist.m3u8",
    "#{@folder_path}/output_%03d.mp3"
  ]

  def mount(_params, _session, socket) do
    # Ensure the directory exists
    File.mkdir_p(@folder_path)

    # Initialize transcription_results as an empty list
    {:ok, assign(socket, recording_status: "Not started", ffmpeg_pid: nil, transcription_results: [])}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.button phx-click="start_recording">Start Recording</.button>
      <.button phx-click="stop_recording">Stop Recording</.button>
    </div>
    <p><%= @recording_status %></p>
    <p><%= inspect @ffmpeg_pid %></p>

    <div id="transcriptions">
      <%= for transcription <- @transcription_results do %>
        <p><%= transcription %></p>
      <% end %>
    </div>

    """
  end


  def handle_event("start_recording", _params, socket) do
    task = Task.async(fn ->
      Rambo.run(@ffmpeg_command, @args, log: true)
    end)
    {:noreply, assign(socket, recording_status: "Recording...", ffmpeg_pid: task.pid, task: task)}
  end


 def handle_event("stop_recording", _params, socket) do
  pid = socket.assigns.ffmpeg_pid
  task = socket.assigns.task
  Rambo.kill(pid)
  Task.await(task, 20000)
  #{:killed, %Rambo{status: nil}}
  {:noreply, assign(socket, recording_status: "stopped", ffmpeg_pid: nil, transcription_results: [])}
 end


defp read_latest_segment(playlist_path) do
  with {:ok, content} <- File.read(playlist_path),
       [latest_segment | _] <- Enum.reverse(String.split(content, "\n")),
       true <- String.ends_with?(latest_segment, ".mp3") do
    latest_segment
  else
    _ -> nil
  end
end


 def handle_info({:file_event, _, :modified, playlist_path}, socket) do
  if Path.basename(playlist_path) == "playlist.m3u8" do
    latest_segment = read_latest_segment(playlist_path)
    if latest_segment do
      # Start an asynchronous task for the transcription
      transcription_task = Task.async(fn -> speech_to_text(latest_segment) end)

      # Monitor the transcription task to receive a message when it's done
      ref = Process.monitor(transcription_task.pid)

      # Store the reference in the socket assigns to use it later
      socket = assign(socket, :transcription_task_ref, ref)
    end
  end

  {:noreply, socket}
end



 defp speech_to_text(path) do
  {:ok, whisper} = Bumblebee.load_model({:hf, "openai/whisper-tiny"})
  {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "openai/whisper-tiny"})
  {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "openai/whisper-tiny"})
  {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "openai/whisper-tiny"})

  serving =
  Bumblebee.Audio.speech_to_text_whisper(whisper, featurizer, tokenizer, generation_config,
  defn_options: [compiler: EXLA]
  )
  result = Nx.Serving.run(serving, {:file, path})

  texts = Enum.map(result.chunks, fn chunk -> chunk.text end)
  Enum.join(texts, " ")
end


end
