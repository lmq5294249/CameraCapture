//
//  SelectedPictureOrVideoController.m
//  MR100AerialPhotography
//
//  Created by xzw on 2017/11/30.
//  Copyright © 2017年 AllWinner. All rights reserved.
//

#import "JUNFTPGetRequest.h"
#import "AWLinkConstant.h"

void myGetSocketReadCallBack (CFReadStreamRef stream, CFStreamEventType event, void *myPtr);

@interface JUNFTPGetRequest ()
{
    NSURL* resourceUrl;
    NSString *directoryStr;
    
    CFReadStreamRef readStream;

}

@end

@implementation JUNFTPGetRequest

-(id)initWithResource:(NSURL*)url
          toDirectory:(NSString*)directory
        finishedBlock:(FTPGetFinishedBlock)finishedBlock
            failBlock:(FTPGetFailBlock)failBlock
        progressBlock:(FTPGetProgressBlock)progressBlock
{
    
	self = [super init];
    
    if(self)
    {
        resourceUrl = url;
		directoryStr = directory;
        self.finishedBlock = finishedBlock;
        self.failBlock = failBlock;
        self.progressBlock = progressBlock;
        
	}
	return self;
}

+(JUNFTPGetRequest*)requestWithResource:(NSURL*)url
                            toDirectory:(NSString*)directory
{
    return [[self alloc] initWithResource:url toDirectory:directory finishedBlock:nil failBlock:nil progressBlock:nil];
}

+(JUNFTPGetRequest *)requestWithResource:(NSURL*)url
                             toDirectory:(NSString*)directory
                           finishedBlock:(FTPGetFinishedBlock)finishedBlock
                               failBlock:(FTPGetFailBlock)failBlock
                           progressBlock:(FTPGetProgressBlock)progressBlock
{
    return [[self alloc] initWithResource:url toDirectory:directory finishedBlock:finishedBlock failBlock:failBlock progressBlock:progressBlock];
}

-(void)start
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:DOWNLOADPATH])
    {
        [fileManager createDirectoryAtPath: DOWNLOADPATH withIntermediateDirectories:YES attributes:nil error:nil];
        
    }
    NSString *path = [DOWNLOADPATH stringByAppendingPathComponent:directoryStr];
    
    NSURL *url = [NSURL fileURLWithPath:path];
    
    if (self.fileStream == nil) {
        
        self.fileStream = CFWriteStreamCreateWithFile(kCFAllocatorDefault, (__bridge CFURLRef)(url));

        if (!CFWriteStreamOpen(self.fileStream)) {
           // CFStreamError myErr = CFWriteStreamGetError(self.fileStream); // An error has occurred.
            NSLog(@"CFWriteStreamOpen error");
            return;
        }
    }
    
    readStream = CFReadStreamCreateWithFTPURL(NULL, (__bridge CFURLRef)resourceUrl);
    CFReadStreamSetProperty(readStream, kCFStreamPropertyFTPFetchResourceInfo, kCFBooleanTrue);

    CFStreamClientContext clientContext;
    clientContext.version = 0;
    clientContext.info = CFBridgingRetain(self) ;
    clientContext.retain = nil;
    clientContext.release = nil;
    clientContext.copyDescription = nil;
    if (CFReadStreamSetClient (readStream,
                               kCFStreamEventOpenCompleted |
                               kCFStreamEventHasBytesAvailable |
                               kCFStreamEventCanAcceptBytes |
                               kCFStreamEventErrorOccurred |
                               kCFStreamEventEndEncountered,
                               myGetSocketReadCallBack,
                               &clientContext ) )
    {
        NSLog(@"Set read callBack Succeeded");
        CFReadStreamScheduleWithRunLoop(readStream,
                                        CFRunLoopGetCurrent(),
                                        kCFRunLoopCommonModes);
    }
    else
    {
        NSLog(@"Set read callBack Failed");
    }
    
    BOOL success = CFReadStreamOpen(readStream);
    if (!success) {
        printf("stream open fail\n");
        return;
    }
    
}

-(void)stop
{
    if (self.fileStream) {
        CFWriteStreamClose(self.fileStream);
        CFRelease(self.fileStream);
        self.fileStream = nil;
    }
    if (readStream) {
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFReadStreamClose(readStream);
        CFRelease(readStream);
        readStream = nil;
    }
}

@end

#define BUFSIZE 32768
void myGetSocketReadCallBack (CFReadStreamRef stream, CFStreamEventType event, void *myPtr)
{
    JUNFTPGetRequest* request = (__bridge JUNFTPGetRequest *)myPtr;
    CFNumberRef       cfSize;
    UInt64            size;
    switch(event)
    {
        case kCFStreamEventOpenCompleted:
            
            cfSize = CFReadStreamCopyProperty(stream, kCFStreamPropertyFTPResourceSize);
            if (cfSize) {
                if (CFNumberGetValue(cfSize, kCFNumberLongLongType, &size)) {
                    printf("File size is %llu\n", size);
                    request.bytesTotal = size;
                }
                CFRelease(cfSize);
            } else {
                printf("File size is unknown.\n");
                
            }
        
            break;
        case kCFStreamEventHasBytesAvailable:
        {
            UInt8 recvBuffer[BUFSIZE];
            
            CFIndex bytesRead = CFReadStreamRead(stream, recvBuffer, BUFSIZE);
            
            printf("bytesRead:%ld\n",bytesRead);
            if (bytesRead > 0)
            {
                NSInteger   bytesOffset = 0;
                do
                {
                    CFIndex bytesWritten = CFWriteStreamWrite(request.fileStream, &recvBuffer[bytesOffset], bytesRead-bytesOffset );
                    if (bytesWritten > 0) {
                        bytesOffset += bytesWritten;
                        request.bytesDownloaded +=bytesWritten;
                        request.progressBlock((float)request.bytesDownloaded/(float)request.bytesTotal);
                    }
                    else if (bytesWritten == 0)
                    {
                        break;
                    }
                    else
                    {
                        request.failBlock();
                        return;
                    }
                }while ((bytesRead-bytesOffset)>0);
            }
            else if(bytesRead == 0)
            {
                request.finishedBlock();
                [request stop];
            }
            else
            {
                request.failBlock();
            }
        }
            break;
        case kCFStreamEventErrorOccurred:
        {
            CFStreamError error = CFReadStreamGetError(stream);
            printf("kCFStreamEventErrorOccurred-%d\n",error.error);
            
            [request stop];
            request.failBlock();
        }
           break;
        case kCFStreamEventEndEncountered:
            printf("request finished\n");
            request.finishedBlock();
            [request stop];
            break;
        default:
            break;
    }
}

