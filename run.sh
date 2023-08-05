#!/bin/bash

# Define base directory
base_directory="$(dirname "$(readlink -f "$0")")"

# Set default values for arguments
wd14_output_extension="wd14cap"
blip2_output_extension="b2cap"
flamingo_output_extension="flamcap"
summarize_file_extensions="${wd14_output_extension}" "${flamingo_output_extension}" "${blip2_output_extension}"
# A variable to store user arguments
user_args=""
config_file=""

for arg in "$@"
do
    if [[ $arg == *"--use_config_file"* ]]; then
        # config_file="${arg#*=}"
        config_file="$2"
        break
    fi
done

# If --use_config_file is set, read the config file
if [ -n "$config_file" ]; then
    echo "Loading options from config file $config_file"
    while IFS= read -r line
    do
        # Checks if line is flagged as a comment
        if [[ $line != \#* ]]; then
            # Parses the line
            varname="${line%=*}"
            varvalue="${line#*=}"
            # Sets the correct variable
            declare $varname="$varvalue"
        fi
    done < "$config_file"
fi


# Parsing command line arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
    --use_config_file) 
        config_file="$2";  
        shift ;;
    --help)
#basic options
        echo "Usage: run.sh [OPTIONS]"
        echo "Options:"
        echo "--use_config_file: absolute path to a config file containing arguments to be used. see example_config_file.txt"
        echo "--use_blip2: create blip2 captions of images in your input directory"
        echo "--use_open_flamingo: create open flamingo captions of images in your input directory"
        echo "--use_wd14: create wd14 tags for images in your input directory"
        echo "--summarize_with_gpt: use OpenAI's GPT to attempt to combine your caption files into one. Requires that summarize_openai_api_key argument be passed with a valid OpenAI API key OR the environment variable OPENAI_API_KEY be set with that value. *********WARNING: this can get expensive, especially if using GPT-4. You've been warned********"
        echo "--summarize_with_llama: use a llama derived local model for combining/summarizing your caption files"        
        echo "--input_directory: absolute path to the directory containing the image files you wish to caption"
        echo "--output_directory: output directory for saving caption files. If not set, defaults to value passed to --input_directory"
#wd14 options help
        echo "--wd14_stack_models: runs three wd14 models and takes the mean of their values Default: ['SmilingWolf/wd-v1-4-convnext-tagger-v2', 'SmilingWolf/wd-v1-4-vit-tagger-v2', 'SmilingWolf/wd-v1-4-swinv2-tagger-v2'] "
        echo "--wd14_model: if not stacking, which wd14 model to run Default: SmilingWolf/wd-v1-4-swinv2-tagger-v2"
        echo "--wd14_threshold: min confidence threshold for wd14 captions. If wd14_stack_models is passed, the threshold is applied before stacking. Default: .45  "
        echo "--wd14_filter: tags to filter out when running wd14 tagger"
        echo "--wd14_output_extension: file extension that wd14 captions will be saved with Default: wd14cap"
#blip2 options help
        echo "--blip2_model: blip2 model to use for generating captions Default: blip2_opt/caption_coco_opt6.7b"
        echo "--blip2_use_nucleus_sampling: whether to use nucleus sampling when generating blip2 captions Default: False"
        echo "--blip2_beams: number of beams to use for blip2 captioning. More beams may be more accurate, but is slower and uses more vram"
        echo "--blip2_max_tokens: max_tokens value to be passed to blip2 model Default: 75"
        echo "--blip2_min_tokens: min_tokens value to be passed to blip2 model Default: 20"
        echo "--blip2_top_p: top_p value to be passed to blip2 model Default: 1"
        echo "--blip2_output_extension: file extension that blip2 captions will be saved with Default: b2cap"
