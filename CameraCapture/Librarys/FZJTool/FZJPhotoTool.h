//
//  FZJPhotoTool.h
//  FZJPhotosFrameWork
//
//  Created by fdkj0002 on 16/1/10.
//  Copyright © 2016年 fdkj0002. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "Singleton.h"

#define kFileManager        [NSFileManager defaultManager]
typedef void(^SaveImageResult)(NSError *error,UIImage *image);
typedef void(^AssetRemoveResult)(NSError *error);
typedef void(^VideoSaveResult)(NSError *error,NSString *filePath);
typedef void(^Result)(NSURL *url);

@interface FZJPhotoTool : NSObject
singleton_interface(FZJPhotoTool)

/**
 *  保存图片到自定义相册
 *
 *  @param image image
 */
- (void)saveImageIntoCustomeCollectionFromImageArr:(NSArray<UIImage *> *)imageArr  resultBlock:(SaveImageResult)block;

/**
 *  保存视频到自定义相册
 *
 *  @param fileURL 视屏的链接
 */
- (void)saveVideoIntoCustomeCollectionFromUrl:(NSURL *)fileURL  resultBlock:(VideoSaveResult)block;

/**
 *  移除指定下标处的图片或视频
 *
 *  @param set 下标集合
 */
- (void)removeVideoOrPhotoAtIndexs:(NSArray<NSString *> *)arr resultBlock:(AssetRemoveResult)block;

/**
 *  获取自定义的相册
 *
 *  @return @“MR100”
 */
- (PHAssetCollection *)createdCollection;

/**
 *  获取自定义相册中的所有图片和视频
 *
 *  @return 图片和视频集
 */
- (PHFetchResult *)getAssetsInCustomeAssetCollection;

/**
 *  获取指定资源的数据，分享的时候要用到
 *
 *  @param asset  asset
 *  @param result dataBlock
 */
+ (void)getDataFromPHAsset:(PHAsset *)asset Complete:(Result)result;


@end
