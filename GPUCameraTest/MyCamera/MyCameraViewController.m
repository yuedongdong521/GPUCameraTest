//
//  MyCameraViewController.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/4/6.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "MyCameraViewController.h"
#import "GPUImage.h"
#import "GPUImageBeautifyFilter.h"
#import "MyCameraMainView.h"
#import "MyLookupFilter.h"
#import "FilterModel.h"

@interface MyCameraViewController () <MyCameraMainViewDelegate>
@property (nonatomic, strong) GPUImageStillCamera *stillCamera; //静态相机
@property (nonatomic, strong) GPUImageBeautifyFilter *meiyanFilter;
@property (nonatomic, strong) GPUImageView *gpuImageView;
@property (nonatomic, strong) GPUImageFilterGroup *groupFilter;
@property (nonatomic, strong) MyLookupFilter *lookupImageFilterGroup;
@property (nonatomic, assign) NSInteger currentFilterIndex;
@property (nonatomic, strong) FilterModel *filterModel;
@end

@implementation MyCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initStillCamera];
    [self initFilterGroup];
}

- (FilterModel *)filterModel
{
    if (!_filterModel) {
        _filterModel = [[FilterModel alloc] init];
    }
    return _filterModel;
}

- (void)initFilterGroup
{
    
}

- (void)closeCamera
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initStillCamera
{
    _stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionFront];
    _stillCamera.horizontallyMirrorFrontFacingCamera = YES;
    _stillCamera.horizontallyMirrorRearFacingCamera = NO;
    
    _meiyanFilter = [[GPUImageBeautifyFilter alloc] init];
    
    self.gpuImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    self.gpuImageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;//按比例中心放大
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;//UI方向
    [self.stillCamera addTarget:self.meiyanFilter];
    
    [self.meiyanFilter addTarget:self.gpuImageView];
    [self.view addSubview:_gpuImageView];
    [self.stillCamera startCameraCapture];
    
    MyCameraMainView *camerView = [[MyCameraMainView alloc] initWithFrame:self.view.bounds];
    camerView.delegate = self;
    [self.view addSubview:camerView];
}

- (void)takePhone
{
    [self.stillCamera capturePhotoAsImageProcessedUpToFilter:self.lookupImageFilterGroup withCompletionHandler:^(UIImage *processedImage, NSError *error) {
        if (error) {
            
        } else {
            if (processedImage) {
                UIImageWriteToSavedPhotosAlbum(processedImage, self, @selector(image:didfinishSavingWithError:contextInfo:), NULL);
            }
        }
    }];
}

- (void)image:(UIImage *)image didfinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (image == nil) {
        return;
    }
    NSString *msg = @"保存图片成功";
    if(error != NULL){
        msg = @"保存图片失败" ;
    }
    NSLog(@"%@",msg);
}

- (void)selectFilterIndex:(NSInteger)index
{
    [self.meiyanFilter removeAllTargets];
    [self.groupFilter removeAllTargets];
    [self.stillCamera removeAllTargets];
    self.currentFilterIndex = index;
    FilterItem *item = self.filterModel.filterList[index];
    NSString *lookupImageName= item.lookupImageName;
    NSLog(@"%@", lookupImageName);
    self.lookupImageFilterGroup = [[MyLookupFilter alloc] initWithName:lookupImageName];
    self.groupFilter = [[GPUImageFilterGroup alloc] init];
    [self.groupFilter addTarget:self.meiyanFilter];
    [self.meiyanFilter addTarget:self.lookupImageFilterGroup];
    self.groupFilter.initialFilters = @[self.meiyanFilter];
    self.groupFilter.terminalFilter = self.lookupImageFilterGroup;
    
    [self.stillCamera addTarget:self.groupFilter];
    [self.groupFilter addTarget:self.gpuImageView];
}

- (void)changeCameraActionDeleagate
{
    [self.stillCamera rotateCamera];
    [self selectFilterIndex:_currentFilterIndex];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
