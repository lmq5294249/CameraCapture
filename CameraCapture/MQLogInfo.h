//
//  MQLogInfo.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MQLogInfo : NSObject

+ (void)writeToFileWithString:(NSString *)tagString fileName:(NSString *)fileName;

+ (NSString *)readFileName:(NSString *)fileName;

+ (void)deleteFileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
