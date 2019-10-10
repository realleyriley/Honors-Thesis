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

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    
    @IBOutlet weak var predictedOrientation: UILabel!
    @IBOutlet weak var confidence: UILabel!
    
    @IBOutlet weak var cameraView: UIView!
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    var backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    
    var model = try! VNCoreMLModel(for: m6_23090_9970().model)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Additional setup after loading the view ONCE
        // TODO: use global 'frontCamera' instead?
        let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)  // loads the back camera with default settings on startup
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

            captureOutput.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue(label: "videoQueue"))     // buffer the video and start the capture session
            
            captureSession?.startRunning()
            print("viewDidLoad successfully: ", Date())
        }
        catch {
            print("error")
        }
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    
//    override var shouldAutorotate: Bool {
//        return false
//    }
    
    
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
                    let captureOutput = AVCaptureVideoDataOutput()
                    captureSession?.addOutput(captureOutput)
                    captureOutput.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue(label: "videoQueue"))     // buffer the video and start the capture session
                    captureSession?.startRunning()
                }
                catch{
                    print("camera switch error")
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
                    let captureOutput = AVCaptureVideoDataOutput()
                    captureSession?.addOutput(captureOutput)
                    captureOutput.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue(label: "videoQueue"))     // buffer the video and start the capture session
                    captureSession?.startRunning()
                }
                catch{
                    print("camera switch error")
                }
            }
        }
    }
    
    var CVpixel: CVPixelBuffer? = nil
    
    // This is an overriden function https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutputsamplebufferdelegate/1385775-captureoutput
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
//        print(class_getInstanceSize(CVpixel))
        
        // move the captured images to a global place so that viewWillTransition can access it
        CVpixel = CMSampleBufferGetImageBuffer(sampleBuffer)
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        
    }
    // portrait = 1, upsidedown = 2, landscapeLeft = 3, landscapeRight = 4
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("-------- View Will Transition --------")
        let gravity_orientation = UIDevice.current.orientation.rawValue     // this is the orientation that the device *wants* to rotate to
        print("Current orientation: ", gravity_orientation)
        
        
        let startTime = DispatchTime.now() // <<<<<<<<<< Start time
        
        // here is where the magic happens
        let coreML_output = VNCoreMLRequest(model: self.model) { (finishedRequest, error) in
            // grab the inference results
            guard (finishedRequest.results as? [VNClassificationObservation]) != nil else { return }
        }
        
        // get the scores for two images. We want to have more confidence in our decision, so we can check multiple images
        try? VNImageRequestHandler(cvPixelBuffer: CVpixel!, options: [:]).perform([coreML_output])
        var observation_zero: VNClassificationObservation = coreML_output.results!.first as! VNClassificationObservation
        try? VNImageRequestHandler(cvPixelBuffer: CVpixel!, options: [:]).perform([coreML_output])
        var observation_one: VNClassificationObservation = coreML_output.results!.first as! VNClassificationObservation
        
        var i = 2
        var override_gravity: Bool = false
        
        // loop over 8 more images at max if we don't get confident scores. If we get a good enough confidence for two consecutive images at a time, then we can break
        while(i < 10) {
            // the two outputs need to be the same
            if (observation_zero.identifier == observation_one.identifier){
                if (observation_zero.confidence > 0.75 && observation_one.confidence > 0.75){
                    override_gravity = true     // later we want to override gravity because we are confident that this is the correct orientation
                    break       // break out of this while loop
                }
            }
            
            print("low confidence.. getting more images")
            // ! means to abort the execution if that variable is nil
            try? VNImageRequestHandler(cvPixelBuffer: CVpixel!, options: [:]).perform([coreML_output])
            
            if i%2 == 0 {
                observation_zero = coreML_output.results!.first as! VNClassificationObservation
            } else {
                observation_one = coreML_output.results!.first as! VNClassificationObservation
            }
            
            i = i + 1
        }

        // set the label text
        var predictedOrientation: String?
        switch Int(observation_one.identifier) {
        case 1:
            predictedOrientation = "portrait"
        case 2:
            predictedOrientation = "upsidedown"
        case 3:
            predictedOrientation = "landscapeLeft"
        case 4:
            predictedOrientation = "landscapeRight"
        case .none:
            predictedOrientation = ".none"
        case .some(_):
            predictedOrientation = ".some(_)"
        }
        self.predictedOrientation.text = predictedOrientation
        
        let predconfidence = String(format: "%.01f%%%", observation_one.confidence * 100)
        self.confidence.text = "\(predconfidence)"
        
        let endTime = DispatchTime.now()   // <<<<<<<<<<   end time
        let seconds = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000 // <<<<< Difference in nano seconds (UInt64)
        print("Took \(seconds) seconds to anlyze \(i) images")
        // only override if we are confident enough. If we weren't confident enough, then we don't ever override gravity
        if override_gravity {
            // if the two agree on the rotation, then we allow the rotation
            if(gravity_orientation == Int(observation_one.identifier)){
                return
            }
            else {
                // since they don't agree, override the gravity rotation
                print("OVERRIDE")
                UIDevice.current.setValue(Int(observation_one.identifier), forKey: "orientation")
            }
        }
        else {
            predictedOrientation = predictedOrientation! + " - Grav"
            self.predictedOrientation.text = predictedOrientation
        }
        
        

    }
    
    // does not support upsidedown by default
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        get{
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        // call the parent function
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
}

