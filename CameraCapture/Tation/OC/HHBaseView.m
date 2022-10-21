//
//  HHBaseView.m
//  Hohem Pro
//
//  Created by jolly on 2020/7/3.
//  Copyright © 2020 jolly. All rights reserved.
//

#import "HHBaseView.h"

@implementation HHBaseView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    [self initAttribute];
    [self setUpUI];
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    [self initAttribute];
    [self setUpUI];
    
    return self;
}

- (void)initAttribute {
    
    
}

- (void)setUpUI {
    
    self.backgroundColor = [UIColor whiteColor];
}

- (void)updateOrientation:(UIInterfaceOrientation)interfaceOrientation angle:(CGFloat)angle {
    
    
}

@end
