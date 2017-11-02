//
//  VideoCameraView.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/6/6.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "VideoCameraView.h"
#import "GPUImageBeautifyFilter.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SDAVAssetExportSession.h"
#import "VideoEnditor.h"

#define VIDEO_FOLDER @"videoFolder"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
@interface VideoCameraView ()<CAAnimationDelegate>
{
    float preLayerWidth;//镜头宽
    float preLayerHeight;//镜头高
    float preLayerHWRate; //高，宽比
    NSMutableArray* urlArray;
    AVCaptureDeviceFormat * _defaultFormat;
    CMTime _defaultMinFrameDuration;
    CMTime _defaultMaxFrameDuration;
    
    AVCaptureMovieFileOutput *_captureMovieFileOutput;
}

@property (nonatomic, assign) BOOL isrecording;
@property (weak, nonatomic) IBOutlet UIButton *quiteBtn;

@property (weak, nonatomic) IBOutlet UIButton *changeCaptureBtn;
@property (weak, nonatomic) IBOutlet UIButton *changeFileBtn;
@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (weak, nonatomic) IBOutlet UIButton *finishRecordBtn;

@property (weak, nonatomic) IBOutlet UISlider *filterSlider;
@property (weak, nonatomic) IBOutlet UIButton *slowBtn;
@end

@implementation VideoCameraView

- (instancetype)init{
    
    self = [[[NSBundle mainBundle] loadNibNamed:@"VideoCameraView" owner:self options:nil] lastObject];
    if (!self)
    {
        return nil;
    }
    self.frame = [UIScreen mainScreen].bounds;
    preLayerWidth = SCREEN_WIDTH;
    preLayerHeight = SCREEN_HEIGHT;
    preLayerHWRate =preLayerHeight/preLayerWidth;
    urlArray = [[NSMutableArray alloc]init];
    [self createVideoFolderIfNotExist];
    mainScreenFrame = self.bounds;
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
    videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [videoCamera addAudioInputsAndOutputs];
    
    filter = [[GPUImageSaturationFilter alloc] init];
    filteredVideoView = [[GPUImageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [videoCamera addTarget:filter];
    [filter addTarget:filteredVideoView];
    
    
//    // 创建输出流
//    _captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
//    
//    // 将输出流添加到AVCaptureSession
//    if ([videoCamera.captureSession canAddOutput:_captureMovieFileOutput]) {
//        [videoCamera.captureSession addOutput:_captureMovieFileOutput];
//        // 根据设备输出获得连接
//        AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
//        // 判断是否支持光学防抖
//        if ([videoCamera.inputCamera.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
//            // 如果支持防抖就打开防抖
//            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
//        }
//    }
//    
    // 保存默认的AVCaptureDeviceFormat
    // 之所以保存是因为修改摄像头捕捉频率之后，防抖就无法再次开启，试了下只能够用这个默认的format才可以，所以把它存起来，关闭慢动作拍摄后在设置会默认的format开启防抖
    _defaultFormat = videoCamera.inputCamera.activeFormat;
    _defaultMinFrameDuration = videoCamera.inputCamera.activeVideoMinFrameDuration;
    _defaultMaxFrameDuration = videoCamera.inputCamera.activeVideoMaxFrameDuration;

    
    [videoCamera startCameraCapture];
    
    [self addSomeView];
    
    UITapGestureRecognizer *singleFingerOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewTapAction:)];
    singleFingerOne.numberOfTouchesRequired = 1; //手指数
    singleFingerOne.numberOfTapsRequired = 1; //tap次数
    [filteredVideoView addGestureRecognizer:singleFingerOne];
    [self insertSubview:filteredVideoView atIndex:0];

    _isrecording = NO;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    return self;
}

- (void)willResignActive
{
    [videoCamera pauseCameraCapture];
    [videoCamera stopCameraCapture];
    
    runSynchronouslyOnVideoProcessingQueue(^{
        glFinish();
    });
}

