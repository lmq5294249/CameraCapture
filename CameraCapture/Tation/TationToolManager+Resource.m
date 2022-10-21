//
//  TationToolManager+Resource.m
//  Hohem Pro
//
//  Created by Jolly on 2022/5/19.
//  Copyright © 2022 jolly. All rights reserved.
//

#import "TationToolManager+Resource.h"

//是否为资源包资源
#define UserBundleResource NO
#define BundleFileName @"HohemFrameworksBundle.bundle"

@implementation TationToolManager (Resource)

//语言文字适配
- (NSString *)TationResourceManagerWithString:(NSString *)str {
    
    if (UserBundleResource) {
        
        return NSLocalizedStringFromTableInBundle(str, nil, [self bundle], nil);
    }
    return NSLocalizedString(str, nil);
}

//图片适配
- (UIImage *)TationResourceManagerWithImageStr:(NSString *)str {
    
    if (UserBundleResource) {
        
        return [UIImage imageNamed:str inBundle:[self bundle] compatibleWithTraitCollection:nil];
    }
    return [UIImage imageNamed:str];
}

//文件路径适配
- (NSString *)TationResourceManagerWithFilePathStr:(NSString *)str {
    
    if (UserBundleResource) {
        
        return [[self bundle] pathForResource:str ofType:nil];
    }
    return [[NSBundle mainBundle] pathForResource:str ofType:nil];
}

//保存图片到沙盒
- (NSString *)saveImage:(UIImage *)image imageName:(NSString *)name {
    
    NSData *data = UIImagePNGRepresentation(image);
    NSString *fileName = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:name];
    
    if ([data writeToFile:fileName atomically:YES]) {
        
        return fileName;
    }
    return nil;
}

//资源Bundle
- (NSBundle *)bundle {
    
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        bundle = [[NSBundle alloc] initWithPath:[[NSBundle mainBundle] pathForResource:BundleFileName ofType:nil]];
    });
    return bundle;
}

@end
