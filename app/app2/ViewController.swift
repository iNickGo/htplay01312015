//
//  ViewController.swift
//  cap
//

//  Copyright (c) 2015 na. All rights reserved.
//

import UIKit
import Foundation
import MobileCoreServices

class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    let client : Client = Client.sharedInstance
    
    @IBOutlet var imgView: UIImageView?
    @IBOutlet var btn: UIButton?
    
    var cameraUI: UIImagePickerController! = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.view = self
        //        client.connect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func onClick(sender: AnyObject) {
        self.presentCamera()
    }
    
    func presentCamera()
    {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
        {
            cameraUI = UIImagePickerController()
            cameraUI.delegate = self
            cameraUI.sourceType = UIImagePickerControllerSourceType.Camera;
            cameraUI.mediaTypes = [kUTTypeImage]
            cameraUI.allowsEditing = false
            cameraUI.cameraDevice = UIImagePickerControllerCameraDevice.Front
            
            self.presentViewController(cameraUI, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker:UIImagePickerController!, didFinishPickingMediaWithInfo info:NSDictionary)
    {
        if(picker.sourceType == UIImagePickerControllerSourceType.Camera)
        {
            var image: UIImage = info.objectForKey(UIImagePickerControllerOriginalImage) as UIImage
            var size = CGSizeMake(100, 300)             //default size
            
            //swift style, XDD
            if var imgViewSize = imgView?.image {
                size = imgViewSize.size
            }
            
            var newImg = RBResizeImage(image, targetSize: size)
            var data  = UIImageJPEGRepresentation(newImg, 50)
            
            let base64String = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.allZeros)
            
            
            //client.uploadImg(base64String, skill: skill)
            
            if var img = imgView? {
                img.image = image
            }
            
            self.dismissViewControllerAnimated(true, completion: nil)
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

