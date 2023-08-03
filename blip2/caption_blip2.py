import os
import time
import gc
import torch
from lavis.models import load_model_and_preprocess
import argparse
from PIL import Image
from glob import glob

ALLOWED_IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png']

class BLIP2:
    device = None
    max_length: int

    def __init__(self, device, model_name: str = None, max_length=0) -> None:
        if model_name is not None:
            self.model_name = model_name
        self.device = device
        self.max_length = max_length
        name, model_type = self.model_name.split('/')
        self.model, self.processor, _ = load_model_and_preprocess(
            name=name, model_type=model_type, is_eval=True, device=device
        )

    def caption(self, img: Image) -> str:
        image = self.processor["eval"](img).unsqueeze(0).to(self.device)
        return self.model.generate({"image": image})[0]

    def unload(self):
        del self.model
        del self.processor
        if self.device == 'cuda':
            torch.cuda.empty_cache()
        gc.collect()


def gen_caps_for_dir(caption_model, directory):
    images = glob(os.path.join(directory, '*'))  # finds all files in the directory

    for img_path in images:
        _, ext = os.path.splitext(img_path)
        ext = ext.lower()

        if ext not in ALLOWED_IMAGE_EXTENSIONS:
            continue  # Skip non-image files

        img = Image.open(img_path).convert('RGB')

        start_time = time.time()
        caption = caption_model.caption(img)

        elapsed_time = time.time() - start_time
        print(f"Time taken for '{img_path}': {elapsed_time:.2f} seconds")

        base = os.path.basename(img_path)
        name, _ = os.path.splitext(base)
        output_file_extension = args.output_file_extension.lstrip('.')
        output_path = os.path.join(os.path.dirname(img_path), f"{name}.{output_file_extension}")

        with open(output_path, "w") as file:
            print(output_path)
            print(caption)
            file.write(caption)


if __name__ == "__main__":
    print('****STARTING BLIP2 PASS****')
    parser = argparse.ArgumentParser(description='Generate captions for images in a directory')
    parser.add_argument('--dir', required=True, help='Directory of images')
    parser.add_argument('--model', default="blip2_opt/caption_coco_opt6.7b", help='Model name and type, separated by "/"')
    parser.add_argument('--use_nucleus_sampling', default=False, help='whether or not to use nucleus sampling. Defaults to false')
    parser.add_argument('--max_length', default=48, help='max blip2 caption length')
    parser.add_argument('--min_length', default=False, help='min blip2 caption length')
    parser.add_argument('--top_p', default=1.0)
    parser.add_argument('--num_beams', default=10, help='number of beams')
    parser.add_argument('--output_file_extension', default='b2cap',help='extension that caption files will be saved with')

    args = parser.parse_args()

    blip = BLIP2(device='cuda', model_name=args.model)
    gen_caps_for_dir(blip, args.dir)
    blip.unload()
