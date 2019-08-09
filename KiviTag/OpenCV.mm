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

std::array<std::array<cv::Point, 3>, 7> masks {{
    {{cv::Point(15, 5),  cv::Point(60, 12), cv::Point(50,0)}},
    {{cv::Point(7, 18),  cv::Point(14, 41), cv::Point(40,0)}},
    {cv::Point(47, 18), cv::Point(54, 41), cv::Point(50,0)},
    {cv::Point(7, 51),  cv::Point(14, 75), cv::Point(50,0)},
    {cv::Point(47, 51), cv::Point(54, 75), cv::Point(50,0)},
    {cv::Point(20, 40), cv::Point(50, 60), cv::Point(50,0)},
    {cv::Point(0, 81),  cv::Point(69, 95), cv::Point(35,0)}
}};

std::vector<cv::Mat> outputs;

int check = 0;
Mat onlyNumbers;
int len = 0;

int getDigitFromStringMap(std::string scheme){
    int output = -1;
    
    if(scheme == "1111101"){
        output = 0;
    }else if(scheme == "1011011"){
        output = 2;
    }else if(scheme == "1010111"){
        output = 3;
    }else if(scheme == "0110110"){
        output = 4;
    }else if(scheme == "1100111"){
        output = 5;
    }else if(scheme == "1101111"){
        output = 6;
    }else if(scheme == "1010100"){
        output = 7;
    }else if(scheme == "1111111"){
        output = 0;
    }else if(scheme == "1110111"){
        output = 9;
    }
    
    return output == -1 ? std::stoi(scheme) : output;
}


double medianMat(cv::Mat Input)
{
    Input = Input.reshape(0,1);// spread Input Mat to single row
    std::vector<double> vecFromMat;
    Input.copyTo(vecFromMat); // Copy Input Mat to vector vecFromMat
    std::nth_element(vecFromMat.begin(), vecFromMat.begin() + vecFromMat.size() / 2, vecFromMat.end());
    return vecFromMat[vecFromMat.size() / 2];
}

cv::Mat auto_canny(cv::Mat &image,cv::Mat &output,float sigma=0.73)
{
    //convert to grey colour space
    output = image;
    //apply small amount of Gaussian blurring
    cv::GaussianBlur( output, output, cv::Size( 3, 3), 0, 0);
    //get the median value of the matrix
    double v = medianMat(output);
    //generate the thresholds
    int lower = (int)std::max(0.0, (1, 0-sigma)*v);
    int upper = (int)std::min(255.0, (1, 0+sigma)*v);
    //apply canny operator
    cv::Canny(output, output, lower, upper, 3);
    return output;
}

