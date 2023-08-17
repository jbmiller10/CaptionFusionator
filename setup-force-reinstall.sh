#!/bin/bash

# Define base directory
base_directory="$(dirname "$(readlink -f "$0")")"

# Create separate environments for each script
python3 -m venv "$base_directory/blip2/venv_blip2"
python3 -m venv "$base_directory/open_flamingo/venv_open_flamingo"
python3 -m venv "$base_directory/wd14/venv_wd14"
python3 -m venv "$base_directory/summarize/venv_summarize"

printf '\n\n*****************************************************************\n'
printf 'installing blip2 reqs'
printf '\n*****************************************************************\n\n'
# Install requirements for each script
source "$base_directory/blip2/venv_blip2/bin/activate"
cd "$base_directory/blip2"
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt --force-reinstall
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 --force-reinstall
pip install typing_extensions==4.7.1 --force-reinstall
fi
deactivate
printf '\n\n*****************************************************************\n'
printf 'installing flamingo reqs'
printf '\n*****************************************************************\n\n'
source "$base_directory/open_flamingo/venv_open_flamingo/bin/activate"
cd "$base_directory/open_flamingo"
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt --force-reinstall
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 --force-reinstall
fi
deactivate

printf '\n\n*****************************************************************\n'
printf 'installing wd14 reqs'
printf '\n*****************************************************************\n\n'
source "$base_directory/wd14/venv_wd14/bin/activate"
cd "$base_directory/wd14"
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt --force-reinstall
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 --force-reinstall
fi
deactivate
printf '\n\n*****************************************************************\n'
printf 'installing summarize reqs'
printf '\n*****************************************************************\n\n'
source "$base_directory/summarize/venv_summarize/bin/activate"
cd "$base_directory/summarize"
export CMAKE_ARGS="-DLLAMA_CUBLAS=on"
export FORCE_CMAKE=1
pip install llama-cpp-python --force-reinstall --upgrade --no-cache-dir --verbose
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt --force-reinstall
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 --force-reinstall
    
fi
deactivate

cd "$base_directory"
exit 0
