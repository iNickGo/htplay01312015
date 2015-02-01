//
//  ViewController.swift
//  cap
//

//  Copyright (c) 2015 na. All rights reserved.
//

//reference: https://github.com/bradley/iOSSwiftOpenGLCamera/blob/master/iOSSwiftOpenGLCamera/CameraSessionController.swift


import UIKit
import Foundation
import MobileCoreServices
import AVFoundation
import SwiftyJSON

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    let client : Client = Client.sharedInstance
    
    @IBOutlet var imgView: UIImageView?
    @IBOutlet var btn: UIButton?
    @IBOutlet var imgView2: UIImageView?
    
    var sessionQueue: dispatch_queue_t!
    
    var cameraUI: UIImagePickerController! = UIImagePickerController()
    
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    var stillImageOutput: AVCaptureStillImageOutput!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.view = self
        client.connect()
        
        
        
        sessionQueue = dispatch_queue_create("CameraSessionController Session", DISPATCH_QUEUE_SERIAL)
        
        
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        
    //
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Front) {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        println("Capture device found")
                        beginSession()
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func onClick(sender: AnyObject) {
        captureImage(0);
    }
    
    func captureImage(reqType: Int) {
        println("capturing image")
        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        }
        
        if  stillImageOutput == nil {
            return
        }
        
        var client = self.client
        var parent = self
        
        self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(
            self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo),completionHandler: {
                (imageDataSampleBuffer: CMSampleBuffer?, error: NSError?) -> Void in
                if imageDataSampleBuffer  == nil || error != nil {
                    return
                }
                else if imageDataSampleBuffer != nil{
                    var imageData: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer?)
//                    var image: UIImage! = UIImage(data: imageData)
  //                  println(image.size)
                    
                    //720,1280
                    //self.imgView2?.image = image
                    let base64String = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
                    
                    if reqType == 0 {
                        var json:JSON = ["cmd":"uploadImg", "data": base64String]
                        client.socket.writeData(json.rawData()!)
                    }                   
                }
            }
        )
    }
    
    
    
    func beginSession() {
        
        var err : NSError? = nil
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        if var oview = self.imgView  {
            previewLayer?.frame = oview.layer.frame
            captureSession.startRunning()
        }
    }

    
    func RBResizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSizeMake(size.width * heightRatio, size.height * heightRatio)
        } else {
            newSize = CGSizeMake(size.width * widthRatio,  size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

