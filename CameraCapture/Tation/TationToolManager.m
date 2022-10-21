//
//  TationToolManager.m
//  Hohem Pro
//
//  Created by Jolly on 2022/5/18.
//  Copyright © 2022 jolly. All rights reserved.
//

#import "TationToolManager.h"
#import "sys/utsname.h"
#import "mach/mach_time.h"
#import "NSString+HHFormat.h"

@interface TationToolManager()<CLLocationManagerDelegate>

//传感器
@property (nonatomic, strong) CMMotionManager *motionManager;
//电话
@property (nonatomic, strong) CTCallCenter *callCenter;
//经纬度
@property (nonatomic, strong) CLLocationManager *locationManager;
//地理位置
@property (nonatomic, strong) CLGeocoder *geocoder;

@end

@implementation TationToolManager

+ (instancetype)sharedToolManager {
    
    static TationToolManager *instanceType;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instanceType = [[TationToolManager alloc] init];
        [instanceType initAttribute];
    });
    return instanceType;
}

- (void)initAttribute {
    
    self.isIphoneX = [self isIphoneXDevice];
    [self motionHandler];
    [self callHandler];
    [self phonePowerHandler];
    [self volumeHandler];
    [self languageHandler];
    [self locationHandler];
    [self loadApplicationMessage];
}

#pragma mark - 传感器
- (void)motionHandler {
    
    self.motionManager = [[CMMotionManager alloc] init];
    //加速度数据更新间隔
    self.motionManager.accelerometerUpdateInterval = .2;
    //陀螺仪数据更新间隔
    self.motionManager.gyroUpdateInterval = .2;
    //启动传感器监听
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
        
        if (error) {
            
            NSLog(@"%s -- %@",__FUNCTION__,error);
            return;
        }
        
        if (accelerometerData.acceleration.x >= 0.75) {
            
            self.interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
        }else if (accelerometerData.acceleration.x <= -0.75) {
            
            self.interfaceOrientation = UIInterfaceOrientationLandscapeRight;
        }else if (accelerometerData.acceleration.y <= -0.75) {
            
            self.interfaceOrientation = UIInterfaceOrientationPortrait;
        }else if (accelerometerData.acceleration.y >= 0.75) {
            
            self.interfaceOrientation = UIInterfaceOrientationPortraitUpsideDown;
        }
    }];
}

- (void)setInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    if (_interfaceOrientation != interfaceOrientation) {
        
        _interfaceOrientation = interfaceOrientation;
        [[NSNotificationCenter defaultCenter] postNotificationName:Tation_kNotificationInterfaceOrientation object:nil userInfo:@{
            Tation_kNotificationInterfaceOrientation_Value : @(interfaceOrientation)                                                                                                }];
    }
}

//是否为竖屏
- (BOOL)isVerticalScreen {
    
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        
        return NO;
    }
    return YES;
}

#pragma mark - 电话状态监听
- (void)callHandler {
    
    self.callCenter = [[CTCallCenter alloc] init];
    self.callCenter.callEventHandler = ^(CTCall *call) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            TationCallState state = TationCallState_Other;
            if ([call.callState isEqualToString:CTCallStateDialing]) {
                
                state = TationCallState_Dialing;
            }else if ([call.callState isEqualToString:CTCallStateConnected]) {
            
                state = TationCallState_Dialing;
            }else if ([call.callState isEqualToString:CTCallStateIncoming]) {
            
                state = TationCallState_Dialing;
            }else if ([call.callState isEqualToString:CTCallStateDisconnected]) {
            
                state = TationCallState_Dialing;
            }else{
            
                state = TationCallState_Other;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:Tation_kNotificationCallEvent object:@(state)];
        });
    };
}

#pragma mark - 电量
- (void)phonePowerHandler {
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    self.batteryState = [UIDevice currentDevice].batteryState;
    self.batteryLevel = [UIDevice currentDevice].batteryLevel;
    
    //电量改变通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UIDeviceBatteryLevelDidChangeNotificationWithNotification:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    //电池状态改变通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UIDeviceBatteryStateDidChangeNotificationWithNotification:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
}

