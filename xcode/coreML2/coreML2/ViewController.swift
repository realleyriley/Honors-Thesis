//
//  ViewController.swift
//  coreML2
//
//  Created by Communist Hacker on 9/6/19.
//  Copyright © 2019 Communism. All rights reserved.
//

// import necessary packages
import UIKit
import AVFoundation
import Vision


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

//    let model = VNCoreMLModel(for: m6_33512_9652().model) // else { throw(exception:any) }
//    var model: VNCoreMLModel
    
    var model = try! VNCoreMLModel(for: m5_26078_9879().model)
    
    
//    func initModel() {
//        guard let model = try? VNCoreMLModel(for: m5_26078_9879().model) else { return }
//    }
    
/*    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        guard self.model = try? VNCoreMLModel(for: m5_26078_9879().model) else { return nil }
//        self.model = VNCoreMLModel(for: m5_26078_9879().model)
        do {
            self.model = try VNCoreMLModel(for: m5_26078_9879().model)
        }
        catch let error as NSError {
            print(error.localizedDescription)
            
        } catch {
            self.model = nil
        }
        
        
        super.init(coder: aDecoder)
    }
*/
    
    // create a label to hold the label and confidence
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        label.font = label.font.withSize(30)
        return label
    }()
    
    // this is called exactly once
    override func viewDidLoad() {
        // call the parent function
        super.viewDidLoad()
        
        // establish the capture session and add the label
        setupCaptureSession()
        view.addSubview(label)
        setupLabel()
//        initModel()     // this doesn't work yet
    }
    
    // called whenever this view appears. right now I'm just testing some swift functions.
    override func viewDidAppear(_ animated: Bool) {
        if UIDevice.current.orientation.isFlat {
            print( "UIDevice.current.orientation.isFlat " )
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
        
    override func didReceiveMemoryWarning() {
        // call the parent function
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
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
        print("Caputure Output")
//        // load our CoreML Pokedex model
//        guard let model = try? VNCoreMLModel(for: m5_26078_9879().model) else { return }
        
        // run an inference with CoreML
        let request = VNCoreMLRequest(model: self.model) { (finishedRequest, error) in
            
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
}

