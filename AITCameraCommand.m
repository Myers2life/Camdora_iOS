//
//  AITCameraCommand.m
//  WiFiCameraViewer
//
//  Created by Clyde on 2013/11/8.
//  Copyright (c) 2013年 a-i-t. All rights reserved.
//

#import "AITCameraCommand.h"
#import "AITUtil.h"
#import "Toast+UIView.h"

@interface AITCameraCommand()
{
    AITCameraRequest *request ;
    UIView *view ;
}
@end


@implementation AITCameraCommand

static NSString *CGI_PATH = @"/cgi-bin/Config.cgi" ;
static NSString *ACTION_SET = @"set" ;
static NSString *ACTION_GET = @"get" ;
static NSString *ACTION_DEL = @"del" ;
static NSString *ACTION_LS = @"dir" ;
static NSString *ACTION_SETCAMID = @"setcamid" ;


static NSString *PROPERTY = @"property";
static NSString *PROPERTY_NET = @"Net" ;
static NSString *PROPERTY_SSID = @"Net.WIFI_AP.SSID" ;
static NSString *PROPERTY_CAMERA_RTSP = @"Camera.Preview.RTSP.av" ;
static NSString *PROPERTY_ENCRYPTION_KEY = @"Net.WIFI_AP.CryptoKey" ;
static NSString *PROPERTY_DCIM = @"DCIM" ;
static NSString *PROPERTY_PHOTO = @"Photo" ;
static NSString *PROPERTY_VIDEO = @"Video" ;
static NSString *PROPERTY_QUERY_RECORD = @"Camera.Preview.MJPEG.status.record" ;
static NSString *PROPERTY_QUERY_PREVIEW_STATUS = @"Camera.Preview.*" ;
static NSString *PROPERTY_DATETIME = @"TimeSettings";
static NSString *PROPERTY_CAMERAID = @"Camera.Preview.Source.1.Camid";

static NSString *VALUE = @"value" ;
static NSString *COMMAND_FIND_CAMERA = @"findme" ;
static NSString *COMMAND_RESET = @"reset" ;
static NSString *COMMAND_CAPTURE = @"capture" ;
static NSString *COMMAND_RECORD = @"record" ;

static NSString *FORMAT = @"format" ;
static NSString *FORMAT_AVI = @"avi" ;
static NSString *FORMAT_JPEG = @"jpeg" ;
static NSString *FORMAT_ALL = @"all" ;

static NSString *COUNT = @"count" ;
static int COUNT_MAX = 32 ;
static int COUNT_MIN = 1 ;

static NSString *FROM = @"from" ;

static NSString *CAMERA_SETTINGS = @"Camera.Menu.*";
static NSString *PROPERTY_AWB = @"AWB";
static NSString *PROPERTY_EV = @"EV";
static NSString *PROPERTY_FLICKER = @"Flicker";
static NSString *PROPERTY_FWversion = @"FWversion";
static NSString *PROPERTY_MTD = @"MTD";
static NSString *PROPERTY_IMAGERES = @"Imageres";
static NSString *PROPERTY_ISSTREAMING = @"IsStreaming";
static NSString *PROPERTY_VIDEORES= @"Videores";
//
static NSString *CAMERA_GetTIME = @"TimeSettings";
static NSString *CAMERA_SetTIME = @"Camera.Preview.MJPEG.TimeStamp";

+ (NSString *) PROPERTY_SSID
{
    return PROPERTY_SSID ;
}

+ (NSString *) PROPERTY_ENCRYPTION_KEY
{
    return PROPERTY_ENCRYPTION_KEY ;
}

+ (NSString *) PROPERTY_CAMERA_RTSP
{
    return PROPERTY_CAMERA_RTSP;
}

+ (NSString *) PROPERTY_QUERY_RECORD
{
    return PROPERTY_QUERY_RECORD;
}

+ (NSString *) PROPERTY_CAMERAID
{
    return PROPERTY_CAMERAID;
}

+ (NSString *) PROPERTY_awb
{
    return PROPERTY_AWB;
}

+ (NSString *) PROPERTY_ev
{
    return PROPERTY_EV;
}

+ (NSString *) PROPERTY_mtd;
{
    return PROPERTY_MTD;
}

+ (NSString *) PROPERTY_ImageRes
{
    return PROPERTY_IMAGERES;
}

+ (NSString *) PROPERTY_Flicker
{
    return PROPERTY_FLICKER;
}

+ (NSString *) PROPERTY_VideoRes
{
    return PROPERTY_VIDEORES;
}

+ (NSString *) PROPERTY_IsStreaming
{
    return PROPERTY_ISSTREAMING;
}