- (void)UIDeviceBatteryLevelDidChangeNotificationWithNotification:(NSNotification *)notification {
    
    self.batteryLevel = [UIDevice currentDevice].batteryLevel;
}

- (void)UIDeviceBatteryStateDidChangeNotificationWithNotification:(NSNotification *)notification {
    
    self.batteryState = [UIDevice currentDevice].batteryState;
}

#pragma mark - 音量
- (void)volumeHandler {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AVSystemController_SystemVolumeDidChangeNotificationWithNotification:)name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

//系统音量回调
- (void)AVSystemController_SystemVolumeDidChangeNotificationWithNotification:(NSNotification *)notification {
    
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    self.curVolume = volume;
}

#pragma mark - 手机语言
- (void)languageHandler {
    
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    TationLanguageEnum languageEnum = TationLanguageEnum_EN;
    if ([language hasPrefix:@"zh-Hans"]) {//简体中文
        
        languageEnum = TationLanguageEnum_CN;
    }else if ([language hasPrefix:@"zh"]) {//繁体中文
        
        languageEnum = TationLanguageEnum_CN_Hant;
    }else if ([language hasPrefix:@"en-CN"]) {//英国
        
        languageEnum = TationLanguageEnum_EN_CN;
    }else if ([language hasPrefix:@"en-US"]) {//美国
         
         languageEnum = TationLanguageEnum_EN_US;
     }else if ([language hasPrefix:@"en-CA"]) {//加拿大
         
         languageEnum = TationLanguageEnum_EN_CA;
     }else if ([language hasPrefix:@"en"]) {//英国
         
         languageEnum = TationLanguageEnum_EN;
     }else if ([language hasPrefix:@"pt-BR"]) {//巴西
         
         languageEnum = TationLanguageEnum_PT_BR;
     }else if([language hasPrefix:@"pt"]){//葡萄牙
         
         languageEnum = TationLanguageEnum_PT;
     }else if([language hasPrefix:@"de"]){//德国
        
        languageEnum = TationLanguageEnum_DE;
    }else if([language hasPrefix:@"ja"]){//日本
        
        languageEnum = TationLanguageEnum_JA;
    }else if([language hasPrefix:@"es"]){//西班牙
        
        languageEnum = TationLanguageEnum_ES;
    }else if([language hasPrefix:@"fr"]){//法国
        
        languageEnum = TationLanguageEnum_FR;
    }else if([language hasPrefix:@"it"]){//意大利
        
        languageEnum = TationLanguageEnum_IT;
    }else if([language hasPrefix:@"ko"]){//韩国
        
        languageEnum = TationLanguageEnum_KO;
    }else if([language hasPrefix:@"ru"]){//俄罗斯
        
        languageEnum = TationLanguageEnum_RU;
    }
    self.languageEnum = languageEnum;
}

//获取语言字符串(网络使用)
- (NSString *)getLanguageStr {
    
    NSString *languageStr = @"EN_US";
    
    switch (self.languageEnum) {
        case TationLanguageEnum_CN:
            languageStr = @"ZH_CN";
            break;
        case TationLanguageEnum_CN_Hant:
            languageStr = @"ZH_HANT";
            break;
        case TationLanguageEnum_EN_US:
        case TationLanguageEnum_EN_CN:
        case TationLanguageEnum_EN_CA:
            languageStr = @"EN_US";
            break;
        case TationLanguageEnum_DE:
            languageStr = @"DE";
            break;
        case TationLanguageEnum_PT:
            languageStr = @"PT";
            break;
        case TationLanguageEnum_JA:
            languageStr = @"JA";
            break;
        case TationLanguageEnum_ES:
            languageStr = @"ES";
            break;
        case TationLanguageEnum_FR:
            languageStr = @"FR";
            break;
        case TationLanguageEnum_IT:
            languageStr = @"IT";
            break;
        case TationLanguageEnum_KO:
            languageStr = @"KO";
            break;
        case TationLanguageEnum_RU:
            languageStr = @"RU";
            break;
        default:
            break;
    }
    return languageStr;
}

