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
        let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)  // loads the front camera with default settings on startup
        do { try videoCaptureDevice?.lockForConfiguration() }
        catch { print("Cannot lock") }
//        var videoSupportedFrameRateRanges: [AVFrameRateRange] { get }
//        print(videoSupportedFrameRateRanges)
//        videoCaptureDevice?.activeVideoMaxFrameDuration
        print("MaxFrame: ", 1/CMTimeGetSeconds(videoCaptureDevice!.activeVideoMaxFrameDuration))
        print("MinFrame: ", 1/CMTimeGetSeconds(videoCaptureDevice!.activeVideoMinFrameDuration))
        
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
    
    override var shouldAutorotate: Bool {
        return false
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
    
    
    // This is an overriden function https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutputsamplebufferdelegate/1385775-captureoutput
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // run an inference with CoreML
        let request = VNCoreMLRequest(model: self.model) { (finishedRequest, error) in
            // grab the inference results
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
            guard let Observation = results.first else { return }   // grab the highest confidence result

            let predclass = "\(Observation.identifier)"     // create the label text components
            let predconfidence = String(format: "%.02f%", Observation.confidence * 100)

            // set the label text
            DispatchQueue.main.async(execute: {
                self.predictedOrientation.text = "\(predclass)"
                self.confidence.text = "\(predconfidence)"
            })
        }
        
        // create a Core Video pixel buffer which is an image buffer that holds pixels in main memory
        // Applications generating frames, compressing or decompressing video, or using Core Image
        // can all make use of Core Video pixel buffers
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // execute the request
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    override func didReceiveMemoryWarning() {
        // call the parent function
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
}

