# Define base directory
$base_directory = "$pwd\"

# Set default values for arguments
$wd14_output_extension = "wd14cap"
$blip2_output_extension = "b2cap"
$flamingo_output_extension = "flamcap"
# $summarize_file_extensions="{0}_{1}_{2}" -f $wd14_output_extension,$flamingo_output_extension,$blip2_output_extension

# A variable to store user arguments
$user_args = ""
$config_file = ""

# Loop through arguments
foreach ($arg in $args) {
    if ($arg -like "*--use_config_file*") {
        $config_file = $args[$args.IndexOf($arg) + 1]
        break
    }
}

if (![string]::IsNullOrWhiteSpace($config_file)) {
    Write-Host "Loading options from config file $config_file"
    Get-Content $config_file | ForEach-Object {
        # Checks if line is flagged as a comment
        if (-not $_.StartsWith("#")) {
            # Parses the line
            $varname, $varvalue = $_ -split '=', 2
            # Sets the correct variable
            Set-Variable -Name $varname -Value $varvalue
        }
    }
}

while ($args.Length -gt 0) {
    switch ($args[0]) {
        "--use_config_file" {
            $options,$config_file,$args = $args
            continue
        }
        "--help" {
            #basic options
            Write-Host "Usage: run.sh [OPTIONS]"
            Write-Host "Options:"
            Write-Host "--use_config_file: absolute path to a config file containing arguments to be used. see example_config_file.txt"
            Write-Host "--use_blip2: create blip2 captions of images in your input directory"
            Write-Host "--use_open_flamingo: create open flamingo captions of images in your input directory"
            Write-Host "--use_wd14: create wd14 tags for images in your input directory"
            Write-Host "--summarize_with_gpt: use OpenAI's GPT to attempt to combine your caption files into one. Requires that summarize_openai_api_key argument be passed with a valid OpenAI API key OR the environment variable OPENAI_API_KEY be set with that value. *********WARNING: this can get expensive, especially if using GPT-4. You've been warned********"
            Write-Host "--summarize_with_llama: use a llama derived local model for combining/summarizing your caption files"        
            Write-Host "--input_directory: absolute path to the directory containing the image files you wish to caption"
            Write-Host "--output_directory: output directory for saving caption files. If not set, defaults to value passed to --input_directory"
            #wd14 options help
            Write-Host "--wd14_stack_models: runs three wd14 models and takes the mean of their values Default: ['SmilingWolf/wd-v1-4-convnext-tagger-v2', 'SmilingWolf/wd-v1-4-vit-tagger-v2', 'SmilingWolf/wd-v1-4-swinv2-tagger-v2'] "
            Write-Host "--wd14_model: if not stacking, which wd14 model to run Default: SmilingWolf/wd-v1-4-swinv2-tagger-v2"
            Write-Host "--wd14_threshold: min confidence threshold for wd14 captions. If wd14_stack_models is passed, the threshold is applied before stacking. Default: .45  "
            Write-Host "--wd14_filter: tags to filter out when running wd14 tagger"
            Write-Host "--wd14_output_extension: file extension that wd14 captions will be saved with Default: wd14cap"
            #blip2 options help
            Write-Host "--blip2_model: blip2 model to use for generating captions Default: blip2_opt/caption_coco_opt6.7b"
            Write-Host "--blip2_use_nucleus_sampling: whether to use nucleus sampling when generating blip2 captions Default: False"
            Write-Host "--blip2_beams: number of beams to use for blip2 captioning. More beams may be more accurate, but is slower and uses more vram"
            Write-Host "--blip2_max_tokens: max_tokens value to be passed to blip2 model Default: 75"
            Write-Host "--blip2_min_tokens: min_tokens value to be passed to blip2 model Default: 20"
            Write-Host "--blip2_top_p: top_p value to be passed to blip2 model Default: 1"
            Write-Host "--blip2_output_extension: file extension that blip2 captions will be saved with Default: b2cap"
            #open flamingo options help
            Write-Host "--flamingo_example_img_dir: path to open flamingo example image/caption pairs"
            Write-Host "--flamingo_model: open_flamingo model to be used for captioning. Default: openflamingo/OpenFlamingo-9B-vitl-mpt7b"
            Write-Host "--flamingo_min_new_tokens: min_tokens value to be passed to open flamingo model Default: 20"
            Write-Host "--flamingo_max_new_tokens: max_tokens value to be passed to open flamingo model Default:48 "
            Write-Host "--flamingo_num_beams: num_beams value to be passed to open flamingo model Default: 6"
            Write-Host "--flamingo_prompt: prompt value to be passed to open flamingo model Default: 'Output:'"
            Write-Host "--flamingo_temperature: value to be passed to open flamingo model Default: 1.0"
            Write-Host "--flamingo_top_k: top_k value to be passed to open flamingo model Default: 0"
            Write-Host "--flamingo_top_p: top_p value to be passed to open flamingo model Default: 1.0"
            Write-Host "--flamingo_repetition_penalty: repitition penalty  value to be passed to open flamingo model Default: 1"
            Write-Host "--flamingo_length_penalty: length penalty value to be passed to open flamingo model"
            Write-Host "--flamingo_output_extension: file extension that open flamingo captions will be saved with Default: flamcap"
            #summarize options help
            Write-Host "--summarize_gpt_model: OpenAI model to use for summarization Default: gpt-3.5-turbo"
            Write-Host "--summarize_gpt_max_tokens: max tokens for GPT Default: 75"
            Write-Host "--summarize_gpt_temperature: temperature to be set for GPT Default: 1.0"
            Write-Host "--summarize_gpt_prompt_file_path: file path to a txt file containing the system prompt to be passed to gpt for summarizing your captions"
            # Write-Host "--summarize_file_extensions: The file extensions/captions you want to be passed to your summarize model. Defaults to values of flamingo, blip2, and wd14 output extensions, e.g. ['wd14cap','flamcap','b2cap']"
            Write-Host "--summarize_openai_api_key: value of a valid open ai api key. Not needed if the OPENAI_API_KEY env variable is set"
            Write-Host "--summarize_llama_model_repo_id: Huggingface Repository ID or name of the llama model to use for summarization."
            Write-Host "--summarize_llama_model_filename: filename of the specific model to be used for llama summarization. Must be set in conjunction with --summarize_llama_model_repo_id"
            Write-Host "--summarize_llama_prompt_filepath: Path to a prompt file that provides additional context for llama summarization. If you need to guide the summarization process with specific instructions or prompts, provide the path to the file containing those prompts here."
            Write-Host "--summarize_llama_n_threads: number of cpu threads to run llama model on Default: 4"
            Write-Host "--summarize_llama_n_batch: batch size to load llama model with Default:512"
            Write-Host "--summarize_llama_n_gpu_layers: number of layers to offload to GPU Default: 55"
            Write-Host "--summarize_llama_n_gqa: I honestly don't know, but it needs to be set to to 8 for 70B models Default: 8"
            Write-Host "--summarize_llama_max_tokens: Maximum number of tokens to use for llama summarization. Set this value to control the length of the generated summary."
            Write-Host "--summarize_llama_temperature: Temperature value for controlling the randomness of llama summarization. Higher values (e.g., 1.0) make the output more random, while lower values (e.g., 0.2) make it more focused and deterministic."
            Write-Host "--summarize_llama_top_p : top_p value to run llama model with Default: 1.0"
            Write-Host "--summarize_llama_frequency_penalty : frequency penalty value to run llama model with Default: 0"
            Write-Host "--summarize_llama_top_p : presence penalty value to run llama model with Default: 0"
        }
        '--use_blip2' {
            $use_blip2 = $true
            $user_args = '{0} --use_blip2' -f $user_args
            $options,$args = $args
            continue
        }
        '--use_open_flamingo' {
            $use_open_flamingo = $true
            $user_args = '{0} --use_open_flamingo' -f $user_args
            $options,$args = $args
            continue
        }
        '--use_wd14' {
            $use_wd14 = $true
            $user_args = '{0} --use_wd14' -f $user_args
            $options,$args = $args
            continue
        }
        '--summarize_with_gpt' {
            $summarize_with_gpt = $true
            $user_args = '{0} --summarize_with_gpt' -f $user_args
            $options,$args = $args
            continue
        }
        '--summarize_with_llama' {
            $summarize_with_llama = $true
            $user_args = '{0} --summarize_with_llama' -f $user_args
            $options,$args = $args
            continue
        }
        '--input_directory' {
            $options,$value,$args = $args
            $input_directory = $value
            $flamingo_img_dir = $value
            $blip2_dir = $value
            $user_args = '{0} --input_directory "{1}"' -f $user_args, $value
            continue
        }
        '--output_directory' {
            $options,$value,$args = $args
            $output_directory = $value
            $user_args = '{0} --output_directory "{1}"' -f $user_args, $value
            $args = $args[2..($args.Count - 1)]
            continue
        }
        '--wd14_stack_models' {
            $wd14_stack_models = $true
            $user_args = '{0} --wd14_stack_models' -f $user_args
            $options,$args = $args
            continue
        }
        '--wd14_model' {
            $options,$value,$args = $args
            $wd14_model = $value
            $user_args = '{0} --wd14_model "{1}"' -f $user_args, $value
            continue
        }
        '--wd14_threshold'{
            $options,$value,$args = $args
            $wd14_threshold=$value
            $user_args = '{0} --wd14_threshold "{1}"' -f $user_args, $value
            continue
        }
        '--wd14_filter'{
            $options,$value,$args = $args
            $wd14_filter=$value
            $user_args = '{0} --wd14_filter "{1}"' -f $user_args, $value
            continue
        }
        '--wd14_output_extension'{
            $options,$value,$args = $args
            $wd14_output_extension=$value
            # $summarize_file_extensions="{0}_{1}_{2}" -f $wd14_output_extension,$flamingo_output_extension,$blip2_output_extension
            $user_args = '{0} --wd14_output_extension "{1}"' -f $user_args, $value
            continue
        }
        '--blip2_model'{
            $options,$value,$args = $args
            $blip2_model=$value
            $user_args = '{0} --wd14_output_extension "{1}"' -f $user_args, $value
            continue
        }
        '--blip2_beams'{
            $options,$value,$args = $args
            $blip2_beams=$value
            $user_args = '{0} --blip2_beams "{1}"' -f $user_args, $value
            continue
        }
        '--blip2_use_nucleus_sampling'{
            $options,$value,$args = $args
            $blip2_use_nucleus_sampling=$value
            $user_args = '{0} --blip2_use_nucleus_sampling "{1}"' -f $user_args, $value
            continue
        }
        '--blip2_max_length'{
            $options,$value,$args = $args
            $blip2_max_length=$value
            $user_args = '{0} --blip2_max_length "{1}"' -f $user_args, $value
            continue
        }
        '--blip2_min_length'{
            $options,$value,$args = $args
            $blip2_min_length=$value
            $user_args = '{0} --blip2_min_length "{1}"' -f $user_args, $value 
            continue
        }
        '--blip2_top_p'{
            $options,$value,$args = $args
            $blip2_top_p=$value
            $user_args = '{0} --blip2_top_p "{1}"' -f $user_args, $value 
            continue
        }
        '--blip2_output_extension'{
            $options,$value,$args = $args
            $blip2_output_extension=$value
            # $summarize_file_extensions="{0}_{1}_{2}" -f $wd14_output_extension, $flamingo_output_extension, $blip2_output_extension
            $user_args = '{0} --blip2_output_extension "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_example_img_dir'{
            $options,$value,$args = $args
            $flamingo_example_img_dir=$value
            $user_args = '{0} --flamingo_example_img_dir "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_model'{
            $options,$value,$args = $args
            $flamingo_model=$value
            $user_args = '{0} --flamingo_model "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_min_new_tokens'{
            $options,$value,$args = $args
            $flamingo_min_new_tokens=$value
            $user_args = '{0} --flamingo_min_new_tokens "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_max_new_tokens'{
            $options,$value,$args = $args
            $flamingo_max_new_tokens=$value
            $user_args = '{0} --flamingo_max_new_tokens "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_num_beams'{
            $options,$value,$args = $args
            $flamingo_num_beams=$value
            $user_args = '{0} --flamingo_num_beams "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_prompt'{
            $options,$value,$args = $args
            $flamingo_prompt=$value
            $user_args = '{0} --flamingo_prompt "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_temperature'{
            $options,$value,$args = $args
            $flamingo_temperature=$value
            $user_args = '{0} --flamingo_temperature "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_top_k'{
            $options,$value,$args = $args
            $flamingo_top_k=$value
            $user_args = '{0} --flamingo_top_k "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_top_p'{
            $options,$value,$args = $args
            $flamingo_top_p=$value
            $user_args = '{0} --flamingo_top_p "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_repetition_penalty'{
            $options,$value,$args = $args
            $flamingo_repetition_penalty=$value
            $user_args = '{0} --flamingo_repetition_penalty "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_length_penalty'{
            $options,$value,$args = $args
            $flamingo_length_penalty=$value
            $user_args = '{0} --flamingo_length_penalty "{1}"' -f $user_args, $value
            continue
        }
        '--flamingo_output_extension'{
            $options,$value,$args = $args
            $flamingo_output_extension=$value
            # $summarize_file_extensions="{0}_{1}_{2}" -f $wd14_output_extension,$flamingo_output_extension,$blip2_output_extension
            $user_args = '{0} --flamingo_output_extension "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_gpt_model'{
            $options,$value,$args = $args
            $summarize_gpt_model=$value
            $user_args = '{0} --summarize_gpt_model "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_gpt_max_tokens'{
            $options,$value,$args = $args
            $summarize_gpt_max_tokens=$value
            $user_args = '{0} --summarize_gpt_max_tokens "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_gpt_temperature'{
            $options,$value,$args = $args
            $summarize_gpt_temperature=$value
            $user_args = '{0} --summarize_gpt_temperature "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_gpt_prompt_file_path'{
            $options,$value,$args = $args
            $summarize_gpt_prompt_file_path=$value
            $user_args = '{0} --summarize_gpt_prompt_file_path "{1}"' -f $user_args, $value
            continue
        }
        # '--summarize_file_extensions'{
        #     $options,$value,$args = $args
        #     $summarize_file_extensions=$value
        #     $user_args = '{0} --summarize_file_extensions "{1}"' -f $user_args, $value
        #     continue
        # }
        '--summarize_openai_api_key'{
            $options,$value,$args = $args
            $summarize_openai_api_key=$value
            $user_args = '{0} --summarize_openai_api_key "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_model_repo_id'{
            $options,$value,$args = $args
            $summarize_llama_model_repo_id=$value
            $user_args = '{0} --summarize_llama_model_repo_id "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_model_filename'{
            $options,$value,$args = $args
            $summarize_llama_model_filename=$value
            $user_args = '{0} --summarize_llama_model_filename "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_prompt_filepath'{
            $options,$value,$args = $args
            $summarize_llama_prompt_filepath=$value
            $user_args = '{0} --summarize_llama_prompt_filepath "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_n_threads'{
            $options,$value,$args = $args
            $summarize_llama_n_threads=$value
            $user_args = '{0} --summarize_llama_n_threads "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_n_batch'{
            $options,$value,$args = $args
            $summarize_llama_n_batch=$value
            $user_args = '{0} --summarize_llama_n_batch "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_n_gqa'{
            $options,$value,$args = $args
            $summarize_llama_n_gqa=$value
            $user_args = '{0} --summarize_llama_n_gqa "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_n_gpu_layers'{
            $options,$value,$args = $args
            $summarize_llama_n_gpu_layers=$value
            $user_args = '{0} --summarize_llama_n_gpu_layers "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_max_tokens'{
            $options,$value,$args = $args
            $summarize_llama_max_tokens=$value
            $user_args = '{0} --summarize_llama_max_tokens "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_temperature'{
            $options,$value,$args = $args
            $summarize_llama_temperature=$value
            $user_args = '{0} --summarize_llama_temperature "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_top_p'{
            $options,$value,$args = $args
            $summarize_llama_top_p=$value
            $user_args = '{0} --summarize_llama_top_p "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_frequency_penalty'{
            $options,$value,$args = $args
            $summarize_llama_frequency_penalty=$value
            $user_args = '{0} --summarize_llama_frequency_penalty "{1}"' -f $user_args, $value
            continue
        }
        '--summarize_llama_presence_penalty'{
            $options,$value,$args = $args
            $summarize_llama_presence_penalty=$value
            $user_args = '{0} --summarize_llama_presence_penalty "{1}"' -f $user_args, $value
            continue
        }
        default {
            Write-Host "Unknown parameter passed: $($args[0])"
            exit 1
        }
    }
    $options,$args = $args
}

# Check if --summarize_with_gpt is set
if (-not [string]::IsNullOrEmpty($summarize_with_gpt)) {
    # Try to get the environment variable
    $openai_api_key = $env:OPENAI_API_KEY

    # If the environment variable is not set, try to get the argument
    if ([string]::IsNullOrEmpty($openai_api_key)) {
        $openai_api_key = $summarize_openai_api_key
    }

    # If neither the environment variable nor the argument is set, print an error message and exit
    if ([string]::IsNullOrEmpty($openai_api_key)) {
        Write-Host "Error: When --summarize_with_gpt is set, either the environment variable OPENAI_API_KEY needs to be set or the --summarize_openai_api_key argument needs to be passed."
        exit 1
    }
}

# Checking if the input and output directories are set
if ([string]::IsNullOrEmpty($input_directory)) {
    Write-Host "--input_directory is required"
    exit 1
}

if ([string]::IsNullOrEmpty($output_directory)) {
    $output_directory = $input_directory
}

# Print user arguments
Write-Host "User Arguments:"
Write-Host "$user_args"

function generate_blip2_options {
    param(
        $options = ""
    )

    if (-not [string]::IsNullOrEmpty($blip2_model)) { $options = "{0} --model {1}" -f $options,$blip2_model }
    if (-not [string]::IsNullOrEmpty($input_directory)) { $options = "{0} --dir {1}" -f $options,$input_directory }
    if (-not [string]::IsNullOrEmpty($blip2_beams)) { $options = "{0} --num_beams {1}" -f $options,$blip2_beams }
    if (-not [string]::IsNullOrEmpty($blip2_use_nucleus_sampling)) { $options = "{0} --use_nucleus_sampling {1}" -f $options,$blip2_use_nucleus_sampling }
    if (-not [string]::IsNullOrEmpty($blip2_max_length)) { $options = "{0} --max_length {1}" -f $options,$blip2_max_length }
    if (-not [string]::IsNullOrEmpty($blip2_min_length)) { $options = "{0} --min_length {1}" -f $options,$blip2_min_length }
    if (-not [string]::IsNullOrEmpty($blip2_top_p)) { $options = "{0} --top_p {1}" -f $options,$blip2_top_p }
    if (-not [string]::IsNullOrEmpty($blip2_output_extension)) { $options = "{0} --output_file_extension {1}" -f $options,$blip2_output_extension }
    
    return $options.Remove(0,1) 
}

# Running blip2 if set
if ($use_blip2 -eq "true") {
    $blip2ScriptPath = Join-Path $base_directory "blip2/venv_blip2/Scripts/activate.ps1"
    $blip2Directory = Join-Path $base_directory "blip2"
    
    . $blip2ScriptPath
    Set-Location $blip2Directory
    $options = generate_blip2_options
    $cmd = 'python caption_blip2.py {0}' -f $options
    Invoke-Expression -Command $cmd
    # deactivate
    Set-Location $base_directory
}

function generate_open_flamingo_options {
    param(
        $options = ""
    )

    if (-not [string]::IsNullOrEmpty($flamingo_example_img_dir)) { $options = "{0} --example_img_dir {1}" -f $options,$flamingo_example_img_dir }
    if (-not [string]::IsNullOrEmpty($input_directory)){ $options = "{0} --img_dir {1}" -f $options,$input_directory }
    if (-not [string]::IsNullOrEmpty($flamingo_model)){ $options = "{0} --model {1}" -f $options,$flamingo_model }
    if (-not [string]::IsNullOrEmpty($flamingo_min_new_tokens)){ $options = "{0} --min_new_tokens {1}" -f $options,$flamingo_min_new_tokens }
    if (-not [string]::IsNullOrEmpty($flamingo_max_new_tokens)){ $options = "{0} --max_new_tokens {1}" -f $options,$flamingo_max_new_tokens }
    if (-not [string]::IsNullOrEmpty($flamingo_num_beams)){ $options = "{0} --num_beams {1}" -f $options,$flamingo_num_beams }
    if (-not [string]::IsNullOrEmpty($flamingo_prompt)){ $options = "{0} --prompt {1}" -f $options,$flamingo_prompt }
    if (-not [string]::IsNullOrEmpty($flamingo_temperature)){ $options = "{0} --temperature {1}" -f $options,$flamingo_temperature }
    if (-not [string]::IsNullOrEmpty($flamingo_top_k)){ $options = "{0} --top_k {1}" -f $options,$flamingo_top_k }
    if (-not [string]::IsNullOrEmpty($flamingo_top_p)){ $options = "{0} --top_p {1}" -f $options,$flamingo_top_p }
    if (-not [string]::IsNullOrEmpty($flamingo_repetition_penalty)){ $options = "{0} --repetition_penalty {1}" -f $options,$flamingo_repetition_penalty }
    if (-not [string]::IsNullOrEmpty($flamingo_length_penalty)){ $options = "{0} --length_penalty {1}" -f $options,$flamingo_length_penalty }
    if (-not [string]::IsNullOrEmpty($flamingo_output_extension)){ $options = "{0} --output_extension {1}" -f $options,$flamingo_output_extension }
    
    return $options.Remove(0,1) 
}

# Running blip2 if set
if ($use_open_flamingo -eq "true") {
    $flamingoScriptPath = Join-Path $base_directory "open_flamingo/venv_open_flamingo/Scripts/activate.ps1"
    $flamingoDirectory = Join-Path $base_directory "open_flamingo"
    
    . $flamingoScriptPath
    Set-Location $flamingoDirectory
    $options = generate_open_flamingo_options
    $cmd = 'python caption_flamingo.py {0}' -f $options
    Invoke-Expression -Command $cmd

    deactivate
    Set-Location $base_directory
}

function generate_wd14_options {
    param(
        $options = ""
    )

    if (-not [string]::IsNullOrEmpty($wd14_model)) { $options = "{0} --model_repo_id {1}" -f $options,$wd14_model }
    if (-not [string]::IsNullOrEmpty($input_directory)) { $options = "{0} --input_directory {1}" -f $options,$input_directory }
    if (-not [string]::IsNullOrEmpty($wd14_threshold)) { $options = "{0} --threshold {1}" -f $options,$wd14_threshold }
    if (-not [string]::IsNullOrEmpty($wd14_filter)) { $options = "{0} --filter {1}" -f $options,$wd14_filter }
    if (-not [string]::IsNullOrEmpty($wd14_output_extension)) { $options = "{0} --output_extension {1}" -f $options,$wd14_output_extension }
    if (-not [string]::IsNullOrEmpty($wd14_stack_models)) { $options = "{0} --stack_models" -f $options }

    return $options.Remove(0,1) 
}

# Running wd14 if set
if ($use_wd14 -eq "true") {
    $wd14ScriptPath = Join-Path $base_directory "wd14/venv_wd14/Scripts/activate.ps1"
    $wd14Directory = Join-Path $base_directory "wd14"

    . $wd14ScriptPath
    Set-Location $wd14Directory
    $options = generate_wd14_options
    $cmd = 'python caption_wd14.py {0}' -f $options
    Invoke-Expression -Command $cmd
    
    deactivate
    Set-Location $base_directory
}

function generate_summarize_with_gpt_options {
    param(
        $options = ""
    )

    if (-not [string]::IsNullOrEmpty($input_directory)) { $options = "{0} --input_dir {1}" -f $options,$input_directory }
    if (-not [string]::IsNullOrEmpty($summarize_gpt_prompt_file_path)) { $options = "{0} --prompt_file_path {1}" -f $options,$summarize_gpt_prompt_file_path }
    if (-not [string]::IsNullOrEmpty($summarize_gpt_max_tokens)) { $options = "{0} --filter {1}" -f $options,$summarize_gpt_max_tokens }
    if (-not [string]::IsNullOrEmpty($summarize_gpt_temperature)) { $options = "{0} --temperature {1}" -f $options,$summarize_gpt_temperature }
    if (-not [string]::IsNullOrEmpty($summarize_gpt_model)) { $options = "{0} --model {1}" -f $options,$summarize_gpt_model }
    if (-not [string]::IsNullOrEmpty($summarize_openai_api_key)) { $options = "{0} --api_key {1}" -f $options,$summarize_openai_api_key }
    # if (-not [string]::IsNullOrEmpty($summarize_file_extensions)) { $options = "{0} --caption_exts {1}" -f $options,$summarize_file_extensions }
    if (-not [string]::IsNullOrEmpty($output_directory)) { $options = "{0} --output_dir {1}" -f $options,$output_directory }

    return $options.Remove(0,1) 
}

# Running summarize_with_gpt if set
if ($summarize_with_gpt -eq "true") {
    $summarizeScriptPath = Join-Path $base_directory "summarize/venv_summarize/Scripts/activate.ps1"
    $summarizeDirectory = Join-Path $base_directory "summarize"

    . $summarizeScriptPath
    Set-Location $summarizeDirectory
    $options = generate_summarize_with_gpt_options
    $cmd = 'python summarize_with_gpt.py {0}' -f $options
    Invoke-Expression -Command $cmd
    
    deactivate
    Set-Location $base_directory
}


function generate_summarize_with_llama_options {
    param(
        $options = ""
    )
    if (-not [string]::IsNullOrEmpty($input_directory)) { $options = "{0} --input_dir {1}" -f $options,$input_directory }
    if (-not [string]::IsNullOrEmpty($output_directory)) { $options = "{0} --output_dir {1}" -f $options,$output_directory }
    if (-not [string]::IsNullOrEmpty($summarize_llama_prompt_file_path)) { $options = "{0} --prompt_file_path {1}" -f $options,$summarize_llama_prompt_file_path }
    if (-not [string]::IsNullOrEmpty($summarize_llama_model_repo_id)) { $options = "{0} --hf_repo_id {1}" -f $options,$summarize_llama_model_repo_id }
    if (-not [string]::IsNullOrEmpty($summarize_llama_model_filename)) { $options = "{0} --hf_filename {1}" -f $options,$summarize_llama_model_filename }
    # use default exts
    # if (-not [string]::IsNullOrEmpty($summarize_file_extensions)) { $options = "{0} --caption_exts {1}" -f $options,$summarize_file_extensions }
    if (-not [string]::IsNullOrEmpty($summarize_llama_n_threads)) { $options = "{0} --n_threads {1}" -f $options,$summarize_llama_n_threads }
    if (-not [string]::IsNullOrEmpty($summarize_llama_n_batch)) { $options = "{0} --n_batch {1}" -f $options,$summarize_llama_n_batch }
    if (-not [string]::IsNullOrEmpty($summarize_llama_n_gpu_layers)) { $options = "{0} --n_gpu_layers {1}" -f $options,$summarize_llama_n_gpu_layers }
    if (-not [string]::IsNullOrEmpty($summarize_llama_n_gqa)) { $options = "{0} --n_gqa {1}" -f $options,$summarize_llama_n_gqa }
    if (-not [string]::IsNullOrEmpty($summarize_llama_max_tokens)) { $options = "{0} --max_tokens {1}" -f $options,$summarize_llama_max_tokens }
    if (-not [string]::IsNullOrEmpty($summarize_llama_temperature)) { $options = "{0} --temperature {1}" -f $options,$summarize_llama_temperature }
    if (-not [string]::IsNullOrEmpty($summarize_llama_top_p)) { $options = "{0} --top_p {1}" -f $options,$summarize_llama_top_p }
    if (-not [string]::IsNullOrEmpty($summarize_llama_frequency_penalty)) { $options = "{0} --frequency_penalty {1}" -f $options,$summarize_llama_frequency_penalty }
    if (-not [string]::IsNullOrEmpty($summarize_llama_presence_penalty)) { $options = "{0} --presence_penalty {1}" -f $options,$summarize_llama_presence_penalty }
    
    return $options.Remove(0,1) 
}

# Running summarize_with_llama if set
if ($summarize_with_llama -eq "true") {
    $summarizeScriptPath = Join-Path $base_directory "summarize/venv_summarize/Scripts/activate.ps1"
    $summarizeDirectory = Join-Path $base_directory "summarize"

    . $summarizeScriptPath
    Set-Location $summarizeDirectory
    $options = generate_summarize_with_llama_options
    $cmd = 'python summarize_with_llama.py {0}' -f $options
    Invoke-Expression -Command $cmd
    
    deactivate
    Set-Location $base_directory
}
