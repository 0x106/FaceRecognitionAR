//
//  Card.swift
//  Nebula
//
//  Created by Jordan Campbell on 15/02/18.
//  Copyright © 2018 Atlas Innovation. All rights reserved.
//

import Foundation
import ARKit

let top = 0
let left = 1
let right = 2
let bottom = 3

class VirtualLabel {
  
  var text: String = ""
  
  var onTapCallback: (() -> ())?
  
  // AR properties
  var rootNode = SCNNode()
  var geometry: SCNPlane?
  var x: Float = 0.0
  var y: Float = 0.0
  var totalWidth: Float = 0.0
  var totalHeight: Float = 0.0
  let scale: Float = 0.001
  
  var marginSize: [Float] = [0.0, 0.0, 0.0, 0.0]
  var paddingSize: [Float] = [0.0, 0.0, 0.0, 0.0]
  var borderSize: [Float] = [0.0, 0.0, 0.0, 0.0]
  var border: [CGRect] = [CGRect(), CGRect(), CGRect(), CGRect()]
  
  // display properties
  var cell: CGRect = CGRect()
  var nucleus: CGRect = CGRect()
  var image: UIImage?
  
  var font: UIFont = UIFont()
  var font_size: Float = 0.0
  var font_weight: Float = 0.0
  
  var color: UIColor = UIColor()
  var backgroundColor: UIColor = UIColor()
  var borderColor: [UIColor] = [UIColor(), UIColor(), UIColor(), UIColor()]
  var cornerRadius: Float = 0.0
  
  var canRender: Bool = true
  var canDrawOverlay: Bool = true
  var textAlignment: String = "left"
  var allow_auto_resize: Bool = true
  var isButton: Bool = false
  
  init(theme: String = "", text: String = "Label") {
    
    for idx in 0...3 {
      self.border[idx] = CGRect(x: 0, y: 0, width: 0, height: 0)
    }
    
    for idx in 0...3 {
      self.borderColor[idx] = UIColor.white.withAlphaComponent(CGFloat(0.0))
    }
    
    self.color = UIColor.black.withAlphaComponent(CGFloat(1.0))
    
    self.theme(theme)
    self.text = text
    
    _ = self.render()
    
    self.setPivotLocation()
    
    self.rootNode.name = UUID().uuidString
  }
  
  func setBorder(_ _colour: UIColor, _ _size: Float, _ _border:Int = -1) {
    
    if _border == -1 {
      self.borderSize = [_size, _size, _size, _size]
      self.borderColor = [_colour, _colour, _colour, _colour]
    } else {
      self.borderSize[_border] = _size
      self.borderColor[_border] = _colour
    }
  }
  
