import cv2
import numpy as np

# Load original image
img_path = r"C:\Users\Rexxon\.gemini\antigravity\brain\36181a36-2d4e-4f6b-8f67-b354445549a6\media__1781259175057.jpg"
img = cv2.imread(img_path)
h, w, _ = img.shape

# Convert to RGB (OpenCV uses BGR by default)
img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

# Define masks
# Red robot color
red_mask = (img_rgb[:, :, 0] > 150) & (img_rgb[:, :, 1] < 70) & (img_rgb[:, :, 2] < 70)
# White glasses color
white_mask = (img_rgb[:, :, 0] > 200) & (img_rgb[:, :, 1] > 200) & (img_rgb[:, :, 2] > 200)

# Create a combined mask of red and white
robot_parts = np.zeros((h, w), dtype=np.uint8)
robot_parts[red_mask | white_mask] = 255

# Let's save a temp image of red and white parts to see
cv2.imwrite("assets/images/temp_parts.png", robot_parts)

# Now, we need to include the black glasses frames.
# The frames are black/very dark and located inside the head.
# Let's find contours of the red+white mask.
contours, hierarchy = cv2.findContours(robot_parts, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

# Create a mask for the robot
robot_mask = np.zeros((h, w), dtype=np.uint8)

# Filter contours by area to ignore noise
min_area = 100
large_contours = [c for c in contours if cv2.contourArea(c) > min_area]

# Draw the large external contours filled (this will fill the inside of the head/body, including the black glasses!)
# Wait, let's see if the black glasses are filled. Yes, since RETR_EXTERNAL only finds the external boundary of the red/white parts.
# Wait, if the black frames of the glasses touch the outside boundary, RETR_EXTERNAL might follow the boundary. But the temples of the glasses go to the edge of the head.
# Let's see: do the temples of the glasses go outside the red head? No, they are inside the red head's silhouette, except maybe on the very edges where they connect.
# Let's draw the external contours filled.
for c in large_contours:
    cv2.drawContours(robot_mask, [c], -1, 255, thickness=cv2.FILLED)

# Let's also close any small holes inside the robot mask just in case
kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))
robot_mask = cv2.morphologyEx(robot_mask, cv2.MORPH_CLOSE, kernel)

# Now let's extract the robot using the mask
result = np.zeros((h, w, 4), dtype=np.uint8)
result[:, :, :3] = img_rgb
result[:, :, 3] = robot_mask

# For the black glasses frames, we need to make sure their original colors are preserved.
# Since we used robot_mask (which covers the whole silhouette including glasses and frames),
# their original colors (black/white/red) from img_rgb are copied to result[:, :, :3].
# Let's save the result.
cv2.imwrite("assets/images/app_icon_processed.png", cv2.cvtColor(result, cv2.COLOR_RGBA2BGRA))
print("Saved assets/images/app_icon_processed.png")
