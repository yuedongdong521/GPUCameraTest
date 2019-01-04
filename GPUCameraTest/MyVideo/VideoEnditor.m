//
//  VideoEnditor.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/6/9.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "VideoEnditor.h"

@implementation VideoEnditor


- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

//视频中合入音频
- (void)addMusicToVideoFileUrl:(NSURL *)fileUrl ForMusicUrl:(NSURL *)musicUrl CompletionBlock:(void(^)(NSURL *backURL))completionBlock
{
    if (!fileUrl) {
        return;
    }
    //读取视频
    AVAsset *asset = [AVAsset assetWithURL:fileUrl];
    
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    
    //获取视频轨道
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    }
    //获取音频轨道
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
    }
    NSError *error = nil;
    
    //获取目标音频资源
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:musicUrl options:nil];
    AVAssetTrack *newAudioTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio][0];
    
    // 创建组合器
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
        
    // 添加原来的视频轨道到组合器
    if (assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    }
    // 添加原来的音频轨道到组合器
    if (assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
    }

    // Step 3
    // 添加新的音频资源轨道到组合器
    AVMutableCompositionTrack *customAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [customAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [mutableComposition duration]) ofTrack:newAudioTrack atTime:kCMTimeZero error:&error];
    
    
    //对新加入的音频音量变化进行处理
    AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:customAudioTrack];
//    [mixParameters setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:CMTimeRangeMake(kCMTimeZero, mutableComposition.duration)];
    
    [mixParameters setVolume:1 atTime:kCMTimeZero];
    
    //混合音频
    AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];
    mutableAudioMix.inputParameters = @[mixParameters];
    
    [self exportVideoForMutableComposition:mutableComposition ForVideoComposition:nil ForAudioMix:mutableAudioMix ForFileType:AVFileTypeMPEG4 ForOutRUL:[self getVideoOutputFilePath:@"meegaVide"] BackResult:^(BOOL isCompleted, NSURL *videoUrl) {
        if (isCompleted) {
            completionBlock(videoUrl);
        } else {
            completionBlock(nil);
        }
    }];
    
}

