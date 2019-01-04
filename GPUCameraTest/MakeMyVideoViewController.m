//
//  MakeMyVideoViewController.m
//  GPUCameraTest
//
//  Created by ydd on 2018/12/25.
//  Copyright © 2018 ydd. All rights reserved.
//

#import "MakeMyVideoViewController.h"
#import "VideoEnditor.h"
#import <AVFoundation/AVFoundation.h>

#define VideoType @"public.movie"

@interface MakeMyVideoViewController ()<UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UITextField *widthField;
@property (nonatomic, strong) UITextField *heightField;

@end

@implementation MakeMyVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  
  self.view.backgroundColor = [UIColor whiteColor];
  [self.view addSubview:self.widthField];
  [self.view addSubview:self.heightField];
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
  [btn setTitle:@"选取" forState:UIControlStateNormal];
  btn.frame = CGRectMake(20, 150, 100, 50);
  [btn addTarget:self action:@selector(getVideo) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:btn];
  
  UIButton *cutupBtn = [UIButton buttonWithType:UIButtonTypeSystem];
  [cutupBtn setTitle:@"start" forState:UIControlStateNormal];
  cutupBtn.frame = CGRectMake(20, 250, 100, 50);
  [cutupBtn addTarget:self action:@selector(cutupVideo) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:cutupBtn];
  
}

- (void)getVideo
{
  
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.delegate = self;
  picker.allowsEditing = NO;
  picker.videoMaximumDuration = 30;
  picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
  picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
  NSLog(@"%@", AVMediaTypeVideo);
  picker.mediaTypes = @[VideoType];
  
  [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
  [picker dismissViewControllerAnimated:YES completion:nil];
  NSString *mediaType = info[UIImagePickerControllerMediaType];

  if ([mediaType isEqualToString:VideoType]) {
    NSURL *pathURL = info[UIImagePickerControllerMediaURL];
    [self cutOutVideosWithVideoPath:pathURL];
  }
}

- (void)cutupVideo
{
  
}

- (UITextField *)widthField
{
  if (!_widthField) {
    _widthField = [[UITextField alloc] initWithFrame:CGRectMake(20, 80, 150, 50)];
    _widthField.placeholder = @"请输入视频宽";
    _widthField.keyboardType = UIKeyboardTypeNumberPad;
    _widthField.returnKeyType = UIReturnKeyDone;
    _widthField.layer.borderColor = [UIColor blackColor].CGColor;
    _widthField.layer.borderWidth = 0.5;
    _widthField.layer.cornerRadius = 5;
    _widthField.layer.masksToBounds = YES;
  }
  return _widthField;
}

- (UITextField *)heightField
{
  if (!_heightField) {
    _heightField = [[UITextField alloc] initWithFrame:CGRectMake(190, 80, 150, 50)];
    _heightField.placeholder = @"请输入视频宽";
    _heightField.keyboardType = UIKeyboardTypeNumberPad;
    _heightField.returnKeyType = UIReturnKeyDone;
    _heightField.layer.borderColor = [UIColor blackColor].CGColor;
    _heightField.layer.borderWidth = 0.5;
    _heightField.layer.cornerRadius = 5;
    _heightField.layer.masksToBounds = YES;
  }
  return _heightField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  return YES;
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
 
}

- (void)cutOutVideosWithVideoPath:(NSURL *)url
{
  VideoEnditor *enditor = [[VideoEnditor alloc] init];
  CGFloat width = [self.widthField.text floatValue];
  CGFloat height = [self.heightField.text floatValue];
  CGSize cutSize = CGSizeMake(width, height);
  [enditor cutOutVideosAtFileURL:url ForCutSize:cutSize ForBackNewVideoUrl:^(NSURL *newVideoUrl) {
    [self saveVideo:newVideoUrl.path];
  }];
}


//videoPath为视频下载到本地之后的本地路径
- (void)saveVideo:(NSString *)videoPath{
  
  if (videoPath) {
    
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath)) {
      //保存相册核心代码
      UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
    
  }
  
}
//保存视频完成之后的回调
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
  AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
  NSLog(@"video duration : %f", CMTimeGetSeconds(asset.duration));
  if (error) {
    NSLog(@"保存视频失败%@", error.localizedDescription);
  }
  else {
    NSLog(@"保存视频成功");
  }
  
}

-(UIView *)findView:(UIView *)aView withName:(NSString *)name{
  Class cl = [aView class];
  NSString *desc = [cl description];
  if ([name isEqualToString:desc])
    return aView;
  for (UIView *view in aView.subviews) {
    Class cll = [view class];
    NSString *stringl = [cll description];
    if ([stringl isEqualToString:name]) {
      return view;
    }
  }
  return nil;
}

-(void)addSomeElements:(UIViewController *)viewController{
  UIView *PLCameraView = [self findView:viewController.view withName:@"PLCameraView"];
  UIView *PLCropOverlay = [self findView:PLCameraView withName:@"PLCropOverlay"];
  UIView *bottomBar = [self findView:PLCropOverlay withName:@"PLCropOverlayBottomBar"];
  UIImageView *bottomBarImageForSave = [bottomBar.subviews objectAtIndex:0];
  UIButton *retakeButton=[bottomBarImageForSave.subviews objectAtIndex:0];
  [retakeButton setTitle:@"重拍"  forState:UIControlStateNormal];
  UIButton *useButton=[bottomBarImageForSave.subviews objectAtIndex:1];
  [useButton setTitle:@"保存" forState:UIControlStateNormal];
  UIImageView *bottomBarImageForCamera = [bottomBar.subviews objectAtIndex:1];
  UIButton *cancelButton=[bottomBarImageForCamera.subviews objectAtIndex:1];
  [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  [self addSomeElements:viewController];
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
