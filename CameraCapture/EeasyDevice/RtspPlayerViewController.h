//
//  RtspPlayerViewController.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/29.
//

#import <UIKit/UIKit.h>


@interface RtspPlayerViewController : UIViewController

@property (nonatomic, copy) dispatch_block_t videoPlayCancelBlock;

@end