  func render() -> Bool {
    
    // if the image is / will be drawn then we don't need to render anything
    if !self.canDrawOverlay {return true}
    
    let paragraphStyle = NSMutableParagraphStyle()
    if self.textAlignment == "left" { paragraphStyle.alignment = .left }
    if self.textAlignment == "center" { paragraphStyle.alignment = .center }
    
    let fontAttrs: [NSAttributedString.Key: Any] =
      [NSAttributedString.Key.font: self.font as UIFont,
       NSAttributedString.Key.paragraphStyle: paragraphStyle,
       NSAttributedString.Key.foregroundColor: self.color]
    
    if self.allow_auto_resize {
      self.resizeToText(fontAttrs)
    }
    
    self.border[top] = CGRect(x: CGFloat(self.marginSize[left]),
                              y: CGFloat(self.marginSize[top]),
                              width: CGFloat(self.cell.width),
                              height: CGFloat(self.borderSize[top]))
    
    self.border[left] = CGRect(x: CGFloat(self.marginSize[left]),
                               y: CGFloat(self.marginSize[top]),
                               width: CGFloat(self.borderSize[left]),
                               height: CGFloat(self.cell.height))
    
    self.border[right] = CGRect(x: self.cell.width - CGFloat(self.borderSize[right]),
                                y: CGFloat(self.marginSize[top]),
                                width: CGFloat(self.borderSize[right]),
                                height: CGFloat(self.cell.height))
    
    self.border[bottom] = CGRect(x: CGFloat(self.marginSize[left]),
                                 y: self.cell.height - CGFloat(self.borderSize[bottom]),
                                 width: CGFloat(self.cell.width),
                                 height: CGFloat(self.borderSize[bottom]))
    
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: CGFloat(self.totalWidth), height: CGFloat(self.totalHeight)))
    self.image = renderer.image { [unowned self] context in
      
      self.backgroundColor.setFill()
      context.fill(self.cell)
      
      self.borderColor[top].setFill()
      context.fill(self.border[top])
      
      self.borderColor[left].setFill()
      context.fill(self.border[left])
      
      self.borderColor[right].setFill()
      context.fill(self.border[right])
      
      self.borderColor[bottom].setFill()
      context.fill(self.border[bottom])
      
      if self.textAlignment == "center" {
        let stringSize = self.text.size(withAttributes: fontAttrs)
        let drawRect = CGRect(x: CGFloat((self.nucleus.width / 2.0) - (stringSize.width/2.0)),
                              y: CGFloat((self.nucleus.height / 2.0) - (stringSize.height/2.0)),
                              width: CGFloat(stringSize.width),
                              height: CGFloat(stringSize.height))
        self.text.draw(with: drawRect, options: .usesLineFragmentOrigin, attributes: fontAttrs, context: nil)
      } else {
        self.text.draw(with: self.nucleus, options: .usesLineFragmentOrigin, attributes: fontAttrs, context: nil)
      }
    }
    
    self.geometry = SCNPlane(width: CGFloat(self.totalWidth * self.scale), height: CGFloat(self.totalHeight * self.scale))
    self.geometry?.firstMaterial?.diffuse.contents = self.image
    
    self.geometry?.cornerRadius = CGFloat(self.cornerRadius)
    
    self.rootNode.geometry = self.geometry
    self.rootNode.geometry?.firstMaterial?.isDoubleSided = true
    
    return true
  }
  
  func shift(camera: ARCamera) {
    var translation = matrix_identity_float4x4
    translation.columns.3.z = -1.0 // Translate 10 cm in front of the camera
    self.rootNode.simdTransform = matrix_multiply(camera.transform, translation)
    
    self.rootNode.eulerAngles = SCNVector3Make(camera.eulerAngles.x,
                                               camera.eulerAngles.y,
                                               camera.eulerAngles.z + (.pi/2.0))
  }
  
  private func resizeToText(_ _fontAttrs: [NSAttributedString.Key: Any]) {
    
    // get the size of the text
    let stringSize = self.text.size(withAttributes: _fontAttrs)
    
    self.cell = CGRect(x: CGFloat(self.marginSize[left]), y: CGFloat(self.marginSize[bottom]),
                       width: CGFloat(stringSize.width) + CGFloat(self.paddingSize[left]) + CGFloat(self.paddingSize[right]),
                       height: CGFloat(stringSize.height) + CGFloat(self.paddingSize[top]) + CGFloat(self.paddingSize[bottom]))
    self.nucleus = CGRect(x: CGFloat(self.paddingSize[left]),
                          y: CGFloat(self.paddingSize[bottom]),
                          width: CGFloat(stringSize.width),
                          height: CGFloat(stringSize.height))
    
    self.totalWidth = Float(stringSize.width) + Float(self.paddingSize[left]) + Float(self.paddingSize[right]) + Float(self.marginSize[left]) + Float(self.marginSize[right])
    self.totalHeight = Float(stringSize.height) + Float(self.paddingSize[top]) + Float(self.paddingSize[bottom]) + Float(self.marginSize[top]) + Float(self.marginSize[bottom])
  }
  
  func setFont(_ selectedFont: String, _ size: Float) {
    self.font = UIFont(name: selectedFont, size: CGFloat(size))!
  }
  
  func setText(text: String) {
    self.text = text
    let _ = self.render()
  }
  
  func setPivotLocation(location: PivotLocation = .center ) {
    
    let (minBound, maxBound) = self.rootNode.boundingBox
    var x: Float = 0
    var y: Float = 0
    
    switch location {
    case .center:
      x = minBound.x + (maxBound.x - minBound.x)/2
      y = minBound.y + (maxBound.y - minBound.y)/2
      
    case .topLeft:
      x = minBound.x
      y = maxBound.y
    case .topRight:
      x = maxBound.x
      y = maxBound.y
    case .bottomLeft:
      x = minBound.x
      y = minBound.y
    case .bottomRight:
      x = maxBound.x
      y = minBound.y
      
    case .leftMid:
      x = minBound.x
      y = minBound.y + (maxBound.y - minBound.y)/2
    case .rightMid:
      x = maxBound.x
      y = minBound.y + (maxBound.y - minBound.y)/2
    case .topMid:
      x = minBound.x + (maxBound.x - minBound.x)/2
      y = maxBound.y
    case .bottomMid:
      x = minBound.x + (maxBound.x - minBound.x)/2
      y = minBound.y
    }
    self.rootNode.pivot = SCNMatrix4MakeTranslation( x, -y, 0.0 )
  }
  
  func click() {
    if let cb = self.onTapCallback {
      cb()
    }
  }
  
  func onTap(callback: @escaping () -> ()) {
    self.onTapCallback = callback
  }
}

