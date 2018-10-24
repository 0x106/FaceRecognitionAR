//
//  FaceRecognitionAR.m
//  FaceRecognitionAR
//
//  Created by Jordan Campbell on 23/10/18.
//  Copyright © 2018 Astro. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FRBackend.h"
#import <UIKit/UIKit.h>

#include <dlib/image_processing.h>
#include <dlib/image_io.h>
#include <dlib/dnn.h>
#include <dlib/clustering.h>
#include <dlib/string.h>

#include <dlib/image_processing/frontal_face_detector.h>

using namespace std;
using namespace dlib;

template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
using residual = add_prev1<block<N,BN,1,tag1<SUBNET>>>;

template <template <int,template<typename>class,int,typename> class block, int N, template<typename>class BN, typename SUBNET>
using residual_down = add_prev2<avg_pool<2,2,2,2,skip1<tag2<block<N,BN,2,tag1<SUBNET>>>>>>;

template <int N, template <typename> class BN, int stride, typename SUBNET>
using block  = BN<con<N,3,3,1,1,relu<BN<con<N,3,3,stride,stride,SUBNET>>>>>;

template <int N, typename SUBNET> using ares      = relu<residual<block,N,affine,SUBNET>>;
template <int N, typename SUBNET> using ares_down = relu<residual_down<block,N,affine,SUBNET>>;

template <typename SUBNET> using alevel0 = ares_down<256,SUBNET>;
template <typename SUBNET> using alevel1 = ares<256,ares<256,ares_down<256,SUBNET>>>;
template <typename SUBNET> using alevel2 = ares<128,ares<128,ares_down<128,SUBNET>>>;
template <typename SUBNET> using alevel3 = ares<64,ares<64,ares<64,ares_down<64,SUBNET>>>>;
template <typename SUBNET> using alevel4 = ares<32,ares<32,ares<32,SUBNET>>>;

using anet_type = loss_metric<fc_no_bias<128,avg_pool_everything<
alevel0<
alevel1<
alevel2<
alevel3<
alevel4<
max_pool<3,3,2,2,relu<affine<con<32,7,7,2,2,
input_rgb_image_sized<150>
>>>>>>>>>>>>;

@implementation DlibWrapper {
  dlib::shape_predictor sp;
  anet_type network;
}

- (instancetype)init {
  self = [super init];
  
  NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
  std::string modelFileNameCString = [modelFileName UTF8String];
  
  NSString *recognition_modelFileName = [[NSBundle mainBundle] pathForResource:@"dlib_face_recognition_resnet_model_v1" ofType:@"dat"];
  std::string recognition_modelFileNameCString = [recognition_modelFileName UTF8String];
  
  dlib::deserialize(modelFileNameCString) >> sp;
  dlib::deserialize(recognition_modelFileNameCString) >> network;
  
  return self;
}

- (void)faceRecognition:(CVPixelBufferRef)imageBuffer with:(float*)embedding inRect:(NSValue *)rect {
  
  dlib::array2d<dlib::bgr_pixel> img;
  
  CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
  
  size_t width = CVPixelBufferGetWidth(imageBuffer);
  size_t height = CVPixelBufferGetHeight(imageBuffer);
  char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);
  
  img.set_size(height, width);
  img.reset();
  long position = 0;
  while (img.move_next()) {
    dlib::bgr_pixel& pixel = img.element();
    long bufferLocation = position * 4; //(row * width + column) * 4;
    char b = baseBuffer[bufferLocation + 0];
    char g = baseBuffer[bufferLocation + 1];
    char r = baseBuffer[bufferLocation + 2];
    dlib::bgr_pixel newpixel(b, g, r);
    pixel = newpixel;
    position++;
  }
  
  CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
  
  CGRect facerect = [rect CGRectValue];
  long left = facerect.origin.x;
  long top = facerect.origin.y;
  long right = left + facerect.size.width;
  long bottom = top + facerect.size.height;
  dlib::rectangle face(left, top, right, bottom);
  
  auto shape = sp(img, face);
  
  matrix<rgb_pixel> face_chip;
  extract_image_chip(img, get_face_chip_details(shape,150,0.25), face_chip);
  std::vector<matrix<rgb_pixel>> faces;
  faces.push_back(move(face_chip));
  std::vector<matrix<float,0,1>> face_descriptors = network(faces);
  
  if (face_descriptors.size() > 0) {
    int i = 0;
    for (float value : face_descriptors[0]) {
      embedding[i] = value;
      i++;
    }
  }
  
  CVPixelBufferLockBaseAddress(imageBuffer, 0);
  
  img.reset();
  position = 0;
  while (img.move_next()) {
    dlib::bgr_pixel& pixel = img.element();
    
    long bufferLocation = position * 4;
    baseBuffer[bufferLocation + 0] = pixel.blue;
    baseBuffer[bufferLocation + 1] = pixel.green;
    baseBuffer[bufferLocation + 2] = pixel.red;
    position++;
  }
  CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

@end
