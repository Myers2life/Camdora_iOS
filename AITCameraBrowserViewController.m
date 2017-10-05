//
//  AITCameraBrowserViewController.m
//  WiFiCameraViewer
//
//  Created by Clyde on 2013/11/17.
//  Copyright (c) 2013年 a-i-t. All rights reserved.
//

#import "AITCameraBrowserViewController.h"
#import "AITFileNode.h"
#import "AITFileCell.h"
#import "AITFileDownloader.h"
#import "AITUtil.h"
#import "GDataXMLNode.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UINavagationHelper.h"
#import "AITLocalAlbumViewController.h"
//#import "VLCMovieViewController.h"

typedef enum
{
    CAMERA_FILE_LIST,
    CAMERA_FILE_DELETE,
    CAMERA_FILE_STREAM
} CAMERA_cmd_t;

@interface AITCameraBrowserViewController ()
{
    UIActivityIndicatorView *indicator;
    NSMutableArray *fileNodes ;

    int fetch_try_cnt;
    int fetchSize ;
    int fileDelCount;
    bool fetchFirst ;
    bool fetchStopped ;
    
    AITCameraCommand *cameraCommand ;
    UIDocumentInteractionController *documentInteractionController ;

    NSIndexPath *selectedIndexPath ;
    
    int dlCount;
    int activeIndex;
    NSTimer *dlTimer;
    CAMERA_cmd_t   cmd_tag;
    //改
    NSMutableArray *fileNodesAVI;
    NSMutableArray *fileNodesJPG;
    AITPopoverViewController *popViewCtl;
    NSString *fileProperty;
    NSString *currentFileList;
    //改
    
    //改
    UIBarButtonItem *saveButton;
    UIBarButtonItem *deleteButton;
    UIBarButtonItem *cancelButton;
    UIBarButtonItem *switchButton;
    UIBarButtonItem *flexibleSpace;
    UIBarButtonItem *localAlbumButton;
    IBOutlet UIView * localAlbumView;
    AITLocalAlbumViewController *localAlbumViewController;
}
@end

@implementation AITCameraBrowserViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        indicator = nil;
    }
    return self;
}

- (bool)isRunning
{
    if (fileNodes == nil)
        return NO;
    for (unsigned int i = 0; i < [fileNodes count]; i++) {
        AITFileNode *fn = [fileNodes objectAtIndex:i];
        if (fn->downloader)
            return YES;
    }
    return NO;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    int total, i;

    total = (int)[self.tableView numberOfRowsInSection:0];
    if (editing) {
        // show toolbar
        [self.navigationItem setHidesBackButton: YES];
//        [self.navigationController setToolbarHidden:FALSE];
            [self setToolbarItems:[NSArray arrayWithObjects:deleteButton,
                                                            flexibleSpace,
                                                            saveButton,
                                                            flexibleSpace,
                                                            cancelButton,
                                                            flexibleSpace,
                                                            switchButton,
                                                            nil] animated:YES];
        // TODO: Show selected marker
        for (i = 0; i < total; i++) {
            AITFileNode *fileNode = [fileNodes objectAtIndex:i];
            /* Not to remove selected, if there are some file node is downloading */
            if (fileNode->downloader == nil) {
                fileNode.selected = NO;
            }
            NSIndexPath *p = [NSIndexPath indexPathForRow:i inSection:0];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:p];
            if (cell && fileNode->downloader)
                [cell setSelected:YES];
            else
                [cell setSelected:NO];
        }
    } else {
        for (int i = 0; i < [fileNodes count]; i++) {
            AITFileNode *fileNode = [fileNodes objectAtIndex:i];
            if (fileNode->downloader == nil)
                fileNode.selected = NO;
        }
        // remove toolbar
        [self setToolbarItems: [NSArray arrayWithObjects:flexibleSpace,localAlbumButton,flexibleSpace,nil]];
        //        [self.navigationController setToolbarHidden:TRUE];
        [self.navigationItem setHidesBackButton: NO];
    }
}

