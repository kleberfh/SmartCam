//
//  ViewController.swift
//  smartCam
//
//  Created by Kleber Fernando on 31/07/18.
//  Copyright © 2018 Kleber Fernando. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var acur: UILabel!
    
    var useFrontCamera = false
    
    @IBAction func switchCameraAction(_ sender: Any) {
        useFrontCamera = !useFrontCamera
        loadCamera()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //load the camera
        loadCamera()
    }
    
    func loadCamera() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        let useFront = self.useFrontCamera
        
        let witchCamera = (useFront ? getFrontCamera() : getBackCamera())
        
        let input = try? AVCaptureDeviceInput(device: witchCamera!)
        
        captureSession.addInput(input!)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    func getFrontCamera() -> AVCaptureDevice?{
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        return videoDevice
    }
    
    func getBackCamera() -> AVCaptureDevice{
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)!
    }

    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: MobileNet().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservartion = results.first else { return }
            
            DispatchQueue.main.async{
                self.label.text = firstObservartion.identifier
                self.acur.text = String(firstObservartion.confidence)
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

