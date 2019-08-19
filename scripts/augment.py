# Augment all images

import cv2
import imutils
import numpy as np
import os
import xml.etree.ElementTree as ET
import pdb
import copy
import sys

def rotate_images(images_folder, debug=False):
    image_names = os.listdir(f'{images_folder}/.')
    for image_name in image_names:
        image = cv2.imread(f'{images_folder}/{image_name}')     # read in each image into memory
        for angle in [90, 180, 270]:
            rotated = imutils.rotate(image, angle)      # rotate image
            if(debug):
                cv2.imshow("Rotated", rotated)           # show the image
                key = cv2.waitKey(0)
                if key == ord("q"):   # if the `q` key was pressed, break from the loop
                    break
            cv2.imwrite(f'{images_folder}/{image_name[0:-4]}_{angle}.jpg', rotated)
    
    if(debug):
        cv2.destroyAllWindows()     # cleanup

def rotate_and_grey_images(images_folder, save_folder, debug=False):
    image_names = os.listdir(f'{images_folder}/.')
    for image_name in image_names:
        image = cv2.imread(f'{images_folder}/{image_name}')     # read in each image into memory
        grey = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)          # convert to grey 
        cv2.imwrite(f'{save_folder}/{image_name[0:-4]}_c1.jpg', grey)

        for angle in [90, 180, 270]:
            rotated = imutils.rotate(grey, angle)      # rotate image
            if(debug):
                cv2.imshow("Rotated", rotated)           # show the image
                key = cv2.waitKey(0)
                if key == ord("q"):   # if the `q` key was pressed, break from the loop
                    break
            cv2.imwrite(f'{save_folder}/{image_name[0:-4]}_c{int(angle/90) + 1}.jpg', rotated)
    
    if(debug):
        cv2.destroyAllWindows()     # cleanup
        
        
