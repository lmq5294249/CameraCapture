//
//  MediaCell.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/26.
//

#import <UIKit/UIKit.h>
#import "MediaModel.h"

typedef NS_ENUM(NSUInteger, MediaButtonType) {
    MediaButtonTypePlay,
    MediaButtonTypeLoad,
    MediaButtonTypeDelete,
};

typedef void(^DidButtonClickBlock)(MediaModel *model, MediaButtonType buttonType);

@interface MediaCell : UITableViewCell


@property (nonatomic, strong) UILabel *fileNameLabel;
@property (nonatomic, strong) UIButton *loadBtn;
@property (nonatomic, strong) UIButton *deleteBtn;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong) MediaModel *model;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, copy)   DidButtonClickBlock didButtonClickBlock;

@end
