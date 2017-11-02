//
//  MyCameraMainView.m
//  GPUCameraTest
//
//  Created by ispeak on 2017/4/6.
//  Copyright © 2017年 ydd. All rights reserved.
//

#import "MyCameraMainView.h"
#import "FilterModel.h"

@interface CameraFilterCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *filterImageView;
@property (nonatomic, strong) UILabel *filterLabel;

@end

@implementation CameraFilterCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        UIImage *filterImage = [UIImage imageNamed:@"filter0@2x.jpg"];
        self.filterImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, self.frame.size.height - 20)];
        self.filterImageView.image = filterImage;
        [self.contentView addSubview:self.filterImageView];
        
        self.filterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 20, self.contentView.frame.size.width, 20)];
        self.filterLabel.textAlignment = NSTextAlignmentCenter;
        self.filterLabel.font = [UIFont systemFontOfSize:12];
        self.filterLabel.layer.shadowRadius = 2;
        self.filterLabel.layer.shadowOffset = CGSizeMake(0, 3);
        self.filterLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        self.filterLabel.layer.shadowOpacity = 0.9;
        self.filterLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:self.filterLabel];
        
    }
    return self;
}

@end

@interface MyCameraMainView ()<UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *filterCollectionView;
@property (nonatomic, strong) FilterModel *filterModel;

@end

@implementation MyCameraMainView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self initView];
      
        
    }
    return self;
}
- (void)closeCameraAction
{
    if ([_delegate respondsToSelector:@selector(closeCamera)]) {
        [_delegate closeCamera];
    }
}

- (void)initView
{
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(10, 30, 60, 40);
    [close setTitle:@"返回" forState:UIControlStateNormal];
    [close setTintColor:[UIColor whiteColor]];
    [close addTarget:self action:@selector(closeCameraAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:close];
    
    UIButton *changeCamera = [UIButton buttonWithType:UIButtonTypeSystem];
    changeCamera.frame = CGRectMake(ScreenWidth - 70, 30, 60, 40);
    [changeCamera setTitle:@"切换" forState:UIControlStateNormal];
    [changeCamera setTintColor:[UIColor whiteColor]];
    [changeCamera addTarget:self action:@selector(changeCameraAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:changeCamera];
    
    UIButton *takePhone = [UIButton buttonWithType:UIButtonTypeSystem];
    takePhone.frame = CGRectMake(ScreenWidth / 2 - 40, ScreenHeight - 90, 80, 80);
    takePhone.backgroundColor = [UIColor redColor];
    takePhone.layer.cornerRadius = 40;
    takePhone.layer.masksToBounds = YES;
    takePhone.layer.borderWidth = 1.0;
    takePhone.layer.borderColor = [UIColor whiteColor].CGColor;
    [takePhone addTarget:self action:@selector(takePhone) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:takePhone];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.itemSize = CGSizeMake(60, 80);
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 1, 0, 1);
    
    _filterModel = [[FilterModel alloc] init];
    
    _filterCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, ScreenHeight - 200, ScreenWidth, 80) collectionViewLayout:flowLayout];
    _filterCollectionView.backgroundColor = [UIColor clearColor];
    _filterCollectionView.delegate = self;
    _filterCollectionView.dataSource = self;
    [self addSubview:_filterCollectionView];
    
    [_filterCollectionView registerClass:[CameraFilterCell class] forCellWithReuseIdentifier:@"filter"];
    
}

- (void)changeCameraAction
{
    if ([_delegate respondsToSelector:@selector(changeCameraActionDeleagate)]) {
        [_delegate changeCameraActionDeleagate];
    }
}

- (void)takePhone
{
    if ([_delegate respondsToSelector:@selector(takePhone)]) {
        [_delegate takePhone];
    }
}

- (void)selectCameraFilterIndex:(NSInteger)index
{
    if ([_delegate respondsToSelector:@selector(selectFilterIndex:)]) {
        [_delegate selectFilterIndex:index];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.filterModel.filterList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    CameraFilterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"filter" forIndexPath:indexPath];
    FilterItem *filterItem = self.filterModel.filterList[indexPath.row];
    cell.filterLabel.text = filterItem.title;
    cell.filterImageView.image = [UIImage imageNamed:filterItem.imageTilte];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectCameraFilterIndex:indexPath.row];
}



@end
