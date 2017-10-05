//
//  AITCameraCommand.h
//  WiFiCameraViewer
//
//  Created by Clyde on 2013/11/8.
//  Copyright (c) 2013年 a-i-t. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AITCameraRequest.h"

@interface AITCameraCommand : NSObject <AITCameraRequestDelegate>

// Set property
+ (NSURL*) setProperty:(NSString*)prop Value:(NSString*)val;
//
+ (NSURL*) commandUpdateUrl: (NSString *) ssid EncryptionKey: (NSString *) encryptionKey ;
+ (NSURL*) commandFindCameraUrl ;
+ (NSURL*) commandCameraSnapshotUrl;
+ (NSURL*) commandCameraRecordUrl;
+ (NSURL*) commandQueryPreviewStatusUrl;
+ (NSURL*) commandGetCameraidUrl;
+ (NSURL*) commandSetCameraidUrl:(NSString *) camid;
+ (NSURL*) commandQueryCameraRecordUrl;
+ (NSURL*) commandReactivateUrl ;
+ (NSURL*) commandWifiInfoUrl ;
//改
+ (NSURL*) commandListFileUrl: (int) count From: (int) from Property: (NSString *) property;
+ (NSURL*) commandListFirstFileUrl: (int) count Property: (NSString *) property;
//改
+ (NSURL*) commandDelFileUrl: (NSString *) fileName;
+ (NSURL*) commandQuerySettings;
+ (NSURL*) commandSetVideoRes: (NSString*) nsRes;
+ (NSURL*) commandSetImageRes: (NSString*) nsRes;
+ (NSURL*) commandSetFlicker: (NSString*) nsHz;
+ (NSURL*) commandSetEV: (NSString*) nsEvlabel;
+ (NSURL*) commandSetMTD: (NSString*) nsmtd;
+ (NSURL*) commandSetAWB: (NSString*) nsawb;
//
+ (NSURL*) commandSetDateTime: (NSString *) datetime;
//
+ (NSURL*) commandGetCamMenu;

+ (NSDictionary*) buildResultDictionary:(NSString*)result;

+ (NSString *) PROPERTY_SSID ;
+ (NSString *) PROPERTY_ENCRYPTION_KEY ;
+ (NSString *) PROPERTY_CAMERA_RTSP;
+ (NSString *) PROPERTY_QUERY_RECORD;
+ (NSString *) PROPERTY_CAMERAID;

+ (NSString *) PROPERTY_awb;
+ (NSString *) PROPERTY_ev;
+ (NSString *) PROPERTY_mtd;
+ (NSString *) PROPERTY_ImageRes;
+ (NSString *) PROPERTY_Flicker;
+ (NSString *) PROPERTY_VideoRes;
+ (NSString *) PROPERTY_IsStreaming;
+ (NSString *) PROPERTY_FWversion;
+ (NSString *) PROPERTY_DATETIME;

- (id) initWithUrl: (NSURL*) url View: (UIView *)aView ;
- (id) initWithUrl: (NSURL*) url Delegate:(id<AITCameraRequestDelegate>)delegate ;

@end
