//
//  AppDelegate.m
//  TOSMBClientExample
//
//  Created by Tim Oliver on 7/27/15.
//  Copyright (c) 2015 TimOliver. All rights reserved.
//

#import "TOAppDelegate.h"
#import "TOSMBClient.h"

@interface TOAppDelegate () <TOSMBSessionDownloadTaskDelegate>

@property (nonatomic, strong) TOSMBSession *session;

- (NSString *)documentsDirectory;

@end

@implementation TOAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.session = [[TOSMBSession alloc] initWithHostName:@"TITANNAS" ipAddress:@"192.168.1.3"];
    TOSMBSessionDownloadTask *download = [self.session downloadTaskForFileAtPath:@"/Books/Manga/ラブひな/ラブひな - 1巻.pdf" destinationPath:[self documentsDirectory] delegate:self];
    [download resume];
    
    NSLog(@"Downloading %@", download.sourceFilePath.lastPathComponent);
    
    return YES;
}

- (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

#pragma mark - Delegate -
- (void)downloadTask:(TOSMBSessionDownloadTask *)downloadTask didWriteBytes:(uint64_t)bytesWritten totalBytesReceived:(uint64_t)totalBytesReceived totalBytesExpectedToReceive:(int64_t)totalBytesToReceive
{
    NSLog(@"%f", (CGFloat)totalBytesReceived / (CGFloat)totalBytesToReceive);
}

- (void)downloadTask:(TOSMBSessionDownloadTask *)downloadTask didFinishDownloadingToPath:(NSString *)destinationPath
{
    NSLog(@"Done!!");
}
                                          
@end
