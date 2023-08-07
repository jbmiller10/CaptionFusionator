import time
import os
import glob
import requests
import argparse

def ask_openai(comments, model, max_tokens, temperature, api_key):
    data = {
        'messages': comments
    }
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {api_key}',
    }
    response = requests.post(
        'https://api.openai.com/v1/chat/completions',
        json={
            'messages': data['messages'],
            'model': model,
            'max_tokens': max_tokens,
            'n': 1,
            'stop': None,
            'temperature': temperature,
        },
        headers=headers,
    )
    if response.status_code == 429:
        print("Rate limit exceeded. Waiting before retrying...")
        time.sleep(10)  # wait for 10 seconds before retrying
    return response.json()

def process_images_and_captions(directory, model, max_tokens, temperature, api_key, prompt, caption_exts):
    image_extensions = ["jpg", "jpeg", "png"]

    image_files = [f for ext in image_extensions for f in glob.glob(f"{directory}/*.{ext}")]

    total_cost = 0  # initialize total cost

    for image_file in image_files:
        base_name = os.path.splitext(image_file)[0]
        print(base_name)
        comments = [
            {
                'role': 'system',
                'content': prompt
            }
        ]
        caption_number = 1
        tags_number = 1
        for caption_ext in caption_exts:
            caption_file = f"{base_name}.{caption_ext}"
            if os.path.isfile(caption_file):
                with open(caption_file, 'r') as f:
                    caption_text = f.read()
                    if caption_ext == "wd14cap":
                        prepend_text = "Tags {tags_number}: "
                        tags_number +=1
                    elif caption_ext == "descap":
                        prepend_text = "Tags {tags_number}: "
                        tags_number +=1
                    else:
                        prepend_text = f"Caption {caption_number}: "
                        caption_number += 1
                    comments.append({
                        'role': 'user',
                        'content': prepend_text + caption_text
                    })

        if len(comments) > 1:
            response = ask_openai(comments, model, max_tokens, temperature, api_key)

            if 'usage' in response:
                prompt_tokens_used = response['usage']['prompt_tokens']
                completion_tokens_used = response['usage']['completion_tokens']

                if model == 'gpt-3.5-turbo':
                    prompt_cost = prompt_tokens_used * 0.0015 / 1000
                    completion_cost = completion_tokens_used * 0.002 / 1000
                elif model == 'gpt-4':
                    prompt_cost = prompt_tokens_used * 0.03 / 1000
                    completion_cost = completion_tokens_used * 0.06 / 1000
                else:
                    raise ValueError("Unknown model. Add the pricing for this model.")

                total_cost += prompt_cost + completion_cost  # add cost used in this API call to the total

                print(f"Response content: {response['choices'][0]['message']['content']}")
                print(f"Total cost so far: {total_cost}")

                synth_file = f"{base_name}.txt"
                with open(synth_file, 'w') as f:
                    f.write(response['choices'][0]['message']['content'])
                    print(response['choices'][0]['message']['content'])

def main():
    print('****STARTING GPT PASS****')
    parser = argparse.ArgumentParser(description="Process images and captions")
    parser.add_argument("--input_dir", type=str,help="Input directory", required=True)
    parser.add_argument("--output_dir", type=str,help="Output directory")
    parser.add_argument("--model", type=str,help="Model to use for the OpenAI API call", default="gpt-4")
    parser.add_argument("--max_tokens", type=int, help="Max tokens for the OpenAI API call", default=75)
    parser.add_argument("--temperature", type=float, help="Temperature for the OpenAI API call", default=0.8)
    parser.add_argument("--api_key", type=str,help="OpenAI API Key")
    parser.add_argument("--prompt_file_path", type=str,help="Path to txt file containing system prompt for the the model", default="gpt_system_prompt.txt")
    parser.add_argument("--caption_exts", nargs='+', help="Extensions for caption files", default=["b2cap", "flamcap", "wd14cap","descap"])

    args = parser.parse_args()

    input_directory = args.input_dir
    output_directory = args.output_dir
    model = args.model
    max_tokens = args.max_tokens
    temperature = args.temperature
    api_key = args.api_key
    caption_exts = args.caption_exts

    #read in gpt sys prompt file
    with open(args.prompt_file_path, 'r') as prompt_file:
       prompt = prompt_file.read().strip()

    if not api_key:
        api_key = os.getenv("OPENAI_API_KEY")

    if not api_key:
        print("Please set OPENAI_API_KEY env variable.")
        return
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

    process_images_and_captions(input_directory, model, max_tokens, temperature, api_key, prompt, caption_exts)

if __name__ == "__main__":
    main()

