//
//  MyGPUMovie.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/12/11.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "MyGPUMovie.h"

@implementation MyGPUMovie

- (instancetype)initWithVideoPath:(NSString *)videoPath WithTagView:(UIView *)tagView
{
    self = [super init];
    if (self) {
        GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:tagView.frame];
        [tagView addSubview:filterView];
        NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
        _movieFile = [[GPUImageMovie alloc] initWithURL:videoURL];
        
        /**
         *  This enables the benchmarking mode, which logs out instantaneous and average frame times to the console
         *
         *  这使当前视频处于基准测试的模式，记录并输出瞬时和平均帧时间到控制台
         *
         *  每隔一段时间打印： Current frame time : 51.256001 ms，直到播放或加滤镜等操作完毕
         */
        _movieFile.runBenchmark = NO;
        
        //是否重复播放
        _movieFile.shouldRepeat = YES;
        
        /**
         *  控制GPUImageView预览视频时的速度是否要保持真实的速度。
         *  如果设为NO，则会将视频的所有帧无间隔渲染，导致速度非常快。
         *  设为YES，则会根据视频本身时长计算出每帧的时间间隔，然后每渲染一帧，就sleep一个时间间隔，从而达到正常的播放速度。
         */
        _movieFile.playAtActualSpeed = YES;
        
        //    GPUImageFilter* progressFilter = [[GPUImageFilter alloc] init];
        //    [movieFile addTarget:progressFilter];
        [_movieFile addTarget:filterView];
        
        
        
        //    [movieWriter startRecording];
        /**
         *  视频处理后输出到 GPUImageView 预览时不支持播放声音，需要自行添加声音播放功能
         *
         *  开始处理并播放...
         */
        
    }
    return self;
}

- (void)startPlayer
{
    [_movieFile startProcessing];
}

- (void)didCompletePlayingMovie
{
    NSLog(@"播放完成");
}

- (void)getAudioDate:(NSURL *)url
{
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
}


@end
