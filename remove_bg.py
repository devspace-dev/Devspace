import os
from rembg import remove
from PIL import Image

input_dir = r"C:\Users\Rexxon\Downloads\Emotions"
output_dir = r"d:\devspace_flutter\assets\images\emotions"

os.makedirs(output_dir, exist_ok=True)

for filename in os.listdir(input_dir):
    if filename.endswith(".png") or filename.endswith(".jpg"):
        input_path = os.path.join(input_dir, filename)
        output_path = os.path.join(output_dir, filename)
        
        try:
            with open(input_path, 'rb') as i:
                input_data = i.read()
                
            output_data = remove(input_data)
            
            with open(output_path, 'wb') as o:
                o.write(output_data)
                
            print(f"Processed {filename}")
        except Exception as e:
            print(f"Error processing {filename}: {e}")
