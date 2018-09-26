//
//  MyGPUMovie.h
//  GPUCameraTest
//
//  Created by ispeak on 2017/12/11.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GPUImage.h"
@interface MyGPUMovie : NSObject<GPUImageMovieDelegate>

@property (nonatomic, strong) GPUImageMovie *movieFile;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *filter;



@end
