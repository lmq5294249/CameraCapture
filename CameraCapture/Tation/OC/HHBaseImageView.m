//
//  HHBaseImageView.m
//  Hohem Pro
//
//  Created by jolly on 2020/7/1.
//  Copyright © 2020 jolly. All rights reserved.
//

#import "HHBaseImageView.h"

@implementation HHBaseImageView

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
    
    self.contentMode = UIViewContentModeScaleAspectFit;
    self.userInteractionEnabled = YES;
}

- (void)setUpUI {
    
    self.backgroundColor = [UIColor clearColor];
}

@end
