//
//  MyFilterGroup.h
//  GPUCameraTest
//
//  Created by ispeak on 2017/4/6.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@class GPUImageCombinationFilter;
@interface MyFilterGroup : GPUImageFilterGroup
{
    GPUImageBilateralFilter *bilateralFilter; //face
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter; //edge
    GPUImageCombinationFilter *combinationFilter;
    GPUImageHSBFilter *hsbFilter;
}


@end
