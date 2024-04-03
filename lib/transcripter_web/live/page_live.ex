defmodule TranscripterWeb.PageLive do
  use TranscripterWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
    socket
    |> assign(:transcription, nil)
    |> assign(:uploaded_files, [])
    |> assign(:form, to_form(%{}))
    |> allow_upload(:audio, accept: ["audio/*"], max_entries: 1, auto_upload: true)

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
     <div>
     <.simple_form for = {@form}
     id="tempfolder"
     phx-submit = "convert_to_text"
     phx-change="validate">
     <.live_file_input upload={@uploads.audio} />
     <.button type = "submit">convert to text</.button>
     </.simple_form>
     </div>

     <p><%= @transcription %></p>
   """
  end

  def handle_event("start_recording", _params, socket) do
    Task.async(fn ->
      TranscripterWeb.RecordTest.record_audio_segment("//Users//nivethanagarajan//output2314.mp3")
    end)
    {:noreply, assign(socket, recording_status: "Recording")}
  end

  def handle_event("stop_recording", _params, socket) do
    # Add logic to stop recording here. This might include uploading the recorded file for transcription.
    {:noreply, assign(socket, recording_status: "Not Recording")}
  end

  def handle_event("convert_to_text", _params, socket) do

    uploaded_files =
    consume_uploaded_entries(socket, :audio, fn %{path: path}, _entry ->
      dest = Path.join(Application.app_dir(:transcripter, "priv/static/uploads"), Path.basename(path))

      File.cp!(path, dest)
      speech_to_text_result = speech_to_text(path)
      {:ok, speech_to_text_result}

    end)
   {:noreply, assign(socket, :transcription, Enum.join(uploaded_files, ", "))}
  end


  def handle_event("validate", _params, socket) do
    {:noreply, socket}
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
