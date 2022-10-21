//
//  TationReminderView.m
//  Hohem Pro
//
//  Created by jolly on 2020/4/12.
//  Copyright © 2020 jolly. All rights reserved.
//

#import "TationReminderView.h"
#import "UILabel+TationLableSize.h"

@interface TationReminderView()

@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

@property (nonatomic, strong) UIView *reminderView;
@property (nonatomic, strong) HohemBaseLabel *titleLab;
@property (nonatomic, strong) HohemBaseLabel *messageLab;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) HohemBaseButton *confirmBtn;
@property (nonatomic, strong) UIView *divideLineView;
@property (nonatomic, strong) HohemBaseButton *cancelBtn;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *confirm;
@property (nonatomic, copy) NSString *cancel;
@property (nonatomic, assign) BOOL showCancel;

@end

@implementation TationReminderView

- (instancetype)initWithTitle:(nullable NSString *)title message:(NSString *)message confirm:(nullable NSString *)confirm cancel:(nullable NSString *)cancel showCancel:(BOOL)showCancel confirmBlock:(nullable void(^)(void))confirmBlock cancelBlock:(nullable void(^)(void))cancelBlock {
    
    self = [super init];
    
    self.title = title ? title : @"Hohem.Alert.Title";
    self.confirm = confirm ? confirm : @"Hohem.Alert.Confirm";
    self.cancel = cancel ? cancel : @"Hohem.Alert.Cancel";
    self.message = message;
    self.showCancel = showCancel;
    self.cancelBlock = cancelBlock;
    self.confirmBlock = confirmBlock;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(Tation_kNotificationInterfaceOrientationWithNotification:) name:Tation_kNotificationInterfaceOrientation object:nil];
    
    [self setUpUI];
    
    return self;
}

- (void)setUpUI {
    
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    
    self.reminderView = [[UIView alloc] init];
    self.reminderView.backgroundColor = [UIColor whiteColor];
    self.reminderView.layer.cornerRadius = 10;
    self.reminderView.layer.masksToBounds = YES;
    [self addSubview:self.reminderView];
    
    self.titleLab = [[HohemBaseLabel alloc]initWithFrame:CGRectZero];
    self.titleLab.font = [UIFont systemFontOfSize:20];
    self.titleLab.textColor = [UIColor blackColor];
    self.titleLab.textAlignment = NSTextAlignmentCenter;
    self.titleLab.text = Tation_Resource_Str(self.title);
    [self.reminderView addSubview:self.titleLab];
    
    self.messageLab = [[HohemBaseLabel alloc]initWithFrame:CGRectZero];
    self.messageLab.font = [UIFont systemFontOfSize:14];
    self.messageLab.textColor = [UIColor blackColor];
    self.messageLab.textAlignment = NSTextAlignmentCenter;
    self.messageLab.numberOfLines = 0;
    self.messageLab.text = Tation_Resource_Str(self.message);
    [self.reminderView addSubview:self.messageLab];
    
    self.lineView = [[UIView alloc] init];
    self.lineView.backgroundColor = [UIColor blackColor];
    [self.reminderView addSubview:self.lineView];
    
    self.confirmBtn = [[HohemBaseButton alloc]init];
    [self.confirmBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.confirmBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [self.confirmBtn setTitle:Tation_Resource_Str(self.confirm) forState:UIControlStateNormal];
    [self.confirmBtn addTarget:self action:@selector(didConfirmBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.reminderView addSubview:self.confirmBtn];
    
    self.divideLineView = [[UIView alloc] init];
    self.divideLineView.backgroundColor = [UIColor blackColor];
    [self.reminderView addSubview:self.divideLineView];
    self.divideLineView.hidden = !self.showCancel;
    
    self.cancelBtn = [[HohemBaseButton alloc]init];
    [self.cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.cancelBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [self.cancelBtn setTitle:Tation_Resource_Str(self.cancel) forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(didCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.reminderView addSubview:self.cancelBtn];
    self.cancelBtn.hidden = !self.showCancel;
    
    [self Tation_kNotificationInterfaceOrientationWithNotification:nil];
}

- (void)didConfirmBtn:(HohemBaseButton *)btn {
    
    [self removeFromSuperview];
    if (self.confirmBlock) self.confirmBlock();
}

- (void)didCancelBtn:(HohemBaseButton *)btn {
    
    [self removeFromSuperview];
    if (self.cancelBlock) self.cancelBlock();
}

- (void)Tation_kNotificationInterfaceOrientationWithNotification:(NSNotification *)notification {
    
    self.interfaceOrientation = Tation_kSharedToolManager.interfaceOrientation;
    
    CGFloat angle = 0;
    switch (self.interfaceOrientation) {
        case 1:
            angle = 0;
            break;
        case 2:
            angle = M_PI;
            break;
        case 3:
            angle = M_PI_2;
            break;
        case 4:
            angle = M_PI_2 * 3;
            break;
        default:
            angle = 0;
            break;
    }
    self.reminderView.transform = CGAffineTransformMakeRotation(angle);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width - Tation_AutoFitWithX(48) * 2;
    CGFloat h = 0;

    CGFloat titleH = [UILabel getHeightByWidth:w title:self.titleLab.text font:self.titleLab.font];
    titleH = titleH < Tation_AutoFitWithX(44) ? Tation_AutoFitWithX(44) : titleH;
    
    CGFloat messageH = [UILabel getHeightByWidth:w title:self.messageLab.text font:self.messageLab.font];
    messageH = messageH < Tation_AutoFitWithX(44) ? Tation_AutoFitWithX(44) : messageH;
    if (!self.message || self.message.length == 0) messageH = Tation_AutoFitWithX(32);
    
    CGFloat actionH = Tation_AutoFitWithX(44);
    
    h = titleH + messageH + Tation_AutoFitWithX(0.5) + actionH;
    
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown || self.interfaceOrientation == UIInterfaceOrientationUnknown) {
        
        self.reminderView.frame = CGRectMake((self.bounds.size.width - w) / 2, (self.bounds.size.height - h) / 2, w, h);
    }else{
        
        self.reminderView.frame = CGRectMake((self.bounds.size.width - h) / 2, (self.bounds.size.height - w) / 2, h, w);
    }
    
    w = self.reminderView.bounds.size.width;
    h = titleH;
    self.titleLab.frame = CGRectMake(0, 0, w, h);
    
    h = messageH;
    self.messageLab.frame = CGRectMake(0, CGRectGetMaxY(self.titleLab.frame), w, h);
    
    h = Tation_AutoFitWithX(0.5);
    self.lineView.frame = CGRectMake(0, CGRectGetMaxY(self.messageLab.frame), w, h);
    
    if (self.showCancel) {
        
        w = (self.reminderView.bounds.size.width - Tation_AutoFitWithX(0.5)) / 2;
        h = actionH;
        self.cancelBtn.frame = CGRectMake(0, CGRectGetMaxY(self.lineView.frame), w, h);
        
        w = Tation_AutoFitWithX(0.5);
        self.divideLineView.frame = CGRectMake(CGRectGetMaxX(self.cancelBtn.frame), CGRectGetMaxY(self.lineView.frame), w, h);
        
        w = self.cancelBtn.bounds.size.width;
        self.confirmBtn.frame = CGRectMake(CGRectGetMaxX(self.cancelBtn.frame), CGRectGetMinY(self.cancelBtn.frame), w, h);
    }else{
        
        w = self.reminderView.bounds.size.width;
        h = actionH;
        self.confirmBtn.frame = CGRectMake(0, CGRectGetMaxY(self.lineView.frame), w, h);
    }
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%s",__FUNCTION__);
}

@end
