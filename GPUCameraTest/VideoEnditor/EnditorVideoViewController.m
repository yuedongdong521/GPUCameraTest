//
//  EnditorVideoViewController.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/8/10.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "EnditorVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoEnditor.h"


@interface EnditorVideoViewController ()
{
    AVPlayer *player;
    id _playerTimeObserver;
}

@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIView *coverView;
@property (nonatomic, assign) CMTime startTime;
@property (nonatomic, assign) CMTime endTime;
@property (nonatomic, strong) VideoEnditor *videoEnditor;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIView *bgImageView;
@property (nonatomic, strong) UIImageView *leftImageView;
@property (nonatomic, strong) UIImageView *rightImageView;
@property (nonatomic, assign) CGPoint startRightPt;
@property (nonatomic, assign) CGPoint startLeftPt;

@property (nonatomic, strong) UILabel *leftLabel;
@property (nonatomic, strong) UILabel *rightLabel;

@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, strong) UILabel *speedLabel;

@property (nonatomic, strong) UIView *topBgView;
@property (nonatomic, strong) UIView *bottomBgView;

@property (nonatomic, strong) UIView *enditorBgView;



@end

@implementation EnditorVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.isPlaying = NO;
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.videoEnditor = [[VideoEnditor alloc] init];
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(leftAction)]];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(rightAction)]];
    
    
    self.videoUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Movie" ofType:@"mp4"]];
    [self initAVPlayer];
    
    [self initEnditorVideoView];
    
    [self initToolBar];
    
    
    
}

- (void)initToolBar
{
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(toolbarAction:)];
    [item1 setTag:1];
    
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:@"美颜" style:UIBarButtonItemStylePlain target:self action:@selector(toolbarAction:)];
    [item2 setTag:2];
    UIBarButtonItem *emptyItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, ScreenHeight - 44, ScreenWidth, 44)];
    [toolBar setBarStyle:UIBarStyleDefault];
    toolBar.items = @[ emptyItem, item1, emptyItem, item2, emptyItem];
    [self.view addSubview:toolBar];
}

- (void)toolbarAction:(id)sender
{
    UIBarButtonItem *item = (UIBarButtonItem *)sender;
    if (item.tag == 1) {
        _enditorBgView.hidden = NO;
    } else {
        _enditorBgView.hidden = YES;
    }
}

- (void)leftAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)rightAction
{
    
    
}

- (void)trimVideoForUrl:(NSURL *)videoUrl
{
    CMTime videoDuration = [AVURLAsset assetWithURL:videoUrl].duration;
    
    int64_t leftTime = ((viewOriginX(_leftImageView) + viewWidth(_leftImageView)) / (viewWidth(_bgImageView) - 40)) * CMTimeGetSeconds(videoDuration) * 1000;
    CMTime startTime = CMTimeMake(leftTime, 1000);
    
    int64_t rightTime = (viewOriginX(_rightImageView) / (viewWidth(_bgImageView) - 40)) * CMTimeGetSeconds(videoDuration) * 1000;
    CMTime endTime = CMTimeMake(rightTime, 1000);
    NSLog(@"duration = %f", CMTimeGetSeconds(CMTimeSubtract(endTime, startTime)));
    [self.videoEnditor trimVideoForFileUrl:videoUrl StartTime:startTime EndStr:endTime BackNewVideoUrl:^(NSURL *url) {
        AVAsset *asset = [AVAsset assetWithURL:url];
        
        NSLog(@"编辑后的视频时长 %f", CMTimeGetSeconds(asset.duration));
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
        [player replaceCurrentItemWithPlayerItem:playerItem];
        [self startPlayer];
        UISaveVideoAtPathToSavedPhotosAlbum(url.absoluteString, self, nil, nil);
        
    }];

}