- (void)didBecomeActiive
{
    [videoCamera resumeCameraCapture];
    [videoCamera startCameraCapture];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) addSomeView{

    timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 60.0, 100, 30.0)];
    timeLabel.font = [UIFont systemFontOfSize:15.0f];
    timeLabel.text = @"00:00:00";
    timeLabel.textAlignment = NSTextAlignmentCenter;
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.textColor = [UIColor whiteColor];
    [filteredVideoView addSubview:timeLabel];
}
- (IBAction)quiteAction:(id)sender {
    [videoCamera stopCameraCapture];
    if ([_delegate respondsToSelector:@selector(quiteDelegate)]) {
        [_delegate quiteDelegate];
    }
}
- (IBAction)slowBtnAction:(id)sender {
    
    self.slowBtn.selected = !self.slowBtn.selected;
    if (self.slowBtn) {
        [self cameraBackgroundDidClickOpenSlow];
    } else {
        [self cameraBackgroundDidClickCloseSlow];
    }
    
}

- (IBAction)changeCaptureAction:(id)sender {
    
    if (videoCamera.cameraPosition == AVCaptureDevicePositionFront) {
        
    } else {
        
    }
    [videoCamera rotateCamera];
    
}


- (IBAction)filterChangeAction:(id)sender {
    if (!_changeFileBtn.selected) {
        _filterSlider.hidden = YES;
        _changeFileBtn.selected = YES;
        [videoCamera removeAllTargets];
        filter = [[GPUImageOpacityFilter alloc] init];
        [videoCamera addTarget:filter];
        [filter addTarget:filteredVideoView];
        
        
    }else
    {
        _filterSlider.hidden = NO;
        _changeFileBtn.selected = NO;
        [videoCamera removeAllTargets];
        filter = [[GPUImageSaturationFilter alloc] init];
        [videoCamera addTarget:filter];
        [filter addTarget:filteredVideoView];
    }

}

