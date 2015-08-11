//
// TOSMBDownloadTask.m
// Copyright 2015 Timothy Oliver
//
// This file is dual-licensed under both the MIT License, and the LGPL v2.1 License.
//
// -------------------------------------------------------------------------------
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
// -------------------------------------------------------------------------------

#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>

#import "TOSMBSessionDownloadTask.h"
#import "TOSMBClient.h"
#import "smb_session.h"
#import "smb_share.h"
#import "smb_file.h"
#import "smb_defs.h"

@interface TOSMBSession ()

- (NSError *)attemptConnectionWithSessionPointer:(smb_session *)session;
- (NSString *)shareNameFromPath:(NSString *)path;
- (NSString *)filePathExcludingSharePathFromPath:(NSString *)path;
- (void)resumeDownloadTask:(TOSMBSessionDownloadTask *)task;

@end

@interface TOSMBSessionDownloadTask ()

@property (nonatomic, assign, readwrite) TOSMBSessionDownloadTaskState state;

@property (nonatomic, strong, readwrite) NSString *sourceFilePath;
@property (nonatomic, strong, readwrite) NSString *destinationFilePath;
@property (nonatomic, strong) NSString *tempFilePath;

@property (nonatomic, weak, readwrite) TOSMBSession *session;
@property (nonatomic, strong) TOSMBSessionFile *file;
@property (nonatomic, assign) smb_session *downloadSession;
@property (nonatomic, strong) NSBlockOperation *downloadOperation;

@property (assign,readwrite) int64_t countOfBytesReceived;
@property (assign,readwrite) int64_t countOfBytesExpectedToReceive;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

/** Feedback handlers */
@property (nonatomic, weak) id<TOSMBSessionDownloadTaskDelegate> delegate;

@property (nonatomic, copy) void (^progressHandler)(uint64_t totalBytesWritten, uint64_t totalBytesExpected);
@property (nonatomic, copy) void (^successHandler)(NSString *filePath);
@property (nonatomic, copy) void (^failHandler)(NSError *error);

/* Download methods */
- (void)setupDownloadOperation;
- (void)performDownloadWithOperation:(__weak NSBlockOperation *)weakOperation;
- (TOSMBSessionFile *)requestFileForItemAtPath:(NSString *)filePath inTree:(smb_tid)treeID;

/* File Path Methods */
- (NSString *)hashForFilePath;
- (NSString *)filePathForTemporaryDestination;

/* Feedback events sent to either the delegate or callback blocks */
- (void)didSucceedWithFilePath:(NSString *)filePath;
- (void)didFailWithError:(NSError *)error;
- (void)didUpdateWriteBytes:(uint64_t)bytesWritten totalBytesWritten:(uint64_t)totalBytesWritten totalBytesExpected:(uint64_t)totalBytesExpected;

@end

@implementation TOSMBSessionDownloadTask

- (instancetype)init
{
    //This class cannot be instantiated on its own.
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithSession:(TOSMBSession *)session filePath:(NSString *)filePath destinationPath:(NSString *)destinationPath delegate:(id<TOSMBSessionDownloadTaskDelegate>)delegate
{
    if (self = [super init]) {
        _downloadSession = smb_session_new();
        
        _session = session;
        _sourceFilePath = filePath;
        _destinationFilePath = destinationPath;
        _delegate = delegate;
        
        _tempFilePath = [self filePathForTemporaryDestination];
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session filePath:(NSString *)filePath destinationPath:(NSString *)destinationPath progressHandler:(id)progressHandler successHandler:(id)successHandler failHandler:(id)failHandler
{
    if (self = [super init]) {
        _downloadSession = smb_session_new();
        
        _session = session;
        _sourceFilePath = filePath;
        _destinationFilePath = destinationPath;
        
        _progressHandler = progressHandler;
        _successHandler = successHandler;
        _failHandler = failHandler;
        
        _tempFilePath = [self filePathForTemporaryDestination];
    }
    
    return self;
}

- (void)dealloc
{
    smb_session_destroy(self.downloadSession);
}
#pragma mark - Temporary Destination Methods -
- (NSString *)filePathForTemporaryDestination
{
    NSString *fileName = [[self hashForFilePath] stringByAppendingPathExtension:@"smbclient.data"];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

- (NSString *)hashForFilePath
{
    NSString *filePath = self.sourceFilePath.lowercaseString;
    
    NSData *data = [filePath dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return [NSString stringWithString:output];
}

#pragma mark - Public Control Methods -
- (void)resume
{
    if (self.state == TOSMBSessionDownloadTaskStateRunning)
        return;
    
    [self setupDownloadOperation];
    [self.session resumeDownloadTask:self];
}

- (void)suspend
{
    if (self.state != TOSMBSessionDownloadTaskStateRunning)
        return;
        
}

- (void)cancel
{
    
}

#pragma mark - Feedback Methods -
- (BOOL)resumeDataExists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:self.tempFilePath];
}

- (void)didSucceedWithFilePath:(NSString *)filePath
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:didFinishDownloadingToPath:)])
            [self.delegate downloadTask:self didFinishDownloadingToPath:filePath];
        
        if (self.successHandler)
            self.successHandler(filePath);
    }];
}

