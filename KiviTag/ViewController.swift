//
//  ViewController.swift
//  KiviTag
//
//  Created by KiviCode on 2019/08/08.
//  Copyright (c) 2019 KiviCode. All rights reserved.
//

import UIKit
import AVFoundation

extension String {
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
}

struct defaultsKeys {
    static let settingsFrom = "settingsFrom"
    static let settingsTo   = "settingsTo"
    static let settingsInk  = "settingsInk"
    static let settingsRateList  = "settingsRateList"
    static let settingsRateDict  = "settingsRateDict"
    static let settingsCalcMemory  = "settingsCalcMemory"
    static let settingsCalcBase  = "settingsCalcBase"
    
    static var ratesDef: [String]     = []
    static var rates: [String: Double] = [:]
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var rates = [
        "EUR": 1.0,
        "RUB": 73.82,
        "PL": 4.36325
    ]
    
    var converted: Float = 0.0
    
    var neuralNet: NeuralNet!
    
    var onTest: String = ""
    
    var goal = "[Fail]"
    
    var testCounter: Int = 0
    
    @IBOutlet weak var label: UILabel!
	
	@IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var digitsView: UIImageView!
	
	var session: AVCaptureSession!
	var device: AVCaptureDevice!
	var output: AVCaptureVideoDataOutput!
    
    
    var detect = !false
    
    var once = false
    
    var sizeOfRect: CGPoint = CGPoint(x: 300, y: 150)
    var center: CGPoint = CGPoint(x: 0, y: 0)
    
    var roiW: Int = 300
    var roiH: Int = 150
    
    @IBOutlet weak var SumLabel: UILabel!
    
    @IBAction func ClearMemory(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(Float(0.0), forKey: defaultsKeys.settingsCalcMemory)
        updateMemory()
    }
    
    @IBAction func PlusToMemory(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set((UserDefaults.standard.float(forKey: defaultsKeys.settingsCalcMemory) ) + Float(converted), forKey: defaultsKeys.settingsCalcMemory)
        updateMemory()
    }
    override func viewDidLoad() {
		super.viewDidLoad()
        
        
        let defaults = UserDefaults.standard
        defaultsKeys.rates = (defaults.dictionary(forKey: defaultsKeys.settingsRateDict) ?? [:]) as! [String: Double]
        defaultsKeys.ratesDef = (defaults.array(forKey: defaultsKeys.settingsRateList) ?? []) as! [String]
        request()
        
        updateMemory()
        
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
        
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        
        
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
//            self.device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 60) // 20 fps
			self.device.unlockForConfiguration()
		} catch {
			print("could not configure a device")
			return
		}
		
		self.session.startRunning()
	}
    
    func updateMemory(){
        var t  = "EUR"
        if let to = UserDefaults.standard.string(forKey: defaultsKeys.settingsTo) {
            t = to
        }
        if let mem: Float = UserDefaults.standard.float(forKey: defaultsKeys.settingsCalcMemory) {
                SumLabel.text = "Sum: \(Float(round(100 * mem) / 100)) \(t)"
        }
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
        let useEINK = UserDefaults.standard.bool(forKey: defaultsKeys.settingsInk)
		// Convert a captured image buffer to UIImage.
		guard let buffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			print("could not get a pixel buffer")
			return
		}
		CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
		let image = CIImage(cvPixelBuffer: buffer).oriented(CGImagePropertyOrientation.right)
		let capturedImage = UIImage(ciImage: image)
		CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
		
        let resultImage = useEINK ? OpenCV.processEink(capturedImage) : OpenCV.process(capturedImage)
        
//        if(OpenCV.shouldCheck() == 1 && detect){
////            resultImage = OpenCV.process(resultImage, false)
//            DispatchQueue.main.async(execute: {
//                self.digitsView.image = OpenCV.getNumberImage(0);
//            })
//        }
        
        ///*
        
        if(OpenCV.shouldCheck() == 1 && detect){
            let num = OpenCV.numberOfDigits()
            var outp = ""
            if(num > 0) {
                for i in 0..<min(num, 5) {
                    let numbers = OpenCV.getNumberImage(Int32(i))
                    outp = classify(inp: numbers) + outp;
                }
            }
            if(outp != onTest){
                testCounter += 1
            } else {
                testCounter = 0
            }
            if(testCounter >= 7) {
                onTest = outp
                testCounter = 0
                
                DispatchQueue.main.sync(execute: {
                    let defaults = UserDefaults.standard

                    var frm = "EUR"
                    var t  = "EUR"
                    if let from = defaults.string(forKey: defaultsKeys.settingsFrom) {
                        frm = from
                    }
                    if let to = defaults.string(forKey: defaultsKeys.settingsTo) {
                        t = to
                    }
                    var cnv = (((Float(outp) ?? 0) / 100) / Float(rates[frm] ?? 1) * Float(rates[t] ?? 1))
                    cnv = Float(round(100 * cnv) / 100)
                    let reg = Float(round(Float(outp) ?? 0) / 100)
                    converted = cnv
//                    self.label.text = "{\(useEINK ? "E-Ink" : "Reg")} \(reg) [\(frm)] -> \(cnv) [\(t)]"
                    self.label.text = "\(reg)[\(frm)] -> \(cnv)[\(t)]"
                })
            }
        }
         //*/
        // Show the result.
        DispatchQueue.main.async(execute: {
            self.imageView.image = resultImage
            self.center =  CGPoint(x: self.imageView.frame.width/2, y: self.imageView.frame.height/2)

        })
	}
    
    func classify(inp: UIImage) -> String{
        guard let imageArray = scanImage(img: inp) else { return ""}
        
        // Perform classification
        do {
            let output = try neuralNet.infer(imageArray)
            if let (label, _) = label(from: output) {
//                DispatchQueue.main.async(execute: {
//                    self.digitsView.image = inp
//                })
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
    
    var swapRight = true
    
    @objc func handleSwipes(_ sender:UISwipeGestureRecognizer) {
        request()
    }
    
    func request(){
        let url = URL(string: "https://api.exchangeratesapi.io/latest")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                var ratesList = Array((responseJSON["rates"] as! [String: Double]).keys)
                ratesList.append("EUR")
                ratesList = ratesList.sorted(by: <)
                defaultsKeys.rates = responseJSON["rates"] as! [String: Double]
                defaultsKeys.rates["EUR"] = Double(1)
                self.rates = defaultsKeys.rates
                defaultsKeys.ratesDef = ratesList
                let defaults = UserDefaults.standard
                defaults.set(defaultsKeys.rates, forKey: defaultsKeys.settingsRateDict)
                defaults.set(defaultsKeys.ratesDef, forKey: defaultsKeys.settingsRateList)
            }
        }
        
        task.resume()
    }
    
    var locationOfBeganTap: CGPoint = CGPoint(x: 0, y: 0)
    var locationOfEndTap: CGPoint   = CGPoint(x: 0, y: 0)
    @IBAction func panDetector(_ gesture: UIPanGestureRecognizer) {
        let finger: CGPoint = gesture.location(in: self.view)
        
        if gesture.state == UIGestureRecognizer.State.began {
            locationOfBeganTap = finger
        } else if gesture.state == UIGestureRecognizer.State.ended {
            locationOfEndTap = finger
            if(distance(locationOfBeganTap, locationOfEndTap) >= 50){
                locationOfBeganTap = finger
                OpenCV.setROI(OpenCV.getROIWidth() == 300 ? 150 : 300, hei: 150)
            }
        }
    }
    
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
}

