//
//  TationToolManager+Resource.h
//  Hohem Pro
//
//  Created by Jolly on 2022/5/19.
//  Copyright © 2022 jolly. All rights reserved.
//

#import "TationToolManager.h"

#define Tation_Resource_Str(A) [Tation_kSharedToolManager TationResourceManagerWithString:A]
#define Tation_Resource_Image(A) [Tation_kSharedToolManager TationResourceManagerWithImageStr:A]
#define Tation_Resource_Path(A) [Tation_kSharedToolManager TationResourceManagerWithFilePathStr:A]

NS_ASSUME_NONNULL_BEGIN

@interface TationToolManager (Resource)

//语言文字适配
- (NSString *)TationResourceManagerWithString:(NSString *)str;
//图片适配
- (UIImage *)TationResourceManagerWithImageStr:(NSString *)str;
//文件路径适配
- (NSString *)TationResourceManagerWithFilePathStr:(NSString *)str;
//保存图片到沙盒
- (NSString *)saveImage:(UIImage *)image imageName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
