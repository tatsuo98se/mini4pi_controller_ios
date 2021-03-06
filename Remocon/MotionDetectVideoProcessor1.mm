//
//  MotionDetectVideoProcessor1.m
//  Scouter
//
//  Created by Tatsuo Fukushima on 2016/11/10.
//  Copyright © 2016年 FXAT. All rights reserved.
//
#import <opencv2/opencv.hpp>
#import <opencv2/video/background_segm.hpp>
#import <opencv2/imgproc.hpp>
#import "MotionDetectVideoProcessor1.h"

using namespace cv;

@interface MotionDetectVideoProcessor1()
{
    Ptr<BackgroundSubtractor> pBS; //MOG Background subtractor
}

@end

@implementation MotionDetectVideoProcessor1

- (id)init{
    self = [super init];
    if(self){
        pBS = new BackgroundSubtractorMOG2(); //MOG2 approach
    }
    return self;
}

// 動画の1フレームを受け取るデリゲート
- (void)processImage:(Mat&)image
{
    // Do some OpenCV stuff with the image
    Mat image_copy;
    cvtColor(image, image_copy, CV_BGRA2BGR);
    
    pBS->operator()(image_copy, image_copy, 0.03);
    dilate(image_copy, image_copy, Mat());
    erode(image_copy, image_copy, Mat());
    
    //輪郭の座標リスト
    std::vector< std::vector< cv::Point > > contours;
    
    //輪郭取得
    findContours(image_copy, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);
    
    //表示する輪郭のカウント

    int width = image.cols;
    int height = image.rows;
    
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    float ratioW = screenWidth / width;
    float ratioH = screenHeight / height;
    
    float ratio = MAX(ratioW, ratioH);
    
    float paddingW = (ratio * width - screenWidth)/ratio;
    float paddingH = (ratio * height - screenHeight)/ratio;
    
    
    int leftBoader = ((width - paddingW) * 0.33f)+0.5 + paddingW/2;
    int rightBoader = ((width - paddingW) * 0.66f)+0.5 + paddingW/2;
    
    int topBoarder = ((height - paddingH) * 0.33f)+0.5 + paddingH/2;
    int bottomBoarder = ((height - paddingH) * 0.66)+0.5 + paddingH/2;
   
    line(image, cv::Point(leftBoader, 0), cvPoint(leftBoader, height), Scalar(255, 0, 0), 0.5f, CV_AA);
    line(image, cv::Point(rightBoader, 0), cvPoint(rightBoader, height), Scalar(255, 0, 0), 0.5f, CV_AA);

    cv::putText(image, "Left", cv::Point(paddingW/2, topBoarder), CV_FONT_HERSHEY_PLAIN, 1, cv::Scalar(255, 255, 255));
    cv::putText(image, "Forward", cv::Point(leftBoader, topBoarder), CV_FONT_HERSHEY_PLAIN, 1, cv::Scalar(255, 255, 255));
    cv::putText(image, "Right", cv::Point(rightBoader, topBoarder), CV_FONT_HERSHEY_PLAIN, 1, cv::Scalar(255, 255, 255));

    
    int motorX = 0, motorY = 0;
    for (auto contour = contours.begin(); contour != contours.end(); contour++){
        
        std::vector< cv::Point > approx;
        
        //輪郭を直線近似する
        cv::approxPolyDP(Mat(*contour), approx, 0.01 * arcLength(*contour, true), true);
        
        // 近似の面積が一定以上なら取得
        double area = cv::contourArea(approx);
        
        if (area > 1000.0 && area < 10000.0){ // テキトーな面積のしきい値
            
            std::vector< cv::Point > hull;
            
            // 凹を無くす
            convexHull(approx, hull);
            cv::polylines(image, hull, true, cv::Scalar(255, 0, 0), 1, CV_AA);
            
            // 中心点を算出し、円を描画する
            cv::Point2f center;
            float radius;
            minEnclosingCircle(*contour, center, radius);
            circle(image, center, 20.0f, cv::Scalar(133, 255, 133, 120), CV_FILLED, CV_AA);
//            circle(image, center, 20.0f, Scalar(133, 255, 133), 1, CV_AA);
            
            if(center.x < leftBoader){
                motorX = 90;
            }
            else if(center.x > rightBoader){
                motorX = -90;
                
            }
            else{
                motorY = 100;
            }
            
            
            /*
            roiCnt++;
            if (roiCnt == 3){
                return;
            }
            */
        }
    }
    [self.remoteController setStatusX:motorX y:motorY];
}

@end
