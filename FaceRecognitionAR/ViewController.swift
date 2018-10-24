//
//  ViewController.swift
//  FaceRecognitionAR
//
//  Created by Jordan Campbell on 23/10/18.
//  Copyright © 2018 Astro. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
  
  @IBOutlet var sceneView: ARSCNView!
  
  var sentinel: Sentinel!
  var frequency = 60
  var frameCounter = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Set the view's delegate
    sceneView.delegate = self
    sceneView.session.delegate = self
    
    // Show statistics such as fps and timing information
    sceneView.showsStatistics = true
    
    // Create a new scene
    let scene = SCNScene()
    
    // Set the scene to the view
    sceneView.scene = scene
    
    self.sentinel = Sentinel(scene: self.sceneView)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.sentinel?.touchActive = true
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.sentinel?.touchActive = false
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    
    // Run the view's session
    sceneView.session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Pause the view's session
    sceneView.session.pause()
  }
  
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    if frameCounter % frequency == 0 {
      self.sentinel.run(frame)
    }
    frameCounter += 1
  }
}