//两个视频合成
- (void)addVideoToVideoFileUrl:(NSURL *)fileUrl CompletionBlock:(void(^)(NSURL *backUrl))completionBlock
{
    if (!fileUrl) {
        return;
    }
    CGFloat videoWidth = 0;

    AVAsset *asset = [AVAsset assetWithURL:fileUrl];
    AVAssetTrack *videoTrack = nil;
    AVAssetTrack *audioTrack = nil;
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count != 0) {
        videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        videoWidth = videoTrack.naturalSize.width;
    }
    
    if ([asset tracksWithMediaType:AVMediaTypeAudio].count != 0) {
        audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    }
    
    NSError *error = nil;
    
    NSMutableArray *videoLayerArray = [NSMutableArray array];
    
    AVMutableComposition *mutComposition = [AVMutableComposition composition];
    if (videoTrack != nil) {
        AVMutableCompositionTrack *videoMutCompositionTrack = [mutComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [videoMutCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:&error];
        
        AVMutableVideoCompositionLayerInstruction *videoLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoMutCompositionTrack];
        [videoLayer setOpacity:0.5 atTime:kCMTimeZero];
        
//        CGAffineTransform transform = CGAffineTransformMake(videoTrack.preferredTransform.a, videoTrack.preferredTransform.b, videoTrack.preferredTransform.c, videoTrack.preferredTransform.d, videoTrack.preferredTransform.tx, videoTrack.preferredTransform.ty);

//        transform = CGAffineTransformRotate(transform, M_PI);
        CGAffineTransform rotationTransform = CGAffineTransformMakeRotation(M_PI);
//        CGAffineTransform lationTransform = CGAffineTransformMakeTranslation(videoTrack.naturalSize.width * -1, videoTrack.naturalSize.height * -1);
        CGAffineTransform lation = CGAffineTransformTranslate(rotationTransform, videoTrack.naturalSize.width, videoTrack.naturalSize.height);
        CGAffineTransform transform = GetCGAffineTransformRotateAroundPoint(0, 0, videoTrack.naturalSize.width / 2.0, videoTrack.naturalSize.height / 2.0, M_PI);
        [videoLayer setTransformRampFromStartTransform:videoTrack.preferredTransform toEndTransform:lation timeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)];
        
        [videoLayerArray addObject:videoLayer];
        
    }
    
    if (audioTrack != nil) {
        AVMutableCompositionTrack *audioMutCompositionTrack = [mutComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioMutCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    }
    
    AVAsset *newAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Movie" ofType:@"mp4"]]];
    AVAssetTrack *newVideoTrack = nil;
    AVAssetTrack *newAudioTrack = nil;
    
    if ([newAsset tracksWithMediaType:AVMediaTypeVideo].count != 0) {
        newVideoTrack = [[newAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    }
    
    if ([newAsset tracksWithMediaType:AVMediaTypeAudio].count != 0) {
        newAudioTrack = [[newAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    }
    
    if (newVideoTrack != nil) {
        AVMutableCompositionTrack *newVideoCompositionTrack = [mutComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [newVideoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:newVideoTrack atTime:kCMTimeZero error:&error];
        AVMutableVideoCompositionLayerInstruction *newVideoLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:newVideoCompositionTrack];
        [newVideoLayer setOpacity:0.5 atTime:kCMTimeZero];
        [newVideoLayer setCropRectangle:CGRectMake(0, 0, videoTrack.naturalSize.width, videoTrack.naturalSize.height) atTime:kCMTimeZero];
        
        CGFloat rate = videoWidth / newVideoTrack.naturalSize.width;
        CGAffineTransform transform = newVideoTrack.preferredTransform;
        transform = CGAffineTransformScale(transform, rate, rate);
        [newVideoLayer setTransform:transform atTime:kCMTimeZero];
        
        
        [videoLayerArray addObject:newVideoLayer];
    }
    
    
    AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    videoCompositionInstruction.layerInstructions = videoLayerArray;
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = @[videoCompositionInstruction];
    videoComposition.frameDuration = CMTimeMake(1, 30);
    videoComposition.renderSize =videoTrack.naturalSize;

    
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    if (newAudioTrack != nil) {
        AVMutableCompositionTrack *newAudioCompositionTrack = [mutComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [newAudioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:newAudioTrack atTime:kCMTimeZero error:&error];
        
        AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:newAudioCompositionTrack];
        [mixParameters setVolume:1.0 atTime:kCMTimeZero];
        audioMix.inputParameters = @[mixParameters];
    }
    
    [self exportVideoForMutableComposition:mutComposition ForVideoComposition:videoComposition ForAudioMix:audioMix ForFileType:AVFileTypeMPEG4 ForOutRUL:[self getVideoOutputFilePath:@"addVideoTest"] BackResult:^(BOOL isCompleted, NSURL *videoUrl) {
       
        if (isCompleted) {
            completionBlock(videoUrl);
        } else {
            completionBlock(nil);
        }
        
    }];
    
    
    
}


CGAffineTransform GetCGAffineTransformRotateAroundPoint(float centerX, float centerY, float x, float y, float angle) {
    x = x - centerX;
    y = y - centerY;
    CGAffineTransform trans = CGAffineTransformMakeTranslation(x, y);
    trans = CGAffineTransformRotate(trans, angle);
    trans = CGAffineTransformTranslate(trans, -x, -y);
    return trans;
}

- (NSURL *)getVideoOutputFilePath:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:@"videoFolder"];
    BOOL isDire;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDire]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *fileName = [path stringByAppendingPathComponent:[name stringByAppendingString:@".mp4"]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
    }
    return [NSURL fileURLWithPath:fileName];

}

//剪切视频
- (void)trimVideoForFileUrl:(NSURL *)fileUrl StartTime:(CMTime)startTime EndStr:(CMTime)endTime BackNewVideoUrl:(void(^)(NSURL *url))newVideoURL
{
    AVAsset *asset = [AVAsset assetWithURL:fileUrl];
    AVAssetTrack *assetVideoTrack = nil;
    AVAssetTrack *assetAudioTrack = nil;
    if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
        assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    }
    
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
        assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    }
    
    NSError *error = nil;
    CMTime newVideoDuration = CMTimeSubtract(endTime, startTime);
    
    NSLog(@"新视频时长newDuration = %f", CMTimeGetSeconds(newVideoDuration));
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    if (assetVideoTrack != nil) {
        AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(startTime, newVideoDuration) ofTrack:assetVideoTrack atTime:kCMTimeZero error:&error];
    }
    
    if (assetAudioTrack != nil) {
        AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(startTime, newVideoDuration) ofTrack:assetAudioTrack atTime:kCMTimeZero error:&error];
    }
    
    [self exportVideoForMutableComposition:mutableComposition ForVideoComposition:nil ForAudioMix:nil ForFileType:AVFileTypeMPEG4 ForOutRUL:[self getVideoOutputFilePath:@"trimVideoTest"] BackResult:^(BOOL isCompleted, NSURL *videoUrl) {
        if (isCompleted) {
            if (newVideoURL) {
                newVideoURL(videoUrl);
            }
        } else {
            if (newVideoURL) {
                newVideoURL(videoUrl);
            }
        }
        
    }];
    
    
}

