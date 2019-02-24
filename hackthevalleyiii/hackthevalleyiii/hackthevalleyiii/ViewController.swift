//
//  ViewController.swift
//  hackthevalleyiii
//
//  Created by Alexander Chudinov on 2019-02-22.
//  Copyright © 2019 Alexander Chudinov. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreMotion
import FirebaseDatabase
import FirebaseStorage
import CoreLocation
import FirebaseAuth

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var uidLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        Auth.auth().signInAnonymously() { (authResult, error) in
            let user = authResult?.user
            self.uidLabel.text = user?.uid
        }
        generateScene()
        CMMotionManager().startAccelerometerUpdates(to: OperationQueue.current!, withHandler: { data, error in
            guard error == nil else { return }
            guard let accelerometerData = data else { return }
            print(accelerometerData.acceleration)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        //generate the scene (fetch all entries using firebase storage)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    @IBAction func onNewDrawing(_ sender: Any) {self.locationManager.stopUpdatingLocation()}
    struct dataEntry {
        var location : Dictionary<String, Any>
        var sensorData : Array<Double>
    }
    
    let globalScene = SCNScene()
    struct LocationObject{
        var latitude = String.self
        var longitude = String.self
    }
    
    func appendToScene(coords: Any?, sensorData: Any?, uuid: String){
        if((coords as? NSDictionary)?.object(forKey: "latitude") != nil){
            let p = [(coords as! NSDictionary).object(forKey: "latitude")!,
                     (coords as! NSDictionary).object(forKey: "longitude")!,
                     (coords as! NSDictionary).object(forKey: "altitude")!]
            let s = [(sensorData as! NSDictionary).object(forKey: "pitch")!,
                    (sensorData as! NSDictionary).object(forKey: "roll")!,
                    (sensorData as! NSDictionary).object(forKey: "yaw")!]
            let h = locationManager.location?.coordinate
            let geometry = SCNPlane.init(width: 0.099*2, height: 0.214*2)
            
            let texture = SCNMaterial()
            var image = UIImage(named: "art.scnassets/placeholder.jpg")
            
            let storageRef = FirebaseStorage.StorageReference().child("user_content/\(uuid).png")
            storageRef.getData(maxSize: 2 * 1024 * 1024) { data, error in
                if let error = error {
                    print(error.localizedDescription)
                    
                } else {
                    image = UIImage(data: data!)
                    texture.diffuse.contents = image
                    geometry.materials = [texture]
                    geometry.firstMaterial?.isDoubleSided = true
                    geometry.material(named: "texture")?.isDoubleSided = true
                    let frame = SCNNode(geometry: geometry)
                    
                    let longDistance = ((h?.longitude)!) - (p[1] as! Double)
                    let latDistance = ((h?.latitude)!) - (p[0] as! Double)
                    let altDistance = (self.locationManager.location?.altitude)! - (p[2] as! Double)
                    
                    print(longDistance)
                    print(latDistance)
                    print(altDistance)
                    
                    frame.position.x = Float(longDistance)
                    frame.position.y = Float(latDistance)
                    frame.position.z = Float(altDistance)
                    
                    frame.eulerAngles.x = Float(s[1] as! Double)
                    frame.eulerAngles.y = Float(s[0] as! Double)
                    frame.eulerAngles.z = Float(s[2] as! Double)
                self.globalScene.rootNode.addChildNode(frame)
                }
            }
        }
    }
    
    func generateScene(){
        var databaseRef: DatabaseReference!
        databaseRef = Database.database().reference().child("user_content")
        databaseRef.observe(DataEventType.value, with: { (snapshot) in
            let response = snapshot.value as? NSDictionary
            let entryKeys = [response?.allKeys][0]
            for i in 0...((entryKeys?.count)!)-1 {
                let entryValue = response!.object(forKey: entryKeys?[i]as Any)as! NSDictionary
                let location = entryValue.object(forKey: "location")
                let sensorData = entryValue.object(forKey: "sensorData")
                self.appendToScene(coords: location, sensorData: sensorData, uuid: entryKeys?[i] as! String)
            }
            self.sceneView.scene = self.globalScene
        }) { (error) in
            print(error.localizedDescription)
        }
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
    
}