- (IBAction)startRecordAction:(id)sender {
    if (!_isrecording) {
        _isrecording = YES;
        _startRecordBtn.selected = YES;
        _changeFileBtn.hidden = YES;

        pathToMovie = [self getVideoPath];
        NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
        movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720.0, 1280.0)];
        
        movieWriter.encodingLiveVideo = YES;
        movieWriter.assetWriter.movieFragmentInterval = kCMTimeInvalid;
        movieWriter.shouldPassthroughAudio = NO;
        
        [filter addTarget:movieWriter];
        videoCamera.audioEncodingTarget = movieWriter;
        [movieWriter startRecording];
        NSTimeInterval timeInterval =1.0;
        fromdate = [NSDate date];
        if (myTimer == nil) {
            myTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                       target:self
                                                     selector:@selector(updateTimer:)
                                                     userInfo:nil
                                                      repeats:YES];
        }
    } else {
        [self stopRecord];
    }
}
- (IBAction)finishRecord:(id)sender {
    if (_isrecording) {
        [self stopRecord];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self mergeAndExportVideosAtFileURLs:urlArray];
    });
}
- (IBAction)updateSliderValue:(id)sender {
    [(GPUImageSaturationFilter *)filter setSaturation:[(UISlider *)sender value]];
}
//为视频添加边框，水印
- (void)addVideoLayerFrame:(CGRect)frame VideoCamposition:(AVMutableVideoComposition *)videoComposition
{
    CALayer *backgroundLayer = [CALayer layer];
    backgroundLayer.contents = (__bridge id _Nullable)([UIImage imageNamed:@"xiangkuang"].CGImage);
    backgroundLayer.frame = frame;
    backgroundLayer.masksToBounds = YES;
    
    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(10, 10, frame.size.width - 20, frame.size.height - 20);
    
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = frame;
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:backgroundLayer];
    
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}
//为视频添加动画
- (void)addVideoAnimationForSize:(CGSize)size ForIndex:(int)index forComposition:(AVMutableVideoComposition *)composition
{
    // 1
    UIImage *animationImage = [UIImage imageNamed:@"katong.png"];;
    CALayer *overlayLayer1 = [CALayer layer];
    [overlayLayer1 setContents:(id)[animationImage CGImage]];
    overlayLayer1.frame = CGRectMake(size.width/2-64, size.height/2 + 200, 128, 128);
    [overlayLayer1 setMasksToBounds:YES];
    
    CALayer *overlayLayer2 = [CALayer layer];
    [overlayLayer2 setContents:(id)[animationImage CGImage]];
    overlayLayer2.frame = CGRectMake(size.width/2-64, size.height/2 - 200, 128, 128);
    [overlayLayer2 setMasksToBounds:YES];
    
    // 2 - Rotate
    if (index == 0) {
        CABasicAnimation *animation =
        [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        animation.duration=2.0;
        animation.repeatCount=5;
        animation.autoreverses=YES;
        // rotate from 0 to 360
        animation.fromValue=[NSNumber numberWithFloat:0.0];
        animation.toValue=[NSNumber numberWithFloat:(2.0 * M_PI)];
        animation.beginTime = AVCoreAnimationBeginTimeAtZero;
        [overlayLayer1 addAnimation:animation forKey:@"rotation"];
        
        animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        animation.duration=2.0;
        animation.repeatCount=5;
        animation.autoreverses=YES;
        // rotate from 0 to 360
        animation.fromValue=[NSNumber numberWithFloat:0.0];
        animation.toValue=[NSNumber numberWithFloat:(2.0 * M_PI)];
        animation.beginTime = AVCoreAnimationBeginTimeAtZero;
        [overlayLayer2 addAnimation:animation forKey:@"rotation"];
        
        // 3 - Fade
    } else if(index == 1) {
        CABasicAnimation *animation
        =[CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.duration=3.0;
        animation.repeatCount=5;
        animation.autoreverses=YES;
        // animate from fully visible to invisible
        animation.fromValue=[NSNumber numberWithFloat:1.0];
        animation.toValue=[NSNumber numberWithFloat:0.0];
        animation.beginTime = AVCoreAnimationBeginTimeAtZero;
        [overlayLayer1 addAnimation:animation forKey:@"animateOpacity"];
        
        animation=[CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.duration=3.0;
        animation.repeatCount=5;
        animation.autoreverses=YES;
        // animate from invisible to fully visible
        animation.fromValue=[NSNumber numberWithFloat:1.0];
        animation.toValue=[NSNumber numberWithFloat:0.0];
        animation.beginTime = AVCoreAnimationBeginTimeAtZero;
        [overlayLayer2 addAnimation:animation forKey:@"animateOpacity"];
        
        
        // 4 - Twinkle
    } else if(index == 2) {
        CABasicAnimation *animation =
        [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        animation.duration=0.5;
        animation.repeatCount=10;
        animation.autoreverses=YES;
        // animate from half size to full size
        animation.fromValue=[NSNumber numberWithFloat:0.5];
        animation.toValue=[NSNumber numberWithFloat:1.0];
        animation.beginTime = AVCoreAnimationBeginTimeAtZero;
        [overlayLayer1 addAnimation:animation forKey:@"scale"];
        
        animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        animation.duration=1.0;
        animation.repeatCount=5;
        animation.autoreverses=YES;
        // animate from half size to full size
        animation.fromValue=[NSNumber numberWithFloat:0.5];
        animation.toValue=[NSNumber numberWithFloat:1.0];
        animation.beginTime = AVCoreAnimationBeginTimeAtZero;
        [overlayLayer2 addAnimation:animation forKey:@"scale"];
    }
    // 5
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer1];
    [parentLayer addSublayer:overlayLayer2];
    
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

- (void)addVideo3DAnimatinForVideoSize:(CGSize)size forType:(int)type forComposition:(AVMutableVideoComposition*)composition
{
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    
    CATransform3D identityTransform = CATransform3DIdentity;
    
    if (type == 0) {
        identityTransform.m34 = 1.0 / 1000;
    } else if (type == 1) {
        identityTransform.m34 = 1.0 / -1000;
    }
    
    videoLayer.transform = CATransform3DRotate(identityTransform, M_PI / 6.0, 1.0f, 0.0f, 0.0f);
    composition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
}

- (void)creatImageAnimatinForVideoSize:(CGSize)videoSize forComposition:(AVMutableVideoComposition *)composition
{
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    
    NSMutableArray *imageArray = [NSMutableArray array];
    CGSize imageSize = CGSizeMake(0, 0);
    for (int i = 1; i < 89; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"oppo%d.png",i]];
        if (image) {
            [imageArray addObject:image];
            imageSize = image.size;
        }
    }
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(videoSize.width - imageSize.width - 20, videoSize.height - imageSize.height - 20, imageSize.width, imageSize.height)];
    imageView.animationImages = imageArray;
    imageView.animationDuration = 1.0 / 15;
    imageView.animationRepeatCount = 0;
    
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:imageView.layer];
    
    
    composition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    
}

