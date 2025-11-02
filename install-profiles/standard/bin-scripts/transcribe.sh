#
# Description: Transcribes a video file using whisperX
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "-?" || "$1" == "-h" || "$1" == "--help" ]]; then
	cat <<EOT
transcribe: Transcribes a video file using whisperX
Usage: transcribe <video>

The transcribed output will be written to files in the same directory as the video,
with various formats (.srt, .vtt, .txt, .json).

You'll also need to accept the pyannote terms at
https://huggingface.co/pyannote/speaker-diarization-3.1 and at
https://huggingface.co/pyannote/segmentation-3.0.
EOT
#'
	exit 0
fi

if [[ -f "$1" ]]; then
#	whisperx "$1" --model medium --diarize --hf_token "$HF_TOKEN" --language English --min_speakers 8 --max_speakers 10
	whisperx "$1" --model medium --language English
else
	echo "Video file not found"
	exit 1
fi