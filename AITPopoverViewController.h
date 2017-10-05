//
//  AITPopoverViewController.h
//  WiFiCameraViewer
//
//  Created by yang on 2017/9/20.
//  Copyright © 2017年 a-i-t. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSUInteger, AITFileType) {
    ATIDCIM= 0,
    ATIPhoto
};
@protocol AITPopoverViewControllerDelegate <NSObject>
@optional
-(void)clickItem:(AITFileType) type;

@end

@interface AITPopoverViewController : UIViewController
@property (nonatomic,weak) id<AITPopoverViewControllerDelegate> delegate;

@end
