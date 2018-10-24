//
//  Util.swift
//  FaceRecognitionAR
//
//  Created by Jordan Campbell on 24/10/18.
//  Copyright © 2018 Astro. All rights reserved.
//

import Foundation
import ARKit

// Need to get reference for this function
extension CVPixelBuffer {
  func uiImage() -> UIImage {
    let ciImage = CIImage(cvPixelBuffer: self)
    let context = CIContext(options: nil)
    let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
    let uiImage = UIImage(cgImage: cgImage!)
    return uiImage
  }
}

func buffer(from image: UIImage) -> CVPixelBuffer? {
  let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
  var pixelBuffer : CVPixelBuffer?
  let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
  guard (status == kCVReturnSuccess) else {
    return nil
  }
  
  CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
  let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
  
  let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
  let context = CGContext(data: pixelData,
                          width: Int(image.size.width),
                          height: Int(image.size.height),
                          bitsPerComponent: 8,
                          bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                          space: rgbColorSpace,
                          bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
  
  context?.translateBy(x: 0, y: image.size.height)
  context?.scaleBy(x: 1.0, y: -1.0)
  
  UIGraphicsPushContext(context!)
  image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
  UIGraphicsPopContext()
  CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
  
  return pixelBuffer
}

func uniqueID() -> String {
  return String((UUID().uuidString).split(separator: "-")[0])
}

var imageOrientation: CGImagePropertyOrientation {
  switch UIDevice.current.orientation {
  case .portrait: return .right
  case .landscapeRight: return .down
  case .portraitUpsideDown: return .left
  case .unknown: fallthrough
  case .faceUp: fallthrough
  case .faceDown: fallthrough
  case .landscapeLeft: return .up
  }
}