#open flamingo options help
        echo "--flamingo_example_img_dir: path to open flamingo example image/caption pairs"
        echo "--flamingo_model: open_flamingo model to be used for captioning. Default: openflamingo/OpenFlamingo-9B-vitl-mpt7b"
        echo "--flamingo_min_new_tokens: min_tokens value to be passed to open flamingo model Default: 20"
        echo "--flamingo_max_new_tokens: max_tokens value to be passed to open flamingo model Default:48 "
        echo "--flamingo_num_beams: num_beams value to be passed to open flamingo model Default: 6"
        echo "--flamingo_prompt: prompt value to be passed to open flamingo model Default: 'Output:'"
        echo "--flamingo_temperature: value to be passed to open flamingo model Default: 1.0"
        echo "--flamingo_top_k: top_k value to be passed to open flamingo model Default: 0"
        echo "--flamingo_top_p: top_p value to be passed to open flamingo model Default: 1.0"
        echo "--flamingo_repetition_penalty: repitition penalty  value to be passed to open flamingo model Default: 1"
        echo "--flamingo_length_penalty: length penalty value to be passed to open flamingo model"
        echo "--flamingo_output_extension: file extension that open flamingo captions will be saved with Default: flamcap"
#summarize options help
        echo "--summarize_gpt_model: OpenAI model to use for summarization Default: gpt-3.5-turbo"
        echo "--summarize_gpt_max_tokens: max tokens for GPT Default: 75"
        echo "--summarize_gpt_temperature: temperature to be set for GPT Default: 1.0"
        echo "--summarize_gpt_prompt_file_path: file path to a txt file containing the system prompt to be passed to gpt for summarizing your captions"
        echo "--summarize_file_extensions: The file extensions/captions you want to be passed to your summarize model. Defaults to values of flamingo, blip2, and wd14 output extensions, e.g. ['wd14cap','flamcap','b2cap']"
        echo "--summarize_openai_api_key: value of a valid open ai api key. Not needed if the OPENAI_API_KEY env variable is set"
        echo "--summarize_llama_model_repo_id: Huggingface Repository ID or name of the llama model to use for summarization."
        echo "--summarize_llama_model_filename: filename of the specific model to be used for llama summarization. Must be set in conjunction with --summarize_llama_model_repo_id"
        echo "--summarize_llama_prompt_filepath: Path to a prompt file that provides additional context for llama summarization. If you need to guide the summarization process with specific instructions or prompts, provide the path to the file containing those prompts here."
        echo "--summarize_llama_n_threads: number of cpu threads to run llama model on Default: 4"
        echo "--summarize_llama_n_batch: batch size to load llama model with Default:512"
        echo "--summarize_llama_n_gpu_layers: number of layers to offload to GPU Default: 55"
        echo "--summarize_llama_n_gqa: I honestly don't know, but it needs to be set to to 8 for 70B models Default: 8"
        echo "--summarize_llama_max_tokens: Maximum number of tokens to use for llama summarization. Set this value to control the length of the generated summary."
        echo "--summarize_llama_temperature: Temperature value for controlling the randomness of llama summarization. Higher values (e.g., 1.0) make the output more random, while lower values (e.g., 0.2) make it more focused and deterministic."
        echo "--summarize_llama_top_p : top_p value to run llama model with Default: 1.0"
        echo "--summarize_llama_frequency_penalty : frequency penalty value to run llama model with Default: 0"
        echo "--summarize_llama_top_p : presence penalty value to run llama model with Default: 0"
        echo "--summarize_llama_prompt_template_path : path to a template file that defines the template to use for your chosen llama model. See documentation for help. Default: llama_prompt_template.txt Default: 0"
        exit 0
        ;;
        --use_blip2) use_blip2=true; user_args="${user_args} --use_blip2" ;;
        --use_open_flamingo) use_open_flamingo=true; user_args="${user_args} --use_open_flamingo" ;;
        --use_wd14) use_wd14=true; user_args="${user_args} --use_wd14" ;;
        --summarize_with_gpt) summarize_with_gpt=true; user_args="${user_args} --summarize_with_gpt" ;;
        --summarize_with_llama) summarize_with_llama=true; user_args="${user_args} --summarize_with_llama" ;;
        --input_directory) input_directory="$2"; flamingo_img_dir="$2"; blip2_dir="$2"; user_args="${user_args} --input_directory=$2"; shift ;;
        --output_directory) output_directory="$2"; user_args="${user_args} --output_directory=$2"; shift ;;
        --wd14_stack_models) wd14_stack_models=true; user_args="${user_args} --wd14_stack_models" ;;
        --wd14_model) wd14_model="$2"; user_args="${user_args} --wd14_model=$2"; shift ;;
        --wd14_threshold) wd14_threshold="$2"; user_args="${user_args} --wd14_threshold=$2"; shift ;;
        --wd14_filter) wd14_filter="$2"; user_args="${user_args} --wd14_filter=$2"; shift ;;
        --wd14_output_extension) wd14_output_extension="$2"; summarize_file_extensions="${wd14_output_extension},${flamingo_output_extension},${blip2_output_extension}"; user_args="${user_args} --wd14_output_extension=$2"; shift ;;
        --blip2_model) blip2_model="$2"; user_args="${user_args} --blip2_model=$2"; shift ;;\
        --blip2_beams) blip2_beams="$2"; user_args="${user_args} --blip2_beams=$2"; shift ;;
        --blip2_use_nucleus_sampling) blip2_use_nucleus_sampling="$2"; user_args="${user_args} --blip2_use_nucleus_sampling=$2"; shift ;;
        --blip2_max_length) blip2_max_length="$2"; user_args="${user_args} --blip2_max_length=$2"; shift ;;
        --blip2_min_length) blip2_min_length="$2"; user_args="${user_args} --blip2_min_length=$2"; shift ;;
        --blip2_top_p) blip2_top_p="$2"; user_args="${user_args} --blip2_top_p=$2"; shift ;;
        --blip2_output_extension) blip2_output_extension="$2"; summarize_file_extensions="${wd14_output_extension},${flamingo_output_extension},${blip2_output_extension}"; user_args="${user_args} --blip2_output_extension=$2"; shift ;;
        --flamingo_example_img_dir) flamingo_example_img_dir="$2"; user_args="${user_args} --flamingo_example_img_dir=$2"; shift ;;
        --flamingo_model) flamingo_model="$2"; user_args="${user_args} --flamingo_model=$2"; shift ;;
        --flamingo_min_new_tokens) flamingo_min_new_tokens="$2"; user_args="${user_args} --flamingo_min_new_tokens=$2"; shift ;;
        --flamingo_max_new_tokens) flamingo_max_new_tokens="$2"; user_args="${user_args} --flamingo_max_new_tokens=$2"; shift ;;
        --flamingo_num_beams) flamingo_num_beams="$2"; user_args="${user_args} --flamingo_num_beams=$2"; shift ;;
        --flamingo_prompt) flamingo_prompt="$2"; user_args="${user_args} --flamingo_prompt=$2"; shift ;;
        --flamingo_temperature) flamingo_temperature="$2"; user_args="${user_args} --flamingo_temperature=$2"; shift ;;
        --flamingo_top_k) flamingo_top_k="$2"; user_args="${user_args} --flamingo_top_k=$2"; shift ;;
        --flamingo_top_p) flamingo_top_p="$2"; user_args="${user_args} --flamingo_top_p=$2"; shift ;;
        --flamingo_repetition_penalty) flamingo_repetition_penalty="$2"; user_args="${user_args} --flamingo_repetition_penalty=$2"; shift ;;
        --flamingo_length_penalty) flamingo_length_penalty="$2"; user_args="${user_args} --flamingo_length_penalty=$2"; shift ;;
        --flamingo_output_extension) flamingo_output_extension="$2"; summarize_file_extensions="${wd14_output_extension},${flamingo_output_extension},${blip2_output_extension}"; user_args="${user_args} --flamingo_output_extension=$2"; shift ;;
        --summarize_gpt_model) summarize_gpt_model="$2"; user_args="${user_args} --summarize_gpt_model=$2"; shift ;;
        --summarize_gpt_max_tokens) summarize_gpt_max_tokens="$2"; user_args="${user_args} --summarize_gpt_max_tokens=$2"; shift ;;
        --summarize_gpt_temperature) summarize_gpt_temperature="$2"; user_args="${user_args} --summarize_gpt_temperature=$2"; shift ;;
        --summarize_gpt_prompt_file_path) summarize_gpt_prompt_file_path="$2"; user_args="${user_args} --summarize_gpt_prompt_file_path=$2"; shift ;;
        --summarize_file_extensions) summarize_file_extensions="$2"; user_args="${user_args} --summarize_file_extensions=$2"; shift ;;
        --summarize_openai_api_key) summarize_openai_api_key="$2"; user_args="${user_args} --summarize_openai_api_key=$2"; shift ;;
        --summarize_llama_model_repo_id) summarize_llama_model_repo_id="$2"; user_args="${user_args} --summarize_llama_model_repo_id=$2"; shift ;;
        --summarize_llama_model_filename) summarize_llama_model_filename="$2"; user_args="${user_args} --summarize_llama_model_filename=$2"; shift ;;
        --summarize_llama_prompt_filepath) summarize_llama_prompt_filepath="$2"; user_args="${user_args} --summarize_llama_prompt_filepath=$2"; shift ;;
        --summarize_llama_n_threads) summarize_llama_n_threads="$2"; user_args="${user_args} --summarize_llama_n_threads=$2"; shift ;;
        --summarize_llama_n_batch) summarize_llama_n_batch="$2"; user_args="${user_args} --summarize_llama_n_batch=$2"; shift ;;
        --summarize_llama_n_gqa) summarize_llama_n_gqa="$2"; user_args="${user_args} --summarize_llama_n_gqa=$2"; shift ;;
        --summarize_llama_n_gpu_layers) summarize_llama_n_gpu_layers="$2"; user_args="${user_args} --summarize_llama_n_gpu_layers=$2"; shift ;;
        --summarize_llama_max_tokens) summarize_llama_max_tokens="$2"; user_args="${user_args} --summarize_llama_max_tokens=$2"; shift ;;
        --summarize_llama_temperature) summarize_llama_temperature="$2"; user_args="${user_args} --summarize_llama_temperature=$2"; shift ;;
        --summarize_llama_top_p) summarize_llama_top_p="$2"; user_args="${user_args} --summarize_llama_top_p=$2"; shift ;;
        --summarize_llama_frequency_penalty) summarize_llama_frequency_penalty="$2"; user_args="${user_args} --summarize_llama_frequency_penalty=$2"; shift ;;
        --summarize_llama_presence_penalty) summarize_llama_presence_penalty="$2"; user_args="${user_args} --summarize_llama_presence_penalty=$2"; shift ;;
        --summarize_llama_prompt_template_path) summarize_llama_prompt_template_path="$2"; user_args="${user_args} --summarize_llama_prompt_template_path=$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done


