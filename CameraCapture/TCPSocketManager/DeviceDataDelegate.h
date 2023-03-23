//
//  DeviceDataDelegate.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/28.
//

#ifndef DeviceDataDelegate_h
#define DeviceDataDelegate_h

@protocol DeviceDataDelegate <NSObject>

- (void)getMeidaList:(NSArray *)array mediaType:(int)type;

- (void)startVideoPlayback;

- (void)didFinishMediaDownloadOperation;

- (void)didUpgradeFirmwareProgress:(NSInteger)progress completed:(BOOL)finish;

- (void)didFinishFormatSDCard;

- (void)didGetThumbList:(NSArray *)array;

@end




#endif /* DeviceDataDelegate_h */
