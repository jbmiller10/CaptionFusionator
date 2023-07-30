import time
import os
import glob
from huggingface_hub import hf_hub_download
from llama_cpp import Llama
import argparse

def process_images_and_captions(directory, prompt, caption_exts,hf_repo_id, hf_filename, n_threads, n_batch, n_gpu_layers, n_gqa, max_tokens, temperature, top_p, frequency_penalty, presence_penalty):
    image_extensions = ["jpg", "jpeg", "png"]
    image_files = [f for ext in image_extensions for f in glob.glob(f"{directory}/*.{ext}")]
    
    model_path = hf_hub_download(repo_id=hf_repo_id, filename=hf_filename)
    # Load the Llama model
    lcpp_llm = Llama(
        model_path=model_path,
        n_threads=n_threads, 
        n_batch=n_batch,  # Should be between 1 and n_ctx
        n_gpu_layers=n_gpu_layers,  
        n_gqa=n_gqa
        #add n_ctx maybe?
    )

    for image_file in image_files:
        base_name = os.path.splitext(image_file)[0]
        print(base_name)
        prompt_string = f"### SYSTEM: {prompt}\n\n### USER: "

        caption_number = 1
        for caption_ext in caption_exts:
            caption_file = f"{base_name}.{caption_ext}"
            if os.path.isfile(caption_file):
                with open(caption_file, 'r') as f:
                    caption_text = f.read().strip()
                    if caption_ext == "wd14cap":
                        prepend_text = "Tags: "
                    else:
                        prepend_text = f"Caption {caption_number}: "
                        caption_number += 1
                    prompt_string += prepend_text + caption_text + "\n"

        prompt_string += "\n### ASSISTANT: "

        if caption_number > 1:
            # Generate response using Llama model
            response = lcpp_llm(
                prompt=prompt_string,
                max_tokens=max_tokens,
                temperature=temperature,
                top_p=top_p,
                frequency_penalty=frequency_penalty,
                presence_penalty=presence_penalty
            )

            synth_file = f"{base_name}.txt"
            with open(synth_file, 'w') as f:
                f.write(response['choices'][0]['text'])
                print(response['choices'][0]['text'])

def main():
    print('****STARTING LLAMA PASS****')
    parser = argparse.ArgumentParser(description="Process images and captions")
    parser.add_argument("--input_dir", type=str,help="Input directory", required=True)
    parser.add_argument("--output_dir", type=str,help="Output directory")
    parser.add_argument("--hf_repo_id", type=str, help="HF Path to  llama repo",default="TheBloke/StableBeluga2-70B-GGML") #just a random model for now
    parser.add_argument("--hf_filename", type=str, help="HF model filename",default="stablebeluga2-70b.ggmlv3.q2_K.bin") #just a random model for now
    #parser.add_argument("--model_path", type=str, help="path to llama model")
    parser.add_argument("--prompt_file_path", type=str,help="Path to txt file containing system prompt for the the model", default="llama_system_prompt.txt")
    parser.add_argument("--caption_exts", nargs='+', help="Extensions for caption files", default=["b2cap", "flamcap", "wd14cap"])
    parser.add_argument("--n_batch", type=int, default=512)
    parser.add_argument("--num_threads", type=int, default=4)
    parser.add_argument("--n_gpu_layers", type=int, default=55)
    parser.add_argument("--n_gqa", type=int, default=8)
    parser.add_argument("--max_tokens", type=int, help="Max tokens for the Llama model", default=75)
    parser.add_argument("--temperature", type=float, help="Temperature for the Llama model", default=.7)
    parser.add_argument("--top_p", type=float, default=1.0)
    parser.add_argument("--frequency_penalty", type=float, default=0)
    parser.add_argument("--presence_penalty", type=float, default=0)
    
    

    args = parser.parse_args()

    input_directory = args.input_dir
    output_directory = args.output_dir
    hf_repo_id = args.hf_repo_id
    hf_filename = args.hf_filename
    caption_exts = args.caption_exts
    num_threads = args.num_threads
    n_batch = args.n_batch
    n_gpu_layers = args.n_gpu_layers
    n_gqa = args.n_gqa
    max_tokens = args.max_tokens
    temperature = args.temperature
    top_p = args.top_p
    frequency_penalty = args.frequency_penalty
    presence_penalty = args.presence_penalty
    
    
    
    #read in llama sys prompt file
    with open(args.prompt_file_path, 'r') as prompt_file:
       prompt = prompt_file.read().strip()

    if not output_directory:
        output_directory = input_directory

    # Validate directories
    if not os.path.isdir(input_directory):
        print("Input directory does not exist.")
        return

    if not os.path.isdir(output_directory):
        print("Output directory does not exist.")
        return

    os.chdir(output_directory)  # Change current working directory to output directory

    process_images_and_captions(input_directory, prompt, caption_exts , hf_repo_id, hf_filename, num_threads, n_batch, n_gpu_layers, n_gqa, max_tokens, temperature, top_p, frequency_penalty, presence_penalty)

if __name__ == "__main__":
    main()