# Check if --summarize_with_gpt is set
if [ ! -z "$summarize_with_gpt" ]; then
    # Try to get the environment variable
    openai_api_key=$OPENAI_API_KEY

    # If the environment variable is not set, try to get the argument
    if [ -z "$openai_api_key" ]; then
        openai_api_key=$summarize_openai_api_key
    fi

    # If neither the environment variable nor the argument is set, print an error message and exit
    if [ -z "$openai_api_key" ]; then
        echo "Error: When --summarize_with_gpt is set, either the environment variable OPENAI_API_KEY needs to be set or the --summarize_openai_api_key argument needs to be passed."
        exit 1
    fi
fi


# Checking if the input and output directories are set
if [[ -z "$input_directory" ]]; then
    echo "--input_directory is required"
    exit 1
fi

if [[ -z "$output_directory" ]]; then
    output_directory="$input_directory"
fi

# Print user arguments
echo "User Arguments:"
echo "$user_args"


generate_blip2_options() {
    local options=""

    [ -n "$blip2_model" ] && options+=" --model=$blip2_model"
    [ -n "$input_directory" ] && options+=" --dir=$input_directory"
    [ -n "$blip2_beams" ] && options+=" --num_beams=$blip2_beams"
    [ -n "$blip2_use_nucleus_sampling" ] && options+=" --use_nucleus_sampling=$blip2_use_nucleus_sampling"
    [ -n "$blip2_max_length" ] && options+=" --max_length=$blip2_max_length"
    [ -n "$blip2_min_length" ] && options+=" --min_length=$blip2_min_length"
    [ -n "$blip2_top_p" ] && options+=" --top_p=$blip2_top_p"
    [ -n "$blip2_output_extension" ] && options+=" --output_file_extension=$blip2_output_extension"
    
    echo "$options"
}

