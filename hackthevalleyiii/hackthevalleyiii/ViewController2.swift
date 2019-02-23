//
//  ViewController2.swift
//  hackthevalleyiii
//
//  Created by Alexander Chudinov on 2019-02-23.
//  Copyright © 2019 Alexander Chudinov. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase
import CoreMotion
import CoreLocation

class ViewController2: UIViewController {
    
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var tempImageView: UIImageView!
    var lastPoint = CGPoint.zero
    var color = UIColor.black
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    var swiped = false
    
    let motion = CMMotionManager()
    let queue = OperationQueue()
    var sensorData = [0.0,0.0,0.0]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startQueuedUpdates()
        startLocationTracking()
        // Do any additional setup after loading the view.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        swiped = false
        lastPoint = touch.location(in: view)
    }
    
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        UIGraphicsBeginImageContext(view.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        tempImageView.image?.draw(in: view.bounds)
        
        context.move(to: fromPoint)
        context.addLine(to: toPoint)
        
        context.setLineCap(.round)
        context.setBlendMode(.normal)
        context.setLineWidth(brushWidth)
        context.setStrokeColor(color.cgColor)
        
        context.strokePath()
        
        tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        tempImageView.alpha = opacity
        UIGraphicsEndImageContext()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        swiped = true
        let currentPoint = touch.location(in: view)
        drawLine(from: lastPoint, to: currentPoint)
        
        lastPoint = currentPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            // draw a single point
            drawLine(from: lastPoint, to: lastPoint)
        }
        
        // Merge tempImageView into mainImageView
        UIGraphicsBeginImageContext(mainImageView.frame.size)
        mainImageView.image?.draw(in: view.bounds, blendMode: .normal, alpha: 1.0)
        tempImageView?.image?.draw(in: view.bounds, blendMode: .normal, alpha: opacity)
        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        tempImageView.image = nil
    }
    
    @IBAction func onDrawingComplete(_ sender: Any) {
        self.locationManager.stopUpdatingLocation()
        self.isNeeded = false
        
        let local_uuid = UUID().uuidString
        let image = mainImageView.image

        let storageRef = FirebaseStorage.StorageReference().child("user_content/"+local_uuid+".png")
        storageRef.putData((image?.pngData())!)
        
        var databaseRef: DatabaseReference!
        databaseRef = Database.database().reference().child("user_content/\(local_uuid)")
        databaseRef.child("sensorData").setValue(["roll":sensorData[0],
                                                  "pitch":sensorData[1],
                                                  "yaw":sensorData[2]])
        databaseRef.child("location").setValue(["latitude":locationManager.location?.coordinate.latitude,
                                                "longitude":locationManager.location?.coordinate.longitude])
    }
    
    @IBAction func onResetImage(_ sender: Any) {
        mainImageView.image = nil
    }
    
    let locationManager = CLLocationManager()
    func startLocationTracking(){
        locationManager.delegate = self as? CLLocationManagerDelegate
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    var isNeeded = true
    func startQueuedUpdates() {
        if motion.isDeviceMotionAvailable {
            self.motion.deviceMotionUpdateInterval = 1.0 / 60.0
            self.motion.showsDeviceMovementDisplay = true
            self.motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical,
                                                 to: self.queue, withHandler: { (data, error) in
                                                    // Make sure the data is valid before accessing it.
                                                    if let validData = data{
                                                        if self.isNeeded==true{
                                                            self.sensorData[0] = validData.attitude.roll
                                                            self.sensorData[1] = validData.attitude.pitch
                                                            self.sensorData[2] = validData.attitude.yaw
                                                        }
                                                        // Get the altitude relative to the magnetic north reference frame.
                                                    }
            })
        }
    }
}
