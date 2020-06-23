%% Initialization
clear; close all; clc;

%% Note
%Some pics in base folder might be read as rotated, this is because:
%Issue: when you use windows to rotate an image, Matlab's 'imread' function
%does not acknowledge the image rotation and instead loads the image in its
%original (un-rotated) form.

%% Set Minimum Resolution of subimages
%Minimum Image Resolution (px x px) for each mini-pic in mosaic
%CAN BE CHANGED
MiniRes = 50;

%% User Inputs

%Getting Folder where all images are present from User Via Dialog Box
selpath = uigetdir('','Select Folder with All the Images');
if isequal(selpath,0)
    disp('Selection Cancelled')
    return;
else
    disp(selpath)
end

%Getting Image File to be Overlaid from User Via Dialog Box
[FileName,PathName]=uigetfile({'*.jpg;*.jpeg;*.png;*.tif','Acceptable Types'},...
    'Select the "jpg", "jpeg", "png" or "tif" file to be Overlaid:');
FullName=fullfile(PathName,FileName);
if isequal(FileName,0)
    disp('Selection Cancelled')
    return;
else
    disp(FullName)
end

%Getting Destination Folder to Save Mosaic from User Via Dialog Box
%selpath specifies the start path in which the dialog box opens
destpath = uigetdir(selpath,'Select Destination Folder to store Mosaic');
if isequal(destpath,0)
    disp('Selection Cancelled')
    return;
else
    disp(destpath)
end

%% Read User Inputs

%Read input image to be overlaid
im = imread(FullName);

%Read Base Images Folder
%Create an image datastore for all images in the folder
%(Identifies All imformats)
ds = imageDatastore(selpath);

%% Calculate Grid Properties (Px, NumPicsPerRow&Col) & Resize Overlay

%Shuffle the images in the datastore
ds = shuffle(ds);

%Get number of image files in the folder
n = length(ds.Files);

%If no images in folder, Print error and terminate
if n==0
    disp('No Images in Selected Folder')
    return;
end

%Height and Width of Original Overlay Image
height = size(im,1);
width = size(im,2);

%If there are too many images and a very small overlay, then resize (i.e.
%enlarge) overlay
availableArea = n*MiniRes*MiniRes;
overlayArea = height*width;
scaleFactor = sqrt(availableArea/overlayArea);
if scaleFactor>1
    im = imresize(im, scaleFactor);
    height = size(im,1);
    width = size(im,2);
end

%If 'n' is in excess,
%Take minimum possible resolution and use as many pics as possible.
%Resolution of each square mini-pic will be kept as (MiniRes x MiniRes)
px = MiniRes;

%If 'n' is not in excess, increase 'px',
%Take available number of pics and calculate px accordingly
if n < (fix(height/MiniRes) * fix(width/MiniRes))
    %Calculate the pixels of subimages such that we manage in 'n' images
    %which are actually not in excess, Hence we increase each subimage size
    %from MiniRes Pixels to higher so as to fill the space
    px = fix(sqrt(width*height/n));
end

%With calculated pixel size 'px', calculate how many pics would be fitting
%in each row and column
num_pics_per_row = fix(width/px);
num_pics_per_col = fix(height/px);

%Total number of pics that will be used out of 'n' available pics
n_used = num_pics_per_row * num_pics_per_col;

%Check amount of space remaining horizontally and vertically
width_unused = mod(width,px);
height_unused = mod(height,px);

%While maintaining the aspect ratio, resize the Overlay image to remove
%either side of the wasted space by reducing the size of Overlay image.
%Maintain Aspect Ratio
if (width_unused <= width/height*height_unused)
    %This is the condition when, we reduce Overlay's width (horizontally)
    im = imresize(im, [NaN width-width_unused]);
elseif (width_unused > width/height*height_unused)
    %This is the condition when, we reduce Overlay's height (vertically)
    im = imresize(im, [height-height_unused NaN]);
end

