//
//  VideoCameraView.h
//  GPUCameraTest
//
//  Created by ispeak on 2017/6/6.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"

@protocol VideoCameraViewDelegate <NSObject>

- (void)recordFinishForVideoPath:(NSURL *)videoUrl;
- (void)quiteDelegate;
@end

@interface VideoCameraView : UIView
{
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
    NSString *pathToMovie;
    GPUImageView *filteredVideoView;
    CALayer *_focusLayer;
    NSTimer *myTimer;
    UILabel *timeLabel;
    NSDate *fromdate;
    CGRect mainScreenFrame;
}

@property (nonatomic, weak) id<VideoCameraViewDelegate>delegate;

@end
