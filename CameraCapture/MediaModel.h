//
//  MediaModel.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/26.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MediaType) {
    MediaTypePhoto,
    MediaTypeVideo,
};

@interface MediaModel : NSObject

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, assign) MediaType mediaType;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, assign) int fileSize;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) UIImage *thumbImg; //缩略图

@end

