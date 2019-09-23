//
//  ViewController.swift
//  Intelligent Gyro
//
//  Created by Communist Hacker on 9/9/19.
//  Copyright © 2019 Communism. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var motionManager = CMMotionManager()
    
    // create a label to hold the Pokemon name and confidence
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        label.font = label.font.withSize(30)
        return label
    }()
    
    // called once
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCaptureSession()
        view.addSubview(label)
        setupLabel()
    }
    
    /*
    // gyro scope
    override func viewDidAppear(_ animated: Bool) {
        motionManager.gyroUpdateInterval = 0.5      // update every 0.1 seconds
        
        motionManager.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
            if let gyroData = data {
                print (String(format: "x: %.2f, y: %.2f, z: %.2f", gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z))
            }
        }
    } */

    // accelerometer
    // orientation - (x,y,z)
    // Face up flat - (0,0,-1)
    // Face down flat - (0,0,1)
    // vertical - (0, -1, 0)
    // right - (1,0,0)
    // left - (-1, 0, 0)
    /*
    override func viewDidAppear(_ animated: Bool) {
        motionManager.accelerometerUpdateInterval = 0.5      // update every 0.1 seconds
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
            if let gyroData = data {
                print (String(format: "x: %.2f, y: %.2f, z: %.2f", gyroData.acceleration.x, gyroData.acceleration.y, gyroData.acceleration.z))
            }
        }
    } */
    
    // called whenever the view controller appears
    override func viewDidAppear(_ animated: Bool) {        
//        AppUtility.lockOrientation(.portrait)
//        UIDevice.current.setValue(3, forKey: "orientation")     // rotate the screen AFTER the view appears
        
        // the new FLAT orientation
        if UIDevice.current.orientation.isFlat {
            print( "UIDevice.current.orientation.isFlat = true" )
        }
        else {
            print("Not flat")
        }
        
        // the other orientations
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            print("landscapeLeft")
        case .landscapeRight:
            print("landscapeRight")
        case .portrait:
            print("portrait")
        case .portraitUpsideDown:
            print("portraitUpsideDown")
        case .faceUp:
            print("faceUp")
        case .faceDown:
            print("faceDown")
        default: print("other")
        }
    }
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        if UIDevice.current.orientation.isLandscape {
//            print("Landscape")
//            if UIDevice.current.orientation.isFlat {
//                print("Flat")
//            } else {
//                print("Portrait")
//            }
//        }
//    }
    
    // this is the brains of the operation. When the device wants to rotate, I want to initialize the camera and check the users face to make sure we should actually rotate.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("-------- View Will Transition --------")
        print("Current orientation: ", UIDevice.current.orientation.rawValue)
//        sleep(4)
        // NOTE: UIDevice.current.orientation.is_ gets the current device orientation, not the screen orientation. This is a good thing for me.
        if UIDevice.current.orientation.isLandscape {
            print("Currently Landscape")
            
        }
        else if UIDevice.current.orientation.isPortrait {
            print("Currently Portrait")
            
        }
        
        if UIDevice.current.orientation.isFlat {
            print("Flat main")
        } else {
            print("Not Flat main")
        }
        
//        sleep(2)
    }
    
    func setupCaptureSession() {
        // create a new capture session
        let captureSession = AVCaptureSession()
        
        // find the available cameras
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices
        
        do {
            // select a camera
            if let captureDevice = availableDevices.first {
                captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice))
            }
        } catch {
            // print an error if the camera is not available
            print(error.localizedDescription)
        }
        
        // setup the video output to the screen and add output to our capture session
        let captureOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(captureOutput)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        // buffer the video and start the capture session
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.startRunning()
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // testing at what angle the device says its flat
//        if UIDevice.current.orientation.isFlat {
//            print("Flat main")
//        } else {
//            print("Not Flat main")
//        }
        
        // load our CoreML Pokedex model
        guard let model = try? VNCoreMLModel(for: m5_26078_9879().model) else { return }
        
        // run an inference with CoreML
        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            
            // grab the inference results
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
            
            // grab the highest confidence result
            guard let Observation = results.first else { return }
            
            // create the label text components
            let predclass = "\(Observation.identifier)"
            let predconfidence = String(format: "%.02f%", Observation.confidence * 100)
            
            // set the label text
            DispatchQueue.main.async(execute: {
                self.label.text = "\(predclass) \(predconfidence)"
            })
        }
        
        // create a Core Video pixel buffer which is an image buffer that holds pixels in main memory
        // Applications generating frames, compressing or decompressing video, or using Core Image
        // can all make use of Core Video pixel buffers
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // execute the request
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func setupLabel() {
        // constrain the label in the center
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        // constrain the the label to 20 pixels from the bottom
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
    }
    
    override func didReceiveMemoryWarning() {
        // call the parent function
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
}

//struct AppUtility {
//
//    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
//
//        if let delegate = UIApplication.shared.delegate as? AppDelegate {
//            delegate.orientationLock = orientation
//        }
//    }
//
//    /// OPTIONAL Added method to adjust lock and rotate to the desired orientation
//    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
//
//        self.lockOrientation(orientation)
//
//        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
//        UINavigationController.attemptRotationToDeviceOrientation()
//    }
//
//}
