from PIL import Image

# Open image
im = Image.open("./servers.jpg")

print("Printing Image size meta-data...")
print(im.format, im.size, im.mode)

# https://pythonexamples.org/pillow-convert-image-to-grayscale/
print("Converting image to grayscale...")
# Convert the image to grayscale
im = im.convert("L")
print("Saving newly created image to disk...")
# Save the grayscale image
im.save("grayscale_image.jpg")

print("Printing GRayscale Image size meta-data...")
print(im.format, im.size, im.mode)
