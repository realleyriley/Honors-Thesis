#!/usr/bin/python
# The contents of this file are in the public domain. See LICENSE_FOR_EXAMPLE_PROGRAMS.txt
#
#   This example program shows how to use dlib's implementation of the paper:
#   One Millisecond Face Alignment with an Ensemble of Regression Trees by
#   Vahid Kazemi and Josephine Sullivan, CVPR 2014
#
#   In particular, we will train a face landmarking model based on a small
#   dataset and then evaluate it.  If you want to visualize the output of the
#   trained model on some images then you can run the
#   face_landmark_detection.py example program with predictor.dat as the input
#   model.
#
#   It should also be noted that this kind of model, while often used for face
#   landmarking, is quite general and can be used for a variety of shape
#   prediction tasks.  But here we demonstrate it only on a simple face
#   landmarking task.
#   Requirements:
#       dlib
#       numpy
#       *Compiling dlib should work on any operating system so long as you have
#       CMake installed.
#  out of 0-67, keep: 33, 36, 39, 42, 45
#
# python train_shape_predictor.py faces

import os
import sys
import glob
import dlib

# In this example we are going to train a face detector based on the small
# faces dataset in the examples/faces directory.  This means you need to supply
# the path to this faces folder as a command line argument so we will know
# where it is.
if len(sys.argv) != 2:
    print(
        "Give the path to the examples/faces directory as the argument to this "
        "program. For example, if you are in the python_examples folder then "
        "execute this program by running:\n"
        "    ./train_shape_predictor.py ../examples/faces."
        # "The second argument should be the my_predictor.dat file"
        )
    exit()
faces_folder = sys.argv[1]
models = 'models//'
# shape_predictor_folder = sys.argv[2]

options = dlib.shape_predictor_training_options()
# Now make the object responsible for training the model.
# This algorithm has a bunch of parameters you can mess with.  The
# documentation for the shape_predictor_trainer explains all of them.
# You should also read Kazemi's paper which explains all the parameters
# in great detail.  However, here I'm just setting three of them
# differently than their default values.  I'm doing this because we
# have a very small dataset.  In particular, setting the oversampling
# to a high amount (300) effectively boosts the training set size, so
# that helps this example.
options.oversampling_amount = 100
# I'm also reducing the capacity of the model by explicitly increasing
# the regularization (making nu smaller) and by using trees with
# smaller depths.
# options.nu = 0.05
# options.tree_depth = 2
options.be_verbose = True
options.cascade_depth = 15      # lets bump this up from 10 to 15
# options.feature_pool_region_padding
options.num_threads = 4


# dlib.train_shape_predictor() does the actual training.  It will save the
# final predictor to predictor.dat.  The input is an XML file that lists the
# images in the training dataset and also contains the positions of the face
# parts.
training_xml_path = "out_train.xml"
training_xml_path = "train_cleaned.xml"
training_xml_path = "train_rotated.xml"
print('Beginning to train....')
dlib.train_shape_predictor(training_xml_path, models + "15_cascades.dat", options)

# Now that we have a model we can test it.  dlib.test_shape_predictor()
# measures the average distance between a face landmark output by the
# shape_predictor and where it should be according to the truth data.
print("\nTraining accuracy: {}".format(
    dlib.test_shape_predictor(training_xml_path, models + "shape_predictor_5_face_landmarks.dat")))
# The real test is to see how well it does on data it wasn't trained on.  We
# trained it on a very small dataset so the accuracy is not extremely high, but
# it's still doing quite good.  Moreover, if you train it on one of the large
# face landmarking datasets you will obtain state-of-the-art results, as shown
# in the Kazemi paper.
testing_xml_path = "out_test.xml"
testing_xml_path = "test_cleaned.xml"
testing_xml_path = "test_rotated.xml"
print("Testing accuracy: {}".format(
    dlib.test_shape_predictor(testing_xml_path, models + "shape_predictor_5_face_landmarks.dat")))

# Now let's use it as you would in a normal application.  First we will load it
# from disk. We also need to load a face detector to provide the initial
# estimate of the facial location.
predictor = dlib.shape_predictor(models + "shape_predictor_5_face_landmarks.dat")
detector = dlib.get_frontal_face_detector()

# Now let's run the detector and shape_predictor over the images in the faces
# folder and display the results.
print("Showing detections and predictions on the images in the faces folder...")
win = dlib.image_window()
for f in glob.glob(os.path.join(faces_folder, "*.jpg")):
    print("Processing file: {}".format(f))
    img = dlib.load_rgb_image(f)

    win.clear_overlay()
    win.set_image(img)

    # Ask the detector to find the bounding boxes of each face. The 1 in the
    # second argument indicates that we should upsample the image 1 time. This
    # will make everything bigger and allow us to detect more faces.
    dets = detector(img, 1)
    print("Number of faces detected: {}".format(len(dets)))
    for k, d in enumerate(dets):
        print("Detection {}: Left: {} Top: {} Right: {} Bottom: {}".format(
            k, d.left(), d.top(), d.right(), d.bottom()))
        # Get the landmarks/parts for the face in box d.
        shape = predictor(img, d)
        print("Part 0: {}, Part 1: {} ...".format(shape.part(0),
                                                  shape.part(1)))
        # Draw the face landmarks on the screen.
        win.add_overlay(shape)

    win.add_overlay(dets)
    dlib.hit_enter_to_continue()