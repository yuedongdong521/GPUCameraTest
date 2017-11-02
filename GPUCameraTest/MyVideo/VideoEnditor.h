//
//  VideoEnditor.h
//  GPUCameraTest
//
//  Created by ispeak on 2017/6/9.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoEnditor : NSObject

/***
 视频添加音频
 ***/
- (void)addMusicToVideoFileUrl:(NSURL *)fileUrl ForMusicUrl:(NSURL *)musicUrl CompletionBlock:(void(^)(NSURL *backURL))completionBlock;

/***
 视频叠加
 ***/
- (void)addVideoToVideoFileUrl:(NSURL *)fileUrl CompletionBlock:(void(^)(NSURL *backUrl))completionBlock;

/***
 视频剪切
 ***/
- (void)trimVideoForFileUrl:(NSURL *)fileUrl StartTime:(CMTime)startTime EndStr:(CMTime)endTime BackNewVideoUrl:(void(^)(NSURL *url))newVideoURL;

/*****
 视频变速
 ***/
- (void)changeVideoSpeedForUrl:(NSURL *)url ForSpeedScale:(CGFloat)scale ForBackNewVideoUrl:(void(^)(NSURL *newUrl))BackNewVideoUrl;

/*****
 视频合成
 ***/
- (void)mergeAndExportVideosAtFileURLs:(NSMutableArray *)fileURLArray ForNewVideoHWRate:(CGFloat)newVideoHWRate ForBackNewVideoUrl:(void (^)(NSURL *newVideoUrl))BackNewVideoUrl;

@end
