import os
from PIL import Image

input_dir = r"C:\Users\Rexxon\Downloads\Emotions"
output_dir = r"d:\devspace_flutter\assets\images\emotions"

os.makedirs(output_dir, exist_ok=True)

def distance(c1, c2):
    return sum((a - b) ** 2 for a, b in zip(c1[:3], c2[:3])) ** 0.5

for filename in os.listdir(input_dir):
    if filename.endswith(".png") or filename.endswith(".jpg"):
        input_path = os.path.join(input_dir, filename)
        output_path = os.path.join(output_dir, filename)
        
        try:
            img = Image.open(input_path).convert("RGBA")
            img = img.resize((256, 256), Image.Resampling.LANCZOS)
            
            # Simple background removal using flood fill or magic wand would be better
            # but since it's an emote on a solid background, we'll replace the top-left color
            pixels = img.load()
            bg_color = pixels[0, 0]
            
            width, height = img.size
            for y in range(height):
                for x in range(width):
                    if distance(pixels[x, y], bg_color) < 20:  # tolerance
                        pixels[x, y] = (255, 255, 255, 0)
            
            img.save(output_path)
            print(f"Processed {filename}")
        except Exception as e:
            print(f"Error processing {filename}: {e}")
