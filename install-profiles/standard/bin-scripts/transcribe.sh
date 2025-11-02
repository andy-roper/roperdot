#
# Description: Transcribes a video file using WhisperX
#
# Author: Andy Roper <andyroper42@gmail.com>
# URL: https://github.com/andy-roper/roperdot
#
if [[ $# -eq 0 || "$1" == "-?" || "$1" == "-h" || "$1" == "--help" ]]; then
	cat <<EOT
transcribe: Transcribes a video file using WhisperX
Usage: transcribe <video>

The transcribed output will be written to files in the same directory as the video,
with various formats (.srt, .vtt, .txt, .json, .tsv).

If you don't have WhisperX installed:
pip install whisperx

On WSL in Windows, if you want CUDA acceleration with an NVIDIA GPU:
pip install torch==2.8.0 torchaudio==2.8.0 torchvision==0.23.0

For WSL, you should increase the available RAM if needed. Create
C:\Users\<username>\.wslconfig with (for instance):
   [wsl2]
   memory=32GB
   processors=8
   swap=8GB

Then restart WSL: wsl --shutdown
EOT
#'
	exit 0
fi

# Note:
# If diarization is used, you'll also need to accept the pyannote terms:
# https://huggingface.co/pyannote/speaker-diarization-3.1 and at
# https://huggingface.co/pyannote/segmentation-3.0.

if [[ "$ROPERDOT_DESKTOP_ENV" == "windows" ]]; then
	# Add cuDNN library path to LD_LIBRARY_PATH if it's present
	PIP_PYTHON_VERSION=$(pip --version | grep -oP 'python \K\d+\.\d+')
	if [[ -n "$PIP_PYTHON_VERSION" && -d "$HOME/.local/lib/python${PIP_PYTHON_VERSION}/site-packages/nvidia/cudnn/lib" ]]; then
	    export LD_LIBRARY_PATH=$HOME/.local/lib/python${PIP_PYTHON_VERSION}/site-packages/nvidia/cudnn/lib:${LD_LIBRARY_PATH:-}
	fi
fi

if [[ -f "$1" ]]; then
#	whisperx "$1" --model medium --diarize --hf_token "$HF_TOKEN" --language English --min_speakers 8 --max_speakers 10
	whisperx "$1" --model medium --language English
else
	echo "Video file not found"
	exit 1
fi