//
//  MQLogInfo.m
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/27.
//

#import "MQLogInfo.h"

@interface MQLogInfo ()

@end

@implementation MQLogInfo

+ (void)writeToFileWithString:(NSString *)tagString fileName:(NSString *)fileName {
    
    NSString *filePathStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];//NSCachesDirectory
    NSString *fullPathStr = [filePathStr stringByAppendingPathComponent:@"tagDir"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fullPathStr]) {
        [fileManager createDirectoryAtPath:fullPathStr withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if (!fileName) {//没指定文件名，默认按当前时间命名
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *dateStr = [formatter stringFromDate:[NSDate date]];
        fileName = [NSString stringWithFormat:@"%@.log", dateStr];
    }
    
    NSString *tagPathStr = [fullPathStr stringByAppendingPathComponent:fileName];
    
    if ([fileManager fileExistsAtPath:tagPathStr]) {//在已存在的文件后面追加内容
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:tagPathStr];
        [fileHandle seekToEndOfFile];
        NSData *stringData = [tagString dataUsingEncoding:NSUTF8StringEncoding];
        [fileHandle writeData:stringData];
        [fileHandle closeFile];
    }
    else {//不存在文件时，创建并写入内容
        [tagString writeToFile:tagPathStr atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

+ (NSString *)readFileName:(NSString *)fileName
{
    NSString *filePathStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];//NSCachesDirectory
    NSString *fullPathStr = [filePathStr stringByAppendingPathComponent:@"tagDir"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fullPathStr]) {
        [fileManager createDirectoryAtPath:fullPathStr withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *tagPathStr = [fullPathStr stringByAppendingPathComponent:fileName];
    
    if ([fileManager fileExistsAtPath:tagPathStr]) {
        NSData *logData = [NSData dataWithContentsOfFile:tagPathStr];
        NSString *logText = [[NSString alloc]initWithData:logData encoding:NSUTF8StringEncoding];
        return logText;
    }
    else {
        return nil;
    }
}

+ (void)deleteFileName:(NSString *)fileName
{
    NSString *filePathStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];//NSCachesDirectory
    NSString *fullPathStr = [filePathStr stringByAppendingPathComponent:@"tagDir"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fullPathStr]) {
        [fileManager createDirectoryAtPath:fullPathStr withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *tagPathStr = [fullPathStr stringByAppendingPathComponent:fileName];
    if ([fileManager fileExistsAtPath:tagPathStr]) {
        [fileManager removeItemAtPath:fileName error:nil];
    }
}

@end
