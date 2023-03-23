//
//  MediaTableView.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/26.
//


#import <UIKit/UIKit.h>
#import "MediaModel.h"

@protocol MediaButtonDelegate <NSObject>

- (void)didPlayMediaWithModel:(MediaModel *)model;
- (void)didLoadMediaWithModel:(MediaModel *)model;
- (void)didDeleteMediaWithModel:(MediaModel *)model;

- (void)didRequestMediaThumbWith:(NSMutableArray *)array meidaType:(MediaType)type;

@end

NS_ASSUME_NONNULL_BEGIN

@interface MediaTableView : UIView

@property (nonatomic, weak) id<MediaButtonDelegate> delegate;

@property (nonatomic, strong) NSMutableArray *dataArray;

@property (nonatomic, assign) MediaType curMediaType;

@property (nonatomic, strong) NSMutableDictionary *thumbDict;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
