//
//  FilterModel.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/4/6.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "FilterModel.h"

@implementation FilterItem

- (instancetype)initWithCategory:(uint)category Title:(NSString *)title ImageTitle:(NSString *)imageTitle LookupImageName:(NSString *)name
{
    self = [super init];
    if (self) {
        self.category = category;
        self.title = title;
        self.imageTilte = imageTitle;
        self.lookupImageName = name;
    }
    return self;
}

@end

@implementation FilterModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initFilterList];
    }
    return self;
}

- (void)initFilterList
{
    NSArray *filterTitleArray = @[kFilterNone,
                                  kFilterZiRan,
                                  kFilterTianMi,
                                  kFilterQingLiang,
                                  kFilterFenNen,
                                  kFilterFuGu,
                                  kFilterRouGuang,
                                  kFilterWeiMei,
                                  kFilterHeiBai,
                                  kFilterABaoSe,
                                  kFilterHuaiJiu,
                                  kFilterDianYa,
                                  kFilterLuoKeKe];
    NSArray *nameArray = @[@"lookupMeiyan", @"lookupZiran", @"lookupTianmei", @"lookupQingliang", @"lookupFennen", @"lookupFugu", @"lookupRouguang", @"lookupWeimei", @"lookupHeibai", @"lookupAbaose", @"lookupHuaijiu", @"lookupDianya", @"lookupKeke"];
    self.filterList = [NSMutableArray array];
    for (int i = 0; i < filterTitleArray.count; i++) {
        NSString *imageStr = @"filter0@2x.jpg";
        FilterItem *item = [[FilterItem alloc] initWithCategory:kFilterStartTag + i Title:filterTitleArray[i] ImageTitle:imageStr LookupImageName:nameArray[i]];
        [self.filterList addObject:item];
    }
    
}

@end
