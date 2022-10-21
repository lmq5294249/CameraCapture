//
//  ZWTools.m
//  MR100AerialPhotography
//
//  Created by xzw on 2017/10/23.
//  Copyright © 2017年 AllWinner. All rights reserved.
//

#import "ZWTools.h"
#import "MBProgressHUD.h"
#import <CommonCrypto/CommonCrypto.h>

#define FileHashDefaultChunkSizeForReadingData 1024*8

@implementation ZWTools

/**
 *Toast消息提示框
 */
+ (void)showToastWihtMessage:(NSString *)message {
    
    [self showToastWihtMessage:message delay:2.0];
}

/**
 *Toast消息提示框 延时时间
 */
+ (void)showToastWihtMessage:(NSString *)message delay:(NSTimeInterval)delay {
    //避免显示延时,需要切换到主线程刷新UI
//    dispatch_async(dispatch_get_main_queue(), ^{
//        UIWindow *mainView = [[UIApplication sharedApplication] keyWindow];
//        MBProgressHUD *alert = nil;
//        for (UIView *tipVieww in mainView.subviews) {
//            if ([tipVieww isKindOfClass:[MBProgressHUD class]]) {
//                alert = (MBProgressHUD *)tipVieww;
//            }
//        }
//        
//        if (alert == nil) {
//            alert = [MBProgressHUD showHUDAddedTo:mainView animated:YES];
//            alert.yOffset += alert.frame.size.height*0.3;
//        }
//        
//        alert.labelText = message;
//        alert.margin = 10.0f;
//        alert.cornerRadius = 8.0f;
//        
//        alert.labelFont = [UIFont systemFontOfSize:17.0f];
//        alert.mode = MBProgressHUDModeText;
//        alert.removeFromSuperViewOnHide = YES;
//        [alert show:YES];
//        [alert hide:YES afterDelay:delay];
//    });
}

//生成文件的MD5值
+(NSString*)getFileMD5WithPath:(NSString*)path
{
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, FileHashDefaultChunkSizeForReadingData);
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData) {
    
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) goto done;
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    // Make sure chunkSizeForReadingData is valid
    
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    
    if (!didSucceed) goto done;
    
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
      snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}


@end