- (IBAction) buttonSave:(id)sender {
    int total, i;
    
    total = (int)[self.tableView numberOfRowsInSection:0];
    for (i = 0; i < total; i++) {
        AITFileNode *fileNode = [fileNodes objectAtIndex:i];
        if (fileNode.selected) {
            dlCount++;
            if(fileNode->downloader == nil && fileNode.progress == -1) {
                NSURL *url;
                NSString *filename;
                NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] ;
                
                // Create downloader
                url = [NSURL URLWithString: [NSString stringWithFormat:@"http://%@%@", [AITUtil getCameraAddress], [fileNode.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]] ;
                filename = [fileNode.name substringFromIndex:[fileNode.name rangeOfString:@"/" options:NSBackwardsSearch].location + 1] ;
                fileNode->downloader = [[AITFileDownloader alloc] initWithUrl:url Path:[directory stringByAppendingPathComponent:filename]];
                fileNode.progress = 0.0;
            }
        }
    }
    for (int i = 0; i < [self.tableView numberOfRowsInSection:0]; i++) {
        NSIndexPath *p = [NSIndexPath indexPathForRow:i inSection:0];
        AITFileCell *cell = (AITFileCell*)[self.tableView cellForRowAtIndexPath:p];
        AITFileNode *fileNode = [fileNodes objectAtIndex:p.row] ;

        if (cell && fileNode.selected) {
            cell->dlProgress.hidden = FALSE;
            cell->dlProgressLabel.hidden = FALSE;
            cell->dlProgress.progress = fileNode.progress;
        }
    }
    if (dlCount > 0) {
        // To hide Back button to avoid processing by interrupt
        [self.navigationItem setHidesBackButton: YES];
        if(dlTimer == nil)
            dlTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateUI:) userInfo:nil repeats:YES];
    } else {
        [self setEditing:NO animated:YES];
    }
}

- (IBAction) buttonCancel:(id)sender {
    if (dlCount == 0)
        return;
    for (int i = 0; i < [self.tableView numberOfRowsInSection:0]; i++) {
        AITFileNode *fileNode = [fileNodes objectAtIndex:i] ;
        if (fileNode.selected) {
            NSLog(@"Abort %@", fileNode.name);
            //[self.tableView deselectRowAtIndexPath:p animated:YES];
            if(fileNode->downloader) {
                fileNode->downloader->abort = true;
            }
        }
    }
    [self setEditing:NO animated:YES];
}

- (IBAction) buttonDelete:(id)sender {
    [self deleteNext:0];
}

//改
- (IBAction)buttonSwitch:(id)sender {
    
    popViewCtl.modalPresentationStyle = UIModalPresentationPopover;
//    popViewCtl.popoverPresentationController.sourceView = sender;
//    popViewCtl.popoverPresentationController.sourceRect = ((UIBarButtonItem*)sender).accessibilityFrame;
    popViewCtl.popoverPresentationController.barButtonItem = (UIBarButtonItem*)sender;
    popViewCtl.preferredContentSize = CGSizeMake(80, 80);
    popViewCtl.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;
    popViewCtl.popoverPresentationController.delegate = self;
    [self presentViewController:popViewCtl animated:YES completion:nil];
}
//改
//改
- (IBAction)buttonLocaAlbum:(id)sender {
    
    if (localAlbumViewController == nil) {
        localAlbumViewController = [[AITLocalAlbumViewController alloc] initWithNibName:@"AITLocalAlbumViewController" bundle:nil] ;
    }
    localAlbumViewController.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style: UIBarButtonItemStylePlain target:nil action:nil] ;
    [self.navigationController pushViewController:localAlbumViewController animated:YES];
}
//改

- (void)deleteNext:(int) from
{
    int total;
    int i;

    total = (int)[self.tableView numberOfRowsInSection:0];
    fileDelCount = 0;
    for (i = from; i < total; i++) {
        AITFileNode *file = [fileNodes objectAtIndex:i] ;
        
        if(file.selected) {
            fileDelCount = -1;
            activeIndex = i;
            cmd_tag = CAMERA_FILE_DELETE;
            NSLog(@"Select File is %d : %@", activeIndex, file.name);
            /* Delete files */
            cameraCommand = [[AITCameraCommand alloc]
                             initWithUrl:[AITCameraCommand commandDelFileUrl:
                                          [file.name stringByReplacingOccurrencesOfString: @"/" withString:@"$"]]Delegate:self];
            return;
        }
    }
    /* remove items */
    for (i = total - 1; i >= 0; i--) {
        AITFileNode *file = [fileNodes objectAtIndex:i] ;
        if(file.selected) {
            [fileNodes removeObjectAtIndex:i];
        }
    }
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    self.title = NSLocalizedString(@"Camera File Browser", nil) ;
    [self.navigationItem setCustomTitleView];

    
    saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleDone target:self action:@selector(buttonSave:)];
    
    deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(buttonDelete:)];
    
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleDone target:self action:@selector(buttonCancel:)];
    //改
    currentFileList = [NSString stringWithFormat:@"%@",TAG_DCIM];
    switchButton = [[UIBarButtonItem alloc] initWithTitle:currentFileList style:UIBarButtonItemStyleDone target:self action:@selector(buttonSwitch:)];
    flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    //改
    
    localAlbumButton = [[UIBarButtonItem alloc] initWithCustomView: localAlbumView];
    [self setToolbarItems: [NSArray arrayWithObjects:flexibleSpace,localAlbumButton,flexibleSpace,nil]];
