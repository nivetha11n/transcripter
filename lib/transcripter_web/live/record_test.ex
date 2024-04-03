defmodule TranscripterWeb.RecordTest do
  # Define the path to the FFmpeg binary.
  # Ensure ffmpeg is installed on your system and is in your system's PATH,
  # or provide the full path to the ffmpeg binary here.
  @ffmpeg_path "ffmpeg"
  # Define the default duration for recording, sample rate, and audio channels
  @duration_seconds 10  # Change this to the desired duration
  @sample_rate 16000    # Set the desired sample rate
  @channels 1           # Mono (1) or Stereo (2)
  @output_format "mp3"  # The desired output format

  # Public function to start recording an audio segment
  def record_audio_segment(output_path) do

    directory = Path.dirname(output_path)
    # Ensure the directory for the output file exists or create it
    File.mkdir_p!(directory)

    # Construct the FFmpeg command to record audio from the default input device
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

output_path = "//Users//nivethanagarajan//output23.mp3" # Replace with the actual output path

case TranscripterWeb.RecordTest.record_audio_segment(output_path) do
  {:ok, _output} ->
    IO.puts("Recording complete: #{output_path}")
  {:error, err_output} ->
    IO.puts("Error during recording: #{err_output}")
end
