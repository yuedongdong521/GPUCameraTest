//
//  GPUCaptureTestViewController.m
//  GPUCameraTest
//
//  Created by ydd on 2019/3/22.
//  Copyright © 2019 ydd. All rights reserved.
//

#import "GPUCaptureTestViewController.h"
#import "GPUCapture.h"
#import "PlayVideoViewController.h"

@interface GPUCaptureTestViewController ()

@property (nonatomic, strong) GPUCapture *capture;

@end

@implementation GPUCaptureTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  [self.capture captureStartRuning];
  UIView *recordBtn = [[UIView alloc] init];
  recordBtn.backgroundColor = [UIColor cyanColor];
  [self.view addSubview:recordBtn];
  
  [recordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.mas_equalTo(self.view.mas_centerX);
    make.size.mas_equalTo(CGSizeMake(50, 50));
    make.bottom.mas_equalTo(self.view).mas_offset(-20);
  }];
  UILongPressGestureRecognizer *longGes = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longGesAction:)];
  longGes.minimumPressDuration = 1;
  [recordBtn addGestureRecognizer:longGes];
}



- (void)longGesAction:(UIGestureRecognizer *)ges
{
  NSLog(@"longGesAction status : %d", ges.state);
  switch (ges.state) {
    case UIGestureRecognizerStateBegan:
      [self.capture startRecord];
      break;
    case UIGestureRecognizerStateEnded: {
      __weak typeof(self) weakSelf = self;
      [self.capture stopRecordCompletionHandler:^(NSString * _Nonnull outputPath) {
        [weakSelf player:outputPath];
      }];
    }
      break;
    case UIGestureRecognizerStateFailed:
    case UIGestureRecognizerStateCancelled:
      [self.capture cancelRecord];
      break;
    default:
      
      break;
  }
}

- (GPUCapture *)capture
{
  if (!_capture) {
    _capture = [[GPUCapture alloc] initWithVideoPreview:self.view];
  }
  return _capture;
}

- (void)player:(NSString *)str
{
  
  PlayVideoViewController *player = [[PlayVideoViewController alloc] init];
  player.videoURL = [NSURL fileURLWithPath:str];
  [self.navigationController pushViewController:player animated:YES];
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