//    [self setToolbarItems:[NSArray arrayWithObjects:deleteButton,
//                                                    flexibleSpace,
//                                                    saveButton,
//                                                    flexibleSpace,
//                                                    cancelButton,
//                                                    flexibleSpace,
//                                                    switchButton,
//                                                    nil] animated:YES];
    //改
    
    //改
    popViewCtl = [[AITPopoverViewController alloc] init];
    popViewCtl.delegate = self;
    //改
    
    // Set editing mode to false by default
    self.tableView.editing = FALSE;
    
    UINib *nib = [UINib nibWithNibName:@"AITFileCell" bundle:nil];
    
    [self.tableView registerNib:nib forCellReuseIdentifier:[AITFileCell reuseIdentifier]] ;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated] ;

    if (!indicator) {
        indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicator.frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
        indicator.center = self.view.center;
        [self.view addSubview:indicator];
        [indicator bringSubviewToFront:self.view];
    }
    [indicator startAnimating];
    
    if(fileNodes == nil)
        fileNodes = [[NSMutableArray alloc] init];
    //改
    if (fileNodesAVI == nil) {
        fileNodesAVI = [[NSMutableArray alloc] init];
    }
    if (fileNodesJPG == nil) {
        fileNodesJPG = [[NSMutableArray alloc] init];
    }
    if ([self isRunning]) {
        return;
    }
    [fileNodesAVI removeAllObjects];
    [fileNodesJPG removeAllObjects];
    [fileNodes removeAllObjects];
    //改
    [self.tableView reloadData];
    fetchSize = 16;
    fetchStopped = NO ;
    fetchFirst = YES ;
    cmd_tag = CAMERA_FILE_LIST;
    fetch_try_cnt = 3;
    //改
    fileProperty = [NSString stringWithFormat:@"%@",TAG_DCIM];
    cameraCommand = [[AITCameraCommand alloc] initWithUrl:[AITCameraCommand commandListFirstFileUrl:fetchSize Property: fileProperty] Delegate:self] ;
    //改
    
    [self.navigationController setToolbarHidden:FALSE];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated] ;
    if ([self isRunning])
        [indicator stopAnimating];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setEditing:NO animated:YES];
    [self.navigationController setToolbarHidden:TRUE];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated] ;
    
    fetchStopped = YES ;
    cameraCommand = nil ;
}

static NSString *TAG_DCIM = @"DCIM" ;
static NSString *TAG_Photo = @"Photo" ;
static NSString *TAG_file = @"file" ;
static NSString *TAG_name = @"name" ;
static NSString *TAG_format = @"format" ;
static NSString *TAG_size = @"size" ;
static NSString *TAG_attr = @"attr" ;
static NSString *TAG_time = @"time" ;

static NSString *TAG_amount = @"amount" ;


-(GDataXMLElement *) getFirstChild:(GDataXMLElement *) element WithName: (NSString*) name
{
    NSArray *elements = [element elementsForName:name] ;
    
    if (elements.count > 0) {
        
        return (GDataXMLElement *) [elements objectAtIndex:0];
    }
    
    NSLog(@"Cannot find Tag:%@", name) ;
    
    return nil ;
}


