//
//  UIView+CornerRadius.h
//  GPUCameraTest
//
//  Created by ydd on 2019/3/22.
//  Copyright © 2019 ydd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (CornerRadius)
- (void)setCornerRadius:(CGFloat)value addRectCorners:(UIRectCorner)rectCorner;
@end

NS_ASSUME_NONNULL_END
