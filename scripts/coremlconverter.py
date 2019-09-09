# USAGE
# python coremlconverter.py --model pokedex.model --labelbin lb.pickle

# import necessary packages
from keras.models import load_model
from coremltools.converters.keras import convert
import argparse

# construct the argument parser and parse the arguments
ap = argparse.ArgumentParser()
ap.add_argument("-m", "--model", required=True,
	help="name of trained keras model")
#ap.add_argument("-l", "--labelbin", required=True,
#    help="path to label binarizer")
args = vars(ap.parse_args())

# load the class labels
#print("[INFO] loading class labels from label binarizer")
#lb = pickle.loads(open(args["labelbin"], "rb").read())
#class_labels = lb.classes_.tolist()
#print("[INFO] class labels: {}".format(class_labels))

# load the trained convolutional neural network
print("[INFO] loading {}".format(args['model']))
model = load_model('..//models//' + args["model"] + '.h5')

# convert the model to coreml format
print("[INFO] converting model")
class_labels = ['right','upsidedown','left','vertical']
coreml_model = convert(model,
    input_names="image",
    image_input_names="image",
    image_scale=1/255.0,
    class_labels=class_labels,
    is_bgr=False
    )

# save the model to disk
#output = args["model"].rsplit(".", 1)[0] + ".mlmodel"
print("[INFO] saving model")
coreml_model.save('..//models//' + args['model'])