-(void) requestFinished:(NSString*) result
{
    if (cameraCommand == nil)
        return ;
    if (cmd_tag == CAMERA_FILE_LIST) {
        //int index = 0;

        if (fetchFirst && [fileNodes count] > 0) {
            [fileNodes removeAllObjects];
        }
        fetchFirst = NO ;
        if (result) {
            //NSLog(@"Result = %@\n", result) ;
            NSLog(@"======== FILE LIST =======");
            GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithXMLString:[result substringToIndex:[result rangeOfString:@">" options:NSBackwardsSearch].location + 1] options:0 error:nil];
            GDataXMLElement *dcimElement = doc.rootElement ;
            //NSLog(@"dcimElement = %@\n", dcimElement.name) ;
            int amount = -1;
            NSArray *dcimChildren = [dcimElement children] ;
            NSMutableArray *tempFileNodes = [[NSMutableArray alloc] initWithCapacity:3];
            for (GDataXMLElement *dcimChild in dcimChildren) {
                if ([[dcimChild name] isEqualToString:TAG_file]) {
//                    NSArray *fileChildren = [dcimChild children] ;
//                    for (GDataXMLElement * fileChild in fileChildren) {
//                        NSLog(@"Child %@ = %@\n", fileChild.name, [fileChild stringValue]) ;
//                    }
                    AITFileNode *fileNode = [[AITFileNode alloc] init] ;
                    fileNode.name = [[self getFirstChild:dcimChild WithName:TAG_name] stringValue] ;
                    fileNode.format = [[self getFirstChild:dcimChild WithName:TAG_format] stringValue] ;
                    fileNode.size = (unsigned int)[[[self getFirstChild:dcimChild WithName:TAG_size] stringValue] integerValue];
                    fileNode.attr = [[self getFirstChild:dcimChild WithName:TAG_attr] stringValue] ;
                    fileNode.time = [[self getFirstChild:dcimChild WithName:TAG_time] stringValue] ;
                    fileNode.blValid = TRUE;
                    fileNode.progress = -1;
                    [tempFileNodes addObject: fileNode] ;
                    NSLog(@"Added file \"%@\" into fileNode\n", fileNode.name) ;
                } else if ([[dcimChild name] isEqualToString:TAG_amount]) {
                    amount = [[dcimChild stringValue] intValue] ;
                } else {
                    NSLog(@"ERROR TRY!!");
                }
            }
            //改
            if ([fileProperty isEqualToString:TAG_DCIM]) {
                [fileNodesAVI addObjectsFromArray:tempFileNodes];
            } else {
                [fileNodesJPG addObjectsFromArray:tempFileNodes];
            }
            //改
            if ((amount == fetchSize || amount == -1) && !fetchStopped) {
                cmd_tag = CAMERA_FILE_LIST;
                cameraCommand = [[AITCameraCommand alloc] initWithUrl:[AITCameraCommand commandListFileUrl:fetchSize From:(unsigned int)[fileNodes count] Property:fileProperty] Delegate:self] ;
            } else {
                NSLog(@"List DONE");
                //改
                if ([fileProperty isEqualToString:TAG_DCIM]) {
                    fileProperty = [NSString stringWithFormat:@"%@",TAG_Photo];
                    cameraCommand = [[AITCameraCommand alloc] initWithUrl:[AITCameraCommand commandListFirstFileUrl:fetchSize Property:fileProperty] Delegate:self] ;
                } else {
                    [indicator stopAnimating];
                }
                //改
            }
        
        } else {
            NSLog(@"Result = nil, try again!!") ;
            while (fetch_try_cnt) {
                fetch_try_cnt--;
                cmd_tag = CAMERA_FILE_LIST;
                //改
                cameraCommand = [[AITCameraCommand alloc] initWithUrl:[AITCameraCommand commandListFileUrl:fetchSize From:(unsigned int)[fileNodes count] Property:fileProperty] Delegate:self] ;
                //改
                return;
            }
            [indicator stopAnimating];
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Failed", nil)
                                  message:NSLocalizedString(@"Please check network connection or your camera", nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                                  otherButtonTitles:nil, nil];
            [alert show] ;

        }
        //改
        if ([currentFileList isEqualToString:TAG_DCIM]) {
            fileNodes = fileNodesAVI;
        } else {
            fileNodes = fileNodesJPG;
        }
        //改
        [self.tableView reloadData] ;
    } else if (cmd_tag == CAMERA_FILE_DELETE) {
        //Get file deletion response
        if (fileDelCount > 0)
            fileDelCount--;
        if(fileDelCount) {
            NSLog(@"Result = %@\n", result) ;
            NSLog(@"Delete next %d\n", activeIndex + 1) ;
            [self deleteNext: activeIndex + 1];
        } else {
            [fileNodes removeObjectAtIndex:activeIndex];
            [self.tableView reloadData];
            [self.navigationItem setHidesBackButton: NO];
        }
    } else if (cmd_tag == CAMERA_FILE_STREAM) {

    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [fileNodes count] ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    AITFileCell *cell = [tableView dequeueReusableCellWithIdentifier:[AITFileCell reuseIdentifier]];
    if (cell == nil) {
        cell = [[AITFileCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[AITFileCell reuseIdentifier]];
    }
    // Configure the cell...
    AITFileNode *file = [fileNodes objectAtIndex:indexPath.row] ;
    cell.fileName.text = [file.name substringFromIndex:[file.name rangeOfString:@"/" options:NSBackwardsSearch].location + 1] ;

    unsigned int fileSize = file.size ;
    
    NSString *sizeString = @"0" ;
    if (fileSize < 1024) {
        sizeString = [NSString stringWithFormat:@"%u", fileSize] ;
    } else {
        fileSize /= 1024 ;
        if (fileSize < 1024) {
            sizeString = [NSString stringWithFormat:@"%uK", fileSize] ;
        } else {
            fileSize /= 1024 ;
            sizeString = [NSString stringWithFormat:@"%uM", fileSize] ;
        }
    }
    cell.fileSize.text = sizeString ;
    // NSString convert NSDate
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *filedate = [[NSDate alloc] init];
    filedate = [dateFormatter dateFromString:file.time];
    [dateFormatter setDateFormat:@"yy-MM-dd HH:mm"];
    cell.fileDate.text = [dateFormatter stringFromDate:filedate];
    cell.filePath = [NSURL URLWithString:
                     [NSString stringWithFormat:@"http://%@%@", [AITUtil getCameraAddress],
                      [file.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    cell.fileIcon.image = [UIImage imageNamed:@"media-type.png"];
    // Setup progress bar for each cell
    if(cell->dlProgress == nil) {
        cell->dlProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        cell->dlProgress.frame = CGRectMake(100, cell.frame.size.height-5, 130, 9);
        cell->dlProgress.tag =indexPath.row*10+1;
        cell->dlProgress.progress = 0.0;
        [cell.contentView addSubview:cell->dlProgress];
        
        cell->dlProgressLabel =  [[UILabel alloc] initWithFrame:CGRectMake(
                                        100+cell->dlProgress.frame.size.width+1,
                                        cell.frame.size.height-17, 50, 20)];
        cell->dlProgressLabel.text = @"0%";
        [cell.contentView addSubview:cell->dlProgressLabel];
    }
    BOOL hide = !(file.progress != -1);
    if (!hide) {
        cell->dlProgressLabel.text = [NSString stringWithFormat:@"%.0f%%",file.progress*100];
        cell->dlProgress.progress = (float)file.progress;
    }
    [cell->dlProgress setHidden:hide];
    [cell->dlProgressLabel setHidden:hide];
    if (file->downloader) {
        NSLog(@"Select %@", file.name);
        [cell setSelected:YES];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell.frame.size.height;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/
//改
#pragma mark - UIPopoverPresentationControllerDelegate
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController*)controller{
    return UIModalPresentationNone;
}

#pragma mark - AITPopoverViewControllerDelegate
-(void)clickItem:(AITFileType)type {
    UIBarButtonItem *barButton = [self.toolbarItems lastObject];
    if (type == ATIDCIM && ![currentFileList isEqualToString:TAG_DCIM]) {
        NSLog(@"click dcim");
        currentFileList = [NSString stringWithFormat:@"%@",TAG_DCIM];
        [barButton setTitle:TAG_DCIM];
        fileNodes = fileNodesAVI;
        [self.tableView reloadData];
    } else if (type == ATIPhoto && ![currentFileList isEqualToString:TAG_Photo]) {
        NSLog(@"click photo");
        [barButton setTitle:TAG_Photo];
        currentFileList = [NSString stringWithFormat:@"%@",TAG_Photo];
        fileNodes = fileNodesJPG;
        [self.tableView reloadData];
    }
}
//改

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AITFileNode *fileNode = [fileNodes objectAtIndex:indexPath.row] ;
    AITFileCell *cell = (AITFileCell*)[tableView cellForRowAtIndexPath:indexPath] ;
    
    NSLog(@"Select >>%@", cell.filePath) ;
    // Do nothing while in editing mode
    if(self.tableView.editing == FALSE) {
        if (dlCount)    // when running, nothing to do!
            return;
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        selectedIndexPath = indexPath ;
        
        UIAlertView *alert = nil;
        
        if(fileNode->downloader) {
            alert = [[UIAlertView alloc] initWithTitle:[cell fileName].text message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil)  otherButtonTitles:NSLocalizedString(@"Stop download", nil), nil];
        } else if(dlTimer == nil) {
            NSString *extension = [cell.filePath pathExtension];
            
            if ([extension caseInsensitiveCompare:@"jpg"]  == NSOrderedSame ||
                [extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame) {
                // To Popup Save/Delete/Cancel dialogbox
                // TODO: currently not support JPEG viewer
                alert = [[UIAlertView alloc] initWithTitle:[cell fileName].text message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil)  otherButtonTitles:NSLocalizedString(@"Save", nil), NSLocalizedString(@"Delete", nil), nil];
            } else {
                // To Popup Open/Save/Delete/Cancel dialogbox
                // Others should be .MOV
                alert = [[UIAlertView alloc] initWithTitle:[cell fileName].text message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil)  otherButtonTitles:NSLocalizedString(@"Open", nil), NSLocalizedString(@"Save", nil), NSLocalizedString(@"Delete", nil), nil];
            }
        }
        [alert show] ;
    } else {
        fileNode.selected = YES;
        //[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AITFileCell *cell = (AITFileCell*)[tableView cellForRowAtIndexPath:indexPath] ;
    AITFileNode *fileNode = [fileNodes objectAtIndex:indexPath.row];
    if (fileNode->downloader)
        return;
    fileNode.selected = NO;
    //[cell setAccessoryType:UITableViewCellAccessoryNone];
    NSLog(@"Deselect <<%@", cell.filePath) ;
}
//改
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *sectionHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 375, 20)];
    UILabel *titleLable = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 375, 20)];
    titleLable.text = [NSString stringWithFormat:@"File Browser: %@(%ld items)",currentFileList,[fileNodes count]];
    [sectionHeader addSubview:titleLable];
    
    return sectionHeader;
}
//改

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20.0;
}

