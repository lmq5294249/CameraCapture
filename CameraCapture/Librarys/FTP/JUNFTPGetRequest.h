//
//  SelectedPictureOrVideoController.m
//  MR100AerialPhotography
//
//  Created by xzw on 2017/11/30.
//  Copyright © 2017年 AllWinner. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^FTPGetFinishedBlock)(void);
typedef void (^FTPGetFailBlock)(void);
typedef void (^FTPGetProgressBlock)(float progress);

@interface JUNFTPGetRequest : NSObject

@property (nonatomic, strong) FTPGetFinishedBlock finishedBlock;
@property (nonatomic, strong) FTPGetFailBlock failBlock;
@property (nonatomic, strong) FTPGetProgressBlock progressBlock;
@property (nonatomic, assign) unsigned long long bytesTotal;
@property (nonatomic, assign) unsigned long long bytesDownloaded;
@property (nonatomic, assign) CFWriteStreamRef fileStream;

+(JUNFTPGetRequest*)requestWithResource:(NSURL*)url
                            toDirectory:(NSString*)directory;

+(JUNFTPGetRequest *)requestWithResource:(NSURL*)url
                             toDirectory:(NSString*)directory
                           finishedBlock:(FTPGetFinishedBlock)finishedBlock
                               failBlock:(FTPGetFailBlock)failBlock
                           progressBlock:(FTPGetProgressBlock)progressBlock;


-(void)start;
-(void)stop;

@end
