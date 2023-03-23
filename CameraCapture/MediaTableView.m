//
//  MediaTableView.m
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/26.
//

#import "MediaTableView.h"
#import "TationToolManager.h"
#import "MediaCell.h"


static NSString *btCellIdentifier = @"bluetoothCellIdentifier";

@interface MediaTableView ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UILabel *mediaLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGFloat cellHeight;
@property (nonatomic, strong) NSMutableArray *requestArray; //申请缩略图数组

@end


@implementation MediaTableView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
        self.thumbDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setupUI
{
    CGFloat screenWidth = CGRectGetWidth(self.frame);
    CGFloat screenHeight = CGRectGetHeight(self.frame);
    self.backgroundColor = [UIColor clearColor];
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    [self addSubview:backgroundView];
    backgroundView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.65];
    
    CGFloat w = Tation_AutoFitWithX(44);
    CGFloat h = Tation_AutoFitWithX(44);
    CGFloat bottomHeightValue = Tation_BottomSafetyDistance;
    if (bottomHeightValue == 0) {
        bottomHeightValue = Tation_AutoFitWithX(16);
    }
    CGFloat x = CGRectGetWidth(self.frame) - Tation_AutoFitWithX(16 + 44);
    CGFloat y = Tation_AutoFitWithX(8);
    [self addSubview:self.backBtn];
    [self.backBtn setFrame:CGRectMake(x, y, w, h)];
    
    w = Tation_AutoFitWithX(180);
    h = Tation_AutoFitWithX(44);
    x = (CGRectGetWidth(self.frame) - w)/2;
    y = Tation_AutoFitWithX(8);
    self.mediaLabel.frame = CGRectMake(x, y, w, h);
    [self addSubview:self.mediaLabel];
    
    w = CGRectGetWidth(self.frame);
    h = CGRectGetHeight(self.frame) - Tation_AutoFitWithX(44);
    x = 0;
    y = Tation_AutoFitWithX(54);
    self.cellHeight = 120;
    self.tableView.frame = CGRectMake(x, y, w, h);
    [self addSubview:self.tableView];
}

- (void)didClickBackButton:(UIButton *)btn
{
    [self removeFromSuperview];
}

- (void)setDataArray:(NSMutableArray *)dataArray
{
    _dataArray = dataArray;
    [self.tableView reloadData];
}

- (void)reloadData
{
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate
//初始化tableView时设置
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
 if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
    [cell setSeparatorInset:UIEdgeInsetsZero];
 }
  if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
    [cell setLayoutMargins:UIEdgeInsetsZero]; }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MediaCell *cell = [tableView dequeueReusableCellWithIdentifier:btCellIdentifier];
    if (cell == nil) {
        cell = [[MediaCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:btCellIdentifier];
    }
    cell.backgroundColor = [UIColor clearColor];
    MediaModel *model = self.dataArray[indexPath.row];
    model.index = indexPath.row;
    [cell setModel:model];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.didButtonClickBlock = ^(MediaModel *model, MediaButtonType buttonType) {
        if (buttonType == MediaButtonTypePlay) {
            [self.delegate didPlayMediaWithModel:model];
        }
        else if (buttonType == MediaButtonTypeLoad)
        {
            [self.delegate didLoadMediaWithModel:model];
        }
        else if (buttonType == MediaButtonTypeDelete)
        {
            [self.delegate didDeleteMediaWithModel:model];
            [self.dataArray removeObjectAtIndex:model.index];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    };
    
    if (self.thumbDict) {
        UIImage *image = [self.thumbDict objectForKey:model.fileName];
        if (image) {
            [cell.thumbView setImage:image];
        }
        else{
            //加入申请数组中
            [self.requestArray addObject:model];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog(@"打印触摸位置%d",(int)indexPath.row);

    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellHeight;
}

#pragma mark - Scrollview
//刷新缩略图
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"------tableview停止滚动------");
    if (self.requestArray.count > 0 && self.delegate) {
        [self.delegate didRequestMediaThumbWith:self.requestArray meidaType:_curMediaType];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        // 停止类型3
        BOOL dragToDragStop = scrollView.tracking && !scrollView.dragging && !scrollView.decelerating;
        if (dragToDragStop) {
            
            NSLog(@"------tableview停止滚动------");
            if (self.requestArray && self.delegate) {
                [self.delegate didRequestMediaThumbWith:self.requestArray meidaType:_curMediaType];
            }
        }
    }
}

#pragma mark - 懒加载

- (UIButton *)backBtn
{
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"HH.BootView.Cancel"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(didClickBackButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (UILabel *)mediaLabel
{
    if (!_mediaLabel) {
        _mediaLabel = [[UILabel alloc] init];
        _mediaLabel.font = [UIFont systemFontOfSize:16.0];
        _mediaLabel.textColor = [UIColor whiteColor];
        _mediaLabel.textAlignment = NSTextAlignmentCenter;
        _mediaLabel.backgroundColor = [UIColor clearColor];
        _mediaLabel.text = @"文件列表";
    }
    return _mediaLabel;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.sectionFooterHeight = 0;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        if ([_tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [_tableView setSeparatorInset:UIEdgeInsetsZero];
        }
        if ([_tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            [_tableView setLayoutMargins:UIEdgeInsetsZero];
        }
    }
    return _tableView;
}

- (NSMutableArray *)requestArray
{
    if (!_requestArray) {
        _requestArray = [NSMutableArray array];
    }
    return _requestArray;
}

@end
