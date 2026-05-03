from PIL import Image

def pad_image(input_path, output_path, padding_ratio=0.3):
    try:
        img = Image.open(input_path)
        img = img.convert("RGBA")
        
        # Calculate new size with padding
        width, height = img.size
        new_width = int(width * (1 + padding_ratio))
        new_height = int(height * (1 + padding_ratio))
        new_size = max(new_width, new_height)
        
        # Create new image with transparent background
        new_img = Image.new("RGBA", (new_size, new_size), (0, 0, 0, 0))
        
        # Paste original image in the center
        offset_x = (new_size - width) // 2
        offset_y = (new_size - height) // 2
        new_img.paste(img, (offset_x, offset_y), img)
        
        new_img.save(output_path)
        print(f"Successfully saved padded image to {output_path}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    pad_image('assets/images/app_icon.png', 'assets/images/app_icon_splash.png', 0.4)
