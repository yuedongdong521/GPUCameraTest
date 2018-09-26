//
//  MoviePlayerView.h
//  GPUCameraTest
//
//  Created by ispeak on 2017/12/28.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoviePlayerView : UIView

- (instancetype)initWithFrame:(CGRect)frame WithURL:(NSString *)urlStr;

- (void)startPlay;

- (void)stopPlay;

@end
