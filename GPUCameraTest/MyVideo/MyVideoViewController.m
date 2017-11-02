//
//  MyVideoViewController.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/6/6.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "MyVideoViewController.h"
#import "VideoCameraView.h"
#import "PlayVideoViewController.h"

@interface MyVideoViewController ()<VideoCameraViewDelegate>

@end

@implementation MyVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    VideoCameraView *view = [[VideoCameraView alloc] init];
    view.delegate = self;
    [self.view addSubview:view];
    
}

- (void)quiteDelegate
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)recordFinishForVideoPath:(NSURL *)videoUrl
{
    PlayVideoViewController* view = [[PlayVideoViewController alloc]init];
    view.videoURL = videoUrl;
    [self presentViewController:view animated:YES completion:nil];
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
