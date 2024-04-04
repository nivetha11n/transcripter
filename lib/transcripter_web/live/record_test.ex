defmodule TranscripterWeb.RecordTest do

  @ffmpeg_path "ffmpeg"
  @duration_seconds 15
  @sample_rate 16000
  @channels 1


  def record_audio_segment(output_path) do

    directory = Path.dirname(output_path)
    File.mkdir_p!(directory)
    args = [
      "-f", "avfoundation",
      "-i", ":1",
      "-t", Integer.to_string(@duration_seconds),
      "-ar", Integer.to_string(@sample_rate),
      "-ac", Integer.to_string(@channels),
      output_path
    ]


    {output, exit_status} =
      System.cmd(@ffmpeg_path, args, stderr_to_stdout: true)


    case exit_status do
      0 -> {:ok, output}
      _ -> {:error, output}
    end
  end
end