+ (NSString *) PROPERTY_FWversion
{
    return PROPERTY_FWversion;
}

+(NSString *) PROPERTY_DATETIME
{
    return PROPERTY_DATETIME;
}

+ (NSString *) buildKeyValuePair:(NSString*) key Value:(NSString *) value
{
    if(value != nil)
        return [NSString stringWithFormat:@"%@=%@", key, value] ;
    else
        return [NSString stringWithFormat:@"%@", key] ;
}

+ (NSString *) buildProperty:(NSString *) property Value: (NSString *) value
{
    return [NSString stringWithFormat:@"%@&%@", [AITCameraCommand buildKeyValuePair:PROPERTY Value:property], [AITCameraCommand buildKeyValuePair:VALUE Value:value]] ;
}

+ (NSString *) buildProperty:(NSString *) property
{
    return [NSString stringWithFormat:@"%@", [AITCameraCommand buildKeyValuePair:PROPERTY Value:property]] ;
}

+ (NSString *) buildArgumentList: (NSArray *) arguments
{
    NSString *argumentList = @"" ;
    
    for (NSString *argument in arguments) {
    
        if (argument) {
        
            argumentList = [argumentList stringByAppendingFormat: @"&%@", argument] ;
        }
    }
    return argumentList ;
}

+ (NSURL*) buildRequestUrl: (NSString *) path Action: (NSString *) action ArgumentList: (NSString *) argumentList
{
    NSString *cameraIp = [AITUtil getCameraAddress] ;

    NSString *url = [NSString stringWithFormat:@"http://%@%@?action=%@%@", cameraIp, path, action, argumentList];
    
    return [[NSURL alloc] initWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] ;
}

+ (NSURL*) commandUpdateUrl: (NSString *) ssid EncryptionKey: (NSString *) encryptionKey
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_SSID Value: ssid]] ;
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_ENCRYPTION_KEY Value: encryptionKey]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandFindCameraUrl
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_NET Value: COMMAND_FIND_CAMERA]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}
//PROPERTY_CAMERAID
+ (NSURL*) commandGetCameraidUrl
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_CAMERAID]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_GET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandSetCameraidUrl: (NSString *) camid
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_CAMERAID Value:camid]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SETCAMID ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandCameraSnapshotUrl
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_VIDEO Value: COMMAND_CAPTURE]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandCameraRecordUrl
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_VIDEO Value: COMMAND_RECORD]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandQueryPreviewStatusUrl
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_QUERY_PREVIEW_STATUS]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_GET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+(NSURL*) commandQuerySettings
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:CAMERA_SETTINGS]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_GET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
    
}

+ (NSURL*) commandQueryCameraRecordUrl
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_QUERY_RECORD]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_GET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandReactivateUrl
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_NET Value: COMMAND_RESET]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandWifiInfoUrl
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_SSID]] ;
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_ENCRYPTION_KEY]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_GET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandListFileUrl: (int) count From: (int) from Property: (NSString *) property
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    //改
    [arguments addObject: [AITCameraCommand buildProperty:property]] ;
    //改
    [arguments addObject: [AITCameraCommand buildKeyValuePair:FORMAT Value:FORMAT_ALL]] ;
    
    count = count > COUNT_MAX ? COUNT_MAX : count ;
    count = count < COUNT_MIN ? COUNT_MIN : count ;
    
    [arguments addObject: [AITCameraCommand buildKeyValuePair:COUNT Value:[NSString stringWithFormat:@"%d", count]]] ;
    [arguments addObject: [AITCameraCommand buildKeyValuePair:FROM Value:[NSString stringWithFormat:@"%d", from]]] ;

    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_LS ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandListFirstFileUrl: (int) count Property: (NSString *) property
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    //改
    [arguments addObject: [AITCameraCommand buildProperty:property]] ;
    //改
    [arguments addObject: [AITCameraCommand buildKeyValuePair:FORMAT Value:FORMAT_ALL]] ;
    
    count = count > COUNT_MAX ? COUNT_MAX : count ;
    count = count < COUNT_MIN ? COUNT_MIN : count ;
    
    [arguments addObject: [AITCameraCommand buildKeyValuePair:COUNT Value:[NSString stringWithFormat:@"%d", count]]] ;
    
    [arguments addObject: [AITCameraCommand buildKeyValuePair:FROM Value:@"0"]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_LS ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandDelFileUrl: (NSString *) fileName
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    //[arguments addObject: [AITCameraCommand buildProperty:[NSString stringWithFormat:@"%@%@", PROPERTY_DCIM_DEL, fileName]]] ;
    [arguments addObject: [AITCameraCommand buildProperty:[NSString stringWithFormat:@"%@", fileName]]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_DEL ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandSetVideoRes: (NSString*) nsRes
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_VIDEORES Value: [NSString stringWithFormat:@"%@", nsRes]]] ;
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandSetImageRes: (NSString*) nsRes
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_IMAGERES Value: [NSString stringWithFormat:@"%@", nsRes]]] ;
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}
/*
 * Set Flicker
 * cgi-bin/Config.cgi?action=set&property=Flicker&value=[50Hz|60Hz]
 */