//视频变速
- (void)changeVideoSpeedForUrl:(NSURL *)url ForSpeedScale:(CGFloat)scale ForBackNewVideoUrl:(void(^)(NSURL *newUrl))BackNewVideoUrl
{
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    AVAssetTrack *videoTrack = nil;
    AVAssetTrack *audioTrack = nil;
    if ([asset tracksWithMediaType:AVMediaTypeVideo]) {
        videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    }
    if ([asset tracksWithMediaType:AVMediaTypeAudio]) {
        audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    }
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    if (videoTrack != nil) {
        AVMutableCompositionTrack *videoCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(asset.duration.value, asset.duration.timescale)) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
        [videoCompositionTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(asset.duration.value, asset.duration.timescale)) toDuration:CMTimeMake(asset.duration.value * scale , asset.duration.timescale)];
    }
    
    if (audioTrack != nil) {
        AVMutableCompositionTrack *audioCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioTrack atTime:kCMTimeZero error:nil];
        [audioCompositionTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(asset.duration.value, asset.duration.timescale)) toDuration:CMTimeMake(asset.duration.value * scale , asset.duration.timescale)];
    }
    
    
    [self exportVideoForMutableComposition:mutableComposition ForVideoComposition:nil ForAudioMix:nil ForFileType:AVFileTypeMPEG4 ForOutRUL:[self getVideoOutputFilePath:@"speedVideoTest"] BackResult:^(BOOL isCompleted, NSURL *videoUrl) {
        if (isCompleted) {
            if (BackNewVideoUrl) {
                BackNewVideoUrl(videoUrl);
            }
        } else {
            if (BackNewVideoUrl) {
                BackNewVideoUrl(nil);
            }
        }
    }];
    
}

//视频合成
- (void)mergeAndExportVideosAtFileURLs:(NSMutableArray *)fileURLArray ForNewVideoHWRate:(CGFloat)newVideoHWRate ForBackNewVideoUrl:(void (^)(NSURL *newVideoUrl))BackNewVideoUrl
{
    if (fileURLArray.count < 1) {
        return;
    }
    NSError *error = nil;
    CGSize renderSize = CGSizeMake(0, 0);
    
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    CMTime totalDuration = kCMTimeZero;
    
    //存放所有音视频数据
    NSMutableArray *assetArray = [[NSMutableArray alloc] init];
    //存放所有视频轨道数据
    NSMutableArray *assetTrackArray = [[NSMutableArray alloc] init];
    
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
    if (newVideoHWRate == 0) {
        newVideoHWRate = renderSize.height / renderSize.width;
    }
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
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruciton.layerInstructions = layerInstructionArray;
    //创建用来添加AVMutableCompositionTrack的，你可以把它想象成用来调度每个视频次序，时间的这么一个调度器。
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = CGSizeMake(renderW, renderW * newVideoHWRate);
  
    //导出视频
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.videoComposition = mainCompositionInst;
    exporter.outputURL = [self getVideoOutputFilePath:@"videoMerge"];
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (BackNewVideoUrl) {
                BackNewVideoUrl(exporter.outputURL);
            }
        });
    }];
}

