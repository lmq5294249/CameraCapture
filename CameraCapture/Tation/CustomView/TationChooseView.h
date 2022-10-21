//
//  TationChooseView.h
//  Hohem Pro
//
//  Created by jolly on 2019/12/5.
//  Copyright © 2019 jolly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TationChooseViewDelegate;

@interface TationChooseView : UIView

@property (nonatomic, weak) id <TationChooseViewDelegate>delegate;
@property (nonatomic, assign) NSInteger selectedIndex;

- (instancetype)initWithTitles:(NSArray *)titles selectedColor:(UIColor *)selectedColor;
- (void)hiddenBlockView:(BOOL)isHidden;

@end

@protocol TationChooseViewDelegate <NSObject>

- (void)TationChooseViewDelegate:(TationChooseView *)chooseView selectedTag:(NSInteger)tag;

@end

NS_ASSUME_NONNULL_END
