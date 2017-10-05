//
//  AITCameraBrowserViewController.h
//  WiFiCameraViewer
//
//  Created by Clyde on 2013/11/17.
//  Copyright (c) 2013年 a-i-t. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AITCameraCommand.h"
#import "AITPopoverViewController.h"

@interface AITCameraBrowserViewController : UITableViewController <AITCameraRequestDelegate, UIAlertViewDelegate,UIPopoverPresentationControllerDelegate,AITPopoverViewControllerDelegate>
- (bool) isRunning;
@end
