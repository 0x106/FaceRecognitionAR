
//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

//
//  FaceRecognitionAR.h
//  FaceRecognitionAR
//
//  Created by Jordan Campbell on 23/10/18.
//  Copyright © 2018 Astro. All rights reserved.
//

//#ifndef FaceRecognitionAR_h
//#define FaceRecognitionAR_h

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface DlibWrapper : NSObject

- (instancetype)init;
- (void)prepare;
- (void)faceRecognition:(CVPixelBufferRef)imageBuffer with:(float*)embedding inRect:(NSValue *)rect;

@end

//#endif /* FaceRecognitionAR_h */
