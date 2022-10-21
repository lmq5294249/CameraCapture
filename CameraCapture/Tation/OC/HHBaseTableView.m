//
//  HHBaseTableView.m
//  Hohem Pro
//
//  Created by jolly on 2020/7/2.
//  Copyright © 2020 jolly. All rights reserved.
//

#import "HHBaseTableView.h"

@implementation HHBaseTableView

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    
    [self initAttribute];
    [self setUpUI];
    
    return self;
}

- (void)initAttribute {
    
    
}

- (void)setUpUI {
    
    self.backgroundColor = [UIColor whiteColor];
}

@end