def rotate_xml(xml_file_path, out='out.xml', debug=False):
    # if(debug):
        # pdb.set_trace()

    tree = ET.parse(f'{xml_file_path}')   # the entire xml file
    images = tree.getroot().find('images')
    
    i = 0
    for image in images.findall('image'):
        i += 1
        image_90 = copy.deepcopy(image)     # copy this image
        image_180 = copy.deepcopy(image)
        image_270 = copy.deepcopy(image)

        # get the width and height of the image
        pic = cv2.imread(image.attrib['file'])
        if(debug):
            rotated = imutils.rotate(pic, 270)

        height, width, channels = pic.shape
        del pic, channels
        height -= 1
        width -= 1         # for future math

        # translate points 90
        for box in image_90.findall('box'):    # find all boxes in this image
            # (y, width - x - box_height)
            new_top = width - int(box.attrib['left']) - int(box.attrib['height'])   
            new_left = box.attrib['top']
            box.set('top', str(new_top))
            box.set('left', new_left)

            for part in box.findall('part'):    # rotate all 5 points
                if(debug):
                    cv2.line(pic, (int(part.attrib['x']),int(part.attrib['y'])), (int(part.attrib['x'])+1,int(part.attrib['y'])), (0,0,200), 2)
                
                # (y, width - x)
                new_x = part.attrib['y']
                part.set('y', str(width - int(part.attrib['x'])))
                part.set('x', new_x)

                if(debug):
                    cv2.line(rotated, (int(part.attrib['x']),int(part.attrib['y'])), (int(part.attrib['x'])+1,int(part.attrib['y'])), (0,0,200), 2)

            if(debug):      # draw the new rect on the image
                attrib = image.find('box').attrib
                cv2.rectangle(pic, (int(attrib['left']), int(attrib['top'])), (int(attrib['left']) + int(attrib['width']), int(attrib['top']) + int(attrib['height'])), (0,200,0), 2)
                cv2.imshow("Reg Box", pic)           # show the image                

                cv2.rectangle(rotated, (new_left, new_top), (new_left + int(box.attrib['width']), new_top + int(box.attrib['height'])), (0,200,0), 2)
                cv2.imshow("Rotated Box", rotated)           # show the image
                key = cv2.waitKey(0)

                if key == ord("q"):   # if the `q` key was pressed, break from the loop
                    sys.exit()

        # insert into the xml tree
        image_90.set('file', image_90.attrib['file'][0:-4] + '_90.jpg')
        images.insert(i, image_90)
        i += 1

        # translate points 180
        for box in image_180.findall('box'):    # find all boxes in this image
            # width - left - box_width
            new_top = height - int(box.attrib['top']) - int(box.attrib['height'])
            new_left = width - int(box.attrib['left']) - int(box.attrib['width'])
            box.set('top', str(new_top))
            box.set('left', str(new_left))

            for part in box.findall('part'):    # rotate all 5 points
                if(debug):
                    cv2.line(pic, (int(part.attrib['x']),int(part.attrib['y'])), (int(part.attrib['x'])+1,int(part.attrib['y'])), (0,0,200), 2)
                part.set('x', str(width - int(part.attrib['x'])))
                part.set('y', str(width - int(part.attrib['y'])))
                if(debug):
                    cv2.line(rotated, (int(part.attrib['x']),int(part.attrib['y'])), (int(part.attrib['x'])+1,int(part.attrib['y'])), (0,0,200), 2)

            if(debug):      # draw the new rect on the image
                attrib = image.find('box').attrib
                cv2.rectangle(pic, (int(attrib['left']), int(attrib['top'])), (int(attrib['left']) + int(attrib['width']), int(attrib['top']) + int(attrib['height'])), (0,200,0), 2)
                cv2.imshow("Reg Box", pic)           # show the image                

                cv2.rectangle(rotated, (new_left, new_top), (new_left + int(box.attrib['width']), new_top + int(box.attrib['height'])), (0,200,0), 2)
                cv2.imshow("Rotated Box", rotated)           # show the image
                key = cv2.waitKey(0)

                if key == ord("q"):   # if the `q` key was pressed, break from the loop
                    sys.exit()

        # insert into the xml tree
        image_180.set('file', image_180.attrib['file'][0:-4] + '_180.jpg')
        images.insert(i, image_180)
        i += 1

        # translate points 270
        for box in image_270.findall('box'):    # find all boxes in this image
            # width - left - box_width
            new_top = box.attrib['left']
            new_left = height - int(box.attrib['top']) - int(box.attrib['width'])
            box.set('top', new_top)
            box.set('left', str(new_left))

            for part in box.findall('part'):    # rotate all 5 points
                if(debug):
                    cv2.line(pic, (int(part.attrib['x']),int(part.attrib['y'])), (int(part.attrib['x'])+1,int(part.attrib['y'])), (0,0,200), 2)
                new_y = part.attrib['x']
                part.set('x', str(height - int(part.attrib['y'])))
                part.set('y', new_y)
                if(debug):
                    cv2.line(rotated, (int(part.attrib['x']),int(part.attrib['y'])), (int(part.attrib['x'])+1,int(part.attrib['y'])), (0,0,200), 2)

            if(debug):      # draw the new rect on the image
                attrib = image.find('box').attrib
                cv2.rectangle(pic, (int(attrib['left']), int(attrib['top'])), (int(attrib['left']) + int(attrib['width']), int(attrib['top']) + int(attrib['height'])), (0,200,0), 2)
                cv2.imshow("Reg Box", pic)           # show the image                

                cv2.rectangle(rotated, (new_left, new_top), (new_left + int(box.attrib['width']), new_top + int(box.attrib['height'])), (0,200,0), 2)
                cv2.imshow("Rotated Box", rotated)           # show the image
                key = cv2.waitKey(0)

                if key == ord("q"):   # if the `q` key was pressed, break from the loop
                    sys.exit()
        
        # insert into the xml tree
        image_270.set('file', image_270.attrib['file'][0:-4] + '_270.jpg')
        images.insert(i, image_270)
        i += 1
    
    tree.write(out)


# rotate_images('images')
# rotate_xml('train_cleaned.xml', 'train.xml')
# rotate_xml('test_cleaned.xml', 'test.xml')

rotate_and_grey_images('..//data//ibug_300W_large_face_landmark_dataset//helen//testset', '..//data//ibug_300W_large_face_landmark_dataset//helen//test_grey_rotated')
rotate_and_grey_images('..//data//ibug_300W_large_face_landmark_dataset//helen//trainset', '..//data//ibug_300W_large_face_landmark_dataset//helen//train_grey_rotated')