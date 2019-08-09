//
//  OpenCV.m
//  OpenCVSample_iOS
//
//  Created by Hiroki Ishiura on 2019/08/12.
//  Copyright (c) 2019 KiviCode. All rights reserved.
//

// Put OpenCV include files at the top. Otherwise an error happens.
#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>

#import <Foundation/Foundation.h>
#import "OpenCV.h"

using namespace cv;

Mat onlyNumbers;
int check = 0;
int len = 0;

std::vector<cv::Mat> outputs;

double medianMat(cv::Mat Input) {
    Input = Input.reshape(0, 1);
    std::vector<double> vecFromMat;
    Input.copyTo(vecFromMat);
    std::nth_element(vecFromMat.begin(), vecFromMat.begin() + vecFromMat.size() / 2, vecFromMat.end());
    return vecFromMat[vecFromMat.size() / 2];
}

cv::Mat auto_canny(cv::Mat &image, cv::Mat &output, float sigma=0.73) {
    output = image;

    cv::GaussianBlur( output, output, cv::Size( 3, 3), 0, 0);

    double v = medianMat(output);

    int lower = (int)std::max(0.0, (static_cast<void>(1), 0-sigma)*v);
    int upper = (int)std::min(255.0, (static_cast<void>(1), 0+sigma)*v);

    cv::Canny(output, output, lower, upper, 3);
    return output;
}


static void UIImageToMat(UIImage *image, cv::Mat &mat) {
	assert(image.size.width > 0 && image.size.height > 0);
	assert(image.CGImage != nil || image.CIImage != nil);

	NSInteger width = image.size.width;
	NSInteger height = image.size.height;
	cv::Mat mat8uc4 = cv::Mat((int)height, (int)width, CV_8UC4);

	// Draw all pixels to the buffer.
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if (image.CGImage) {
		// Render with using Core Graphics.
		CGContextRef contextRef = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
		CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), image.CGImage);
		CGContextRelease(contextRef);
	} else {
		// Render with using Core Image.
		static CIContext* context = nil; // I do not like this declaration contains 'static'. But it is for performance.
		if (!context) {
			context = [CIContext contextWithOptions:@{ kCIContextUseSoftwareRenderer: @NO }];
		}
		CGRect bounds = CGRectMake(0, 0, width, height);
		[context render:image.CIImage toBitmap:mat8uc4.data rowBytes:mat8uc4.step bounds:bounds format:kCIFormatRGBA8 colorSpace:colorSpace];
	}
	CGColorSpaceRelease(colorSpace);

	// Adjust byte order of pixel.
	cv::Mat mat8uc3 = cv::Mat((int)width, (int)height, CV_8UC3);
	cv::cvtColor(mat8uc4, mat8uc3, cv::COLOR_RGBA2BGR);
	
	mat = mat8uc3;
}

static UIImage *MatToUIImage(cv::Mat &mat) {
	
	assert(mat.elemSize() == 1 || mat.elemSize() == 3);
	cv::Mat matrgb;
	if (mat.elemSize() == 1) {
		cv::cvtColor(mat, matrgb, cv::COLOR_GRAY2RGB);
    } else if (mat.elemSize() == 3) {
        cv::cvtColor(mat, matrgb, cv::COLOR_BGR2RGB);
    }
	
	NSData *data = [NSData dataWithBytes:matrgb.data length:(matrgb.elemSize() * matrgb.total())];
	CGColorSpaceRef colorSpace;
	if (matrgb.elemSize() == 1) {
		colorSpace = CGColorSpaceCreateDeviceGray();
	} else {
		colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(matrgb.cols, matrgb.rows, 8, 8 * matrgb.elemSize(), matrgb.step.p[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *image = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	
	return image;
}


static UIImage *RestoreUIImageOrientation(UIImage *processed, UIImage *original) {
	if (processed.imageOrientation == original.imageOrientation) {
		return processed;
	}
	return [UIImage imageWithCGImage:processed.CGImage scale:1.0 orientation:original.imageOrientation];
}

#pragma mark -

@implementation OpenCV

bool compareContour(std::vector<cv::Point> contour1, std::vector<cv::Point> contour2) {
    int i = boundingRect(contour1).x;
    int j = boundingRect(contour2).x;
    return i < j ;
}

bool compareContourArea(std::vector<cv::Point> contour1, std::vector<cv::Point> contour2) {
    int i = contourArea(contour1);
    int j = contourArea(contour2);
    return i < j ;
}

std::string arrToStr(std::array<int, 7> arr){
    std::string output = "";
    for(int i = 0; i < 7; i++){
        output += std::to_string(arr[i]);
    }
    return output;
}

+(int)shouldCheck{
    return check;
}

+(int)numberOfDigits{
    return len;
}

std::vector<cv::Scalar> colors {{
    cv::Scalar(0, 255, 0),
    cv::Scalar(255, 0, 0),
    cv::Scalar(0, 0, 255),
    cv::Scalar(255, 0, 255),
}};

+ (nonnull UIImage *)getNumberImage: (int)number {
    UIImage *res_image = MatToUIImage(outputs[number]);
    CGImageRef rawImageRef=res_image.CGImage;
    const CGFloat colorMasking[6] = {222, 255, 222, 255, 222, 255};
    UIGraphicsBeginImageContext(res_image.size);
    CGImageRef maskedImageRef=CGImageCreateWithMaskingColors(rawImageRef, colorMasking);
    {
        //if in iphone
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0, res_image.size.height);
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    }
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, res_image.size.width, res_image.size.height), maskedImageRef);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRelease(maskedImageRef);
    UIGraphicsEndImageContext();
    return result;
}

