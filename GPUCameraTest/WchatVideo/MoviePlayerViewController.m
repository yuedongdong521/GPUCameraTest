//
//  MoviePlayerViewController.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/12/28.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "MoviePlayerViewController.h"
#import "PKChatMessagePlayerView.h"

@interface MoviePlayerViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation MoviePlayerViewController


- (void)viewWillDisappear:(BOOL)animated
{
    [self appWillResignActive:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    _tableView = tableView;
    
    
    //添加切入后台切回前台监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 300;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    
    PKChatMessagePlayerView *playerView = [[PKChatMessagePlayerView alloc] initWithFrame:CGRectMake(20, 5, 300, 280) videoPath:[[NSBundle mainBundle]pathForResource:@"Movie" ofType:@"mp4"]];
    [cell.contentView addSubview:playerView];
    return cell;
}


- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    for (UIView *view in cell.contentView.subviews) {
        if ([view isKindOfClass:[PKChatMessagePlayerView class]]) {
            PKChatMessagePlayerView *player = (PKChatMessagePlayerView *)view;
            [player stop];
            break;
        }
    }
    NSLog(@"将要结束显示时停止播放");
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"将要显示时播放");
    for (UIView *view in cell.contentView.subviews) {
        if ([view isKindOfClass:[PKChatMessagePlayerView class]]) {
            PKChatMessagePlayerView *player = (PKChatMessagePlayerView *)view;
            [player play];
            break;
        }
    }
    
}

//视频停止播放
- (void)appWillResignActive:(NSNotification *)notify
{
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(startVideoPlay) object:nil];
    NSArray *array = [_tableView indexPathsForVisibleRows];

    for (NSIndexPath *indexPath in array) {
        if (indexPath.row < 20) {
            UITableViewCell *cellView = [_tableView cellForRowAtIndexPath:indexPath];
            for (UIView *view in cellView.contentView.subviews) {
                if ([view isKindOfClass:[PKChatMessagePlayerView class]]) {
                    PKChatMessagePlayerView *player = (PKChatMessagePlayerView *)view;
                    [player stop];
                    break;
                }
            }
        }
    }
}

//进入前台通知
- (void)appWillEnterForeground:(NSNotification *)notify
{
    [self performSelector:@selector(startVideoPlay) withObject:nil afterDelay:0.5];
}


//视频播放
- (void)startVideoPlay
{
    NSArray *array = [_tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in array) {
        if (indexPath.row < 20) {
            UITableViewCell *cellView = [_tableView cellForRowAtIndexPath:indexPath];
            for (UIView *view in cellView.contentView.subviews) {
                if ([view isKindOfClass:[PKChatMessagePlayerView class]]) {
                    PKChatMessagePlayerView *player = (PKChatMessagePlayerView *)view;
                    [player play];
                    break;
                }
            }
        }
    }
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
