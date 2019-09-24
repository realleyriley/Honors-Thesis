//
//  ViewController.swift
//  cpp_testing
//
//  Created by Riley Tallman on 5/27/19.
//  Copyright © 2019 Riley Tallman. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation
import CoreMotion
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var cameraView: UIView!
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    var backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Additional setup after loading the view ONCE
        let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)  // loads the back camera with default settings on startup
        do{
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice!)    // stream of input?
            captureSession = AVCaptureSession()
            captureSession?.addInput(videoInput)
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)    // Connect the preview layer with the capturing session.
            videoPreviewLayer?.frame = view.layer.bounds    // may try removing .bounds to get a ffill the screen rather than fill the CameraView that I created in main.storyboard.
            cameraView.layer.addSublayer(videoPreviewLayer!)    // Add the preview layer into the view's layer hierarchy.
            
            // setup the video output to the screen and add output to our capture session for coreML
            let captureOutput = AVCaptureVideoDataOutput()
            captureSession?.addOutput(captureOutput)

//            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//            previewLayer.frame = view.frame
//            view.layer.addSublayer(previewLayer)
//
//            // buffer the video and start the capture session
//            captureOutput.setSampleBufferDelegate(self as! AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue(label: "videoQueue"))
            
            captureSession?.startRunning()
            print("viewDidLoad successfully: ", Date())
        }
        catch {
            print("error")
        }
        
//        setupCaptureSession()
//        view.addSubview(label)
    }

    @IBAction func switchCamera(_ sender: Any) {
        guard let currentCameraInput: AVCaptureInput = captureSession?.inputs.first else{
            return
        }
        
        if let input = currentCameraInput as? AVCaptureDeviceInput
        {
            if input.device.position == .back
            {
                captureSession?.stopRunning()
                let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                do {
                    let input = try AVCaptureDeviceInput(device: captureDevice!)
                    captureSession = AVCaptureSession()
                    captureSession?.addInput(input)
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                    videoPreviewLayer?.frame = view.layer.bounds
                    cameraView.layer.addSublayer(videoPreviewLayer!)
                    captureSession?.startRunning()
                }
                catch{
                    print("error")
                }
            }
            else
            {
                captureSession?.stopRunning()
                let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                do {
                    let input = try AVCaptureDeviceInput(device: captureDevice!)
                    captureSession = AVCaptureSession()
                    captureSession?.addInput(input)
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                    videoPreviewLayer?.frame = view.layer.bounds
                    cameraView.layer.addSublayer(videoPreviewLayer!)
                    // probably need to setup coreML again
                    captureSession?.startRunning()
                    
                }
                catch{
                    print("error")
                }
                
            }
            
        }
    }
    
//    func setupCaptureSession() {
//        // create a new capture session
//        let captureSession = AVCaptureSession()
//
//        // find the available cameras
//        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices
//
//        do {
//            // select a camera
//            if let captureDevice = availableDevices.first {
//                captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice))
//            }
//        } catch {
//            // print an error if the camera is not available
//            print(error.localizedDescription)
//        }
//
//        // setup the video output to the screen and add output to our capture session
//        let captureOutput = AVCaptureVideoDataOutput()
//        captureSession.addOutput(captureOutput)
//        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewLayer.frame = view.frame
//        view.layer.addSublayer(previewLayer)
//
//        // buffer the video and start the capture session
//        captureOutput.setSampleBufferDelegate(self as! AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue(label: "videoQueue"))
//        captureSession.startRunning()
//    }
    
    
    // This is an overriden function https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutputsamplebufferdelegate/1385775-captureoutput
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Caputured Output")
        //        // load our CoreML Pokedex model
        /*guard let model = try? VNCoreMLModel(for: m5_26078_9879().model) else { return }
        
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
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request]) */
    }
    
    /*
    // called whenever the view controller appears
    override func viewDidAppear(_ animated: Bool) {
        UIDevice.current.setValue(3, forKey: "orientation")     // rotate the screen AFTER the view appears
        
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("-------- View Will Transition --------")
        print("Current orientation: ", UIDevice.current.orientation.rawValue)
        //        sleep(4)
        // NOTE: UIDevice.current.orientation.is_ gets the current device orientation, not the screen orientation. This is a good thing for me.
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
            //            if UIDevice.current.orientation.isFlat {
            //                print("Flat")
            //            } else {
            //                print("Not Flat")
            //            }
        }
        else if UIDevice.current.orientation.isPortrait {
            print("Portrait")
            //            if UIDevice.current.orientation.isFlat {
            //                print("Flat")
            //            } else {
            //                print("Not Flat")
            //            }
        }
        
        if UIDevice.current.orientation.isFlat {
            print("Flat main")
        } else {
            print("Not Flat main")
        }
        
        //        sleep(4)
    }
    */
    
    override func didReceiveMemoryWarning() {
        // call the parent function
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
}