%This would leave a maximum of 1 empty side, which shall later be removed
%by resizing the entire grid that has been generated.

%Height and Width of Resized Overlay Image
height = size(im,1);
width = size(im,2);

%Either or both of these is Zero
width_unused = mod(width,px);
height_unused = mod(height,px);

%% Compose Grid

%We take the Overlay as the base of the mosaic grid. The empty spaces hence
%would be filled with the overlay's corresponding pixels
grid = im;

%Loop through all the images in the datastore and keep arranging them in
%the grid. Divide the unused space on the two sides of the grid's used area

%Counter through datastore images, Loop through 'n_used' images
counter = 1;
while counter<=n_used
    
    %Read image from datastore
    img = read(ds);
    
    %Size of read image
    [h, w, ~] = size(img);
    
    %Square Crop using side with less pixels
    square_crop_px = min([h,w]);
    
    %Markers for cropping image to square
    %Centre cropping of '(square_crop_px x square_crop_px)' size chunk
    start_height = 1 + fix( (h-square_crop_px)/2 );
    end_height = start_height + square_crop_px - 1;
    start_width = 1 + fix( (w-square_crop_px)/2 );
    end_width = start_width + square_crop_px - 1;
    
    %Store full resolution cropped image
    cropped_img = img(start_height:end_height , start_width:end_width, :);
    
    %Convert to (px x px) resolution
    resized_cropped_img = imresize(cropped_img, [px px]);
    
    %Which row and col the piece should go to
    current_row = fix((counter-1)/num_pics_per_row) + 1;
    current_col = mod(counter-1,num_pics_per_row) + 1;
    
    %Markers for where to insert the square piece
    %Also half of unused height has been put on top
    start_h = fix(height_unused/2) + 1 + (current_row-1)*px;
    end_h = start_h + px - 1;
    %Also half of unused width has been put on left
    start_w = fix(width_unused/2) + 1 + (current_col-1)*px;
    end_w = start_w + px - 1;
    
    %Put the square piece in place
    grid(start_h:end_h,start_w:end_w,:) = resized_cropped_img;
    
    counter = counter+1;
end

%% Store Border rows,cols of sub-images' start,end (To Be Darkened)

%Storing columns to be darkened
%Start and end of each sub-image

%Start from 1st used space (start of 1st pic)
ii=fix(width_unused/2)+1;

%Pre-allocating space, num_images*2, start & end col of each pic
cols=ones(num_pics_per_row*2);

%Loop till we get num_images*2 co-ordinates
jj=1;
while jj<=num_pics_per_row*2
    %Storing start col
    cols(jj)=ii;
    jj=jj+1;
    ii=ii+px-1;
    %Storing end col
    cols(jj)=ii;
    jj=jj+1;
    ii=ii+1;
end

%Storing rows to be darkened
%Start and end of each sub-image

%Start from 1st used space (start of 1st pic)
ii=fix(height_unused/2)+1;

%Pre-allocating space, num_images*2, start & end row of each pic
rows=ones(num_pics_per_col*2);

%Loop till we get num_images*2 co-ordinates
jj=1;
while jj<=num_pics_per_col*2
    %Storing start row
    rows(jj)=ii;
    jj=jj+1;
    ii=ii+px-1;
    %Storing end row
    rows(jj)=ii;
    jj=jj+1;
    ii=ii+1;
end

%% Overlay on Grid 

%Main Mosaic Options - Without Sub-image Border
%Taking Some Percentage of Grid, Some Percentage of Overlay
%Choose any of these which performs best for 'mosaic'
mosaic1 = grid*0.4 + im*0.6;
mosaic2 = grid*0.35 + im*0.65;
mosaic3 = grid*0.3 + im*0.7;
mosaic4 = grid*0.25 + im*0.75;

