defmodule TranscripterWeb.StreamingTranscribe do
  @ffmpeg_path "//opt//homebrew//bin//ffmpeg"
  @sample_rate 16000
  @channels 1
  require Nx

  def stream_audio_and_transcribe(live_view_pid) do
    {:ok, whisper} = Bumblebee.load_model({:hf, "openai/whisper-tiny"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "openai/whisper-tiny"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "openai/whisper-tiny"})
    {:ok, generation_config} = Bumblebee.load_generation_config({:hf, "openai/whisper-tiny"})

    serving =
      Bumblebee.Audio.speech_to_text_whisper(whisper, featurizer, tokenizer, generation_config,
        defn_options: [compiler: EXLA]
      )

   command = [
      "-f", "avfoundation",
      "-i", ":1",
     # "-t", "10",
      "-ar", Integer.to_string(@sample_rate),
      "-ac", Integer.to_string(@channels),
      "-f", "wav",
      "-"
    ]

    port = Port.open({:spawn_executable, @ffmpeg_path}, [
      :binary,
      {:args, command},
      :exit_status,
      :stderr_to_stdout
    ])

    stream_port_data_and_transcribe(port, serving, live_view_pid)
  end

  defp stream_port_data_and_transcribe(port, serving, live_view_pid) do
    receive do
      {^port, {:data, data}} ->
        if is_ffmpeg_version_info?(data) do
          stream_port_data_and_transcribe(port, serving, live_view_pid)
        else
          audio_tensor = preprocess_audio_data(data)
          transcription_result = Nx.Serving.run(serving, audio_tensor)

          # Log the transcription result for debugging
          IO.inspect(transcription_result, label: "Transcription Result")

          case transcription_result do
            {:ok, %{chunks: []}} ->
              # This matches when there's an :ok tuple and the chunks list is empty
              IO.puts("No transcription available for this segment.")
              send(live_view_pid, {:transcription_result, "No transcription available"})
            {:ok, %{chunks: _chunks}} ->
              # This matches when there's an :ok tuple with any chunks data (including empty lists)
              # The assumption here is that _chunks is always a list (can be empty or have items)
              if Enum.empty?(_chunks) do
                IO.puts("No transcription available for this segment.")
                send(live_view_pid, {:transcription_result, "No transcription available"})
              else
                IO.puts("Transcription successful.")
                # If _chunks is not empty, we send each transcription result back
                Enum.each(_chunks, fn %{text: text} ->
                  send(live_view_pid, {:transcription_result, text})
                end)
              end
            {:error, _error} ->
              # This matches when an :error tuple is returned
              send(live_view_pid, {:transcription_error, "An error occurred during transcription."})
          end

          stream_port_data_and_transcribe(port, serving, live_view_pid)
        end

      {^port, {:exit_status, _status}} ->
        IO.puts("FFmpeg process exited.")
        send(live_view_pid, {:transcription_complete, "Transcription ended"})

      {:stop, _reason} ->
        IO.puts("Stopping audio stream and transcription.")
        Port.close(port)
    end
  end

  defp preprocess_audio_data(binary_data) do

    samples = decode_audio_binary(binary_data)

    Nx.tensor(samples, type: {:s, 16})
  end

  defp decode_audio_binary(binary) do
    decode_audio_binary(binary, [])
  end

  defp decode_audio_binary(<<>>, samples) do
    Enum.reverse(samples)
  end

  defp decode_audio_binary(<<value::little-signed-16, rest::binary>>, samples) do
    decode_audio_binary(rest, [value | samples])
  end


  defp decode_audio_binary(_leftover_bytes, samples) do
    Enum.reverse(samples)
  end

  defp is_ffmpeg_version_info?(data) do
    String.contains?(data, "ffmpeg version")
  end
end