- (void)initAVPlayer
{

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 84, ScreenWidth - 100, 216)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.layer.masksToBounds = YES;
    imageView.userInteractionEnabled = YES;
    imageView.image = [self getImageForVideo:self.videoUrl atTime:0];
    [self.view addSubview:imageView];
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.videoUrl];
    player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = imageView.bounds;
    playerLayer.backgroundColor = [UIColor clearColor].CGColor;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [imageView.layer addSublayer:playerLayer];
    player.volume = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFinished:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    button.frame = imageView.bounds;
    [button setTitle:@"播放" forState:UIControlStateNormal];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(50 , 0, 50, 0)];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [imageView addSubview:button];
    _button = button;
    
    
    UIView *progressBgView = [[UIView alloc] initWithFrame:CGRectMake(50, 300, ScreenWidth - 120, 50)];
    progressBgView.backgroundColor = [UIColor clearColor];
    progressBgView.tag = 110;
    [self.view addSubview:progressBgView];
    UIPanGestureRecognizer *progressPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(progressValueChange:)];
    [progressBgView addGestureRecognizer:progressPan];
    
     _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 22, ScreenWidth - 120, 2)];
    _progressView.trackTintColor = [UIColor grayColor];
    _progressView.progressTintColor = [UIColor redColor];
    CGAffineTransform transForm = CGAffineTransformMakeScale(1.f, 2.f);
    _progressView.transform = transForm;
    [progressBgView addSubview:_progressView];
   

    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:self.videoUrl];
    int druationTime = CMTimeGetSeconds(urlAsset.duration);
    _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(viewOriginX(progressBgView) + viewWidth(progressBgView) + 10, viewOriginY(progressBgView), 60, 50)];
    _progressLabel.font = [UIFont systemFontOfSize:14];
    _progressLabel.textColor = [UIColor blackColor];
    _progressLabel.textAlignment = NSTextAlignmentCenter;
    _progressLabel.text = [NSString stringWithFormat:@"0/%ds", druationTime];
    [self.view addSubview:_progressLabel];
    
    __weak typeof(self)weakself = self;
    _playerTimeObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if (weakself.isPlaying) {
            [weakself changeProgressLabelValueForTime:time ForVideoDruationTime:CMTimeGetSeconds(urlAsset.duration)];
        }
        
    }];
}

- (void)changeVideoSpeed:(UISlider *)speedValue
{
    self.speedLabel.text = [NSString stringWithFormat:@"%.1f", speedValue.value];
}

- (void)changeVideoSpeedAction:(UIButton *)btn
{
    CGFloat speedValue = [_speedLabel.text floatValue];
    [self.videoEnditor changeVideoSpeedForUrl:self.videoUrl ForSpeedScale:speedValue ForBackNewVideoUrl:^(NSURL *newUrl) {
        if (newUrl) {
            AVPlayerItem *newItem = [AVPlayerItem playerItemWithURL:newUrl];
            [player replaceCurrentItemWithPlayerItem:newItem];
            [self startPlayer];
        }
    }];
}

- (void)initEnditorVideoView
{
    _enditorBgView = [[UIView alloc] initWithFrame:CGRectMake(0, 350, ScreenWidth, 200)];
    _enditorBgView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:_enditorBgView];
    
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(20, 50, ScreenWidth - 100, 100)];
    bgView.backgroundColor = [UIColor grayColor];
    [_enditorBgView addSubview:bgView];
    
    UIButton *finishBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    finishBtn.frame = CGRectMake(viewWidth(bgView) + 30, viewOriginY(bgView) + 25, 50, 50);
    [finishBtn setTitle:@"完成" forState:UIControlStateNormal];
    [finishBtn addTarget:self action:@selector(finishBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [_enditorBgView addSubview:finishBtn];
    
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:self.videoUrl];
    NSTimeInterval videoDuration = CMTimeGetSeconds(urlAsset.duration);
    int duration = 10;
    CGFloat width = (viewWidth(bgView) - 40.0) / duration;

    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < duration; i++) {
        NSTimeInterval time = videoDuration / duration * i;
        [array addObject:[self getImageForVideo:self.videoUrl atTime:time * 60]];
    }
    for (int i = 0; i < array.count; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20 + width * i, 0, width, viewHeight(bgView))];
        imageView.image = array[i];
        imageView.userInteractionEnabled = YES;
        [bgView addSubview:imageView];
    }
    
    UIImageView *leftImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, viewHeight(bgView))];
    UIImage *leftImage = [UIImage imageNamed:@"left@2x"];
    
    leftImageView.image = [leftImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    leftImageView.userInteractionEnabled = YES;
    [bgView addSubview:leftImageView];
    _leftImageView = leftImageView;
    UIPanGestureRecognizer *leftPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(letfPanAction:)];
    [_leftImageView addGestureRecognizer:leftPan];
    
    _leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -30, 30, 30)];
    _leftLabel.font = [UIFont systemFontOfSize:12];
    _leftLabel.textAlignment = NSTextAlignmentCenter;
    [_leftImageView addSubview:_leftLabel];

    _startLeftPt = _leftImageView.center;
    
    
    UIImageView *rightImageView = [[UIImageView alloc] initWithFrame:CGRectMake(viewWidth(bgView) - 30, 0, 30, viewHeight(bgView))];
    UIImage *rightImage = [UIImage imageNamed:@"right@2x"];
    
    rightImageView.image = [rightImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    rightImageView.userInteractionEnabled = YES;
    [bgView addSubview:rightImageView];
     _rightImageView = rightImageView;
    UIPanGestureRecognizer *rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rightPanAction:)];

    [_rightImageView addGestureRecognizer:rightPan];
    
    _rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -30, 30, 30)];
    _rightLabel.font = [UIFont systemFontOfSize:12];
    _rightLabel.textAlignment = NSTextAlignmentCenter;
    [_rightImageView addSubview:_rightLabel];

    _startRightPt = _rightImageView.center;
    _bgImageView = bgView;
    
    
    _topBgView = [[UIView alloc] initWithFrame:CGRectMake(30, 0, viewWidth(bgView) - 60, 2)];
    _topBgView.backgroundColor = [UIColor colorWithRed:13 / 255.0 green:197 / 255.0 blue:162 / 255.0 alpha:1.0];
    [_bgImageView addSubview:_topBgView];
    
    _bottomBgView = [[UIView alloc] initWithFrame:CGRectMake(30, viewHeight(bgView) - 2, viewWidth(bgView) - 60, 2)];
    _bottomBgView.backgroundColor = [UIColor colorWithRed:13 / 255.0 green:197 / 255.0 blue:162 / 255.0 alpha:1.0];
    [_bgImageView addSubview:_bottomBgView];
    
    UISlider *speedSilder = [[UISlider alloc] initWithFrame:CGRectMake(50, viewOriginY(_bgImageView) + viewHeight(_bgImageView), 150, 50)];
    speedSilder.minimumValue = 0.0;
    speedSilder.maximumValue = 5.0;
    speedSilder.thumbTintColor = [UIColor cyanColor];
    speedSilder.minimumTrackTintColor = [UIColor redColor];
    speedSilder.maximumTrackTintColor = [UIColor grayColor];
    [speedSilder addTarget:self action:@selector(changeVideoSpeed:) forControlEvents:UIControlEventValueChanged];
    [_enditorBgView addSubview:speedSilder];
    
    _speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(210, viewOriginY(_bgImageView) + viewHeight(_bgImageView), 50, 50)];
    _speedLabel.text = @"0.0";
    _speedLabel.font = [UIFont systemFontOfSize:14.0];
    [_enditorBgView addSubview:_speedLabel];
    
    UIButton *speedBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    speedBtn.frame = CGRectMake(270, viewOriginY(_bgImageView) + viewHeight(_bgImageView), 50, 50);
    [speedBtn setTitle:@"确定" forState:UIControlStateNormal];
    [speedBtn addTarget:self action:@selector(changeVideoSpeedAction:) forControlEvents:UIControlEventTouchUpInside];
    [_enditorBgView addSubview:speedBtn];
    
    
}