%Main Mosaic Options - With Sub-image Border
%Taking Opposite Percentages: More of Grid, Less of Overlay
%Choose any of these which performs best for 'mosaicb'
mosaic1b = mosaic1;
mosaic1b(rows,:,:) = grid(rows,:,:)*0.6 + im(rows,:,:)*0.4;
mosaic1b(:,cols,:) = grid(:,cols,:)*0.6 + im(:,cols,:)*0.4;
mosaic2b = mosaic2;
mosaic2b(rows,:,:) = grid(rows,:,:)*0.65 + im(rows,:,:)*0.35;
mosaic2b(:,cols,:) = grid(:,cols,:)*0.65 + im(:,cols,:)*0.35;
mosaic3b = mosaic3;
mosaic3b(rows,:,:) = grid(rows,:,:)*0.7 + im(rows,:,:)*0.3;
mosaic3b(:,cols,:) = grid(:,cols,:)*0.7 + im(:,cols,:)*0.3;
mosaic4b = mosaic4;
mosaic4b(rows,:,:) = grid(rows,:,:)*0.75 + im(rows,:,:)*0.25;
mosaic4b(:,cols,:) = grid(:,cols,:)*0.75 + im(:,cols,:)*0.25;

%Just For Fun
%Some nice effects by matlab imfuse function
%Just shown for creative effects
mosaic5 = imfuse(grid,im,'diff');
mosaic6 = imfuse(grid,im,'blend');
mosaic7 = imfuse(grid,im,'checkerboard');
mosaic8 = imfuse(grid,im,'falsecolor');

%% Choose final Mosaics to be Saved

%Mosaic3 is assigned as final Mosaic (without Border) that would be saved
%Mosaic3b is assigned as final Mosaic (with Border) that would be saved
%CAN BE CHANGED
mosaic = mosaic3;
mosaicb = mosaic3b;

%% Display all Mosaic Options

%Display the final mosaics - 'mosaic' & 'mosaicb'
%Full Screen FIGURE Window
figure('units','normalized','outerposition',[0 0 1 1]);
subplot(1,2,1); imshow(mosaic); title('Mosaic');
subplot(1,2,2); imshow(mosaicb); title('Mosaic Bordered');

%Display all mosaics for fun, although 'mosaic' & 'mosaicb' are the final
%Full Screen FIGURE Window
figure('units','normalized','outerposition',[0 0 1 1]);
subplot(2,4,1); imshow(mosaic1); title('40% 60%');
subplot(2,4,2); imshow(mosaic2); title('35% 65%');
subplot(2,4,3); imshow(mosaic3); title('30% 70%');
subplot(2,4,4); imshow(mosaic4); title('25% 75%');
subplot(2,4,5); imshow(mosaic1b); title('40% 60% Bordered');
subplot(2,4,6); imshow(mosaic2b); title('35% 65% Bordered');
subplot(2,4,7); imshow(mosaic3b); title('30% 70% Bordered');
subplot(2,4,8); imshow(mosaic4b); title('25% 75% Bordered');

%Display the fun effects mosaics
%Full Screen FIGURE Window
figure('units','normalized','outerposition',[0 0 1 1]);
subplot(2,2,1); imshow(mosaic5); title('Difference');
subplot(2,2,2); imshow(mosaic6); title('Blend');
subplot(2,2,3); imshow(mosaic7); title('Checkerboard');
subplot(2,2,4); imshow(mosaic8); title('FalseColor');

%% Write To File

%Create file names with user provided directory in path name
%And Write to user provided folder
%Saved as '.tiff' to preserve resolution
%CAN BE CHANGED to '.jpeg', '.png', etc
DestMosaic=fullfile(destpath,'_MOSAIC.tiff');
imwrite(mosaic,DestMosaic);
DestMosaicB=fullfile(destpath,'_MOSAIC_Bordered.tiff');
imwrite(mosaicb,DestMosaicB);
%DestOverlay=fullfile(destpath,'_OverlayResized.tiff');
%imwrite(im,DestOverlay);
%DestGrid=fullfile(destpath,'_Grid.tiff');
%imwrite(grid,DestGrid);
