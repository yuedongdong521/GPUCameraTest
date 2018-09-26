//
//  MoviePlayerView.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/12/28.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "MoviePlayerView.h"
#import "GPUImageMovie.h"
#import "GPUImageView.h"

@interface MoviePlayerView () <GPUImageMovieDelegate>

@property (nonatomic, strong) GPUImageMovie *moviePlayer;

@end

@implementation MoviePlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame WithURL:(NSString *)urlStr
{
    self = [super initWithFrame:frame];
    if (self) {
        GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:self.bounds];
        [self addSubview:filterView];
        _moviePlayer = [[GPUImageMovie alloc] initWithURL:[NSURL fileURLWithPath:urlStr]];
        _moviePlayer.shouldRepeat = YES; //重复播放
        _moviePlayer.runBenchmark = YES; //打印播放日志
        _moviePlayer.playAtActualSpeed = YES; //是否正常速度播放
        [_moviePlayer addTarget:filterView];
        
    }
    return self;
}


- (void)startPlay
{
    [_moviePlayer startProcessing];
}

- (void)stopPlay
{
    [_moviePlayer endProcessing];
}

- (void)didCompletePlayingMovie
{
    
}

- (void)dealloc
{
    NSLog(@"MoivePlayerView dealloc");
}


@end
