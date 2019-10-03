//
//  ViewController.swift
//  iLieTesting
//
//  Created by Communist Hacker on 10/2/19.
//  Copyright © 2019 Tallman. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import Foundation
import CoreMotion
import Vision

class ViewController: UIViewController, WKNavigationDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    var captureSession: AVCaptureSession?
    var model = try! VNCoreMLModel(for: m6_23090_9970().model)
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let url = URL(string: "https://www.eia.gov/tools/faqs/faq.php?id=427&t=3")
        let request = URLRequest(url: url!)
        webView.load(request)
        
        let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)  // loads the front camera with default settings on startup
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice!)    // stream of input?
            captureSession = AVCaptureSession()
            captureSession?.addInput(videoInput)
            
            // setup the video output to the screen and add output to our capture session for coreML
            let captureOutput = AVCaptureVideoDataOutput()
            captureSession?.addOutput(captureOutput)
            
            captureOutput.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue(label: "videoQueue"))     // buffer the video and start the capture session
            
            captureSession?.startRunning()
            print("viewDidLoad successfully: ", Date())
        }
        catch {
            print("error loading camera and linking captureOutput")
        }
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    

    
    var CVpixel: CVPixelBuffer? = nil
    
    // This is an overriden function https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutputsamplebufferdelegate/1385775-captureoutput
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // move the captured images to a global place so that viewWillTransition can access it
        CVpixel = CMSampleBufferGetImageBuffer(sampleBuffer)
    }
    
    
    // portrait = 1, upsidedown = 2, landscapeLeft = 3, landscapeRight = 4
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        print("-------- View Will Transition --------")
        let gravity_orientation = UIDevice.current.orientation.rawValue     // this is the orientation that the device *wants* to rotate to
//        print("Current orientation: ", gravity_orientation)
        
//        let startTime = DispatchTime.now() // <<<<<<<<<< Start time

        // here is where the magic happens
        let coreML_output = VNCoreMLRequest(model: self.model) { (finishedRequest, error) in
            // grab the inference results
            guard (finishedRequest.results as? [VNClassificationObservation]) != nil else { return }
        }
        
        
        let startTime = DispatchTime.now() // <<<<<<<<<< Start timing how long it takes to analyze images with our model

        // get the scores for two images. We want to have more confidence in our decision, so we can check multiple images
        try? VNImageRequestHandler(cvPixelBuffer: CVpixel!, options: [:]).perform([coreML_output])
        var observation_zero: VNClassificationObservation = coreML_output.results!.first as! VNClassificationObservation
        try? VNImageRequestHandler(cvPixelBuffer: CVpixel!, options: [:]).perform([coreML_output])
        var observation_one: VNClassificationObservation = coreML_output.results!.first as! VNClassificationObservation
        
        var i = 2
        var override_gravity: Bool = false
        
        // loop over 8 more images at max if we don't get confident scores. If we get a good enough confidence for two consecutive images at a time, then we can break
        let n = 8
        while(i < n) {
            // the two outputs need to be the same
            if (observation_zero.identifier == observation_one.identifier){
                if (observation_zero.confidence > 0.75 && observation_one.confidence > 0.75){
                    override_gravity = true     // later we want to override gravity because we are confident that this is the correct orientation
                    break       // break out of this while loop
                }
            }
            
//            print("low confidence.. getting more images")
            // ! means to abort the execution if that variable is nil
            try? VNImageRequestHandler(cvPixelBuffer: CVpixel!, options: [:]).perform([coreML_output])
            
            if i%2 == 0 {
                observation_zero = coreML_output.results!.first as! VNClassificationObservation
            } else {
                observation_one = coreML_output.results!.first as! VNClassificationObservation
            }
            
            i = i + 1
        }
        
        let endTime = DispatchTime.now()   // <<<<<<<<<<   end time
        let milliseconds = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000 // <<<<< Difference in milli seconds (UInt64)
        
        // use these 3 lines to collect data on the ammount of time taken for analyzing n images
        if(i == n) {
            print(milliseconds)
        }
        
        print("Took \(milliseconds) ms to anlyze \(i) images")

        
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
        
//        self.predictedOrientation.text = predictedOrientation
        print("predOrient: ", predictedOrientation!)
        
        let predconfidence = String(format: "%.01f%%%", observation_one.confidence * 100)
        print("predConf: ", predconfidence)
        
        
        // only override if we are confident enough. If we weren't confident enough, then we don't ever override gravity
        if override_gravity {
            // if the two agree on the rotation, then we allow the rotation
            if(gravity_orientation == Int(observation_one.identifier)){
                return
            }
            else {
                // since they don't agree, override the gravity rotation
//                print("OVERRIDE")
                UIDevice.current.setValue(Int(observation_one.identifier), forKey: "orientation")
            }
        }
        else {
            print("fall back on gravity")
        }
    }
}

