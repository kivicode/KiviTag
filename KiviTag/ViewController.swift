//
//  ViewController.swift
//  KiviTag
//
//  Created by Hiroki Ishiura on 2019/08/08.
//  Copyright (c) 2019 KoviCpde. All rights reserved.
//

import UIKit
import AVFoundation

extension String {
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var neuralNet: NeuralNet!
    
    var onTest: String = ""
    
    var testCounter: Int = 0
    
    @IBOutlet weak var label: UILabel!
	
	@IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var digitsView: UIImageView!
	
	var session: AVCaptureSession!
	var device: AVCaptureDevice!
	var output: AVCaptureVideoDataOutput!
    
    
    var detect = !false
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        do {
            guard let url = Bundle.main.url(forResource: "neuralnet-mnist-trained", withExtension: nil) else {
                    fatalError("Unable to locate trained neural network file in bundle.")
                }
            neuralNet = try NeuralNet(url: url)
        } catch {
            fatalError("\(error)")
        }
    
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
        
		// Prepare a video capturing session.
		self.session = AVCaptureSession()
		self.session.sessionPreset = AVCaptureSession.Preset.vga640x480 // not work in iOS simulator
		self.device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
		if (self.device == nil) {
			print("no device")
			return
		}
		do {
			let input = try AVCaptureDeviceInput(device: self.device)
			self.session.addInput(input)
		} catch {
			print("no device input")
			return
		}
		self.output = AVCaptureVideoDataOutput()
		self.output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA) ]
		let queue: DispatchQueue = DispatchQueue(label: "videocapturequeue", attributes: [])
		self.output.setSampleBufferDelegate(self, queue: queue)
		self.output.alwaysDiscardsLateVideoFrames = true
		if self.session.canAddOutput(self.output) {
			self.session.addOutput(self.output)
		} else {
			print("could not add a session output")
			return
		}
		do {
			try self.device.lockForConfiguration()
			self.device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 20) // 20 fps
			self.device.unlockForConfiguration()
		} catch {
			print("could not configure a device")
			return
		}
		
		self.session.startRunning()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	override var shouldAutorotate : Bool {
		return false
	}
    
    fileprivate func scale(_ image: UIImage, to: CGSize) -> UIImage {
        let size = CGSize(width: min(20 * image.size.width / image.size.height, 20),
                          height: min(20 * image.size.height / image.size.width, 20))
        let newRect = CGRect(x: 0, y: 0, width: size.width, height: size.height).integral
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()
        context?.interpolationQuality = .none
        image.draw(in: newRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    fileprivate func addBorder(to image: UIImage) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 28, height: 28))
        image.draw(at: CGPoint(x: (28 - image.size.width) / 2,
                               y: (28 - image.size.height) / 2))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    private func scanImage(img: UIImage) -> [Float]? {
        var pixelsArray = [Float]()
        
        let scaledImage = scale(img, to: CGSize(width: 20, height: 20))
        
        // Center sketch in 28x28 white box
        let character = addBorder(to: scaledImage)
        
        // Dispaly character in view
        // Extract pixel data from scaled/cropped image
        guard let cgImage = character.cgImage else { return nil }
        guard let pixelData = cgImage.dataProvider?.data else { return nil }
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        
        // Iterate through
        var position = 0
        for _ in 0..<Int(character.size.height) {
            for _ in 0..<Int(character.size.width) {
                // We only care about the alpha component
                let alpha = Float(data[position + 3])
                // Scale alpha down to range [0, 1] and append to array
                pixelsArray.append(alpha / 255)
                // Increment position
                position += bytesPerPixel
            }
            if position % bytesPerRow != 0 {
                position += (bytesPerRow - (position % bytesPerRow))
            }
        }
        return pixelsArray
    }
	
	func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		
		// Convert a captured image buffer to UIImage.
		guard let buffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			print("could not get a pixel buffer")
			return
		}
		CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
		let image = CIImage(cvPixelBuffer: buffer).oriented(CGImagePropertyOrientation.right)
		let capturedImage = UIImage(ciImage: image)
		CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
		
        let resultImage = OpenCV.process(capturedImage)
        
        if(OpenCV.shouldCheck() == 1 && detect){
            let num = OpenCV.numberOfDigits()
            var outp = ""
            if(num > 0) {
                for i in 0..<min(num, 5) {
                    let numbers = OpenCV.getNumberImage(Int32(i))
                    outp += classify(inp: numbers)
                }
            }
            if(outp != onTest){
                testCounter += 1
            } else {
                testCounter = 0
            }
            if(testCounter >= 4) {
                onTest = outp
                testCounter = 0
                DispatchQueue.main.sync(execute: {
                    self.label.text = String(outp)
                })
            }
        }
        // Show the result.
        DispatchQueue.main.async(execute: {
            self.imageView.image = resultImage
        })
	}
    
    func classify(inp: UIImage) -> String{
        guard let imageArray = scanImage(img: inp) else { return ""}
        
        // Perform classification
        do {
            let output = try neuralNet.infer(imageArray)
            if let (label, _) = label(from: output) {
                DispatchQueue.main.async(execute: {
                    self.digitsView.image = inp
                })
                return String(label)
            } else {
                return "Err"
            }
        } catch {
            print(error)
        }
        return "ERR"
    }
    
    private func label(from output: [Float]) -> (label: Int, confidence: Float)? {
        guard let max = output.max() else { return nil }
        return (output.firstIndex(of: max)!, max)
    }
    
    
    
    @objc func doubleTapped() {
        detect = !detect
    }
}

