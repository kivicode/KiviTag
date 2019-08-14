//
//  OpenCV.h
//  KiviTag
//
//  Created by KiviCode on 2019/08/08.
//  Copyright (c) 2019 KiviCode. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenCV : NSObject

+ (nonnull UIImage *)cvtColorBGR2GRAY:(nonnull UIImage *)image;
+ (nonnull UIImage *)getNumberImage: (int)number;
+ (nonnull UIImage *)process:(UIImage *_Nonnull)image;
+ (nonnull UIImage *)processEink:(UIImage *_Nonnull)image;
+ (int)shouldCheck;
+ (int)numberOfDigits;
+ (void)setROI:(int)w hei:(int)h;
+ (int)getROIWidth;
+ (int)getROIHeigh;
@end
