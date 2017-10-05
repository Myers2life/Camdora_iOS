//
//  AITPopoverViewController.m
//  WiFiCameraViewer
//
//  Created by yang on 2017/9/20.
//  Copyright © 2017年 a-i-t. All rights reserved.
//

#import "AITPopoverViewController.h"

@interface AITPopoverViewController ()

@end

@implementation AITPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.bounds = CGRectMake(0, 0, 400, 400);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)clickDCIM:(id)sender {
    if ([_delegate respondsToSelector:@selector(clickItem:)]) {
        [_delegate clickItem:ATIDCIM];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(IBAction)clickPhoto:(id)sender {
    if ([_delegate respondsToSelector:@selector(clickItem:)]) {
        [_delegate clickItem:ATIPhoto];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
