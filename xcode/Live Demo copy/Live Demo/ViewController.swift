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
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var nativeRes: UILabel!
    
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    var backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Additional setup after loading the view ONCE
        let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)  // loads the front camera with default settings on startup
        do { try videoCaptureDevice?.lockForConfiguration() }
        catch { print("Cannot lock") }
//        var videoSupportedFrameRateRanges: [AVFrameRateRange] { get }
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
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    
    override func didReceiveMemoryWarning() {
        // call the parent function
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
}


