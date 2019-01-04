//
//  MyGPUMovie.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/12/11.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "MyGPUMovie.h"

@interface MyGPUMovie ()
{
  AVPlayerItem *_playerItem;
  AVPlayer *_player;
  CMTime _pausedTime;
}

@property (nonatomic, strong) GPUImageView *videoView;
@property (nonatomic, strong) NSURL *videoURL;


@end


@implementation MyGPUMovie

- (instancetype)initWithVideoPath:(NSString *)videoPath WithTagView:(UIView *)tagView
{
    self = [super init];
    if (self) {
      
      _videoView = [[GPUImageView alloc] initWithFrame:tagView.frame];
      [tagView addSubview:_videoView];
      
      _videoURL = [NSURL fileURLWithPath:videoPath];
      _playerItem = [[AVPlayerItem alloc]initWithURL:_videoURL];
      _player = [AVPlayer playerWithPlayerItem:_playerItem];
      
      _movieFile = [[GPUImageMovie alloc] initWithPlayerItem:_playerItem];
        
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
      
      _filter = [[GPUImageFilter alloc] init];
      [_movieFile addTarget:_filter];
      [_filter addTarget:_videoView];
        
        
        
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


- (void)filterClicked:(UIButton *)button
{
  // Set paused time. If player reaches end of the video, set pausedTime to 0.
  if (CMTimeCompare(_pausedTime, _player.currentItem.asset.duration)) {
    _pausedTime = _player.currentTime;
  } else {
    _pausedTime = CMTimeMake(0, 600.0);
  }
  [self.videoView setBackgroundColor:[UIColor clearColor]];
  
  [_movieFile cancelProcessing];
  
  switch (button.tag)
  {
    case 0:
      _filter = nil;
      _filter = [[GPUImageFilter alloc] init];
      break;
    case 1:
      _filter = nil;
      _filter = [[GPUImageColorInvertFilter alloc] init];
      break;
    case 2:
      _filter = nil;
      _filter = [[GPUImageEmbossFilter alloc] init];
      break;
    case 3:
      _filter = nil;
      _filter = [[GPUImageGrayscaleFilter alloc] init];
      break;
    default:
      _filter = nil;
      _filter = [[GPUImageFilter alloc] init];
      break;
  }
  
  [self filterVideo];
  
}

- (void)filterVideo {
  
  // AVPlayerItem is initialized with required url
  
  _playerItem = [[AVPlayerItem alloc]initWithURL:self.videoURL];
  [_player replaceCurrentItemWithPlayerItem:_playerItem];
  
  //GPUImageMovie is initialized with AVPlayerItem
  
  _movieFile = [[GPUImageMovie alloc] initWithPlayerItem:_playerItem];
  
  _movieFile.runBenchmark = YES;
  _movieFile.playAtActualSpeed = YES;
  
  // Adding targets for movieFile and filter
  
  [_movieFile addTarget:_filter];
  [_filter addTarget:self.videoView]; // self.videoView is my GPUImageView
  
  [_movieFile startProcessing];
  
  
  // Player rate is set to 0 means player is paused
  
  [_player setRate:0.0];
  
  // Seeking to the point where video was paused
  
  if (CMTimeCompare(_pausedTime, _player.currentItem.asset.duration) == 0) {
    [_player play];
    
  } else {
    [_player seekToTime:_pausedTime];
    [_player play];
  }
}





@end
