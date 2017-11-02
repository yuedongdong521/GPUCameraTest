//
//  MyLookupFilter.h
//  GPUCameraTest
//
//  Created by ispeak on 2017/4/6.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface MyLookupFilter : GPUImageFilterGroup

@property (nonatomic, strong) GPUImagePicture *lookupImageSource;

- (instancetype)initWithName:(NSString *)nameStr;
@end
