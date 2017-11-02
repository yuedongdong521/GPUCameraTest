//
//  FilterModel.h
//  GPUCameraTest
//
//  Created by ispeak on 2017/4/6.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FilterItem : NSObject
@property (nonatomic, assign) uint category;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *imageTilte;
@property (nonatomic, strong) NSString *lookupImageName;
@end


@interface FilterModel : NSObject

@property (nonatomic, strong) NSMutableArray *filterList;



@end
