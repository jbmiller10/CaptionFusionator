# CaptionFusionator

This project is intended to provide a modular framework for using multiple image-to-text models and then synthesizing them together into a single caption using a downstream LLM. As it stands, default values assume the user has a Nvidia GPU with at least 24GB of VRAM.

This project is in active development, and generally should be considered in a pre-release state.

## Components

The system includes the following components:

#### 1. caption_blip2.py
This script generates captions for a collection of images using **BLIP2**. By default, the captions are saved in separate files in the image input directory with a '.b2cap' extension.


#### 2. caption_flamingo.py
This script uses  **Open Flamingo** to generate captions. By default, the captions are saved in separate files in the image input directory with a '.flamcap' extension.

#### 3. caption_wd14.py
This script generates tags for images using pre-trained wd14 models. By default, captions are saved in the image input directory with a '.wd14cap' extension 

#### 4. summarize_with_llama.py
This script attempts to combine captions/tags using a llama derived model

#### 5. summarize_with_gpt.py
This script attempts to combine captions/tags using one of OpenAI's GPT models

#### 6. setup.sh
This script creates a venv and installs the requirements for each module

#### 7. run.sh (control script)
This script serves as a control center, enabling the user to choose which tasks to perform by providing different command-line options. 

## Command Line Options

This project provides a wide range of options for you to customize its behavior. All options are passed to the run.sh control script:

#### Basic Options

- `--use_config_file`: absolute path to a config file containing arguments to be used. If using both a config file & CLI arguments this must be the first argument passed. see example_config_file.txt
- `--use_blip2`: Generate BLIP2 captions of images in your input directory.
- `--use_open_flamingo`: Generate Open Flamingo captions of images in your input directory.
- `--use_wd14`: Generate WD14 tags for images in your input directory.
- `--summarize_with_gpt`: Use OpenAI's GPT to attempt to combine your caption files into one. (Requires that summarize_openai_api_key argument be passed with a valid OpenAI API key OR the environment variable OPENAI_API_KEY be set. If this is set, do not use --summarize_with_llama **WARNING: this can get expensive, especially if using GPT-4.**)
- `--summarize_with_llama`: Use a llama derived local model for combining/summarizing your caption files. If this is set, do not use --summarize_with_gpt       
- `--input_directory`: Absolute path to the input directory containing the image files you wish to caption.
- `--output_directory`: Output directory for saving caption files. If not set, defaults to value passed to `--input_directory`.

#### WD14 Model Options

- `--wd14_stack_models`: If set, runs three wd14 models ('SmilingWolf/wd-v1-4-convnext-tagger-v2', 'SmilingWolf/wd-v1-4-vit-tagger-v2', 'SmilingWolf/wd-v1-4-swinv2-tagger-v2') and takes the mean of their values.
- `--wd14_model`: If not stacking, which wd14 model to run. Default: 'SmilingWolf/wd-v1-4-swinv2-tagger-v2'
- `--wd14_threshold`: Min confidence threshold for wd14 captions. If wd14_stack_models is passed, the threshold is applied before stacking. Default: 0.5
- `--wd14_filter`: Tags to filter out when running wd14 tagger.
- `--wd14_output_extension`: File extension that wd14 captions will be saved with. Default: 'wd14cap'

#### BLIP2 Model Options

- `--blip2_model`: BLIP2 model to use for generating captions. Default: 'blip2_opt/caption_coco_opt6.7b'
- `--blip2_use_nucleus_sampling`: Whether to use nucleus sampling when generating blip2 captions. Default: False
- `--blip2_beams`: Number of beams to use for blip2 captioning. More beams may be more accurate, but are slower and use more VRAM. Default: 6
- `--blip2_max_tokens`: max_tokens value to be passed to blip2 model. Default: 75
- `--blip2_min_tokens`: min_tokens value to be passed to blip2 model. Default: 20
- `--blip2_top_p`: top_p value to be passed to blip2 model. Default: 1.0
- `--blip2_output_extension`: File extension that blip2 captions will be saved with. Default: 'b2cap'

#### Open Flamingo Model Options