- (void)didFailWithError:(NSError *)error
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:didCompleteWithError:)])
            [self.delegate downloadTask:self didCompleteWithError:error];
        
        if (self.failHandler)
            self.failHandler(error);
    }];
}

- (void)didUpdateWriteBytes:(uint64_t)bytesWritten totalBytesWritten:(uint64_t)totalBytesWritten totalBytesExpected:(uint64_t)totalBytesExpected
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:didWriteBytes:totalBytesReceived:totalBytesExpectedToReceive:)])
            [self.delegate downloadTask:self didWriteBytes:bytesWritten totalBytesReceived:self.countOfBytesReceived totalBytesExpectedToReceive:self.countOfBytesExpectedToReceive];
        
        if (self.progressHandler)
            self.progressHandler(self.countOfBytesReceived, self.countOfBytesExpectedToReceive);
    }];
}

#pragma mark - Downloading -
- (NSBlockOperation *)downloadOperation
{
    return _downloadOperation;
}

- (TOSMBSessionFile *)requestFileForItemAtPath:(NSString *)filePath inTree:(smb_tid)treeID
{
    const char *fileCString = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
    smb_stat fileStat = smb_fstat(self.downloadSession, treeID, fileCString);
    if (!fileStat)
        return nil;
    
    TOSMBSessionFile *file = [[TOSMBSessionFile alloc] initWithStat:fileStat session:nil parentDirectoryFilePath:filePath];
    
    smb_stat_destroy(fileStat);
    
    return file;
}

- (void)setupDownloadOperation
{
    if (self.downloadOperation)
        return;
    
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    
    __weak typeof (self) weakSelf = self;
    __weak NSBlockOperation *weakOperation = operation;
    
    id executionBlock = ^{
        [weakSelf performDownloadWithOperation:weakOperation];
    };
    [operation addExecutionBlock:executionBlock];
    
    self.downloadOperation = operation;
}

