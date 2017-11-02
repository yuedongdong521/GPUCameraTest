//
//  MyLookupFilter.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/4/6.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "MyLookupFilter.h"

@implementation MyLookupFilter

- (instancetype)initWithName:(NSString *)nameStr
{
    self = [super init];
    if (self) {
        UIImage *image = [UIImage imageNamed:nameStr];
        self.lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];
        GPUImageLookupFilter *lookupFilter = [[GPUImageLookupFilter alloc] init];
        [self addTarget:lookupFilter];
        [self.lookupImageSource addTarget:lookupFilter atTextureLocation:1];
        [self.lookupImageSource processImage];
        self.initialFilters = @[lookupFilter];
        self.terminalFilter = lookupFilter;
    }
    return self;
}


@end
