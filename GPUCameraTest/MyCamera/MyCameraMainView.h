//
//  MyCameraMainView.h
//  GPUCameraTest
//
//  Created by ispeak on 2017/4/6.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MyCameraMainViewDelegate <NSObject>

- (void)closeCamera;
- (void)takePhone;
- (void)selectFilterIndex:(NSInteger)index;
- (void)changeCameraActionDeleagate;

@end

@interface MyCameraMainView : UIView

@property (nonatomic, weak) id<MyCameraMainViewDelegate>  delegate;

@end