- `--flamingo_example_img_dir`: Path to Open Flamingo example image/caption pairs.
- `--flamingo_model`: Open Flamingo model to be used for captioning. Default: 'openflamingo/OpenFlamingo-9B-vitl-mpt7b'
- `--flamingo_min_new_tokens`: min_tokens value to be passed to Open Flamingo model. Default: 20
- `--flamingo_max_new_tokens`: max_tokens value to be passed to Open Flamingo model. Default: 48
- `--flamingo_num_beams`: num_beams value to be passed to Open Flamingo model. Default: 6
- `--flamingo_prompt`: prompt value to be passed to Open Flamingo model. Default: 'Output:'
- `--flamingo_temperature`: value to be passed to Open Flamingo model. Default: 1.0
- `--flamingo_top_k`: top_k value to be passed to Open Flamingo model. Default: 0
- `--flamingo_top_p`: top_p value to be passed to Open Flamingo model. Default: 1.0
- `--flamingo_repetition_penalty`: Repetition penalty value to be passed to Open Flamingo model. Default: 1.0
- `--flamingo_length_penalty`: Length penalty value to be passed to Open Flamingo model. Default: 1.0
- `--flamingo_output_extension`: File extension that Open Flamingo captions will be saved with. Default: 'flamcap'

#### Summarization Options

- `--summarize_gpt_model`: OpenAI model to use for summarization. Default: 'gpt-3.5-turbo'
- `--summarize_gpt_max_tokens`: Max tokens for GPT. Default: 75
- `--summarize_gpt_temperature`: Temperature to be set for GPT. Default: 1.0
- `--summarize_gpt_prompt_file_path`: File path to a TXT file containing the system prompt to be passed to GPT for summarizing your captions.
- `--summarize_file_extensions`: The file extensions/captions you want to be passed to your summarize model. Defaults to values of Flamingo, BLIP2, and WD14 output extensions, e.g., ['wd14cap','flamcap','b2cap'].
- `--summarize_openai_api_key`: Value of a valid OpenAI API key. Not needed if the OPENAI_API_KEY env variable is set.
- `--summarize_llama_model_repo_id`: Huggingface Repository ID of the Llama model to use for summarization. Must be set in conjunction with `--summarize_llama_model_filename`. Default: TheBloke/StableBeluga2-70B-GGML
- `--summarize_llama_model_filename`: Filename of the specific model to be used for Llama summarization. Must be set in conjunction with `--summarize_llama_model_repo_id`. Default: stablebeluga2-70b.ggmlv3.q2_K.bin
- `--summarize_llama_prompt_filepath`: Path to a prompt file that provides the system prompt for llama summarization
- `--summarize_llama_n_threads`: number of cpu threads to run llama model on Default: 4
- `--summarize_llama_n_batch`: batch size to load llama model with Default:512
- `--summarize_llama_n_gpu_layers`: number of layers to offload to GPU Default: 55
- `--summarize_llama_n_gqa`: I honestly don't know, but it needs to be set to to 8 for 70B models Default: 8
- `--summarize_llama_max_tokens`: Maximum number of ouput tokens to use for Llama summarization. Default: 75
- `--summarize_llama_temperature`: Temperature value for controlling the randomness of Llama summarization. Default: 1.0
- `--summarize_llama_top_p`: top_p value to run llama model with Default: 1.0
- `--summarize_llama_frequency_penalty`: frequency penalty value to run llama model with Default: 0
- `--summarize_llama_top_presence_penalty`: presence penalty value to run llama model with Default: 0
  
## Installation

```bash
git clone https://github.com/jbmiller10/CaptionFusionator.git
```
```bash
cd CaptionFusionator
```

Linux
```bash
chmod +x setup.sh
chmod +x run.sh
./setup.sh
```

Window
```bash
setup.bat
```

## Example Usage

You can run this project by executing the `run.sh` script with your desired options. Here's an example command that utilizes multiple models and summarizes with a llama derived model:

Linux
```bash
./run.sh --input_directory /path/to/your/image/dir --use_blip2 --use_open_flamingo --use_wd14 --wd14_stack_models --summarize_with_llama
```

You can run this project by executing the run.ps1 script with your desired options. Here's an example command that utilizes multiple models and summarizes with a llama derived model:
Window
```bash
./run.ps1 --input_directory /path/to/your/image/dir --use_blip2 --use_open_flamingo --use_wd14 --wd14_stack_models --summarize_with_llama
```
Or
```bash
./run.ps1 --use_config_file ./config_file.txt
```

## TO-DO
(in no particular order)

- [ ] Create .bat counterparts to setup.sh & run.sh for Windows
- [ ] Set better defaults to current modules
- [ ] set default models based on user-defined VRAM value
- [ ] Add MiniGPT4-Batch module
- [ ] Add GIT (i.e. generative image to text) Module
- [ ] Add Deepface Module
- [ ] Add Described Module

---
