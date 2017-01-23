//
//  ViewController.swift
//  SwiftPhotoPicker
//
//  Created by Jason Gresh on 1/18/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    var capturedImages: [UIImage]! = []
    var videoURL: URL?
    var imagePickerController: UIImagePickerController!
    
    @IBOutlet var overlayView: UIView!
    @IBOutlet weak var takePictureButton: UIBarButtonItem!
    @IBOutlet weak var startStopButton: UIBarButtonItem!
    @IBOutlet weak var delayedPhotoButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    // for delayed and repeated pictures
    weak var cameraTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let toolbar = self.navigationController?.toolbar,
                var toolbarItems = toolbar.items {
                if toolbarItems.count > 2 {
                    toolbarItems.remove(at: 2)
                    self.setToolbarItems(toolbarItems, animated: false)
                }
            }
        }
    }
    
    @IBAction func showImagePickerForPhotoPicker(sender: UIBarButtonItem) {
        showImagePickerForSourceType(sourceType: .photoLibrary, fromButton: sender)
    }
    
    private func showImagePickerForSourceType(sourceType: UIImagePickerControllerSourceType, fromButton button:UIBarButtonItem) {
        if self.imageView.isAnimating {
            self.imageView.stopAnimating()
        }
        
        if self.capturedImages.count > 0 {
            self.capturedImages.removeAll()
        }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = .currentContext
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = self
        imagePickerController.modalPresentationStyle = (sourceType == .camera) ? .fullScreen : .popover
        imagePickerController.mediaTypes = [String(kUTTypeMovie),String(kUTTypeImage)]
        //media types is an array of string that tells the image picker the type of image you want to show
        
        if let presentationController = imagePickerController.popoverPresentationController {
            presentationController.barButtonItem = button
            presentationController.permittedArrowDirections = .any
        }
        
       /* if (sourceType == .camera) {
            // The user wants to use the camera interface. Set up our custom overlay view for the camera.
            imagePickerController.showsCameraControls = false;
            
            /*
             Load the overlay view from the OverlayView nib file. Self is the File's Owner for the nib file, so the overlayView outlet is set to the main view in the nib. Pass that view to the image picker controller to use as its overlay view, and set self's reference to the view to nil.
             */
            //[[NSBundle mainBundle] loadNibNamed:@"OverlayView" owner:self options:nil];
            Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)
            
            self.overlayView.frame = (imagePickerController.cameraOverlayView?.frame)!;
            imagePickerController.cameraOverlayView = self.overlayView;
            self.overlayView = nil;
        }*/
        
        self.imagePickerController = imagePickerController; // we need this for later
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func showImagePickerForCamera(sender: UIBarButtonItem) {
        let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if authStatus == .denied {
        
        }
        else if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { (granted: Bool) in
                if (granted) {
                    // Allowed access to camera, go ahead and present the UIImagePickerController.
                    self.showImagePickerForSourceType(sourceType: .camera, fromButton: sender)
                }
            }
        }
        else {
            self.showImagePickerForSourceType(sourceType: .camera, fromButton: sender)
        }
    }
    
    private func finishAndUpdate() {
        self.dismiss(animated: true) {
            if let url = self.videoURL{
                let player = AVPlayer(url: url)
                let playerController = AVPlayerViewController()
                
                playerController.player = player
                self.present(playerController, animated: true, completion: {
                    print ("I present myself")
                })
                //self.addChildViewController(playerController)
                //self.view.addSubview(playerController.view)
                //playerController.view.frame = self.view.frame
                // could alternatively grab the imageView's frame
                
                player.play()
                self.videoURL = nil 
            }
            else {
                print("Error getting url from picked asset")
            }
        }
        if self.capturedImages.count > 0 {
            if self.capturedImages.count == 1 {
                self.imageView.image = self.capturedImages[0]
            }
            else {
                self.imageView.animationImages = self.capturedImages
                self.imageView.animationDuration = 5.0
                self.imageView.animationRepeatCount = 0
                self.imageView.startAnimating()
            }
        }
        self.capturedImages.removeAll()
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        switch info[UIImagePickerControllerMediaType] as! String{
            
        case String(kUTTypeImage):
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.capturedImages.append(image)
            }
            
            if let timer = self.cameraTimer,
                timer.isValid {
                print("continuing to snap until the user hits done")
                return
            }
            
            self.finishAndUpdate()
            
        case String(kUTTypeMovie):
            
            if let url = info[UIImagePickerControllerMediaURL] as? URL {
                self.videoURL = url
               // let player = AVPlayer(url: url)
                //let playerController = AVPlayerViewController()
                
                //playerController.player = player
                //self.present(playerController, animated: true, completion: {
                    //print ("I present myself")
                //})
                //self.addChildViewController(playerController)
                //self.view.addSubview(playerController.view)
                //playerController.view.frame = self.view.frame
                // could alternatively grab the imageView's frame
                
               // player.play()
            }
            else {
                print("Error getting url from picked asset")
            }
        default:
            print("Bad Media Type")
        }
          self.finishAndUpdate()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Overlay Actions
    @IBAction func done(sender: UIBarButtonItem) {
        if let timer = self.cameraTimer,
            timer.isValid {
            timer.invalidate()
        }
        self.finishAndUpdate()
    }
    
    @IBAction func takePhoto(sender: UIBarButtonItem) {
        self.imagePickerController.takePicture()
    }
    
    @IBAction func delayedTakePhoto(sender: UIBarButtonItem) {
        self.doneButton.isEnabled = false
        self.takePictureButton.isEnabled = false
        self.delayedPhotoButton.isEnabled = false
        self.startStopButton.isEnabled = false
        
        let fireDate = Date(timeIntervalSinceNow: 5.0)
        let cameraTimer = Timer(fireAt: fireDate, interval: 1.0, target: self, selector: #selector(timedPhotoFire(timer:)), userInfo:nil, repeats: false)
        
        RunLoop.main.add(cameraTimer, forMode: .defaultRunLoopMode)
        self.cameraTimer = cameraTimer
    }
    
    @IBAction func startTakingPicturesAtIntervals(sender: UIBarButtonItem) {
        self.startStopButton.title = NSLocalizedString("Stop", comment: "Why is this suddenly so important")
        self.startStopButton.action = #selector(stopTakingPicturesAtIntervals(sender:))
        self.doneButton.isEnabled = false
        self.delayedPhotoButton.isEnabled = false
        self.takePictureButton.isEnabled = false
        let cameraTimer = Timer(timeInterval: 1.5, target: self, selector: #selector(timedPhotoFire(timer:)), userInfo: nil, repeats: true)
        RunLoop.main.add(cameraTimer, forMode: .defaultRunLoopMode)
        cameraTimer.fire()
        self.cameraTimer = cameraTimer
    }
    
    @IBAction func stopTakingPicturesAtIntervals(sender: UIBarButtonItem) {
        self.cameraTimer?.invalidate()
        self.cameraTimer = nil
        self.finishAndUpdate()
    }
    
    // MARK: - Timer
    
    // Called by the timer to take a picture.
    func timedPhotoFire(timer: Timer) {
        self.imagePickerController.takePicture()
    }
}