- (void)mergeAndExportVideosAtFileURLs:(NSMutableArray *)fileURLArray
{
    if (fileURLArray.count < 1) {
        return;
    }
    NSError *error = nil;
    CGSize renderSize = CGSizeMake(0, 0);
    
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

    CMTime totalDuration = kCMTimeZero;
    
    NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
    NSMutableArray *assetArray = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileURLArray) {
        
        AVAsset *asset = [AVAsset assetWithURL:fileURL];
        [assetArray addObject:asset];
        
        NSArray* tmpAry =[asset tracksWithMediaType:AVMediaTypeVideo];
        if (tmpAry.count>0) {
            AVAssetTrack *assetTrack = [tmpAry objectAtIndex:0];
            [assetTrackArray addObject:assetTrack];
    
            renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.width);
            renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.height);
        }
    }
    
    CGFloat renderW = MIN(renderSize.width, renderSize.height);
    // 360
    //    renderW = 640;
    
    for (int i = 0; i < [assetArray count] && i < [assetTrackArray count]; i++) {
        
        AVAsset *asset = [assetArray objectAtIndex:i];
        AVAssetTrack *assetTrack = [assetTrackArray objectAtIndex:i];
        
        //初始化音频轨道容器
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
        NSArray*dataSourceArray= [asset tracksWithMediaType:AVMediaTypeAudio];
        //插入音频，并指定插入时长和插入时间点
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:([dataSourceArray count]>0)?[dataSourceArray objectAtIndex:0]:nil
                             atTime:totalDuration
                              error:nil];
        
        //初始化视频轨道容器
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        //插入视频，并指定插入时长和插入时间点
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:assetTrack
                             atTime:totalDuration
                              error:&error];
        NSLog(@"line371%lld , %d",asset.duration.value,asset.duration.timescale);
        
//  视频轨道的操作指令      AVMutableVideoCompositionLayerInstruction，它的主要作用是用来规定video的样式，比如说，你合并两个视频，第一个怎么放？转九十度放呢，还是边放边旋转呢？还是边放边改变透明度？都是由这个掌控的
        AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        totalDuration = CMTimeAdd(totalDuration, asset.duration);
        
        CGFloat rate;
    
        rate = renderW / MIN(assetTrack.naturalSize.height, assetTrack.naturalSize.width);
   
        CGAffineTransform layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
 
        layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -0));
        layerTransform = CGAffineTransformScale(layerTransform, rate, rate);
        //设置视频合入的方向、缩放属性
        [layerInstruciton setTransform:layerTransform atTime:kCMTimeZero];
        //设置视频合入的不透明度
