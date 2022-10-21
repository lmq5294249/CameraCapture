//
//  HohemBaseLabel.m
//  Hohem Pro
//
//  Created by jolly on 2020/6/30.
//  Copyright © 2020 jolly. All rights reserved.
//

#import "HohemBaseLabel.h"

@interface HohemBaseLabel ()

@property (nonatomic, assign) UIEdgeInsets insets;

@end

@implementation HohemBaseLabel

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
    
    self.verticalAlignment = HohemBaseLabelTextVertical_Normal;
    self.numberOfLines = 0;
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
    
    CGRect textRect = [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    
    if (self.verticalAlignment == HohemBaseLabelTextVertical_Up) {
        
        textRect.origin.y = bounds.origin.y;
        
        return textRect;
    }else{
        
        return textRect;
    }
}

-(void)drawTextInRect:(CGRect)requestedRect {
    
    if (self.verticalAlignment == HohemBaseLabelTextVertical_Normal) {
        
        [super drawTextInRect:UIEdgeInsetsInsetRect(requestedRect, self.insets)];
    }else if (self.verticalAlignment == HohemBaseLabelTextVertical_Up) {
        
        CGRect actualRect = [self textRectForBounds:requestedRect limitedToNumberOfLines:self.numberOfLines];
        [super drawTextInRect:actualRect];
    }else{
        
        [super drawTextInRect:requestedRect];
    }
}

- (void)setInsets:(UIEdgeInsets)insets {
    
    _insets = insets;
    [self setNeedsDisplay];
}

@end
