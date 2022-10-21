//
//  TationToolManager.h
//  Hohem Pro
//
//  Created by Jolly on 2022/5/18.
//  Copyright © 2022 jolly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <PhotosUI/PhotosUI.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

#define Tation_kSharedToolManager [TationToolManager sharedToolManager]
//齐刘海屏幕相关
#define Tation_isIPhoneX [Tation_kSharedToolManager isIphoneX]
#define Tation_safeArea [TationToolManager boundsOfSafeArea]
#define Tation_StatusBarHeight [UIApplication sharedApplication].statusBarFrame.size.height
#define Tation_BottomSafetyDistance Tation_isIPhoneX ? 34 : 0
#define Tation_AutoFit(length) [TationToolManager autoFitLength:length]
#define Tation_AutoFitWithX(length) [TationToolManager autoFitLengthWithX:length]
//手机朝向
#define Tation_kNotificationInterfaceOrientation @"Tation_kNotificationInterfaceOrientation"
#define Tation_kNotificationInterfaceOrientation_Value @"Tation_kNotificationInterfaceOrientation_Value"
//电话状态
#define Tation_kNotificationCallEvent @"Tation_kNotificationCallEvent"
//本地存储的App版本
#define Tation_AppVersionKey @"Tation_AppVersionKey"
//设备类型
#define Tation_isPhone ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define Tation_isPad ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

//App语言
typedef NS_ENUM(NSInteger,TationLanguageEnum) {
    
    TationLanguageEnum_CN,//中文简体
    TationLanguageEnum_CN_Hant,//中文繁体
    TationLanguageEnum_EN,//英语
    TationLanguageEnum_EN_CN,//英式英语
    TationLanguageEnum_EN_US,//美式英语
    TationLanguageEnum_EN_CA,//加拿大英语
    TationLanguageEnum_DE,//德语
    TationLanguageEnum_PT,//葡萄牙语
    TationLanguageEnum_PT_BR,//巴西葡萄牙语
    TationLanguageEnum_JA,//日语
    TationLanguageEnum_ES,//西班牙语
    TationLanguageEnum_FR,//法语
    TationLanguageEnum_IT,//意大利语
    TationLanguageEnum_KO,//韩语
    TationLanguageEnum_RU,//俄语
};

//电话状态
typedef NS_ENUM(NSInteger,TationCallState) {
    
    TationCallState_Dialing,//拨打
    TationCallState_Connected,//接通
    TationCallState_Incoming,//来电
    TationCallState_Disconnected,//挂掉
    TationCallState_Other
};

@interface TationToolManager : NSObject

//手机朝向
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;
//语言
@property (nonatomic, assign) TationLanguageEnum languageEnum;
//电量
@property (nonatomic, assign) CGFloat batteryLevel;
//充电状态
@property (nonatomic, assign) UIDeviceBatteryState batteryState;
//音量
@property (nonatomic, assign) CGFloat curVolume;
//地址
@property (nonatomic, copy) NSString *address;
//维度
@property (nonatomic, assign) double latitude;
//经度
@property (nonatomic, assign) double longitude;
//应用名称
@property (nonatomic, copy) NSString *applicationName;
//当前应用版本号
@property (nonatomic, copy) NSString *applicationVersion;
//在APP Store中的应用ID
@property (nonatomic, copy) NSString *applicationID;
//app处于前台、后台
@property (nonatomic, assign) BOOL isBackground;
//判断是否为iphoneX系列机型
@property (nonatomic, assign) BOOL isIphoneX;

+ (instancetype)sharedToolManager;

#pragma mark - 手机横竖屏
//是否为竖屏
- (BOOL)isVerticalScreen;

#pragma mark - 手机语言
//获取语言字符串(网络使用)
- (NSString *)getLanguageStr;
//是否为中文
- (BOOL)isChinese;

#pragma mark - 手机信息
//手机唯一标识
- (NSString *)phoneIdentifier;
//手机用户名
- (NSString *)phoneUserName;
//手机系统版本
- (NSString *)deviceiOSVersion;
//手机型号编码
- (NSString *)deviceMachine;
//手机型号
- (NSString *)deviceVersion;

#pragma mark - 齐刘海机型
//获取布局时安全区域
+ (CGRect)boundsOfSafeArea;
//以iphone6屏幕为参考换算长度
+ (CGFloat)autoFitLength:(CGFloat)length;
//以iphoneX屏幕为参考换算长度
+ (CGFloat)autoFitLengthWithX:(CGFloat)length;

#pragma mark - 存储空间
- (float)inquireAvailableSize;

#pragma mark - 获取相册封面图片
/// 获取相册封面图片
/// @param type 类型(1照片,2视频)
/// @param imageSize 封面尺寸
/// @param finish 生成图片
+ (void)getAlbumCoverImage:(NSInteger)type imageSize:(CGSize)imageSize finish:(void(^)(UIImage *coverImage))finish;

#pragma mark - 定位信息
//获取定位信息
- (void)changeLocationState:(BOOL)open;

#pragma mark - int类型转十六进制形式
//将int数据转换成长度为4的字符串,不够前面补0
- (NSString *)getFourLengthStrWithNum:(NSInteger)num;
//nsdata数据转换成十六进制数据
- (NSString *)convertDataToHexStr:(NSData *)data;
//字符串转l十六进制
- (NSInteger)numberWithHexString:(NSString *)hexString;
//校验字符串是否全是数字
- (BOOL)checkIsNumStr:(NSString *)numStr;
//转换录制时间格式
- (NSString *)timeFormatWithSecond:(NSInteger)time;

#pragma mark - 显示提示框
- (void)showAlertVc:(nullable NSString *)title message:(NSString *)message confirm:(nullable NSString *)confirm cancel:(nullable NSString *)cancel showCancel:(BOOL)showCancel confirmBlock:(nullable void(^)(void))confirmBlock cancelBlock:(nullable void(^)(void))cancelBlock;
//当前置顶控制器
- (UIViewController *)getCurViewController;
//获取纯色图片
- (UIImage *)imageWithColor:(UIColor *)color;

#pragma mark - 分享
//分享图片
- (void)shareImageWithImage:(UIImage *)image completeHandler:(nullable void(^)(BOOL result))completeHandler;
//分享视频
- (void)shareVideoWithUrl:(NSURL *)url completeHandler:(nullable void(^)(BOOL result))completeHandler;
//分享视频
- (void)shareVideoWithAsset:(PHAsset *)asset completeHandler:(nullable void(^)(BOOL result))completeHandler;

#pragma mark - App相关信息
//获取在APP Store中的应用版本号
- (void)getApplicationVersionInAppStore:(NSString *)appId;
//跳转到app store指定应用
- (void)goToAppStoreWithAppID:(NSString *)appId;

#pragma mark - 手机时间
//获取当前13位时间
+ (NSString *)getCurTime;
//CPU时间,手机重启会重置
+ (CMTime)getMachTime;

@end

NS_ASSUME_NONNULL_END