//        [layerInstruciton setOpacity:0.0 atTime:totalDuration];
        //渐变的透明度
        CMTime startTime = CMTimeMake(totalDuration.value - 0.5 * totalDuration.timescale, totalDuration.timescale);
        CMTime durationTime = CMTimeMake(0.5 * totalDuration.timescale, totalDuration.timescale);
        CMTimeRange timeRange = CMTimeRangeMake(startTime, durationTime);
        [layerInstruciton setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:timeRange];
 
        
        [layerInstructionArray addObject:layerInstruciton];
    }
    
    //视频合成路径
    NSString *path = [self getVideoFilePathStringForName:@"merge"];
    NSURL *mergeFileURL = [NSURL fileURLWithPath:path];
    
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruciton.layerInstructions = layerInstructionArray;
    //创建用来添加AVMutableCompositionTrack的，你可以把它想象成用来调度每个视频次序，时间的这么一个调度器。
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = CGSizeMake(renderW, renderW*preLayerHWRate);
//    [self addVideoLayerFrame:CGRectMake(0, 0, renderW, renderW*preLayerHWRate) VideoCamposition:mainCompositionInst];
//    [self addVideoAnimationForSize:CGSizeMake(renderW, renderW*preLayerHWRate) ForIndex:2 forComposition:mainCompositionInst];
    
    [self creatImageAnimatinForVideoSize:CGSizeMake(renderW, renderW*preLayerHWRate) forComposition:mainCompositionInst];
    
//    [self addVideo3DAnimatinForVideoSize:CGSizeMake(renderW, renderW * preLayerHWRate) forType:0 forComposition:mainCompositionInst];
    
    //    (CGSize) renderSize = (width = 720, height = 1280) 10s mov 11M  mp4 709kb
    //导出视频
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.videoComposition = mainCompositionInst;
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self videoCompositionForVideoPath:mergeFileURL];
            
//            VideoEnditor *videoEnditor = [[VideoEnditor alloc] init];
//            [videoEnditor addMusicToVideoFileUrl:mergeFileURL CompletionBlock:^(NSURL *backURL) {
//               dispatch_async(dispatch_get_main_queue(), ^{
//                   [self videoCompositionForVideoPath:backURL];
//               });
//            }];
            
//            [videoEnditor addVideoToVideoFileUrl:mergeFileURL CompletionBlock:^(NSURL *backUrl) {
//                [self videoCompositionForVideoPath:backUrl];
//            }];
            
        });
    }];
}

- (void)videoCompositionForVideoPath:(NSURL *)pathUrl
{
    NSDictionary* options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
    AVAsset* anAsset = [AVURLAsset URLAssetWithURL:pathUrl options:options];
    NSArray* keys = @[@"tracks",@"duration",@"commonMetadata"];
    [anAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        SDAVAssetExportSession *encoder = [SDAVAssetExportSession.alloc initWithAsset:anAsset];
        encoder.outputFileType = AVFileTypeMPEG4;
        //视频压缩后输出路径
        encoder.outputURL = [NSURL fileURLWithPath:[self getVideoFilePathStringForName:@"compostion"]];
        encoder.videoSettings = @
        {
        AVVideoCodecKey: AVVideoCodecH264,
        AVVideoWidthKey: @720,
        AVVideoHeightKey: @1280,
        AVVideoCompressionPropertiesKey: @
            {
            AVVideoAverageBitRateKey: @2000000,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            },
        };
        encoder.audioSettings = @
        {
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey: @2,
        AVSampleRateKey: @44100,
        AVEncoderBitRateKey: @128000,
        };
        
        [encoder exportAsynchronouslyWithCompletionHandler:^
         {
             if (encoder.status == AVAssetExportSessionStatusCompleted)
             {
                 NSLog(@"Video export succeeded");
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self outPutResultVideoForVideoPath:encoder.outputURL];
                 });
                 
                 
             }
             else if (encoder.status == AVAssetExportSessionStatusCancelled)
             {
                 NSLog(@"Video export cancelled");
             }
             else
             {
                 NSLog(@"Video export failed with error: %@ (%d)", encoder.error.localizedDescription, encoder.error.code);
             }
         }];

    }];
}

