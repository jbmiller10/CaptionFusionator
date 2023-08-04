import os
import torch
from PIL import Image
import argparse
import requests
from transformers import Blip2Processor, Blip2ForConditionalGeneration, GitProcessor, GitForCausalLM, AutoModel, \
    AutoProcessor
from huggingface_hub import hf_hub_download
from open_flamingo import create_model_and_transforms
import time

EXTENSIONS = [".jpg", ".png", ".jpeg"]


def get_examples(example_img_dir, image_processor):
    examples = []
    for root, dirs, files in os.walk(example_img_dir):
        for file in files:
            ext = os.path.splitext(file)[-1].lower()
            if ext in EXTENSIONS:
                txt_file = os.path.splitext(file)[0] + ".txt"
                with open(os.path.join(root, txt_file), 'r') as f:
                    caption = f.read()
                image = Image.open(os.path.join(root, file))
                vision_x = [image_processor(image).unsqueeze(0)]
                examples.append((caption, vision_x))
    for x in examples:
        print(f" ** Example: {x[0]}")
    return examples


def get_dtype_for_cuda_device(device):
    compute_capability = torch.cuda.get_device_capability()
    if compute_capability[0] >= 8:
        dtype = torch.bfloat16
    else:
        dtype = torch.float16
    return dtype


def main(args):
    device = "cuda" if torch.cuda.is_available() else "cpu"
    dtype = get_dtype_for_cuda_device(device) if device == "cuda" else torch.float32

    if args.prompt:
        prompt = args.prompt
    else:
        prompt = "<image>: "
    print(f" using prompt:  {prompt}")

    if "openflamingo/OpenFlamingo-9B-vitl-mpt7b" in args.model:
        lang_encoder_path = "anas-awadalla/mpt-7b"
        tokenizer_path = "anas-awadalla/mpt-7b"
        model, image_processor, tokenizer = create_model_and_transforms(
            clip_vision_encoder_path="ViT-L-14",
            clip_vision_encoder_pretrained="openai",
            lang_encoder_path=lang_encoder_path,
            tokenizer_path=tokenizer_path,
            cross_attn_every_n_layers=4,
        )
    elif "openflamingo/OpenFlamingo-3B-vitl-mpt1b" in args.model:
        lang_encoder_path = "anas-awadalla/mpt-1b-redpajama-200b"
        tokenizer_path = "anas-awadalla/mpt-1b-redpajama-200b"
        model, image_processor, tokenizer = create_model_and_transforms(
            clip_vision_encoder_path="ViT-L-14",
            clip_vision_encoder_pretrained="openai",
            lang_encoder_path=lang_encoder_path,
            tokenizer_path=tokenizer_path,
            cross_attn_every_n_layers=1,
        )
    elif "openflamingo/OpenFlamingo-4B-vitl-rpj3b" in args.model:
        lang_encoder_path = "togethercomputer/RedPajama-INCITE-Base-3B-v1"
        tokenizer_path = "togethercomputer/RedPajama-INCITE-Base-3B-v1"
        model, image_processor, tokenizer = create_model_and_transforms(
            clip_vision_encoder_path="ViT-L-14",
            clip_vision_encoder_pretrained="openai",
            lang_encoder_path=lang_encoder_path,
            tokenizer_path=tokenizer_path,
            cross_attn_every_n_layers=2,
        )

    tokenizer.padding_side = "left"

    checkpoint_path = hf_hub_download(args.model, "checkpoint.pt")
    model.load_state_dict(torch.load(checkpoint_path), strict=False)
    model.to(0, dtype=dtype)

    examples = get_examples(args.example_img_dir, image_processor)

    prompt = ""
    output_prompt = "Output:"
    per_image_prompt = "<image> " + output_prompt

    for example in iter(examples):
        prompt += f"{per_image_prompt}{example[0]}"
    prompt += per_image_prompt
    prompt = prompt.replace("\n", "")
    print(f" \n** Final full prompt with example pairs: {prompt}")

    for root, dirs, files in os.walk(args.img_dir):
        for file in files:
            ext = os.path.splitext(file)[1]
            if ext.lower() in EXTENSIONS:
                start_time = time.time()

                full_file_path = os.path.join(root, file)
                image = Image.open(full_file_path)

                vision_x = [vx[1][0] for vx in examples]
                vision_x.append(image_processor(image).unsqueeze(0))
                vision_x = torch.cat(vision_x, dim=0)
                vision_x = vision_x.unsqueeze(1).unsqueeze(0)
                vision_x = vision_x.to(device, dtype=dtype)

                lang_x = tokenizer(
                    [prompt],
                    return_tensors="pt",
                )
                lang_x.to(device)

                input_ids = lang_x["input_ids"].to(device)

                with torch.cuda.amp.autocast(dtype=dtype), torch.no_grad():
                    generated_text = model.generate(
                        vision_x=vision_x,
                        lang_x=input_ids,
                        attention_mask=lang_x["attention_mask"],
                        max_new_tokens=args.max_new_tokens,
                        min_new_tokens=args.min_new_tokens,
                        num_beams=args.num_beams,
                        temperature=args.temperature,
                        top_k=args.top_k,
                        top_p=args.top_p,
                        repetition_penalty=args.repetition_penalty,
                    )
                del vision_x
                del lang_x

                generated_text = tokenizer.decode(generated_text[0][len(input_ids[0]):], skip_special_tokens=True)
                generated_text = generated_text.split(output_prompt)[0]

                is_repeat = False
                for example in examples:
                    if example[0].strip() == generated_text.strip():  # Checking for an exact match.
                        is_repeat = True
                        break
                if is_repeat:  # Skip saving the caption if it's a verbatim repeat of an example caption
                    continue

                exec_time = time.time() - start_time
                print(f"Caption:  {generated_text}")

                print(f"{exec_time}")

                name = os.path.splitext(full_file_path)[0]
                if not os.path.exists(name):
                    with open(f"{name}.flamcap", "w") as f:
                        f.write(generated_text)
    print("Done!")


if __name__ == "__main__":
    print('****STARTING OPEN FLAMINGO PASS****')
    parser = argparse.ArgumentParser()
    parser.add_argument("--img_dir", type=str, default="input", help="Path to images")
    parser.add_argument("--example_img_dir", type=str, default="examples", help="Path to precaptioned images")
    parser.add_argument("--model", type=str, default="openflamingo/OpenFlamingo-9B-vitl-mpt7b",
                        help="Model name or path")
    parser.add_argument("--min_new_tokens", type=int, default=20, help="Minimum number of tokens to generate")
    parser.add_argument("--max_new_tokens", type=int, default=48, help="Maximum number of tokens to generate")
    parser.add_argument("--num_beams", type=int, default=10, help="Number of beams for beam search")
    parser.add_argument("--prompt", type=str, default="Output: ", help="Prompt to use for generation")
    parser.add_argument("--temperature", type=float, default=1.0, help="Temperature for sampling")
    parser.add_argument("--top_k", type=int, default=0, help="Top-k sampling")
    parser.add_argument("--top_p", type=float, default=1.0, help="Top-p sampling")
    parser.add_argument("--repetition_penalty", type=float, default=1.0, help="Repetition penalty")
    parser.add_argument("--length_penalty", type=float, default=1.0, help="Length penalty")
    parser.add_argument("--output_extension", type=str, default="flamcap", help="output extension to save caps with")
    args = parser.parse_args()
    main(args)
