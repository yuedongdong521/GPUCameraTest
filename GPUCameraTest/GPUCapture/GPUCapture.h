//
//  GPUCapture.h
//  GPUCameraTest
//
//  Created by ydd on 2019/3/21.
//  Copyright © 2019 ydd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
NS_ASSUME_NONNULL_BEGIN

@interface GPUCapture : NSObject

- (instancetype)initWithVideoPreview:(UIView *)videoPreview;

- (void)setCurFilter:(GPUImageOutput<GPUImageInput> *)curFilter;

- (void)captureStartRuning;

- (void)captureStop;

- (void)startRecord;

- (void)stopRecordCompletionHandler:(void(^)(NSString *outputPath))handler;

- (void)cancelRecord;

@end

NS_ASSUME_NONNULL_END
