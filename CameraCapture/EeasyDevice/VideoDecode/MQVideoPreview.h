//
//  MQVideoPreview.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/29.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PGQCAEAGLLayer.h"

@interface MQVideoPreview : UIView

@property(nonatomic, strong) PGQCAEAGLLayer *previewView;

@property(nonatomic, strong) UIImageView *backgroundView;


@end