/*
 * Periodically update progress of download
 * To find the running, if no then start a new one
 */
- (void)updateUI:(NSTimer *)timer
{
    NSIndexPath *p;
    AITFileCell *cell;
    AITFileNode *fileNode;
    AITFileDownloader *downloader;
    unsigned int i;
    // Fristly, find downloading filenode
    downloader = nil;
    for (i = 0; i < [fileNodes count]; i++) {
        fileNode   = [fileNodes objectAtIndex:i] ;
        if(fileNode.selected && fileNode->downloader) {
            if(fileNode->downloader->downloading) {
                // Got the running
                downloader = fileNode->downloader;
                break;
            }
        }
    }
    if (downloader == nil) {
        // Not found and processing to download then start new one!
        for (i = 0; i < [fileNodes count]; i++) {
            fileNode = [fileNodes objectAtIndex:i] ;
            if(fileNode.selected) {
                downloader = fileNode->downloader;
                if(downloader != nil) {
                    /* start downloading */
                    [downloader startDownload];
                    break;
                }
            }
        }
    }
    if (downloader == nil) {
        // the file may downloaded before!!
        [dlTimer invalidate];
        dlTimer = nil;
        dlCount = 0;
        return;
    }
    // To find appearring cell of working item in current tableview
    p    = [NSIndexPath indexPathForRow:i inSection:0];
    cell = (AITFileCell*)[self.tableView cellForRowAtIndexPath:p];
    if (cell) {
        cell->dlProgress.hidden = FALSE;
        cell->dlProgressLabel.hidden = FALSE;
    }
    // Check the running status
    if(downloader->offsetInFile == -1 || downloader->abort){
        dlCount--;
        if (!downloader->abort) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[cell fileName].text message:NSLocalizedString(@"Download failed!", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil)  otherButtonTitles:nil, nil];
            [alert show] ;
        }
        if (cell) {
            cell->dlProgress.hidden = TRUE;
            cell->dlProgressLabel.hidden = TRUE;
        }
        //cell.userInteractionEnabled = YES;
        [downloader abortDownload];
        fileNode->downloader = nil;
        fileNode.progress = -1;
    } else if (downloader->bodyLength > 0) {
        /* download succeeded */
        if(downloader->offsetInFile == downloader->bodyLength) {
            if (cell) {
                cell->dlProgress.progress = 1;
                cell->dlProgressLabel.text = @"100%";
                [cell setSelected:NO];
            }
            fileNode->downloader = nil;
            fileNode.progress = 1.0;
            dlCount--;
        } else {
            /* downloading */
            fileNode.progress = (float) downloader->offsetInFile/downloader->bodyLength;
            //NSLog(@"Download %@ %.0f%%", fileNode.name, fileNode.progress * 100);
            if (cell) {
                cell->dlProgress.progress = fileNode.progress;
                cell->dlProgressLabel.text =
                        [NSString stringWithFormat:@"%.0f%%",fileNode.progress*100];
            }
        }
    }
    if(dlCount == 0) {
        [dlTimer invalidate];
        dlTimer = nil;
        // After all done, make Back button back!
        [self.navigationItem setHidesBackButton: NO];
    } else {
        // TODO:
    }
}
/*
 * buttons handler for single selection
 */
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *nsAction = [alertView buttonTitleAtIndex: buttonIndex];
    if ([nsAction isEqual: NSLocalizedString(@"Cancel", nil)]) {
        return;
    } else if ([nsAction isEqual: NSLocalizedString(@"Open", nil)]) {
        AITFileCell *cell = (AITFileCell*)[self.tableView cellForRowAtIndexPath:selectedIndexPath] ;
        AITFileNode *fileNode = [fileNodes objectAtIndex:selectedIndexPath.row] ;
        
        if(fileNode->downloader) {
            //Cancel download
            [fileNode->downloader->connection cancel];
            fileNode->downloader = nil;
            dlCount--;
            
            //Hide the progress bar
            cell->dlProgress.progress = 0;
            cell->dlProgressLabel.text = @"0%";
            cell->dlProgress.hidden = YES;
            cell->dlProgressLabel.hidden = YES;
        } else {    //Open the file
            NSURL *url = cell.filePath ;
            
            NSString *extension = [[url lastPathComponent] pathExtension];
            
            if ([extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame || [extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame) {
                // TODO:
            } else {
                MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
                [self presentMoviePlayerViewControllerAnimated:moviePlayer];
                
                [moviePlayer.moviePlayer play];
            }
        }
    } else if ([nsAction isEqual: NSLocalizedString(@"Save", nil)]) {
        AITFileCell *cell = (AITFileCell*)[self.tableView cellForRowAtIndexPath:selectedIndexPath] ;
        NSURL *url = cell.filePath ;
        
        NSString *directory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] ;
        
        AITFileNode *fileNode = [fileNodes objectAtIndex:selectedIndexPath.row] ;
        fileNode.selected = YES;
        fileNode.progress = 0.0;
        cell->dlProgress.progress = 0;
        cell->dlProgressLabel.text = [NSString stringWithFormat:@"%.0f%%",fileNode.progress*100];
        cell->dlProgress.hidden = FALSE;
        cell->dlProgressLabel.hidden = FALSE;
        
        if(dlTimer == nil)
            dlTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateUI:) userInfo:nil repeats:YES];
        
        //cell.userInteractionEnabled = NO;
        
        if(fileNode->downloader == nil) {
            // Count downloading items
            dlCount++;
            
            // Preoare for downloading
            fileNode->downloader = [[AITFileDownloader alloc] initWithUrl:url Path:[directory stringByAppendingPathComponent:cell.fileName.text]];
        }
    } else if ([nsAction isEqual: NSLocalizedString(@"Delete", nil)]) {
        AITFileNode *file;
        
        fileDelCount = 1;
        activeIndex  = (int)selectedIndexPath.row;
        file = [fileNodes objectAtIndex:activeIndex];
        /* Delete file */
        cmd_tag = CAMERA_FILE_DELETE;
        cameraCommand = [[AITCameraCommand alloc] initWithUrl:[AITCameraCommand commandDelFileUrl:[file.name stringByReplacingOccurrencesOfString: @"/" withString:@"$"]] Delegate:self] ;
        
    }
}

@end
