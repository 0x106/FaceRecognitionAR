//
//  Sentinel.swift
//  FaceRecognitionAR
//
//  Created by Jordan Campbell on 23/10/18.
//  Copyright © 2018 Astro. All rights reserved.
//

import ARKit
import Vision

class Sentinel {
  
  var sceneView: ARSCNView
  var runRecognition = true
  var wrapper = DlibWrapper()
  var people = Dictionary<String, [[Float]]>()
  var key: String?
  var touchActive = false
  var labels = Dictionary<String, VirtualLabel>()
  var image: UIImage?
  
  init(scene _scnview: ARSCNView) {
    self.sceneView = _scnview
    self.runRecognition = true
  }
  
  func run(_ frame: ARFrame) {
    
    // create a reference to the current frame
    self.image = (frame.capturedImage.uiImage())
    
    // begin the recognition process
    self.createVisionRequest()
  }
  
  func createVisionRequest() {
    
    guard let currentImage = self.image else { return }
    
    // 1. Create vision handler to register detected Faces
    let visionHandler = VNDetectFaceRectanglesRequest { (request, error) in
      DispatchQueue.main.async {
        if let faces = request.results as? [VNFaceObservation] {
          for face in faces {
            self.detectionHandler(face)
          }
        }
      }
    }
    
    // 2. create vision request
    DispatchQueue.global(qos: .userInteractive).async {
      if let ciimage = CIImage.init(image: currentImage) {
        try? VNImageRequestHandler(ciImage: ciimage, orientation: imageOrientation).perform([visionHandler])
      }
    }
  }
  
  // 3. Add detection handler to extract the roi from the observation
  func detectionHandler(_ observation: VNFaceObservation) {
    
    guard let currentImage = self.image else { return }

    // 4. Get the 3d position of the detected face
    let size = CGSize(width: observation.boundingBox.width * self.sceneView.bounds.width,
                      height: observation.boundingBox.height * self.sceneView.bounds.height)
    let origin = CGPoint(x: observation.boundingBox.origin.x * self.sceneView.bounds.width,
                         y: (1 - observation.boundingBox.origin.y) * self.sceneView.bounds.height - size.height)
    let bounds = CGRect(origin: origin, size: size)
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    
    var position: SCNVector3?
    
    if let hit = self.sceneView.hitTest(center, types: [ARHitTestResult.ResultType.featurePoint]).first {
      let hitTransform = SCNMatrix4.init(hit.worldTransform)
      position = SCNVector3Make(hitTransform.m41,
                                hitTransform.m42,
                                hitTransform.m43)
    }
    
    // ------------------------------------------------------//
    
    // 5. get the roi
    let iw = CGFloat( (currentImage.cgImage?.width)! )
    let ih = CGFloat( (currentImage.cgImage?.height)! )
    
    let width = observation.boundingBox.width * iw
    let height = observation.boundingBox.height * ih
    let x = observation.boundingBox.origin.x * iw
    let y = (1 - observation.boundingBox.origin.y) * ih - height
    
    let region = CGRect(x: x, y: y, width: width, height: height)
    
    self.recognitionHandler(region, position)
  }
  
  // 6. Run face recognition given the image + detected region
  func recognitionHandler(_ rect: CGRect, _ position: SCNVector3?) {
    
    guard let currentImage = self.image else { return }
    
    if self.runRecognition {
      self.runRecognition = false
      DispatchQueue.global(qos: .userInitiated).async {
        let pixelBuffer = buffer(from: currentImage)
        var embedding = [Float](repeating: 0, count: 128) // Buffer for C float array
        
        let _ = self.wrapper?.faceRecognition(pixelBuffer, with: &embedding, inRect: rect as NSValue)
        
        
        // if the user is tapping on the screen
        if self.touchActive {
          
          // if we have already started processing for this user
          if let _ = self.key {
          } else {
            // if this is the first frame for the new touch event
            // then initialise a new dictionary entry
//            self.key = uniqueID()
            
            if self.people.count == 0 {
              self.key = "Obama"
            }
            
            if self.people.count == 1 {
              self.key = "Trump"
            }
            
            self.people[ self.key! ] = [[Float]]()
            self.labels[ self.key! ] = VirtualLabel(theme: "wintermute", text: self.key!)
            if let node = self.labels[ self.key! ]?.rootNode {
              self.sceneView.scene.rootNode.addChildNode( node )
            } else {
              print("Can't get label node")
            }
            
            print("Added new person: \(self.key)")
          }
          
          self.people[ self.key! ]?.append(embedding)
          
        } else if let _ = self.key {
          // if we get in here then there is no longer a touch event,
          // but we did have a key, so set it back to nil
          self.key = nil
        }
        
        let closestMatch = self.match(embedding: embedding)
        if let position = position {
          self.labels[ closestMatch ]?.rootNode.position = position
        }
        
        // allow another frame to be processed
        self.runRecognition = true
      }
    }
  }
  
  func match(embedding: [Float]) -> String {
    
    var min: Float = 1e12
    var output = ""
    
    for person in self.people {
      var distance: Float = 0
      
      let _ = person.value.map {
        distance += (norm($0, embedding) / Float(person.value.count))
      }
      
      if distance < min {
        min = distance
        output = person.key
      }
    }
    
    return output
  }
  
  func norm(_ _X: [Float], _ _Y: [Float]) -> Float {
    var result: Float = 0.0
    for index in 0 ..< 128 {
      result += (_X[index] - _Y[index]) * (_X[index] - _Y[index])
    }
    result = sqrt(result)
    return result
  }
}