- (void)outPutResultVideoForVideoPath:(NSURL *)videoUrl
{
    UISaveVideoAtPathToSavedPhotosAlbum(videoUrl.absoluteString, nil, nil, nil);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    CGFloat movSize = 0;
    for (NSInteger i = 0; i < urlArray.count; i++) {
        NSURL *tempURL = urlArray[i];
        NSData *videoData = [NSData dataWithContentsOfURL:tempURL];
        movSize = movSize + videoData.length / 1024.0 / 1024.0;
        NSString *path = [tempURL absoluteString];
        if ([path hasPrefix:@"file://"]) {
            path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        }
        if ([fileManager fileExistsAtPath:path]) {
            [fileManager removeItemAtPath:path error:nil];
        }
    }
    
    NSData *mp4Data = [NSData dataWithContentsOfURL:videoUrl];
    CGFloat mp4Size = mp4Data.length / 1024.0 / 1024.0;
    NSLog(@"视频大小 mov = %f, mp4 = %f", movSize, mp4Size);
    [urlArray removeAllObjects];
    if ([_delegate respondsToSelector:@selector(recordFinishForVideoPath:)]) {
        [_delegate recordFinishForVideoPath:videoUrl];
    }

}

- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}
//最后合成为 mp4
- (NSString *)getVideoFilePathStringForName:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:VIDEO_FOLDER];

    NSString *fileName = [path stringByAppendingPathComponent:[name stringByAppendingString:@".mp4"]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
    }
    return fileName;
}

- (void)createVideoFolderIfNotExist
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    NSString *folderPath = [path stringByAppendingPathComponent:VIDEO_FOLDER];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isDirExist = [fileManager fileExistsAtPath:folderPath isDirectory:&isDir];
    
    if(!(isDirExist && isDir))
    {
        BOOL bCreateDir = [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
        if(!bCreateDir){
            NSLog(@"创建保存视频文件夹失败");
        }
    }
}

- (NSString *)getVideoPath
{
    NSString *homePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *filePath = [homePath stringByAppendingPathComponent:VIDEO_FOLDER];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL isEx = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    if (!isEx) {
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-HH-mm-ss"];
    NSString *nameStr = [formatter stringFromDate:date];
    NSString *path = [filePath stringByAppendingPathComponent:[nameStr stringByAppendingString:@".mov"]];
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:nil];
    }
    return path;
}

- (void)stopRecord
{
    _isrecording = NO;
    _startRecordBtn.selected = NO;
    _changeFileBtn.hidden = NO;
    videoCamera.audioEncodingTarget = nil;
    NSLog(@"Path %@",pathToMovie);
//    UISaveVideoAtPathToSavedPhotosAlbum(pathToMovie, nil, nil, nil);
    [movieWriter finishRecording];
    [filter removeTarget:movieWriter];
    [myTimer invalidate];
    myTimer = nil;
    [urlArray addObject:[NSURL fileURLWithPath:pathToMovie]];
}

- (void)updateTimer:(NSTimer *)sender{
    NSDateFormatter *dateFormator = [[NSDateFormatter alloc] init];
    dateFormator.dateFormat = @"HH:mm:ss";
    NSDate *todate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *comps  = [calendar components:unitFlags fromDate:fromdate toDate:todate options:NSCalendarWrapComponents];
    //NSInteger hour = [comps hour];
    //NSInteger min = [comps minute];
    //NSInteger sec = [comps second];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *timer = [gregorian dateFromComponents:comps];
    NSString *date = [dateFormator stringFromDate:timer];
    timeLabel.text = date;
}

- (void)setfocusImage{
    UIImage *focusImage = [UIImage imageNamed:@"96"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, focusImage.size.width, focusImage.size.height)];
    imageView.image = focusImage;
    CALayer *layer = imageView.layer;
    layer.hidden = YES;
    [filteredVideoView.layer addSublayer:layer];
    _focusLayer = layer;
    
}

- (void)layerAnimationWithPoint:(CGPoint)point {
    if (_focusLayer) {
        CALayer *focusLayer = _focusLayer;
        focusLayer.hidden = NO;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [focusLayer setPosition:point];
        focusLayer.transform = CATransform3DMakeScale(2.0f,2.0f,1.0f);
        [CATransaction commit];
        
        
        CABasicAnimation *animation = [ CABasicAnimation animationWithKeyPath: @"transform" ];
        animation.toValue = [ NSValue valueWithCATransform3D: CATransform3DMakeScale(1.0f,1.0f,1.0f)];
        animation.delegate = self;
        animation.duration = 0.3f;
        animation.repeatCount = 1;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [focusLayer addAnimation: animation forKey:@"animation"];
        
        // 0.5秒钟延时
        [self performSelector:@selector(focusLayerNormal) withObject:self afterDelay:0.5f];
    }
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
}