- (void)cutOutVideosAtFileURL:(NSURL *)fileURL ForCutSize:(CGSize)cutSize ForBackNewVideoUrl:(void (^)(NSURL *newVideoUrl))BackNewVideoUrl
{
  NSError *error = nil;
  
  NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
  
  AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
  
  CMTime totalDuration = kCMTimeZero;
  
  AVAsset *asset = [AVAsset assetWithURL:fileURL];
  
  NSArray* tmpAry =[asset tracksWithMediaType:AVMediaTypeVideo];
  if (tmpAry.count == 0) {
    if (BackNewVideoUrl) {
      BackNewVideoUrl(nil);
    }
    return;
  }
  
  AVAssetTrack *assetTrack = [tmpAry objectAtIndex:0];
  
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
  
  CGFloat rateX = cutSize.width / assetTrack.naturalSize.width;
  CGFloat rateY = cutSize.height / assetTrack.naturalSize.height;
  
  NSLog(@"原视频分辨率 width : %@, height : %@", @(assetTrack.naturalSize.width), @(assetTrack.naturalSize.height));
  
  CGAffineTransform layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rateX, assetTrack.preferredTransform.ty * rateY);
  
  layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -0));
  layerTransform = CGAffineTransformScale(layerTransform, rateX, rateY);
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
  
  //视频合成路径
  AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
  mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
  mainInstruciton.layerInstructions = layerInstructionArray;
  //创建用来添加AVMutableCompositionTrack的，你可以把它想象成用来调度每个视频次序，时间的这么一个调度器。
  AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
  mainCompositionInst.instructions = @[mainInstruciton];
  mainCompositionInst.frameDuration = CMTimeMake(1, 30);
  mainCompositionInst.renderSize = cutSize;
  
  //导出视频
  AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetLowQuality];
  exporter.videoComposition = mainCompositionInst;
  exporter.outputURL = [self getVideoOutputFilePath:@"videoMerge"];
  exporter.outputFileType = AVFileTypeMPEG4;
  exporter.shouldOptimizeForNetworkUse = YES;
  [exporter exportAsynchronouslyWithCompletionHandler:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      if (BackNewVideoUrl) {
        BackNewVideoUrl(exporter.outputURL);
      }
    });
  }];
}




- (void)exportVideoForMutableComposition:(AVMutableComposition *)mutableComposition ForVideoComposition:(AVMutableVideoComposition *)videoComposition ForAudioMix:(AVMutableAudioMix *)audioMix ForFileType:(NSString *)fileType ForOutRUL:(NSURL *)outURL BackResult:(void(^)(BOOL isCompleted, NSURL *videoUrl))resultBlock
{
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:[mutableComposition copy] presetName:AVAssetExportPreset1280x720];
    exportSession.videoComposition = videoComposition;
    exportSession.audioMix = audioMix;
    exportSession.outputFileType = fileType;
    exportSession.outputURL = outURL;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exportSession.status) {
            case AVAssetExportSessionStatusCompleted:
             
                // Step 3
                // Notify AVSEViewController about export completion
                resultBlock(YES, outURL);
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Failed:%@",exportSession.error);
                resultBlock(NO, outURL);
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Canceled:%@",exportSession.error);
                resultBlock(NO, outURL);
                break;
            default:
                break;

        }
    }];
}


@end