- (void)finishBtnAction
{
    [self trimVideoForUrl:self.videoUrl];
}

- (void)rightPanAction:(UIGestureRecognizer *)pan
{
    if (pan.state == UIGestureRecognizerStateBegan) {
        _startRightPt = [pan locationInView:_rightImageView];
    }
    CGPoint pt = [pan locationInView:_bgImageView];
    CGFloat rightX, rightY = viewHeight(_rightImageView) / 2.0;
    if (viewWidth(_rightImageView) - _startRightPt.x + pt.x >= viewWidth(_bgImageView) - viewWidth(_rightImageView) * 0.5) {
        rightX = viewWidth(_bgImageView) - viewWidth(_rightImageView) * 0.5;
    } else if (- _startRightPt.x + pt.x <= viewOriginX(_leftImageView) + viewWidth(_leftImageView)) {
        rightX = viewOriginX(_leftImageView) + viewWidth(_leftImageView) + viewWidth(_rightImageView) * 0.5;
    } else {
        rightX = viewWidth(_rightImageView) - _startRightPt.x + pt.x;
    }
    _rightImageView.center = CGPointMake(rightX, rightY);
    _topBgView.frame = CGRectMake(viewOriginX(_leftImageView) + viewWidth(_leftImageView), viewOriginY(_topBgView), viewOriginX(_rightImageView) - viewOriginX(_leftImageView) - viewWidth(_leftImageView), viewHeight(_topBgView));
    _bottomBgView.frame = CGRectMake(viewOriginX(_leftImageView) + viewWidth(_leftImageView), viewOriginY(_bottomBgView), viewOriginX(_rightImageView) - viewOriginX(_leftImageView) - viewWidth(_leftImageView), viewHeight(_bottomBgView));
    
    AVAsset *asset = [AVAsset assetWithURL:self.videoUrl];
    CMTime videoDuration = asset.duration;
    int rightTime = ((viewOriginX(_rightImageView) - viewWidth(_rightImageView)) / (viewWidth(_bgImageView) - 60)) * CMTimeGetSeconds(videoDuration);
    _rightLabel.text = [NSString stringWithFormat:@"%d", rightTime];
    
    if (pan.state == UIGestureRecognizerStateEnded) {
        
    }
    
}