extension VirtualLabel {
  func theme(_ _theme: String) {
    switch _theme {
    case "neuromancer":
      self.backgroundColor = zeroColor //randomColour()
      self.color = platinum
      self.setFont("Arial", 100.0)
      self.textAlignment = "left"
      
    case "wintermute":
      self.backgroundColor = zeroColor
      self.color = platinum
      self.setFont("Arial", 60.0)
      self.textAlignment = "left"
      self.paddingSize[left] = 100.0
      self.paddingSize[right] = 100.0
      self.paddingSize[top] = 50.0
      self.paddingSize[bottom] = 50.0
      
      
    case "leaderBoardName":
      self.backgroundColor = UIColor(rgb: 0x13293D)
      self.color = platinum
      self.setFont("Arial", 100.0)
      self.textAlignment = "left"
      self.paddingSize[top] = 20.0
      self.paddingSize[left] = 20.0
      self.paddingSize[right] = 20.0
      self.paddingSize[bottom] = 20.0
      
    case "towerLabel":
      self.backgroundColor = UIColor(rgb: 0x13293D)
      self.backgroundColor = UIColor(rgb: 0xEE4266)
      self.color = platinum
      self.setFont("Arial", 100.0)
      self.textAlignment = "left"
      self.paddingSize[top] = 20.0
      self.paddingSize[left] = 20.0
      self.paddingSize[right] = 20.0
      self.paddingSize[bottom] = 20.0
      self.cornerRadius = 0.05
      
    case "leaderBoardTitle":
      self.backgroundColor = zeroColor
      self.color = platinum
      self.setFont("Arial", 140.0)
      self.textAlignment = "left"
      self.paddingSize[bottom] = 60.0
      self.marginSize[bottom] = 40.0
      self.borderSize[bottom] = 10.0
      self.borderColor[bottom] = UIColor(rgb: 0xCC2936)
      
    case "leaderBoardScore":
      self.backgroundColor = UIColor(rgb: 0x13293D)
      self.color = platinum
      self.setFont("Arial", 100.0)
      self.textAlignment = "left"
      self.paddingSize[left] = 100.0
      self.paddingSize[right] = 20.0
      
      self.paddingSize[top] = 20.0
      self.paddingSize[bottom] = 20.0
      
    case "button":
      self.backgroundColor = cgBlue
      self.color = platinum
      self.setFont("Arial", 200.0)
      self.textAlignment = "left"
      self.cornerRadius = 0.05
      self.paddingSize[left] = 100.0
      self.paddingSize[right] = 100.0
      self.paddingSize[top] = 50.0
      self.paddingSize[bottom] = 50.0
      self.isButton = true
      self.rootNode.scale = SCNVector3Make(0.5, 0.5, 0.5)
      
    case "button_02":
      self.backgroundColor = zeroColor
      self.color = platinum
      self.setFont("Arial", 200.0)
      self.textAlignment = "left"
      self.cornerRadius = 0.01
      self.paddingSize[left] = 100.0
      self.paddingSize[right] = 100.0
      self.paddingSize[top] = 50.0
      self.paddingSize[bottom] = 50.0
      self.borderColor = [platinum, platinum, platinum, platinum]
      self.borderSize = [10.0, 10.0, 10.0, 10.0]
      self.isButton = true
      self.rootNode.scale = SCNVector3Make(0.5, 0.5, 0.5)
      
    case "editButton":
      self.backgroundColor = periwinkle
      self.color = platinum
      self.setFont("Arial", 80.0)
      self.textAlignment = "left"
      self.cornerRadius = 10.0
      self.paddingSize[left] = 75.0
      self.paddingSize[right] = 75.0
      self.paddingSize[top] = 30.0
      self.paddingSize[bottom] = 30.0
      self.isButton = true
    case "playButton":
      self.backgroundColor = persianGreen
      self.color = platinum
      self.setFont("Arial", 80.0)
      self.textAlignment = "left"
      self.cornerRadius = 10.0
      self.paddingSize[left] = 75.0
      self.paddingSize[right] = 75.0
      self.paddingSize[top] = 30.0
      self.paddingSize[bottom] = 30.0
      self.isButton = true
    default:
      self.backgroundColor = zeroColor
      self.color = platinum
      self.setFont("Arial", 200.0)
      self.textAlignment = "left"
    }
    
  }
}

