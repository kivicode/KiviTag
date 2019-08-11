//
//  OpenCV.h
//  KiviTag
//
//  Created by Hiroki Ishiura on 2019/08/08.
//  Copyright (c) 2019 KiviCode. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenCV : NSObject

+ (nonnull UIImage *)cvtColorBGR2GRAY:(nonnull UIImage *)image;
+ (nonnull UIImage *)getNumberImage: (int)number;
+ (nonnull UIImage *)process:(UIImage *_Nonnull)image: (bool)shouldCrop;
+ (nonnull UIImage *)processEink:(UIImage *_Nonnull)image;
+ (int)shouldCheck;
+ (int)numberOfDigits;
@end
