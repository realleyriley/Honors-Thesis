# explore why there are two different boxes for each image

import xml.etree.ElementTree as ET

root = ET.parse('test_cleaned.xml').getroot()

for image in root.find('images').findall('image'):
    boxes = image.findall('box')    # find all boxes in this image
    if(len(boxes) < 1):
        print('no boxes? ', image.attrib)
    if(len(boxes) > 1):             # some images only have one box
        parts0 = [part.attrib for part in boxes[0].findall('part')]
        parts1 = [part.attrib for part in boxes[1].findall('part')]
        if(parts0 != parts1):
            print('unequal points ', image.attrib)
