//
//  GPUCapture.m
//  GPUCameraTest
//
//  Created by ydd on 2019/3/21.
//  Copyright © 2019 ydd. All rights reserved.
//

#import "GPUCapture.h"
#import "GPUImageBeautifyFilter.h"
#import "DSoftLightBlendFilter.h"

@interface GPUCapture ()
{
  GPUImageOutput <GPUImageInput> *_curFilter;
}
@property (nonatomic, strong) NSString *outputPath;
@property (nonatomic, strong) GPUImageVideoCamera *videoCapture;
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) GPUImageView *videoView;
@property (nonatomic, strong) GPUImageBeautifyFilter *beautifyFilter;
@property (nonatomic, strong) GPUImageFilterGroup *filterGroup;
@property (nonatomic, strong) GPUImageBrightnessFilter *brightnessFilter;
@property (nonatomic, strong) GPUImageExposureFilter *exposureFilter;
@property (nonatomic, strong) GPUImageContrastFilter *contrastFilter;
@property (nonatomic, strong) GPUImageSaturationFilter *saturationFilter;
@property (nonatomic, strong) DSoftLightBlendFilter *softLightBlendFilter;


@end

@implementation GPUCapture

- (instancetype)initWithVideoPreview:(UIView *)videoPreview;
{
  self = [super init];
  if (self) {
    [videoPreview addSubview:self.videoView];
    [self setCurFilter:self.filterGroup];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiive) name:UIApplicationDidBecomeActiveNotification object:nil];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (GPUImageBeautifyFilter *)beautifyFilter
{
  if (!_beautifyFilter) {
    _beautifyFilter = [[GPUImageBeautifyFilter alloc] initWithDegree:0.5];
  }
  return _beautifyFilter;
}

- (GPUImageFilterGroup *)filterGroup
{
  if (!_filterGroup) {
    //光度
    _brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    [_brightnessFilter setBrightness:0.0f];
    //曝光
    _exposureFilter = [[GPUImageExposureFilter alloc] init];
    [_exposureFilter setExposure:0.0f];
    //对比度
    _contrastFilter = [[GPUImageContrastFilter alloc] init];
    [_contrastFilter setContrast:1.0f];
    //饱和度
    _saturationFilter = [[GPUImageSaturationFilter alloc] init];
    [_saturationFilter setSaturation:1.0f];
    
    //美颜程度0.5
    [self beautifyFilter];
    
    //柔光
    _softLightBlendFilter = [[DSoftLightBlendFilter alloc] init];
    
    _filterGroup = [[GPUImageFilterGroup alloc] init];
    [_filterGroup addFilter:_brightnessFilter];
    [_filterGroup addFilter:_exposureFilter];
    [_filterGroup addFilter:_contrastFilter];
    [_filterGroup addFilter:_saturationFilter];
    [_filterGroup addFilter:_beautifyFilter];
    [_filterGroup addFilter:_softLightBlendFilter];
    
    //先后顺序
    [_brightnessFilter addTarget:_exposureFilter];
    [_exposureFilter addTarget:_contrastFilter];
    [_contrastFilter addTarget:_saturationFilter];
    [_saturationFilter addTarget:_beautifyFilter];
    [_beautifyFilter addTarget:_softLightBlendFilter];
    
    [_filterGroup setInitialFilters:[NSArray arrayWithObject:_brightnessFilter]];
    [_filterGroup setTerminalFilter:_softLightBlendFilter];
  }
  return _filterGroup;
}

- (void)setCurFilter:(GPUImageOutput<GPUImageInput> *)curFilter
{
  if (_curFilter) {
    [_curFilter removeAllTargets];
    _curFilter = nil;
  }
  [self.videoCapture removeAllTargets];
  _curFilter = curFilter;
  if (_curFilter) {
    [_curFilter addTarget:self.videoView];
    [self.videoCapture addTarget:_curFilter];
  } else {
    [self.videoCapture addTarget:self.videoView];
  }
}

- (GPUImageOutput<GPUImageInput> *)curFilter
{
  if (!_curFilter) {
    _curFilter = [[GPUImageFilter alloc] init];
  }
  return _curFilter;
}

- (void)willResignActive
{
  [self captureStop];
  runSynchronouslyOnVideoProcessingQueue(^{
    glFinish();
  });
}

- (void)didBecomeActiive
{
  [self captureStartRuning];
}


- (void)captureStartRuning
{
  [self.videoCapture startCameraCapture];
}

- (void)captureStop
{
  [self.videoCapture stopCameraCapture];
}
- (void)startRecord
{
  [self resetMovieWriter];
  [_movieWriter startRecording];
}

- (void)stopRecordCompletionHandler:(void(^)(NSString *outputPath))handler
{
  __weak typeof(self) weakself = self;
  [_movieWriter finishRecordingWithCompletionHandler:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      if (handler) {
        handler(weakself.outputPath);
      }
    });
    
  }];
}

- (void)cancelRecord
{
  [_movieWriter cancelRecording];
}

- (GPUImageVideoCamera *)videoCapture
{
  if (!_videoCapture) {
    _videoCapture = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionFront];
    _videoCapture.outputImageOrientation = UIDeviceOrientationPortrait;
    _videoCapture.horizontallyMirrorRearFacingCamera = NO;
    _videoCapture.horizontallyMirrorFrontFacingCamera = YES;
    //该句可防止允许声音通过的情况下，避免录制第一帧黑屏闪屏(====)
    [self.videoCapture addAudioInputsAndOutputs];
    
  }
  return _videoCapture;
}

- (GPUImageView *)videoView
{
  if (!_videoView) {
    _videoView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  }
  return _videoView;
}

- (NSString *)creatOutputPathWithVideoName:(NSString *)name
{
  NSFileManager *manager = [NSFileManager defaultManager];

  NSString *directory = NSTemporaryDirectory();
  NSString *videoPath = [directory stringByAppendingPathComponent:@"Videos"];
  BOOL isDir;
  BOOL isPath = [manager fileExistsAtPath:videoPath isDirectory:&isDir];
  if (!isPath || !isDir) {
    [manager createDirectoryAtPath:videoPath withIntermediateDirectories:YES attributes:nil error:nil];
  }
  videoPath = [videoPath stringByAppendingPathComponent:name];
  if ([manager fileExistsAtPath:videoPath]) {
    [manager removeItemAtPath:videoPath error:nil];
  }
  return videoPath;
}


- (void)resetMovieWriter
{
  if (_movieWriter) {
    _movieWriter = nil;
  }
  _outputPath = [self creatOutputPathWithVideoName:@"test.mp4"];
  NSURL *movieUrl = [NSURL fileURLWithPath:self.outputPath];
  NSDictionary *videoSettings = @{AVVideoCodecKey:AVVideoCodecH264, AVVideoWidthKey:@(720), AVVideoHeightKey:@(1280)};
  _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieUrl size:CGSizeMake(720, 1280) fileType:AVFileTypeQuickTimeMovie outputSettings:videoSettings];
  [_movieWriter setHasAudioTrack:YES];
  self.videoCapture.audioEncodingTarget = _movieWriter;
  _movieWriter.encodingLiveVideo = YES;
   [self.curFilter addTarget:_movieWriter];
}

@end
