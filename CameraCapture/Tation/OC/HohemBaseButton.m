//
//  HohemBaseButton.m
//  Hohem Pro
//
//  Created by jolly on 2020/6/30.
//  Copyright © 2020 jolly. All rights reserved.
//

#import "HohemBaseButton.h"

@implementation HohemBaseButton

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    [self initAttribute];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    [self initAttribute];
    return self;
}

- (void)initAttribute {
    
    self.titleLabel.numberOfLines = 0;
}

@end