enum PivotLocation {
  case center
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight
  case leftMid
  case topMid
  case rightMid
  case bottomMid
}

extension UIColor {
  convenience init(red: Int, green: Int, blue: Int) {
    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
  }
  
  convenience init(rgb: Int) {
    self.init(
      red: (rgb >> 16) & 0xFF,
      green: (rgb >> 8) & 0xFF,
      blue: rgb & 0xFF
    )
  }
}

let burntOrange = UIColor(red: 0xF5, green: 0x5D, blue: 0x3E)
let palatinatePurple = UIColor(red: 0x68, green: 0x2D, blue: 0x63)
let tealBlue = UIColor(red: 0x38, green: 0x86, blue: 0x97)
let zeroColor = UIColor(red: 0x00, green: 0x00, blue: 0x00).withAlphaComponent(CGFloat(0.0))
let babyPowder = UIColor(red: 0xFE, green: 0xFC, blue: 0xFB)
let persianGreen = UIColor(red: 0x00, green: 0xA6, blue: 0xA6)
let ghostWhite = UIColor(red: 0xF8, green: 0xF7, blue: 0xFF)
let periwinkle = UIColor(red: 0xB8, green: 0xB8, blue: 0xFF)
let cgBlue = UIColor(red: 0x12, green: 0x82, blue: 0xA2)
let platinum = UIColor(red: 0xE6, green: 0xEB, blue: 0xE0)
let prussianBlue = UIColor(red: 0x00, green: 0x30, blue: 0x49)
let oxfordBlue = UIColor(red: 0x00, green: 0x1F, blue: 0x54)

func delay(time: Double, callback: @escaping () -> ()) {
  DispatchQueue.main.asyncAfter(deadline: .now() + time) {
    callback()
  }
}