# Running blip2 if set
if [[ "$use_blip2" == "true" ]]; then
    source "$base_directory/blip2/venv_blip2/bin/activate"
    cd "$base_directory/blip2"
    
    options=$(generate_blip2_options)
    python3 caption_blip2.py $options

    deactivate
    cd "$base_directory"
fi

generate_open_flamingo_options() {
    local options=""
    
    [ -n "$flamingo_example_img_dir" ] && options+=" --example_img_dir=$flamingo_example_img_dir"
    [ -n "$input_directory" ] && options+=" --img_dir=$input_directory"
    [ -n "$flamingo_model" ] && options+=" --model=$flamingo_model"
    [ -n "$flamingo_min_new_tokens" ] && options+=" --min_new_tokens=$flamingo_min_new_tokens"
    [ -n "$flamingo_max_new_tokens" ] && options+=" --max_new_tokens=$flamingo_max_new_tokens"
    [ -n "$flamingo_num_beams" ] && options+=" --num_beams=$flamingo_num_beams"
    [ -n "$flamingo_prompt" ] && options+=" --prompt=$flamingo_prompt"
    [ -n "$flamingo_temperature" ] && options+=" --temperature=$flamingo_temperature"
    [ -n "$flamingo_top_k" ] && options+=" --top_k=$flamingo_top_k"
    [ -n "$flamingo_top_p" ] && options+=" --top_p=$flamingo_top_p"
    [ -n "$flamingo_repetition_penalty" ] && options+=" --repetition_penalty=$flamingo_repetition_penalty"
    [ -n "$flamingo_length_penalty" ] && options+=" --length_penalty=$flamingo_length_penalty"
    [ -n "$flamingo_output_extension" ] && options+=" --output_extension=$flamingo_output_extension"
    
    echo "$options"
}

