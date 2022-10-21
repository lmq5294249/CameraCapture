//
//  FZJPhotoTool.m
//  FZJPhotosFrameWork
//
//  Created by fdkj0002 on 16/1/10.
//  Copyright © 2016年 fdkj0002. All rights reserved.
//

#import "FZJPhotoTool.h"

@implementation FZJPhotoTool
singleton_implementation(FZJPhotoTool)

#pragma mark - 保存图片或视频到自定义的相册

- (void)saveImageIntoCustomeCollectionFromImageArr:(NSArray<UIImage *> *)imageArr  resultBlock:(SaveImageResult)block {
    
    /*
     requestAuthorization方法的功能
     1.如果用户还没有做过选择，这个方法就会弹框让用户做出选择
     1> 用户做出选择以后才会回调block
     
     2.如果用户之前已经做过选择，这个方法就不会再弹框，直接回调block，传递现在的授权状态给block
     */
    
    PHAuthorizationStatus oldStatus = [PHPhotoLibrary authorizationStatus];
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        switch (status) {
            case PHAuthorizationStatusAuthorized: {
                
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    
                    [imageArr enumerateObjectsUsingBlock:^(UIImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [self saveImageIntoAlbumWithImge:obj resultBlock:block];
                    }];
                });
                
                break;
            }
                
            case PHAuthorizationStatusDenied: {
                if (oldStatus == PHAuthorizationStatusNotDetermined) return;
                
                NSLog(@"提醒用户打开相册的访问开关");
                break;
            }
                
            case PHAuthorizationStatusRestricted: {
                NSLog(@"因系统原因，无法访问相册！");
                break;
            }
                
            default:
                break;
        }
    }];
}

- (void)saveVideoIntoCustomeCollectionFromUrl:(NSURL *)fileURL  resultBlock:(VideoSaveResult)block {

    /*
     requestAuthorization方法的功能
     1.如果用户还没有做过选择，这个方法就会弹框让用户做出选择
     1> 用户做出选择以后才会回调block
     
     2.如果用户之前已经做过选择，这个方法就不会再弹框，直接回调block，传递现在的授权状态给block
     */
    
    PHAuthorizationStatus oldStatus = [PHPhotoLibrary authorizationStatus];
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
            switch (status) {
                case PHAuthorizationStatusAuthorized: {
                    
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        [self saveVideoIntoAlbumFromUrl:fileURL resultBlock:block];
                    });
                    
                    break;
                }
                    
                case PHAuthorizationStatusDenied: {
                    if (oldStatus == PHAuthorizationStatusNotDetermined) return;
                    
                    NSLog(@"提醒用户打开相册的访问开关");
                    break;
                }
                    
                case PHAuthorizationStatusRestricted: {
                    NSLog(@"因系统原因，无法访问相册！");
                    break;
                }
                    
                default:
                    break;
            }
    }];
}

+ (void)getDataFromPHAsset:(PHAsset *)asset Complete:(Result)result {
    
    __block NSData *data;
    PHAssetResource *resource = [[PHAssetResource assetResourcesForAsset:asset] firstObject];
    NSString *pathCache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES) firstObject];
    NSString *path = [pathCache stringByAppendingPathComponent:resource.originalFilename];
    if ([kFileManager fileExistsAtPath:path]) {
        [kFileManager removeItemAtPath:path error:nil];
    }
    if (asset.mediaType == PHAssetMediaTypeImage) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.synchronous = YES;
        [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                          options:options
                                                    resultHandler:
         ^(NSData *imageData,
           NSString *dataUTI,
           UIImageOrientation orientation,
           NSDictionary *info) {
             data = [NSData dataWithData:imageData];
             [data writeToFile:path atomically:YES];
         }];
        
        if (result) {
            if (data.length <= 0) {
                result(nil);
            } else {
                result([NSURL fileURLWithPath:path]);
            }
        }
    }
    
    else if (asset.mediaType == PHAssetMediaTypeVideo) {
        BOOL ret = [kFileManager createFileAtPath:path contents:nil attributes:nil];
        if (!ret) {
            NSLog(@"创建文件失败");
        }
        NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:path];
        [[PHAssetResourceManager defaultManager] requestDataForAssetResource:resource options:nil dataReceivedHandler:^(NSData * _Nonnull data1) {
            [handle seekToEndOfFile];
            [handle writeData:data1];
        } completionHandler:^(NSError * _Nullable error) {
            [handle closeFile];
            if (!error) {
                result([NSURL fileURLWithPath:path]);
            }
        }];
    }
}


#pragma mark ---  获得自定义相册的所有照片

- (PHFetchResult *)getAssetsInCustomeAssetCollection {
    
    return [self fetchAssetsInAssetCollection:self.createdCollection ascending:YES];

}

//按创建日期升序排列
- (PHFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending {
    
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:option];
    return result;
}

#pragma mark -  保存相片或视频到相册

/**
 *  保存图片到相册
 */
- (void)saveImageIntoAlbumWithImge:(UIImage *)image resultBlock:(SaveImageResult)block
{
    // 获得相册
    PHAssetCollection *createdCollection = self.createdCollection;
    if (createdCollection == nil) {
        NSLog(@"获取失败");
        return;
    }
    
    __block NSString *createdAssetId = nil;
    
    // 添加图片到【相机胶卷】
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        createdAssetId = [PHAssetChangeRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset.localIdentifier;
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        
        PHFetchResult *createdAssets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetId] options:nil];
        // 将相片添加到相册
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdCollection];
            [request insertAssets:createdAssets atIndexes:[NSIndexSet indexSetWithIndex:0]];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {

            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(error,image);
                }
            });
        }];
    }];
    
}


- (void)saveVideoIntoAlbumFromUrl:(NSURL *)fileURL resultBlock:(VideoSaveResult)block {
    
    // 获得相册
    PHAssetCollection *createdCollection = [self createdCollection];
    if (createdCollection == nil) {
        NSLog(@"获取失败");
        return;
    }
    
    __block NSString *createdAssetId = nil;
    
    // 添加视频到【相机胶卷】
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        createdAssetId = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL].placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        
        PHFetchResult *createdAssets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetId] options:nil];
        // 将视频添加到相册
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdCollection];
            [request insertAssets:createdAssets atIndexes:[NSIndexSet indexSetWithIndex:0]];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            //回调
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(error,fileURL.path);
                }
            });
        }];
    }];
}

- (void)removeVideoOrPhotoAtIndexs:(NSArray<NSString *> *)arr resultBlock:(AssetRemoveResult)block{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //根据identifier集取到资源
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:arr options:nil];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            //删除
            [PHAssetChangeRequest deleteAssets: result];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(error);
                }
            });
        }];
    });
}

#pragma mark - 自定义相册

/**
 *  获得【自定义相册】
 */
- (PHAssetCollection *)createdCollection
{
    // 获取软件的名字作为相册的标题
    NSString *title = @"QuadrocopterGallery";
    
    // 获得所有的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:title]) {
            return collection;
        }
    }
    
    // 代码执行到这里，说明还没有自定义相册
    
    __block NSString *createdCollectionId = nil;
    
    @synchronized (self) {
        
        // 创建一个新的相册
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            createdCollectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title].placeholderForCreatedAssetCollection.localIdentifier;
        } error:nil];
    }
    
    if (createdCollectionId == nil) return nil;
    
    // 创建完毕后再取出相册
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCollectionId] options:nil].firstObject;
}


@end
