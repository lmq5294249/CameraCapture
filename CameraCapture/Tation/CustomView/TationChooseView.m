//
//  TationChooseView.m
//  Hohem Pro
//
//  Created by jolly on 2019/12/5.
//  Copyright © 2019 jolly. All rights reserved.
//

#import "TationChooseView.h"

@interface TationChooseView()

@property (nonatomic, copy) NSArray *titles;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, copy) NSArray <HohemBaseButton *>*btns;
@property (nonatomic, copy) NSArray <UIView *>*blockViews;
@property (nonatomic, copy) NSArray <UIView *>*selectedViews;

@end

@implementation TationChooseView

- (instancetype)initWithTitles:(NSArray *)titles selectedColor:(UIColor *)selectedColor {
    
    self = [[TationChooseView alloc]init];
    
    self.titles = titles;
    self.selectedColor = selectedColor;
    
    [self setUpUI];
    
    return self;
}

- (void)setUpUI {
    
    self.backgroundColor = [UIColor whiteColor];
    
    NSMutableArray *btnMtArr = [NSMutableArray array];
    for (NSInteger i = 0; i < self.titles.count; i++) {
        
        HohemBaseButton *btn = [[HohemBaseButton alloc]init];
        btn.tag = i;
        [btn addTarget:self action:@selector(didClickBtn:) forControlEvents:UIControlEventTouchUpInside];
        btn.titleLabel.font = Hohem_Font_Title;
        [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [btn setTitle:Tation_Resource_Str(self.titles[i]) forState:UIControlStateNormal];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [self addSubview:btn];
        
        [btnMtArr addObject:btn];
    }
    self.btns = btnMtArr.copy;
    
    NSMutableArray *blockMtArr = [NSMutableArray array];
    for (NSInteger i = 0; i < self.titles.count - 1; i++) {
        
        UIView *view = [[UIView alloc]init];
        view.tag = i;
        view.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:view];
        
        [blockMtArr addObject:view];
    }
    self.blockViews = blockMtArr.copy;
    
    NSMutableArray *selectedMtArr = [NSMutableArray array];
    for (NSInteger i = 0; i < self.titles.count; i++) {
        
        UIView *view = [[UIView alloc]init];
        view.tag = i;
        view.backgroundColor = [UIColor whiteColor];
        [self addSubview:view];
    
        [selectedMtArr addObject:view];
    }
    self.selectedViews = selectedMtArr.copy;
}

- (void)updateUIShow {
    
    self.btns[self.selectedIndex].selected = YES;
    
    for (NSInteger i = 0; i < self.btns.count; i++) {
        
        if (i == self.selectedIndex) {
            
            self.btns[i].selected = YES;
            self.selectedViews[i].backgroundColor = Hohem_kNormalColor;
        }else{
            
            self.btns[i].selected = NO;
            self.selectedViews[i].backgroundColor = [UIColor whiteColor];
        }
    }
}

- (void)didClickBtn:(HohemBaseButton *)btn {
    
    self.selectedIndex = btn.tag;
    [self updateUIShow];
    
    if ([self.delegate respondsToSelector:@selector(TationChooseViewDelegate:selectedTag:)]) {
        
        [self.delegate TationChooseViewDelegate:self selectedTag:btn.tag];
    }
}

- (void)hiddenBlockView:(BOOL)isHidden {
    
    for (UIView *view in self.blockViews) {
        
        view.hidden = isHidden;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat margin = 0;
    CGFloat w = self.bounds.size.width / self.titles.count;
    CGFloat h = self.bounds.size.height / 3 * 2;
    for (NSInteger i = 0; i < self.titles.count; i++) {
        
        self.btns[i].frame = CGRectMake(w * i, self.bounds.size.height / 3, w, h);
    }
    
    w = 0.5;
    h = self.bounds.size.height - 24;
    margin = (self.bounds.size.width - w * self.blockViews.count) / (self.blockViews.count + 1);
    for (NSInteger i = 0; i < self.blockViews.count; i++) {
        
        self.blockViews[i].frame = CGRectMake(w * i + margin * (i + 1), 12, w, h);
    }
    
    w = self.btns[0].bounds.size.width / 3 * 2;
    h = 0.5;
    margin = (self.bounds.size.width - w * self.selectedViews.count) / (self.selectedViews.count + 1);
    for (NSInteger i = 0; i < self.selectedViews.count; i++) {
        
        self.selectedViews[i].frame = CGRectMake((self.bounds.size.width / self.selectedViews.count - w) / 2 + self.bounds.size.width / self.selectedViews.count * i, CGRectGetMaxY(self.bounds) - h, w, h);
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    
    _selectedIndex = selectedIndex;
     [self updateUIShow];
}

@end