# Running open_flamingo if set
if [[ "$use_open_flamingo" == "true" ]]; then
    source "$base_directory/open_flamingo/venv_open_flamingo/bin/activate"
    cd "$base_directory/open_flamingo"
    
    options=$(generate_open_flamingo_options)
    python3 caption_flamingo.py $options
    
    deactivate
    cd "$base_directory"
fi

generate_wd14_options() {
    local options=""

    [ -n "$wd14_model" ] && options+=" --model_repo_id=$wd14_model"
    [ -n "$input_directory" ] && options+=" --input_directory=$input_directory"
    [ -n "$wd14_threshold" ] && options+=" --threshold=$wd14_threshold"
    [ -n "$wd14_filter" ] && options+=" --filter=$wd14_filter"
    [ -n "$wd14_output_extension" ] && options+=" --output_extension=$wd14_output_extension"
    [ -n "$wd14_stack_models" ] && options+=" --stack_models"

    echo "$options"
}

# Running wd14 if set
if [[ "$use_wd14" == "true" ]]; then
    source "$base_directory/wd14/venv_wd14/bin/activate"
    cd "$base_directory/wd14"
    
    options=$(generate_wd14_options)
    
    python caption_wd14.py $options

    deactivate
    cd "$base_directory"
fi

generate_summarize_with_gpt_options() {
    local options=""
    
    [ -n "$input_directory" ] && options+=" --input_dir=$input_directory"
    [ -n "$summarize_gpt_prompt_file_path" ] && options+=" --prompt_file_path=$summarize_gpt_prompt_file_path"
    [ -n "$summarize_gpt_max_tokens" ] && options+=" --filter=$summarize_gpt_max_tokens"
    [ -n "$summarize_gpt_temperature" ] && options+=" --temperature=$summarize_gpt_temperature"
    [ -n "$summarize_gpt_model" ] && options+=" --model=$summarize_gpt_model"
    [ -n "$summarize_openai_api_key" ] && options+=" --api_key=$summarize_openai_api_key"
    [ -n "$summarize_file_extensions" ] && options+=" --caption_exts=$summarize_file_extensions"
    [ -n "$output_directory" ] && options+=" --output_dir=$output_directory"
    
    echo "$options"
}