//手机当前语言
- (NSString *)preferredLanguage {
    
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0];
}

//是否为中文
- (BOOL)isChinese {
    
    return self.languageEnum == TationLanguageEnum_CN || self.languageEnum == TationLanguageEnum_CN_Hant;
}

#pragma mark - 手机信息
//手机唯一标识
- (NSString *)phoneIdentifier {
    
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

//手机用户名
- (NSString *)phoneUserName {
    
    return [[UIDevice currentDevice] name];
}

//手机系统版本
- (NSString *)deviceiOSVersion {
    
    return [NSString stringWithFormat:@"%@ - %@",[[UIDevice currentDevice] systemName],[[UIDevice currentDevice] systemVersion]];
}

//手机型号编码
- (NSString *)deviceMachine {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

//手机型号
- (NSString *)deviceVersion {
    
    NSString * deviceString = [self deviceMachine];
    //iPhone
    if ([deviceString isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([deviceString isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([deviceString isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    
    if ([deviceString isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone3,2"])    return @"iPhone 4 Verizon";
    if ([deviceString isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    
    if ([deviceString isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,3"])    return @"iPhone 5c";
    if ([deviceString isEqualToString:@"iPhone5,4"])    return @"iPhone 5c";
    if ([deviceString isEqualToString:@"iPhone6,1"])    return @"iPhone 5s";
    if ([deviceString isEqualToString:@"iPhone6,2"])    return @"iPhone 5s";
    
    if ([deviceString isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([deviceString isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([deviceString isEqualToString:@"iPhone8,1"])    return @"iPhone 6s";
    if ([deviceString isEqualToString:@"iPhone8,2"])    return @"iPhone 6s Plus";
    if ([deviceString isEqualToString:@"iPhone8,4"])    return @"iPhone SE";
    
    if ([deviceString isEqualToString:@"iPhone9,1"])    return @"iPhone 7";
    if ([deviceString isEqualToString:@"iPhone9,2"])    return @"iPhone 7 Plus";
    if ([deviceString isEqualToString:@"iPhone9,3"])    return @"iPhone 7";
    if ([deviceString isEqualToString:@"iPhone9,4"])    return @"iPhone 7 Plus";
    
    if ([deviceString isEqualToString:@"iPhone10,1"])   return @"iPhone 8 Global";
    if ([deviceString isEqualToString:@"iPhone10,2"])   return @"iPhone 8 Plus Global";
    if ([deviceString isEqualToString:@"iPhone10,3"])   return @"iPhone X Global";
    if ([deviceString isEqualToString:@"iPhone10,4"])   return @"iPhone 8 GSM";
    if ([deviceString isEqualToString:@"iPhone10,5"])   return @"iPhone 8 Plus GSM";
    if ([deviceString isEqualToString:@"iPhone10,6"])   return @"iPhone X GSM";
    
    if ([deviceString isEqualToString:@"iPhone11,2"])   return @"iPhone XS";
    if ([deviceString isEqualToString:@"iPhone11,4"])   return @"iPhone XS Max (China)";
    if ([deviceString isEqualToString:@"iPhone11,6"])   return @"iPhone XS Max";
    if ([deviceString isEqualToString:@"iPhone11,8"])   return @"iPhone XR";
    
    if ([deviceString isEqualToString:@"iPhone12,1"])    return @"iPhone 11";
    if ([deviceString isEqualToString:@"iPhone12,2"])    return @"iPhone 11 pro";
    if ([deviceString isEqualToString:@"iPhone12,5"])    return @"iPhone 11 pro Max";
    
    if ([deviceString  isEqualToString:@"iPhone13,1"])   return @"iPhone 12 mini";
    if ([deviceString  isEqualToString:@"iPhone13,2"])   return @"iPhone 12";
    if ([deviceString isEqualToString:@"iPhone13,3"])    return @"iPhone 12 Pro";
    if ([deviceString isEqualToString:@"iPhone13,4"])    return @"iPhone 12 Pro Max";
    
    if ([deviceString isEqualToString:@"i386"])         return @"Simulator 32";
    if ([deviceString isEqualToString:@"x86_64"])       return @"Simulator 64";
    
    if ([deviceString isEqualToString:@"iPad1,1"]) return @"iPad";
    if ([deviceString isEqualToString:@"iPad2,1"] ||
        [deviceString isEqualToString:@"iPad2,2"] ||
        [deviceString isEqualToString:@"iPad2,3"] ||
        [deviceString isEqualToString:@"iPad2,4"]) return @"iPad 2";
    if ([deviceString isEqualToString:@"iPad3,1"] ||
        [deviceString isEqualToString:@"iPad3,2"] ||
        [deviceString isEqualToString:@"iPad3,3"]) return @"iPad 3";
    if ([deviceString isEqualToString:@"iPad3,4"] ||
        [deviceString isEqualToString:@"iPad3,5"] ||
        [deviceString isEqualToString:@"iPad3,6"]) return @"iPad 4";
    if ([deviceString isEqualToString:@"iPad4,1"] ||
        [deviceString isEqualToString:@"iPad4,2"] ||
        [deviceString isEqualToString:@"iPad4,3"]) return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad5,3"] ||
        [deviceString isEqualToString:@"iPad5,4"]) return @"iPad Air 2";
    if ([deviceString isEqualToString:@"iPad6,3"] ||
        [deviceString isEqualToString:@"iPad6,4"]) return @"iPad Pro 9.7-inch";
    if ([deviceString isEqualToString:@"iPad6,7"] ||
        [deviceString isEqualToString:@"iPad6,8"]) return @"iPad Pro 12.9-inch";
    if ([deviceString isEqualToString:@"iPad6,11"] ||
        [deviceString isEqualToString:@"iPad6,12"]) return @"iPad 5";
    if ([deviceString isEqualToString:@"iPad7,1"] ||
        [deviceString isEqualToString:@"iPad7,2"]) return @"iPad Pro 12.9-inch 2";
    if ([deviceString isEqualToString:@"iPad7,3"] ||
        [deviceString isEqualToString:@"iPad7,4"]) return @"iPad Pro 10.5-inch";
    
    if ([deviceString isEqualToString:@"iPad2,5"] ||
        [deviceString isEqualToString:@"iPad2,6"] ||
        [deviceString isEqualToString:@"iPad2,7"]) return @"iPad mini";
    if ([deviceString isEqualToString:@"iPad4,4"] ||
        [deviceString isEqualToString:@"iPad4,5"] ||
        [deviceString isEqualToString:@"iPad4,6"]) return @"iPad mini 2";
    if ([deviceString isEqualToString:@"iPad4,7"] ||
        [deviceString isEqualToString:@"iPad4,8"] ||
        [deviceString isEqualToString:@"iPad4,9"]) return @"iPad mini 3";
    if ([deviceString isEqualToString:@"iPad5,1"] ||
        [deviceString isEqualToString:@"iPad5,2"]) return @"iPad mini 4";
    
    if ([deviceString isEqualToString:@"iPod1,1"]) return @"iTouch";
    if ([deviceString isEqualToString:@"iPod2,1"]) return @"iTouch2";
    if ([deviceString isEqualToString:@"iPod3,1"]) return @"iTouch3";
    if ([deviceString isEqualToString:@"iPod4,1"]) return @"iTouch4";
    if ([deviceString isEqualToString:@"iPod5,1"]) return @"iTouch5";
    if ([deviceString isEqualToString:@"iPod7,1"]) return @"iTouch6";
    
    return deviceString;
}

#pragma mark - 齐刘海机型
//判断是否为齐刘海机型
- (BOOL)isIphoneXDevice {
    
    if (@available(iOS 11.0,*)) {
        
        return [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom > 0 ? YES : NO;
    }
    return NO;
}

//获取布局时安全区域
+ (CGRect)boundsOfSafeArea {
    
    CGRect bounds = [UIScreen mainScreen].bounds;
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0,*)) {
        
        safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
    }
    CGRect boundsOfSafeArea = UIEdgeInsetsInsetRect(bounds, safeAreaInsets);
    return boundsOfSafeArea;
}

//以iphone6屏幕为参考换算长度
+ (CGFloat)autoFitLength:(CGFloat)length {
    
    CGFloat min = Tation_safeArea.size.width < Tation_safeArea.size.height ? Tation_safeArea.size.width : Tation_safeArea.size.height;
    return length * (min / 375.0);
}

//以iphoneX屏幕为参考换算长度
+ (CGFloat)autoFitLengthWithX:(CGFloat)length {
    
    CGFloat min = Tation_safeArea.size.width < Tation_safeArea.size.height ? Tation_safeArea.size.width : Tation_safeArea.size.height;
    return length * (min / 390.0);
}

#pragma mark - 存储空间
- (float)inquireAvailableSize {
    
    float totalSize = 0.0;
    float freeSize = 0.0;
    
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:&error];
    if (dict) {
        
        NSNumber *total = [dict objectForKey:NSFileSystemSize];
        totalSize = [total unsignedLongLongValue] * 1.0 / 1024 / 1024 / 1024;
        
        NSNumber *free = [dict objectForKey:NSFileSystemFreeSize];
        freeSize = [free unsignedLongLongValue] * 1.0 / 1024 / 1024 / 1024;
    }else{
        
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    return freeSize;
}

#pragma mark - 获取相册封面图片
/// 获取相册封面图片
/// @param type 类型(1照片,2视频)
/// @param imageSize 封面尺寸
/// @param finish 生成图片
+ (void)getAlbumCoverImage:(NSInteger)type imageSize:(CGSize)imageSize finish:(void(^)(UIImage *coverImage))finish {
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO];
    options.sortDescriptors = @[descriptor];
    if (type == 1) {
        
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeImage];
    }else if (type == 2) {
        
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",PHAssetMediaTypeVideo];
    }
    
    PHFetchResult *result = [PHAsset fetchAssetsWithOptions:options];
    PHAsset *asset = result.firstObject;
    
    PHImageRequestOptions *imageOptions = [[PHImageRequestOptions alloc] init];
    imageOptions.synchronous = YES;
    imageOptions.resizeMode = PHImageRequestOptionsResizeModeNone;
    imageOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    
    if (asset) {
        
        [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:imageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            
            if (result) finish(result);
        }];
    }
}

#pragma mark - 定位信息
- (void)locationHandler {
    
    self.locationManager = [[CLLocationManager alloc] init];
    //用户授权后使用定位信息
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager.delegate = self;
    //定位精度
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //位置变化最小过滤器
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    //位置解析
    self.geocoder = [[CLGeocoder alloc] init];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    
    CLLocation * location = locations.lastObject;
    // 纬度
    self.latitude = location.coordinate.latitude;
    // 经度
    self.longitude = location.coordinate.longitude;
    //解析定位信息
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        if (placemarks.count > 0) {
            
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            //获取城市
            NSString *city = placemark.locality;
            if (!city) {//四大直辖市的城市信息无法通过locality获得，只能通过获取省份的方法来获得（如果city为空，则可知为直辖市
                
                city = placemark.administrativeArea;
            }
            
            /**
             位置名 placemark.name
             街道 placemark.thoroughfare
             子街道 placemark.subThoroughfare
             市 placemark.locality
             区 placemark.subLocality
             国家 placemark.country
             */
            self.address = [NSString stringWithFormat:@"%@%@%@",placemark.country,placemark.locality,placemark.subLocality];
        }else if (error == nil && [placemarks count] == 0) {
            
            NSLog(@"未解析到对应信息,即将继续解析");
        } else if (error != nil){
            
            NSLog(@"解析经纬度失败 error = %@", error);
        }
    }];
}

//获取定位信息
- (void)changeLocationState:(BOOL)open {
    
    open ? [self.locationManager startUpdatingLocation] : [self.locationManager stopUpdatingLocation];
}

#pragma mark - int类型转十六进制形式
//int数据类型转换为四位数的十六进制形式的字符串
- (NSString *)getFourLengthStrWithNum:(NSInteger)num{
    
    NSString *numStr = [self ToHex:num];
    NSString *resultStr;
    
    switch (numStr.length) {
        case 0:
            resultStr = @"0000";
            break;
        case 1:
            resultStr = [NSString stringWithFormat:@"000%@",numStr];
            break;
        case 2:
            resultStr = [NSString stringWithFormat:@"00%@",numStr];
            break;
        case 3:
            resultStr = [NSString stringWithFormat:@"0%@",numStr];
            break;
        case 4:
            resultStr = numStr;
            break;
        default:
            break;
    }
    return resultStr;
}

//int转16进制字符串
- (NSString *)ToHex:(uint16_t)tmpid
{
    NSString *nLetterValue;
    NSString *str =@"";
    uint16_t ttmpig;
    for (int i = 0; i<9; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig)
        {
            case 10:
                nLetterValue =@"A";break;
            case 11:
                nLetterValue =@"B";break;
            case 12:
                nLetterValue =@"C";break;
            case 13:
                nLetterValue =@"D";break;
            case 14:
                nLetterValue =@"E";break;
            case 15:
                nLetterValue =@"F";break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%u",ttmpig];
                
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
        
    }
    return str;
}

//nsdata数据转换成十六进制数据
- (NSString *)convertDataToHexStr:(NSData *)data {
    
    if (!data || [data length] == 0) return @"";
    
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    return string;
}

//字符串转十六进制
- (NSInteger)numberWithHexString:(NSString *)hexString{
    
    const char *hexChar = [hexString cStringUsingEncoding:NSUTF8StringEncoding];
    int hexNumber;
    sscanf(hexChar, "%x", &hexNumber);
    return (NSInteger)hexNumber;
}

//校验字符串是否全是数字
- (BOOL)checkIsNumStr:(NSString *)numStr {
    
    if (numStr.length == 0) return NO;
    numStr = [numStr stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    if(numStr.length > 0) return NO;
    return YES;
}

//转换录制时间格式
- (NSString *)timeFormatWithSecond:(NSInteger)time {
    
    NSInteger second = time % 60;
    NSInteger minute = time % 3600 / 60;
    NSInteger hour = time / 3600;
    return [NSString stringWithFormat:@"%.2ld:%.2ld:%.2ld",(long)hour,(long)minute,(long)second];
}

#pragma mark - 显示提示框
//显示提示信息
//- (void)showAlertVc:(nullable NSString *)title message:(NSString *)message confirm:(nullable NSString *)confirm cancel:(nullable NSString *)cancel showCancel:(BOOL)showCancel confirmBlock:(nullable void(^)(void))confirmBlock cancelBlock:(nullable void(^)(void))cancelBlock {
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//        TationReminderView *reminderView = [[TationReminderView alloc] initWithTitle:title message:message confirm:confirm cancel:cancel showCancel:showCancel confirmBlock:confirmBlock cancelBlock:cancelBlock];
//        [[UIApplication sharedApplication].keyWindow addSubview:reminderView];
//        reminderView.frame = [UIScreen mainScreen].bounds;
//    });
//}

//当前置顶控制器
- (UIViewController *)getCurViewController {
    
    [NSThread mainThread];
    UIViewController *currentViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    BOOL runLoopFind = YES;
    while (runLoopFind) {
        
        if (currentViewController.presentedViewController) {
            
            currentViewController = currentViewController.presentedViewController;
        } else {
            
            if ([currentViewController isKindOfClass:[UINavigationController class]]) {
                
                currentViewController = ((UINavigationController *)currentViewController).visibleViewController;
            } else if ([currentViewController isKindOfClass:[UITabBarController class]]) {
                
                currentViewController = ((UITabBarController* )currentViewController).selectedViewController;
            } else {
                
                break;
            }
        }
    }
    return currentViewController;
}

//获取纯色图片
- (UIImage *)imageWithColor:(UIColor *)color {
   
    CGRect rect = CGRectMake(0.0f,0.0f, 1.0f,1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - 分享
//分享图片
- (void)shareImageWithImage:(UIImage *)image completeHandler:(nullable void(^)(BOOL result))completeHandler {
    
    if (!image) return;
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    [[self getCurViewController] presentViewController:activityVC animated:YES completion:nil];
    activityVC.completionWithItemsHandler = ^(UIActivityType __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError){
        
        if (completeHandler) completeHandler(completed);
    };
}

//分享视频
- (void)shareVideoWithUrl:(NSURL *)url completeHandler:(nullable void(^)(BOOL result))completeHandler {
    
    if (!url) return;
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    [[self getCurViewController] presentViewController:activityVC animated:YES completion:nil];
    activityVC.completionWithItemsHandler = ^(UIActivityType __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError){
        
        if (completeHandler) completeHandler(completed);
    };
}

//分享视频
- (void)shareVideoWithAsset:(PHAsset *)asset completeHandler:(nullable void(^)(BOOL result))completeHandler {
//    
//    if (!asset) return;
//    //解析数据
//    NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
//    PHAssetResource *resource;
//    for (PHAssetResource *assetRes in assetResources) {
//        
//        if (assetRes.type == PHAssetResourceTypePairedVideo ||
//            assetRes.type == PHAssetResourceTypeVideo) {
//            
//            resource = assetRes;
//        }
//    }
//    //获取存储地址
//    NSString *fileName = @"tempAssetVideo.mp4";
//    if (resource.originalFilename) {
//        
//        fileName = resource.originalFilename;
//    }
//    NSString *PATH_MOVIE_FILE = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
//    if ([XCFileManager isExistsAtPath:PATH_MOVIE_FILE]) {
//        
//        [XCFileManager removeItemAtPath:PATH_MOVIE_FILE];
//    }
//    //存储到沙盒
//    [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource toFile:[NSURL fileURLWithPath:PATH_MOVIE_FILE] options:nil completionHandler:^(NSError * _Nullable error){
//        
//        if (!error) {
//            
//            NSArray *activityItems = @[[NSURL fileURLWithPath:PATH_MOVIE_FILE]];
//            //分享同步到主线程
//            dispatch_async(dispatch_get_main_queue(), ^{
//                
//                UIActivityViewController *activityVC = [[UIActivityViewController alloc]initWithActivityItems:activityItems applicationActivities:nil];
//                //不出现在活动项目
//                activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard,UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll];
//                [[self getCurViewController] presentViewController:activityVC animated:YES completion:nil];
//                
//                // 分享之后的回调
//                activityVC.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
//                    
//                    NSLog(@"%s - %@",__FUNCTION__,completed ? @"completed" : @"canceled");
//                    //分享之后删除原地址信息
//                    [[NSFileManager defaultManager] removeItemAtPath:PATH_MOVIE_FILE  error:nil];
//                };
//            });
//        }
//    }];
}

#pragma mark - App相关信息
- (void)loadApplicationMessage {
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    self.applicationName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    self.applicationVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
}

//获取在APP Store中的应用版本号
- (void)getApplicationVersionInAppStore:(NSString *)appId {
    
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com//lookup?id=%@",appId]];
}

//跳转到app store指定应用
- (void)goToAppStoreWithAppID:(NSString *)appId {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/us/app/%@",appId]] options:@{} completionHandler:nil];
}

#pragma mark - 手机时间
//获取当前13位时间
+ (NSString *)getCurTime {
    
    return [NSString stringWithFormat:@"%ld",(long)([[NSDate date] timeIntervalSince1970] * 1000)];
}

//CPU时间,手机重启会重置
+ (CMTime)getMachTime {
    
    mach_timebase_info_data_t timeInfo;
    mach_timebase_info(&timeInfo);
    return CMTimeMake(mach_absolute_time() * timeInfo.numer / timeInfo.denom, 1000000000);
}

@end