+ (NSURL*) commandSetFlicker: (NSString*) nsHz
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_FLICKER Value: [NSString stringWithFormat:@"%@", nsHz]]] ;
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}
/*
 * Set EV (exposure)
 * cgi-bin/Config.cgi?action=set&property=Exposure&value=[EVN200|EVN167|EVN133|EVN100|EVN067|EVN033|
 *                                                        EV0|
 *                                                        EVP033|EVP067|EVP100|EVP133|EVP167|EVP200]
 */
+ (NSURL*) commandSetEV: (NSString*) nsEvlabel
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:@"Exposure" Value: [NSString stringWithFormat:@"%@", nsEvlabel]]] ;
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}
/*
 * Set MTD off, dull, middle, keen
 * cgi-bin/Config.cgi?action=set&property=MTD&value=[Off|Low|Middle|High]
 */
+ (NSURL*) commandSetMTD: (NSString*) nsmtd
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_MTD Value: [NSString stringWithFormat:@"%@", nsmtd]]] ;
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}
/*
 * Set AWB auto, daylight, cloudy
 * cgi-bin/Config.cgi?action=set&property=AWB&value=[Auto|Daylight|Cloudy]
 *
 * TODO: there are 7 items to select, but the UI onle support 3 items
 */
+ (NSURL*) commandSetAWB: (NSString*) nsawb
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_AWB Value: [NSString stringWithFormat:@"%@", nsawb]]] ;
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

+ (NSURL*) commandSetDateTime: (NSString *) datetime
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init] ;
    
    [arguments addObject: [AITCameraCommand buildProperty:PROPERTY_DATETIME Value: datetime]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;

}

/*
 * Get cammenu.xml
 * http://AIT.camera.dev/cdv/cammenu.xml
 */
+ (NSURL*) commandGetCamMenu
{
    NSString *cameraIp = [AITUtil getCameraAddress] ;
    NSString *cammenu  = @"/cdv/cammenu.xml";
    
    NSString *url = [NSString stringWithFormat:@"http://%@%@", cameraIp, cammenu] ;
    return [[NSURL alloc] initWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSDictionary*) buildResultDictionary:(NSString*)result
{
    NSMutableArray *keyArray;
    NSMutableArray *valArray;
    NSArray *lines;
        
    keyArray = [[NSMutableArray alloc] init];
    valArray = [[NSMutableArray alloc] init];
    lines = [result componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        NSArray *state = [line componentsSeparatedByString:@"="];
        if ([state count] != 2)
            continue;
        [keyArray addObject:[[state objectAtIndex:0] copy]];
        [valArray addObject:[[state objectAtIndex:1] copy]];
    }
    if ([keyArray count] == 0)
        return nil;
    return [NSDictionary dictionaryWithObjects:valArray forKeys:keyArray];
}

+ (NSURL*) setProperty:(NSString*)prop Value:(NSString*)val
{
    NSMutableArray * arguments = [[NSMutableArray alloc] init];
    
    [arguments addObject: [AITCameraCommand buildProperty:prop Value: val]] ;
    
    return [AITCameraCommand buildRequestUrl:CGI_PATH Action: ACTION_SET ArgumentList: [AITCameraCommand buildArgumentList:arguments]] ;
}

- (id) initWithUrl: (NSURL*) url View: (UIView *)aView
{
    self = [super init] ;
    
    if (self) {
        view = aView ;
        
        request = [[AITCameraRequest alloc] initWithUrl:url Delegate:self] ;
    }
    return self ;
}

-(void) requestFinished:(NSString*) result
{
    if (result) {
        [view makeToast:NSLocalizedString(@"Command Succeeded", nil)];
    } else {
        [view makeToast:NSLocalizedString(@"Command Failed", nil)];
    }
}

- (id) initWithUrl: (NSURL*) url Delegate:(id<AITCameraRequestDelegate>)delegate
{
    self = [super init] ;
    
    if (self) {
        request = [[AITCameraRequest alloc] initWithUrl:url Delegate:delegate] ;
    }
    return self ;
}

@end