# Running summarize_with_gpt if set
if [[ "$summarize_with_gpt" == "true" ]]; then
    source "$base_directory/summarize/venv_summarize/bin/activate"
    cd "$base_directory/summarize"
    
    options=$(generate_summarize_with_gpt_options)
    python3 summarize_with_gpt.py $options
    
    deactivate
    cd "$base_directory"
fi

generate_summarize_with_llama_options() {
    local options=""
    [ -n "$input_directory" ] && options+=" --input_dir=$input_directory"
    [ -n "$output_directory" ] && options+=" --output_dir=$output_directory"
    [ -n "$summarize_llama_prompt_template_path" ] && options+=" --prompt_template_path=$summarize_llama_prompt_template_path"
    [ -n "$summarize_llama_prompt_file_path" ] && options+=" --prompt_file_path=$summarize_llama_prompt_file_path"
    [ -n "$summarize_llama_model_repo_id" ] && options+=" --hf_repo_id=$summarize_llama_model_repo_id"
    [ -n "$summarize_llama_model_filename" ] && options+=" --hf_filename=$summarize_llama_model_filename"
    [ -n "$summarize_file_extensions" ] && options+=" --caption_exts=$summarize_file_extensions"
    [ -n "$summarize_llama_n_threads" ] && options+=" --n_threads=$summarize_llama_n_threads"
    [ -n "$summarize_llama_n_batch" ] && options+=" --n_batch=$summarize_llama_n_batch"
    [ -n "$summarize_llama_n_gpu_layers" ] && options+=" --n_gpu_layers=$summarize_llama_n_gpu_layers"
    [ -n "$summarize_llama_n_gqa" ] && options+=" --n_gqa=$summarize_llama_n_gqa"
    [ -n "$summarize_llama_max_tokens" ] && options+=" --max_tokens=$summarize_llama_max_tokens"
    [ -n "$summarize_llama_temperature" ] && options+=" --temperature=$summarize_llama_temperature"
    [ -n "$summarize_llama_top_p" ] && options+=" --top_p=$summarize_llama_top_p"
    [ -n "$summarize_llama_frequency_penalty" ] && options+=" --frequency_penalty=$summarize_llama_frequency_penalty"
    [ -n "$summarize_llama_presence_penalty" ] && options+=" --presence_penalty=$summarize_llama_presence_penalty"
    echo "$options"
}

# Running summarize_with_llama if set
if [[ "$summarize_with_llama" == "true" ]]; then
    source "$base_directory/summarize/venv_summarize/bin/activate"
    cd "$base_directory/summarize"
    options=$(generate_summarize_with_llama_options)
    python3 summarize_with_llama.py $options
    
    deactivate
    cd "$base_directory"
fi