- (void)performDownloadWithOperation:(__weak NSBlockOperation *)weakOperation
{
    if (weakOperation.isCancelled)
        return;
    
    //---------------------------------------------------------------------------------------
    //Connect to SMB device
    
    //First, check to make sure the file is there, and to acquire its attributes
    NSError *error = [self.session attemptConnectionWithSessionPointer:self.downloadSession];
    if (error) {
        [self didFailWithError:error];
        return;
    }
    
    if (weakOperation.isCancelled)
        return;
    
    //---------------------------------------------------------------------------------------
    //Connect to share
    
    //Next attach to the share we'll be using
    NSString *shareName = [self.session shareNameFromPath:self.sourceFilePath];
    const char *shareCString = [shareName cStringUsingEncoding:NSUTF8StringEncoding];
    smb_tid treeID = smb_tree_connect(self.downloadSession, shareCString);
    if (!treeID) {
        NSError *error = [NSError errorWithDomain:@"TOSMBClient"
                                             code:1006
                                         userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unable to find share containing file to download.", @"")}];
        
        [self didFailWithError:error];
        return;
    }
    
    if (weakOperation.isCancelled) {
        return;
    }
    
    //---------------------------------------------------------------------------------------
    //Find the target file
    
    NSString *pathExcludingShare = [self.session filePathExcludingSharePathFromPath:self.sourceFilePath];
    
    //Get the file info we'll be working off
    self.file = [self requestFileForItemAtPath:pathExcludingShare inTree:treeID];
    if (self.file == nil) {
        NSError *error = [NSError errorWithDomain:@"TOSMBClient"
                                             code:1007
                                         userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unable to find file to download.", @"")}];
        
        [self didFailWithError:error];
        smb_tree_disconnect(self.downloadSession, treeID);
        return;
    }
    
    if (weakOperation.isCancelled) {
        smb_tree_disconnect(self.downloadSession, treeID);
        return;
    }
    
    if (self.file.directory) {
        NSError *error = [NSError errorWithDomain:@"TOSMBClient"
                                             code:1008
                                         userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Directories cannot be downloaded.", @"")}];
        
        [self didFailWithError:error];
        smb_tree_disconnect(self.downloadSession, treeID);
        return;
    }
    
    self.countOfBytesExpectedToReceive = self.file.fileSize;
    
    //---------------------------------------------------------------------------------------
    //Start downloading
    
    smb_fd fileID = smb_fopen(self.downloadSession, treeID, [pathExcludingShare cStringUsingEncoding:NSUTF8StringEncoding], SMB_MOD_RO);
    if (!fileID) {
        NSError *error = [NSError errorWithDomain:@"TOSMBClient"
                                             code:1007
                                         userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unable to find file to download.", @"")}];
        
        [self didFailWithError:error];
        smb_tree_disconnect(self.downloadSession, treeID);
        return;
    }
    
    if (weakOperation.isCancelled) {
        smb_fclose(self.downloadSession, fileID);
        smb_tree_disconnect(self.downloadSession, treeID);
        return;
    }
    
    
    //---------------------------------------------------------------------------------------
    //Handle the downloading
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[self.tempFilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    
    //Check if there is resume data, or clear it if it's invalid
    BOOL resumeDataExists = self.resumeDataExists;
    if (resumeDataExists) {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.tempFilePath error:nil];
        NSDate *modificationTime = [attributes fileModificationDate];
        if ([modificationTime isEqual:self.file.modificationTime] == NO) {
            [[NSFileManager defaultManager] removeItemAtPath:self.tempFilePath error:nil];
            resumeDataExists = NO;
        }
    }
    
    //Create a new blank file to write to
    if (resumeDataExists == NO)
        [[NSFileManager defaultManager] createFileAtPath:self.tempFilePath contents:nil attributes:nil];
    
    //Open a handle to the file and skip ahead if we're resuming
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.tempFilePath];
    unsigned long seekOffset = [fileHandle seekToEndOfFile];
    self.countOfBytesReceived = seekOffset;
    
    //Create a background handle so the download will continue even if the app is suspended
    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{ [self suspend]; }];
    
    if (seekOffset > 0)
        smb_fseek(self.downloadSession, fileID, seekOffset, SMB_SEEK_SET);
    
    uint64_t bytesRead = 0;
    NSInteger bufferSize = 65535;
    char *buffer = malloc(bufferSize);
    
    do {
        bytesRead = smb_fread(self.downloadSession, fileID, buffer, bufferSize);
        [fileHandle writeData:[NSData dataWithBytes:buffer length:bufferSize]];
        
        if (weakOperation.isCancelled)
            break;
        
        self.countOfBytesReceived += bytesRead;
        
        [self didUpdateWriteBytes:bytesRead totalBytesWritten:self.countOfBytesReceived totalBytesExpected:self.countOfBytesExpectedToReceive];
    } while (bytesRead > 0);
    
    [[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate:self.file.modificationTime} ofItemAtPath:self.tempFilePath error:nil];
    
    free(buffer);
    [fileHandle closeFile];
    smb_fclose(self.downloadSession, fileID);
    smb_tree_disconnect(self.downloadSession, treeID);
    
    if (weakOperation.isCancelled) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        return;
    }
    
    //---------------------------------------------------------------------------------------
    //Move the finished file to its destination
    
    //Finally, copy the file to its destination
    NSString *destination = self.destinationFilePath;
    
    //Check to ensure the destination isn't referring to a file name
    NSString *fileName = [destination lastPathComponent];
    BOOL isFile = ([fileName rangeOfString:@"."].location != NSNotFound && [fileName characterAtIndex:0] != '.');
    
    NSString *folderPath = nil;
    if (isFile) {
        folderPath = [destination stringByDeletingLastPathComponent];
    }
    else {
        fileName = [self.sourceFilePath lastPathComponent];
        folderPath = destination;
    }
    
    NSString *finalDestination = [folderPath stringByAppendingPathComponent:fileName];
    [[NSFileManager defaultManager] moveItemAtPath:self.tempFilePath toPath:finalDestination error:nil];
    
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
}

@end
