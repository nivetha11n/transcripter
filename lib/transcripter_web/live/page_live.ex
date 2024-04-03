defmodule TranscripterWeb.PageLive do
  use TranscripterWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
    socket
    |> assign(:recording_status,nil)
    |> assign(:last_recorded_file,nil)
    |> assign(:transcription_result, nil)

    #|> allow_upload(:audio, accept: ["audio/mpeg", "audio/wav","audio/mp4"], max_entries: 1, auto_upload: true)

   {:ok, assign(socket, form: to_form(%{}))}
  end

  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
     <div>
      <.button phx-click="start_recording">Start Recording</.button>
      <.button phx-click="stop_recording">Stop Recording</.button>
     </div>

     <p><%= @last_recorded_file %></p>
      <p><%= @transcription_result %></p>
   """
  end


    def handle_event("start_recording", _params, socket) do
      unique_filename = "output_" <> UUID.uuid4() <> ".mp3"
      output_path = "//Users//nivethanagarajan//" <> unique_filename

      Task.async(fn ->
        TranscripterWeb.RecordTest.record_audio_segment(output_path)
      end)

      Process.sleep(10_000)
      transcription_result = speech_to_text(output_path)

      {:noreply, assign(socket, recording_status: "Recording", last_recorded_file: unique_filename, transcription_result: transcription_result)}
    end

  def handle_event("stop_recording", _params, socket) do
    # Add logic to stop recording here. This might include uploading the recorded file for transcription.
    {:noreply, assign(socket, recording_status: "Not Recording")}
  end


  def speech_to_text(path) do
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