/// Converts an UIImage to Mat.
/// Orientation of UIImage will be lost.
static void UIImageToMat(UIImage *image, cv::Mat &mat) {
	assert(image.size.width > 0 && image.size.height > 0);
	assert(image.CGImage != nil || image.CIImage != nil);

	// Create a pixel buffer.
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

/// Converts a Mat to UIImage.
static UIImage *MatToUIImage(cv::Mat &mat) {
	
	// Create a pixel buffer.
	assert(mat.elemSize() == 1 || mat.elemSize() == 3);
	cv::Mat matrgb;
	if (mat.elemSize() == 1) {
		cv::cvtColor(mat, matrgb, cv::COLOR_GRAY2RGB);
    } else if (mat.elemSize() == 3) {
        cv::cvtColor(mat, matrgb, cv::COLOR_BGR2RGB);
    }
	
	// Change a image format.
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

/// Restore the orientation to image.
static UIImage *RestoreUIImageOrientation(UIImage *processed, UIImage *original) {
	if (processed.imageOrientation == original.imageOrientation) {
		return processed;
	}
	return [UIImage imageWithCGImage:processed.CGImage scale:1.0 orientation:original.imageOrientation];
}

#pragma mark -

@implementation OpenCV

+ (nonnull UIImage *)cvtColorBGR2GRAY:(nonnull UIImage *)image {
	cv::Mat bgrMat;
	UIImageToMat(image, bgrMat);
	cv::Mat grayMat;
	cv::cvtColor(bgrMat, grayMat, cv::COLOR_BGR2GRAY);
	UIImage *grayImage = MatToUIImage(grayMat);
	return RestoreUIImageOrientation(grayImage, image);
}

static Mat normalizeSobel(Mat grad){
    double min, max;
    minMaxLoc(grad, &min, &max);
    
    for(int j = 0; j < grad.rows; j++) {
        for (int i = 0; i < grad.cols; i++) {
            auto val = grad.at<uchar>(j,i);
            grad.at<uchar>(j,i) = (uchar)(255 * ((val - min) / (max - min)));
        }
    }
    return grad;
}

+(nonnull UIImage *)SobelFilter:(UIImage *)image {
    
    //UIImageをcv::Matに変換
    cv::Mat mat;
    UIImageToMat(image, mat);
    
    //グレースケールに変換
    cv::Mat gray;
    cv::cvtColor(mat, gray, cv::COLOR_BGR2GRAY);
    
    // エッジ抽出
    cv::Mat edge;
    cv::Canny(gray, edge, 100, 200);
    
    //cv::Mat を UIImage に変換
    UIImage *result = MatToUIImage(edge);
    return result;
}


std::array<Point2f, 4> sortPts(RotatedRect rect){
    Point2f pts[4];
    rect.points(pts);
    std::array<Point2f, 4> vec = {pts[0], pts[1], pts[2], pts[3]};
    std::sort(std::begin(vec ), std::end(vec ), [](cv::Point2f a, cv::Point2f b) {return -std::atan2(a.x,-a.y) > -std::atan2(b.x,-b.y); });
    return vec;
}

std::array<int, 7> testMask(Mat mat){
    std::array<int, 7> scheme;
    for(int i = 0; i < 7; i++){
        std::array<cv::Point, 3> mask = masks[i];
        cv::Point a = mask[0];
        cv::Point b = mask[1];
        int norm = mask[2].x;
        
        cv::Rect roi = cv::Rect(a.x, a.y, b.x-a.x, b.y-a.y);
        Mat crop = Mat(mat, roi);
        float white = countNonZero(crop);
        float all   = roi.width * roi.height;
        int mean = int(100 * (white/all));
        scheme[i] = mean >= norm ? 1 : 0;
    }
    return scheme;
}

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

Mat oldResult;
int oldN = 0;

+(UIImage *)changeWhiteColorTransparent: (UIImage *)image {
    CGImageRef rawImageRef=image.CGImage;
    const CGFloat colorMasking[6] = {222, 255, 222, 255, 222, 255};
    UIGraphicsBeginImageContext(image.size);
    CGImageRef maskedImageRef=CGImageCreateWithMaskingColors(rawImageRef, colorMasking);
    {
        //if in iphone
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
    
    Mat gradX, gradY, grad;
//    Sobel(gray, gradX, CV_32F, 1, 0);
//    Sobel(gray, gradY, CV_32F, 0, 1);
//
//    convertScaleAbs(gradX, gradX);
//    convertScaleAbs(gradY, gradY);
//
//    gradX = normalizeSobel(gradX);
//    gradY = normalizeSobel(gradY);
    
//    addWeighted(gradX, 2, gradY, 2, 0, grad);
    
//    medianBlur(grad, grad, 7);
//    erode(grad, grad, getStructuringElement(MORPH_RECT, cv::Size(3, 3)));
    GaussianBlur(gray, gray, cv::Size(3, 3), 0);
    Mat krn = getStructuringElement(MORPH_RECT, cv::Size(3, 3));
    erode(gray, gray, krn);
    dilate(gray, gray, krn);
    Canny(gray, grad, 50, 200);
//
//
//    Canny(grad, grad, 150, 200);
//    auto_canny(grad, grad, 0.8);

    
    Mat mask(grad.rows, grad.cols, CV_8U, Scalar(0));
    bool edited = false;
    
    Mat res(96, 20, CV_8U, Scalar(255));
    Mat delim(28, 5, CV_8U, Scalar(255));
    Mat delimV(10, 210, CV_8U, Scalar(255));
    Mat ext(28, 32, CV_8U, Scalar(255));

    std::vector<std::vector<cv::Point>> contours;
    findContours(grad, contours, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);

//    for(int i = 0; i < contours.size(); i++){
//        auto cnt = contours[i];
//        cv::Rect box = boundingRect(cnt);
//        rectangle(mask, cv::Point(box.x, box.y), cv::Point(box.x+box.width,box.y+box.height), cv::Scalar(255), -1);
//    }
    
//    UIImage *tst = MatToUIImage(mask);
    
//    contours.clear();
//    findContours(mask, contours, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);
    
    std::sort(contours.begin(), contours.end(), compareContourArea);
    std::sort(contours.begin(), contours.end(), compareContour);

        
    int n = 0;
    for(int i = 0; i < contours.size(); i++){
        auto cnt = contours[i];
//        convexHull(Mat(cnt), cnt, false);
        cv::Rect box = boundingRect(cnt);
//        auto area = contourArea(cnt);
        auto area = box.width * box.height;
        if(area > 1000 && n <= 3){
            float aspectRatio = (float)box.width / (float)box.height;
            if(aspectRatio >= 0.3 && aspectRatio <= 0.8){
        
//                drawContours(cropped, contours, i, colors[n], 3);
                Mat normal = Mat(cropped, box);
                resize(normal, normal, cv::Size(int(28*aspectRatio), 28));

                cvtColor(normal, normal, COLOR_BGR2GRAY);
                GaussianBlur(normal, normal, cv::Size(5, 5), 0);
                threshold(normal, normal, 0, 255, THRESH_BINARY + THRESH_OTSU);
                
                int additionalPart = (28 - normal.cols) / 2;
                Mat delim(28, additionalPart, CV_8U, Scalar(255));
                hconcat(normal, delim, normal);
                hconcat(delim, normal, normal);
//                bitwise_not(normal, normal);
//                resize(normal, normal, cv::Size(32, 28));
                
//                hconcat(normal, ext, normal);
//                hconcat(ext, normal, normal);
//                resize(normal, normal, cv::Size(28, 28));
                mask = normal;
                outputs.push_back(normal);
                len++;
                rectangle(input, cv::Point(box.x+roi.x, box.y+roi.y), cv::Point(box.width+box.x+roi.x, box.height+box.y+roi.y), colors[n]);

//                hconcat(res, normal, res);
                cvtColor(normal, normal, COLOR_GRAY2BGR);
                edited = true;
//                int number = getDigitFromStringMap(arrToStr(testMask(normal)));
                putText(cropped, std::to_string(int(10*aspectRatio)), cv::Point(box.x+10, box.y+10),FONT_HERSHEY_PLAIN, 3, cv::Scalar(0, 0, 255));
//                check = 1;
                
//

//                normal.copyTo(input.colRange(100+(normal.cols*n), 100+normal.cols+(normal.cols*n)).rowRange(10, 10+normal.rows));
                n++;
            }
        }
    }
    
    
    cvtColor(grad, grad, COLOR_GRAY2BGR);
//    hconcat(res, delim, res);
    resize(res, res, cv::Size(210, 96));

//    vconcat(delimV, res, res);
//    vconcat(res, delimV, res);
    
//    Mat masked;
//    cropped.copyTo(masked, mask);
    
    
    bitwise_not(res, res);
    cvtColor(res, res, COLOR_GRAY2BGR);
    

    
//    res = grad;
    
//    res.copyTo(input.colRange(roi.x, roi.x + res.cols).rowRange(roi.y, roi.y + res.rows));
    
    rectangle(input, crop_from, crop_to, cv::Scalar(255, 255, 255), 1);
    Mat rslt;
    if(edited) {
        onlyNumbers = mask;
        check = 1;
    }
    UIImage *RES = MatToUIImage(input);
    return RES;
}

@end
