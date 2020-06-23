# photo-mosaic
Given a folder with many images and a picture to be overlaid, create a Photo Mosaic

## HidePicInPic
* The secret-image (or DATA) is hidden in the cover-image (or CANVAS)
* The DATA's resolution should be lesser-than/equal-to the CANVAS' resolution, Else Terminate
* DATA's first 4 MSBs are embedded in CANVAS' last 4 LSBs
* Therefore, both image's 50% bits are preserved
* Binary operations used to enhance speed

## ReadPicInPic
* The stego-image (or CRYPTED) is used to recover the DATA and the CANVAS
* Binary operations and built-in functions instead of loops - used to enhance speed

## Demo
**Input DATA**
![Input Data](/images/input_data.jpg)

**Input CANVAS**
![Input Canvas](/images/input_canvas.jpg)

**Stego-image (CRYPTED)** -> The above DATA has been hidden in the above CANVAS
![Crypted](/images/crypted.jpg)

Now, we shall use the above **Stego-image (CRYPTED)**, to extract the original DATA and CANVAS

**Extracted DATA**
![Extracted Data](/images/extracted_data.jpg)

**Extracted CANVAS**
![Extracted Canvas](/images/extracted_canvas.jpg)

## Acknowledgement
* Data - Photo by Kristina Flour on Unsplash
* Canvas - Photo by Liam Truong on Unsplash
