//
//  OpenCV.h
//  OpenCVSample_iOS
//
//  Created by Hiroki Ishiura on 2015/08/12.
//  Copyright (c) 2015年 Hiroki Ishiura. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenCV : NSObject

/// Converts a full color image to grayscale image with using OpenCV.
+ (nonnull UIImage *)cvtColorBGR2GRAY:(nonnull UIImage *)image;
+ (nonnull UIImage *)getNumberImage: (int)number;
+ (nonnull UIImage *)process:(UIImage *)image;
+ (int)shouldCheck;
+ (int)numberOfDigits;
@end
