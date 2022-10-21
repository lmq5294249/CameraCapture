

#import "HHExceptionHandler.h"
#import <UIKit/UIKit.h>

#define filePath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]

void UncaughtExceptionHandler(NSException *exception) {
    
//    NSArray *arr = [exception callStackSymbols];
//    NSString *reason = [exception reason];
//    NSString *name = [exception name];
//    
//    //App信息
//    NSString *appName = [NSBundle mainBundle].infoDictionary[@"CFBundleDisplayName"];
//    NSString *currentVersion = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
//    
//    //手机信息
//    NSString *strSysVersion = [[UIDevice currentDevice] systemVersion];
//    NSString *phoneModel = [Tation_kSharedToolManager deviceVersion];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
//    NSString *timeBug = [dateFormatter stringFromDate:[NSDate date]];
//    
//    //错误信息
//    NSString *errorStr = [NSString stringWithFormat:@"=============异常崩溃报告=============\n时间：%@\n手机型号: %@\n系统版本号：%@\nAPP名称及版本号:%@ Version：%@ \nname:%@\nreason:\n%@\ncallStackSymbols:\n%@",timeBug,phoneModel,strSysVersion,appName,currentVersion,
//                     name,reason,[arr componentsJoinedByString:@"\n"]];
//    
//    [[NSUserDefaults standardUserDefaults] setValue:@"1" forKey:@"HohemPro.ErrorIndex"];
//    [[NSUserDefaults standardUserDefaults] setValue:errorStr forKey:@"HohemPro.ErrorMessage"];
//    
//    NSString *path = [filePath stringByAppendingPathComponent:@"Exception.txt"];
//    [errorStr writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
//    
//    [[NSNotificationCenter defaultCenter] postNotificationName:HH_kNotificationException object:nil];
//    [NSThread sleepForTimeInterval:2];
}

@interface HHExceptionHandler()

@end

static HHExceptionHandler *instanceType = nil;

@implementation HHExceptionHandler

+ (instancetype)sharedExceptionHandler {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instanceType = [[HHExceptionHandler alloc] init];
        NSSetUncaughtExceptionHandler (&UncaughtExceptionHandler);
    });
    return instanceType;
}

@end