+(UIImage *)changeWhiteColorTransparent: (UIImage *)image {
    CGImageRef rawImageRef=image.CGImage;
    const CGFloat colorMasking[6] = {222, 255, 222, 255, 222, 255};
    UIGraphicsBeginImageContext(image.size);
    CGImageRef maskedImageRef=CGImageCreateWithMaskingColors(rawImageRef, colorMasking);
    {
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0, image.size.height);
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    }
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, image.size.width, image.size.height), maskedImageRef);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRelease(maskedImageRef);
    UIGraphicsEndImageContext();
    return result;
}

+(nonnull UIImage *)process:(UIImage *)image {
    outputs.clear();
    check = 0;
    len = 0;
    
    Mat kernel = getStructuringElement(MORPH_RECT, cv::Size(13, 13));

    Mat input, output;
    UIImageToMat(image, input);
    input.copyTo(output);
    
    int size[] = {300, 150};
    
    int w  = input.cols;
    int h = input.rows;
    
    cv::Point crop_from = cv::Point((int)(w/2 - size[0]/2), (int)(h/2 - size[1]/2));
    cv::Point crop_to   = cv::Point((int)(w/2 + size[0]/2), (int)(h/2 + size[1]/2));
    
    cv::Rect roi = cv::Rect(crop_from.x, crop_from.y, crop_to.x-crop_from.x, crop_to.y-crop_from.y);
    
    Mat cropped = Mat(input, roi);
    
    Mat gray;
    cvtColor(cropped, gray, COLOR_BGR2GRAY);
    
    Mat grad;

    GaussianBlur(gray, gray, cv::Size(3, 3), 0);
    Mat krn = getStructuringElement(MORPH_RECT, cv::Size(3, 3));
    erode(gray, gray, krn);
    dilate(gray, gray, krn);
    Canny(gray, grad, 50, 200);
    
    Mat mask(grad.rows, grad.cols, CV_8U, Scalar(0));
    bool edited = false;

    std::vector<std::vector<cv::Point>> contours;
    findContours(grad, contours, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);

    std::sort(contours.begin(), contours.end(), compareContourArea);
    std::sort(contours.begin(), contours.end(), compareContour);

    int n = 0;
    for(int i = 0; i < contours.size(); i++){
        auto cnt = contours[i];
        cv::Rect box = boundingRect(cnt);
        auto area = box.width * box.height;
        if(area > 1000 && n <= 3){
            float aspectRatio = (float)box.width / (float)box.height;
            if(aspectRatio >= 0.3 && aspectRatio <= 0.8){
                Mat normal = Mat(cropped, box);
                resize(normal, normal, cv::Size(int(28*aspectRatio), 28));

                cvtColor(normal, normal, COLOR_BGR2GRAY);
                GaussianBlur(normal, normal, cv::Size(5, 5), 0);
                threshold(normal, normal, 0, 255, THRESH_BINARY + THRESH_OTSU);
                
                int additionalPart = (28 - normal.cols) / 2;
                Mat delim(28, additionalPart, CV_8U, Scalar(255));
                hconcat(normal, delim, normal);
                hconcat(delim, normal, normal);
                
                outputs.push_back(normal);
                
                rectangle(input, cv::Point(box.x+roi.x, box.y+roi.y), cv::Point(box.width+box.x+roi.x, box.height+box.y+roi.y), colors[n]);
                edited = true;
                n++;
                len++;
            }
        }
    }
    
    rectangle(input, crop_from, crop_to, cv::Scalar(0, 255, 0), 1);
    if(edited) {
        onlyNumbers = mask;
        check = 1;
    }

    return MatToUIImage(input);
}

@end
