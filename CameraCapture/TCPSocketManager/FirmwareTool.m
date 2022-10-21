//
//  FirmwareTool.m
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/14.
//

#import "FirmwareTool.h"
#import <CommonCrypto/CommonCrypto.h>

#define FileHashDefaultChunkSizeForReadingData 1024*8

@implementation FirmwareTool

////生成文件的MD5值
//+(NSString*)getFileMD5WithPath:(NSString*)path
//{
//    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, FileHashDefaultChunkSizeForReadingData);
//}
//
//CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData) {
//
//    // Declare needed variables
//    CFStringRef result = NULL;
//    CFReadStreamRef readStream = NULL;
//
//    // Get the file URL
//    CFURLRef fileURL =
//    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
//                                  (CFStringRef)filePath,
//                                  kCFURLPOSIXPathStyle,
//                                  (Boolean)false);
//    if (!fileURL) goto done;
//    // Create and open the read stream
//    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
//                                            (CFURLRef)fileURL);
//
//    if (!readStream) goto done;
//    bool didSucceed = (bool)CFReadStreamOpen(readStream);
//    if (!didSucceed) goto done;
//    // Initialize the hash object
//    CC_MD5_CTX hashObject;
//    CC_MD5_Init(&hashObject);
//    // Make sure chunkSizeForReadingData is valid
//
//    if (!chunkSizeForReadingData) {
//        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
//    }
//
//    // Feed the data to the hash object
//    bool hasMoreData = true;
//    while (hasMoreData) {
//        uint8_t buffer[chunkSizeForReadingData];
//        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
//        if (readBytesCount == -1) break;
//        if (readBytesCount == 0) {
//            hasMoreData = false;
//            continue;
//        }
//        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
//    }
//
//    // Check if the read operation succeeded
//    didSucceed = !hasMoreData;
//
//    // Compute the hash digest
//    unsigned char digest[CC_MD5_DIGEST_LENGTH];
//
//    CC_MD5_Final(digest, &hashObject);
//
//    // Abort if the read operation failed
//
//    if (!didSucceed) goto done;
//
//    // Compute the string result
//    char hash[2 * sizeof(digest) + 1];
//    for (size_t i = 0; i < sizeof(digest); ++i) {
//      snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
//    }
//    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
//done:
//    if (readStream) {
//        CFReadStreamClose(readStream);
//        CFRelease(readStream);
//    }
//
//    if (fileURL) {
//        CFRelease(fileURL);
//    }
//    return result;
//}

////生成文件的MD5值
//+(NSString*)getFileMD5WithPath:(NSString*)path
//{
//    // 转换成utf-8
//    const char *pointer = [path UTF8String];
//    // CC_MD5_DIGEST_LENGTH: 摘要长度 16
//    // 开辟一个16字节（128位：md5加密出来就是128位/bit）的空间（一个字节=8字位=8个二进制数）
//    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
//
//    /*
//     extern unsigned char *CC_MD5(const void *data, CC_LONG len, unsigned char *md)官方封装好的加密方法
//     把cStr字符串转换成了32位的16进制数列（这个过程不可逆转） 存储到了result这个空间中
//     */
//    CC_MD5(pointer, (CC_LONG)strlen(pointer), md5Buffer);
//
//    // 创建一个32字符的可变字符串
//    NSMutableString *string = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
//
//    /*
//     x表示十六进制，%02X  意思是不足两位将用0补齐，如果多余两位则不影响
//     NSLog("%02X", 0x888);  //888
//     NSLog("%02X", 0x4); //04
//     */
//    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
//        [string appendFormat:@"%02x",md5Buffer[i]];
//
//    return string;
//}

@end