- (void)focusLayerNormal {
    filteredVideoView.userInteractionEnabled = YES;
    _focusLayer.hidden = YES;
}


-(void)cameraViewTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized && (_focusLayer == NO || _focusLayer.hidden)) {
        CGPoint location = [tgr locationInView:filteredVideoView];
        [self setfocusImage];
        [self layerAnimationWithPoint:location];
        AVCaptureDevice *device = videoCamera.inputCamera;
        CGPoint pointOfInterest = CGPointMake(0.5f, 0.5f);
        NSLog(@"taplocation x = %f y = %f", location.x, location.y);
        CGSize frameSize = [filteredVideoView frame].size;
        
        if ([videoCamera cameraPosition] == AVCaptureDevicePositionFront) {
            location.x = frameSize.width - location.x;
        }
        
        pointOfInterest = CGPointMake(location.y / frameSize.height, 1.f - (location.x / frameSize.width));
        
        
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                [device setFocusPointOfInterest:pointOfInterest];
                
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                
                if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
                {
                    
                    
                    [device setExposurePointOfInterest:pointOfInterest];
                    [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                }
                
                [device unlockForConfiguration];
                
                NSLog(@"FOCUS OK");
            } else {
                NSLog(@"ERROR = %@", error);
            }
        }
    }
}

//开始摄像头慢拍方式
- (void)cameraBackgroundDidClickOpenSlow {
    [videoCamera.captureSession stopRunning];
    CGFloat desiredFPS = 240.0;
    AVCaptureDevice *videoDevice = videoCamera.inputCamera;
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    for (AVCaptureDeviceFormat *format in [videoDevice formats]) {
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            if (range.minFrameRate <= desiredFPS && desiredFPS <= range.maxFrameRate && width >= maxWidth) {
                selectedFormat = format;
                frameRateRange = range;
                maxWidth = width;
            }
        }
    }
    if (selectedFormat) {
        if ([videoDevice lockForConfiguration:nil]) {
            NSLog(@"selected format: %@", selectedFormat);
            videoDevice.activeFormat = selectedFormat;
            videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            [videoDevice unlockForConfiguration];
        }
    }
    [videoCamera.captureSession startRunning];
}

//关闭摄像头慢拍方式
- (void)cameraBackgroundDidClickCloseSlow {
    [videoCamera.captureSession stopRunning];
    CGFloat desiredFPS = 60.0;
    AVCaptureDevice *videoDevice = videoCamera.inputCamera;
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    for (AVCaptureDeviceFormat *format in [videoDevice formats]) {
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            if (range.minFrameRate <= desiredFPS && desiredFPS <= range.maxFrameRate && width >= maxWidth) {
                selectedFormat = format;
                frameRateRange = range;
                maxWidth = width;
            }
        }
    }
    if (selectedFormat) {
        if ([videoDevice lockForConfiguration:nil]) {
            NSLog(@"selected format: %@", selectedFormat);
            videoDevice.activeFormat = _defaultFormat;
            videoDevice.activeVideoMinFrameDuration = _defaultMinFrameDuration;
            videoDevice.activeVideoMaxFrameDuration = _defaultMaxFrameDuration;
            [videoDevice unlockForConfiguration];
        }
    }
    [videoCamera.captureSession startRunning];
}

//防抖开启

- (void)cameraBackgroundDidClickOpenAntiShake {
    AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    NSLog(@"change captureConnection: %@", captureConnection);
    AVCaptureDevice *videoDevice = videoCamera.inputCamera;
    NSLog(@"set format: %@", videoDevice.activeFormat);
    if ([videoDevice.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
    }
}


#pragma mark - 防抖关
- (void)cameraBackgroundDidClickCloseAntiShake {
    AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    NSLog(@"change captureConnection: %@", captureConnection);
    AVCaptureDevice *videoDevice = videoCamera.inputCamera;
    if ([videoDevice.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeOff]) {
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;
    }
}




@end
