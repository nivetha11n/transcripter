defmodule TranscripterWeb.RecordTest do

  @ffmpeg_path "ffmpeg"
  @duration_seconds 10
  @sample_rate 16000
  @channels 1
  @output_format "mp3"


  def record_audio_segment(output_path) do

    directory = Path.dirname(output_path)
    File.mkdir_p!(directory)
    args = [
      "-f", "avfoundation",         # Input device for macOS, change if needed for other systems
      "-i", ":1",                   # Select the default microphone
      "-t", Integer.to_string(@duration_seconds), # Recording duration in seconds
      "-ar", Integer.to_string(@sample_rate),     # Audio sample rate
      "-ac", Integer.to_string(@channels),        # Number of audio channels
      output_path                    # Path to the output file
    ]

    # Execute the FFmpeg command
    {output, exit_status} =
      System.cmd(@ffmpeg_path, args, stderr_to_stdout: true)

    # Handle the output of the command based on the exit status
    case exit_status do
      0 -> {:ok, output}
      _ -> {:error, output}
    end
  end
end

#output_path = "//Users//nivethanagarajan//output23.mp3" # Replace with the actual output path

#case TranscripterWeb.RecordTest.record_audio_segment(output_path) do
 # {:ok, _output} ->
  #  IO.puts("Recording complete: #{output_path}")
  #{:error, err_output} ->
   # IO.puts("Error during recording: #{err_output}")
#end
