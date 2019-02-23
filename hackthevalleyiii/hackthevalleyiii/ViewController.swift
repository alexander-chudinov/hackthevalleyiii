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
import Firebase
import FirebaseStorage

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        //sceneView.showsStatistics = true
        //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        //sceneView.scene = scene
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

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    @IBAction func onNewDrawing(_ sender: Any) {}
    
    
}
