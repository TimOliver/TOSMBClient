//
//  TORootViewController.m
//  TOSMBClientExample
//
//  Created by Tim Oliver on 8/10/15.
//  Copyright © 2015 TimOliver. All rights reserved.
//

#import "TORootViewController.h"
#import "TORootTableViewController.h"

#import "TOSMBClient.h"

@interface TORootViewController () <TOSMBSessionDownloadTaskDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) UIDocumentInteractionController *docController;

@property (nonatomic, strong) TOSMBSession *downloadSession;
@property (nonatomic, strong) TOSMBSessionDownloadTask *downloadTask;

@property (nonatomic, strong) NSString *filePath;

@end

@implementation TORootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.noticeLabel.hidden = NO;
    self.downloadView.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addButtonTapped:(id)sender
{
    TORootTableViewController *tableController = [[TORootTableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:tableController];
    controller.modalPresentationStyle = UIModalPresentationFormSheet;
    tableController.rootController = self;
    [self presentViewController:controller animated:YES completion:nil];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(modalCancelButtonTapped:)];
    tableController.navigationItem.rightBarButtonItem = item;
}

- (void)downloadFileFromSession:(TOSMBSession *)session atFilePath:(NSString *)filePath
{
    self.noticeLabel.hidden = YES;
    self.downloadView.hidden = NO;
    
    self.fileNameLabel.text = [filePath lastPathComponent];
    self.progressView.progress = 0.0f;
    
    self.cancelButton.hidden = NO;
    self.suspendButton.hidden = NO;
    self.progressView.alpha = 1.0f;
    
    self.downloadSession = session;
    self.downloadTask = [session downloadTaskForFileAtPath:filePath destinationPath:nil delegate:self];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self.downloadTask resume];
    }];
}

- (void)downloadTask:(TOSMBSessionDownloadTask *)downloadTask didWriteBytes:(uint64_t)bytesWritten totalBytesReceived:(uint64_t)totalBytesReceived totalBytesExpectedToReceive:(int64_t)totalBytesToReceive
{
    self.progressView.progress = (float)totalBytesReceived / (float)totalBytesToReceive;
}

- (void)downloadTask:(TOSMBSessionDownloadTask *)downloadTask didFinishDownloadingToPath:(NSString *)destinationPath
{
    self.cancelButton.hidden = YES;
    self.suspendButton.hidden = YES;
    self.progressView.alpha = 0.5f;
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    self.filePath = destinationPath;
}

- (IBAction)cancelButtonTapped:(id)sender
{
    if (self.downloadTask.state != TOSMBSessionDownloadTaskStateCancelled) {
        [self.downloadTask cancel];
        self.cancelButton.enabled = NO;
        self.progressView.progress = 0.0f;
        [self.suspendButton setTitle:@"Resume" forState:UIControlStateNormal];
    }
}

- (IBAction)actionButtonTapped:(id)sender
{
    self.docController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:self.filePath]];
    self.docController.delegate = self;
    [self.docController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    self.docController = nil;
}

- (IBAction)suspendButtonTapped:(id)sender
{
    if (self.downloadTask.state == TOSMBSessionDownloadTaskStateRunning) {
        [self.downloadTask suspend];
        [self.suspendButton setTitle:@"Resume" forState:UIControlStateNormal];
    }
    else {
        [self.downloadTask resume];
        [self.suspendButton setTitle:@"Suspend" forState:UIControlStateNormal];
    }
}

- (void)modalCancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