- (void)letfPanAction:(UIGestureRecognizer *)pan
{
    if (pan.state == UIGestureRecognizerStateBegan) {
        _startLeftPt = [pan locationInView:_leftImageView];
    }
    CGPoint pt = [pan locationInView:_bgImageView];
    CGFloat rightX, rightY = viewHeight(_leftImageView) / 2.0;
    if (viewWidth(_leftImageView) - _startLeftPt.x + pt.x >= viewOriginX(_rightImageView) - viewWidth(_leftImageView) * 0.5) {
        rightX = viewOriginX(_rightImageView) - viewWidth(_leftImageView) * 0.5;
    } else if (- _startLeftPt.x + pt.x <= 0) {
        rightX = viewWidth(_leftImageView) * 0.5;
    } else {
        rightX = viewWidth(_leftImageView) - _startLeftPt.x + pt.x;
    }
    _leftImageView.center = CGPointMake(rightX, rightY);
    
    _topBgView.frame = CGRectMake(viewOriginX(_leftImageView) + viewWidth(_leftImageView), viewOriginY(_topBgView), viewOriginX(_rightImageView) - viewOriginX(_leftImageView) - viewWidth(_leftImageView), viewHeight(_topBgView));
    _bottomBgView.frame = CGRectMake(viewOriginX(_leftImageView) + viewWidth(_leftImageView), viewOriginY(_bottomBgView), viewOriginX(_rightImageView) - viewOriginX(_leftImageView) - viewWidth(_leftImageView), viewHeight(_bottomBgView));
    
    AVAsset *asset = [AVAsset assetWithURL:self.videoUrl];
    CMTime videoDuration = asset.duration;
    int leftTime = (viewOriginX(_leftImageView) / (viewWidth(_bgImageView) - 60)) * CMTimeGetSeconds(videoDuration);
    _leftLabel.text = [NSString stringWithFormat:@"%d", leftTime];
    
}


- (void)progressValueChange:(UIGestureRecognizer *)pan
{
    UIView *bgView = [self.view viewWithTag:110];
    CGFloat value = [pan locationInView:bgView].x;
 
    CGFloat timeValue = 0;
    if (value <= 0) {
        timeValue = 0;
        [_progressView setProgress:0 animated:YES];
    } else if (value >= viewWidth(_progressView)) {
        [_progressView setProgress:1.0 animated:YES];
        timeValue = CMTimeGetSeconds(player.currentItem.duration);
    } else {
        [_progressView setProgress:value / viewWidth(_progressView) animated:YES];
        timeValue = value / viewWidth(_progressView) * CMTimeGetSeconds(player.currentItem.duration);
    }

    NSLog(@"进度条value = %f 当前时间 Time= %f", _progressView.progress,timeValue);
    CMTime currentTime = CMTimeMake(timeValue * 60, 60);
    [player seekToTime:currentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    if (self.isPlaying) {
//        [self startPlayer];
    } else {
        [self changeProgressLabelValueForTime:currentTime ForVideoDruationTime:CMTimeGetSeconds(player.currentItem.duration)];
    }
}


- (void)changeProgressLabelValueForTime:(CMTime)time ForVideoDruationTime:(CGFloat)druationTime
{
    [self.progressView setProgress:CMTimeGetSeconds(time) / druationTime animated:YES];
    int currentTime = (int)CMTimeGetSeconds(time);
    self.progressLabel.text = [NSString stringWithFormat:@"%d/%ds",currentTime,(int)druationTime];
    NSLog(@"当前视频时间currenttime = %d", currentTime);
}
- (void)buttonAction:(UIButton *)button
{
    button.hidden = YES;
    [self startPlayer];
}

- (void)playerFinished:(NSNotification *)notify
{
    self.isPlaying = NO;
    self.button.hidden = NO;
//    AVPlayerItem *playerItem = (AVPlayerItem *)notify.object;
//    if (playerItem && [playerItem isKindOfClass:[AVPlayerItem class]]) {
//        [playerItem seekToTime:kCMTimeZero];
//        [player replaceCurrentItemWithPlayerItem:playerItem];
//    }
    
}

- (void)startPlayer
{
    [player play];
    self.isPlaying = YES;
}


- (UIImage *)getImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *error = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60) actualTime:NULL error:&error];
    
    NSLog(@"视频画面当前时间帧：%f", CMTimeGetSeconds(CMTimeMake(thumbnailImageTime, 60)));
    
    if (!thumbnailImageRef) {
        return nil;
    } else {
        return [[UIImage alloc] initWithCGImage:thumbnailImageRef];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [player removeTimeObserver:_playerTimeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
