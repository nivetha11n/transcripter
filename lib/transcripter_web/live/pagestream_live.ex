defmodule TranscripterWeb.PagestreamLive do
  use TranscripterWeb, :live_view
  require Logger

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

    File.mkdir_p(@folder_path)

    {:ok, watcher_pid} = FileSystem.start_link(dirs: ["/Users/nivethanagarajan/audiostream"])
     FileSystem.subscribe(watcher_pid)


     # Initialize the socket's assigns
     socket =
       assign(socket, :recording_status, "Not started")
       |> assign(:ffmpeg_pid, nil)
       |> assign(:task, nil)
       |> assign(:transcription_result, [])
       |> assign(:playlist_watcher_pid, watcher_pid)

     {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.button phx-click="start">Start Recording</.button>
      <.button phx-click="stop">Stop Recording</.button>
    </div>
    <p><%= @recording_status %></p>
     <p><%= Enum.join(Enum.reverse(@transcription_result), " ") %></p>
    """
  end

  #<%= for transcription <- @transcription_results do %> <% end %>


  def handle_event("start", _params, socket) do
    task = Task.async(fn ->
      Rambo.run(@ffmpeg_command, @args, log: true)
    end)
    {:noreply, assign(socket, recording_status: "Recording...", ffmpeg_pid: task.pid, task: task)}
  end


 def handle_event("stop", _params, socket) do
  pid = socket.assigns.ffmpeg_pid
  task = socket.assigns.task

  Rambo.kill(pid)
  Task.await(task, 20000)

  {:noreply, assign(socket, recording_status: "Stopped Recording , click on Start Recording to start again", ffmpeg_pid: nil, transcription_results: [])}
 end

 def handle_info({:file_event, _pid, {path, events}}, socket) do
  live_view_pid = self()
  IO.inspect("file modification")
  IO.inspect({path, events}, label: "File Event")

  if Path.basename(path) == "playlist.m3u8" do
    latest_segment = read_latest_segment(path)
    if latest_segment do
      full_path_to_file = Path.join(@folder_path, latest_segment)

      # Start an asynchronous task to perform transcription
      Task.start(fn ->
        transcription_result = speech_to_text(full_path_to_file)
        send(live_view_pid, {:transcription_result, [transcription_result | socket.assigns.transcription_result]})
      end)
    end
  end

  {:noreply, socket}
end

def handle_info({:transcription_result, transcription_result}, socket) do
  Logger.info("Received transcription result: #{transcription_result}")
  {:noreply, assign(socket, :transcription_result, transcription_result)}
end



defp read_latest_segment(playlist_path) do
  IO.inspect("read segment")
  with {:ok, content} <- File.read(playlist_path),
       lines <- String.split(content, "\n"),
       segments <- Enum.filter(lines, &String.ends_with?(&1, ".mp3")),
       latest_segment <- List.last(segments) do
    IO.inspect(latest_segment)
    latest_segment
  else
    _ -> nil
  end
end



 defp speech_to_text(path) do
  IO.inspect("bumblebee")
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
