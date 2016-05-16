//
// TOSMBDownloadTask.m
// Copyright 2015-2016 Timothy Oliver
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

// -------------------------------------------------------------------------
// Private methods in TOSMBSession shared here

@interface TOSMBSession ()

@property (readonly) NSOperationQueue *downloadsQueue;

- (NSError *)attemptConnectionWithSessionPointer:(smb_session *)session;
- (NSString *)shareNameFromPath:(NSString *)path;
- (NSString *)filePathExcludingSharePathFromPath:(NSString *)path;
- (void)resumeDownloadTask:(TOSMBSessionDownloadTask *)task;


@end

// -------------------------------------------------------------------------

@interface TOSMBSessionDownloadTask ()

@property (assign, readwrite) TOSMBSessionDownloadTaskState state;

@property (nonatomic, strong, readwrite) NSString *sourceFilePath;
@property (nonatomic, strong, readwrite) NSString *destinationFilePath;
@property (nonatomic, strong) NSString *tempFilePath;

@property (nonatomic, weak, readwrite) TOSMBSession *session;
@property (nonatomic, strong) TOSMBSessionFile *file;
@property (assign) smb_session *downloadSession;
@property (nonatomic, strong) NSBlockOperation *downloadOperation;

@property (assign, readwrite) int64_t countOfBytesReceived;
@property (assign, readwrite) int64_t countOfBytesExpectedToReceive;

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
- (NSString *)finalFilePathForDownloadedFile;
- (NSString *)documentsDirectory;

/* Feedback events sent to either the delegate or callback blocks */
- (void)didSucceedWithFilePath:(NSString *)filePath;
- (void)didFailWithError:(NSError *)error;
- (void)didUpdateWriteBytes:(uint64_t)bytesWritten totalBytesWritten:(uint64_t)totalBytesWritten totalBytesExpected:(uint64_t)totalBytesExpected;
- (void)didResumeAtOffset:(uint64_t)bytesWritten totalBytesExpected:(uint64_t)totalBytesExpected;

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
        _session = session;
        _sourceFilePath = filePath;
        _destinationFilePath = destinationPath.length ? destinationPath : [self documentsDirectory];
        _delegate = delegate;
        
        _tempFilePath = [self filePathForTemporaryDestination];
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session filePath:(NSString *)filePath destinationPath:(NSString *)destinationPath progressHandler:(id)progressHandler successHandler:(id)successHandler failHandler:(id)failHandler
{
    if (self = [super init]) {
        _session = session;
        _sourceFilePath = filePath;
        _destinationFilePath = destinationPath.length ? destinationPath : [self documentsDirectory];
        
        _progressHandler = progressHandler;
        _successHandler = successHandler;
        _failHandler = failHandler;
        
        _tempFilePath = [self filePathForTemporaryDestination];
    }
    
    return self;
}

- (void)dealloc
{
    // This is called after TOSMBSession dealloc is called, where the smb_session object is released.
    // As so, probably this part is not required at all, so I'm commenting it out. 
    // Anyway, even if my assumptions are wrong, we should firstly check if the whole session still exists.

//    if (self.downloadSession && self.session) {
//        smb_session_destroy(self.downloadSession);
//    }
}
#pragma mark - Temporary Destination Methods -
- (NSString *)filePathForTemporaryDestination
{
    NSString *fileName = [[self hashForFilePath] stringByAppendingPathExtension:@"smb.data"];
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

- (NSString *)finalFilePathForDownloadedFile
{
    NSString *path = self.destinationFilePath;
    
    //Check to ensure the destination isn't referring to a file name
    NSString *fileName = [path lastPathComponent];
    BOOL isFile = ([fileName rangeOfString:@"."].location != NSNotFound && [fileName characterAtIndex:0] != '.');
    
    NSString *folderPath = nil;
    if (isFile) {
        folderPath = [path stringByDeletingLastPathComponent];
    }
    else {
        fileName = [self.sourceFilePath lastPathComponent];
        folderPath = path;
    }
    
    path = [folderPath stringByAppendingPathComponent:fileName];
    
    //If a file with that name already exists in the destination directory, append a number on the end of the file name
    NSString *newFilePath = path;
    NSString *newFileName = fileName;
    NSInteger index = 1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:newFilePath]) {
        newFileName = [NSString stringWithFormat:@"%@-%ld.%@", [fileName stringByDeletingPathExtension], (long)index++, [fileName pathExtension]];
        newFilePath = [folderPath stringByAppendingPathComponent:newFileName];
    }
    
    return newFilePath;
}

- (NSString *)documentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

#pragma mark - Public Control Methods -
- (void)resume
{
    if (self.state == TOSMBSessionDownloadTaskStateRunning)
        return;
    
    [self setupDownloadOperation];
    [self.session.downloadsQueue addOperation:self.downloadOperation];
    self.state = TOSMBSessionDownloadTaskStateRunning;
}

- (void)suspend
{
    if (self.state != TOSMBSessionDownloadTaskStateRunning)
        return;
    
    [self.downloadOperation cancel];
    self.state = TOSMBSessionDownloadTaskStateSuspended;
    self.downloadOperation = nil;
}

- (void)cancel
{
    if (self.state != TOSMBSessionDownloadTaskStateRunning)
        return;
    
    id deleteBlock = ^{
        [[NSFileManager defaultManager] removeItemAtPath:self.tempFilePath error:nil];
    };
    
    NSBlockOperation *deleteOperation = [[NSBlockOperation alloc] init];
    [deleteOperation addExecutionBlock:deleteBlock];
    [deleteOperation addDependency:self.downloadOperation];
    [self.session.downloadsQueue addOperation:deleteOperation];
    
    [self.downloadOperation cancel];
    self.state = TOSMBSessionDownloadTaskStateCancelled;
    
    self.downloadOperation = nil;
}

#pragma mark - Feedback Methods -
- (BOOL)canBeResumed
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.tempFilePath] == NO)
        return NO;
    
    NSDate *modificationTime = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.tempFilePath error:nil] fileModificationDate];
    if ([modificationTime isEqual:self.file.modificationTime] == NO) {
        return NO;
    }
    
    return YES;
}

- (void)didSucceedWithFilePath:(NSString *)filePath
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:didFinishDownloadingToPath:)])
            [self.delegate downloadTask:self didFinishDownloadingToPath:filePath];
        
        if (self.successHandler)
            self.successHandler(filePath);
    });
}

- (void)didFailWithError:(NSError *)error
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:didCompleteWithError:)])
            [self.delegate downloadTask:self didCompleteWithError:error];
        
        if (self.failHandler)
            self.failHandler(error);
    });
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

- (void)didResumeAtOffset:(uint64_t)bytesWritten totalBytesExpected:(uint64_t)totalBytesExpected
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:didResumeAtOffset:totalBytesExpectedToReceive:)])
            [self.delegate downloadTask:self didResumeAtOffset:bytesWritten totalBytesExpectedToReceive:totalBytesExpected];
    }];
}

#pragma mark - Downloading -
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
    operation.completionBlock = ^{
        weakSelf.downloadOperation = nil;
    };
    
    self.downloadOperation = operation;
}

- (void)performDownloadWithOperation:(__weak NSBlockOperation *)weakOperation
{
    if (weakOperation.isCancelled)
        return;
    
    smb_tid treeID = -1;
    smb_fd fileID = 0;
    
    //---------------------------------------------------------------------------------------
    //Set up a cleanup block that'll release any handles before cancellation
    void (^cleanup)(void) = ^{
        
        //Release the background task handler, making the app eligible to be suspended now
        if (self.backgroundTaskIdentifier)
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        
        if (self.downloadSession && treeID)
            smb_tree_disconnect(self.downloadSession, treeID);
        
        if (self.downloadSession && fileID)
            smb_fclose(self.downloadSession, fileID);
        
        if (self.downloadSession) {
            smb_session_destroy(self.downloadSession);
            self.downloadSession = nil;
        }
    };
    
    //---------------------------------------------------------------------------------------
    //Connect to SMB device
    
    self.downloadSession = smb_session_new();
    
    //First, check to make sure the file is there, and to acquire its attributes
    NSError *error = [self.session attemptConnectionWithSessionPointer:self.downloadSession];
    if (error) {
        [self didFailWithError:error];
        cleanup();
        return;
    }
    
    if (weakOperation.isCancelled) {
        cleanup();
        return;
    }
    
    //---------------------------------------------------------------------------------------
    //Connect to share
    
    //Next attach to the share we'll be using
    NSString *shareName = [self.session shareNameFromPath:self.sourceFilePath];
    const char *shareCString = [shareName cStringUsingEncoding:NSUTF8StringEncoding];
    smb_tree_connect(self.downloadSession, shareCString, &treeID);
    if (!treeID) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeShareConnectionFailed)];
        cleanup();
        return;
    }
    
    if (weakOperation.isCancelled) {
        cleanup();
        return;
    }
    
    //---------------------------------------------------------------------------------------
    //Find the target file
    
    NSString *formattedPath = [self.session filePathExcludingSharePathFromPath:self.sourceFilePath];
    formattedPath = [NSString stringWithFormat:@"\\%@",formattedPath];
    formattedPath = [formattedPath stringByReplacingOccurrencesOfString:@"/" withString:@"\\\\"];
    
    //Get the file info we'll be working off
    self.file = [self requestFileForItemAtPath:formattedPath inTree:treeID];
    if (self.file == nil) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileNotFound)];
        cleanup();
        return;
    }
    
    if (weakOperation.isCancelled) {
        cleanup();
        return;
    }
    
    if (self.file.directory) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeDirectoryDownloaded)];
        cleanup();
        return;
    }
    
    self.countOfBytesExpectedToReceive = self.file.fileSize;
    
    //---------------------------------------------------------------------------------------
    //Open the file handle
    
    smb_fopen(self.downloadSession, treeID, [formattedPath cStringUsingEncoding:NSUTF8StringEncoding], SMB_MOD_RO, &fileID);
    if (!fileID) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileNotFound)];
        cleanup();
        return;
    }
    
    if (weakOperation.isCancelled) {
        cleanup();
        return;
    }
    
    
    //---------------------------------------------------------------------------------------
    //Start downloading
    
    //Create the directories to the download destination
    [[NSFileManager defaultManager] createDirectoryAtPath:[self.tempFilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    
    //Create a new blank file to write to
    if (self.canBeResumed == NO)
        [[NSFileManager defaultManager] createFileAtPath:self.tempFilePath contents:nil attributes:nil];
    
    //Open a handle to the file and skip ahead if we're resuming
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.tempFilePath];
    unsigned long long seekOffset = (ssize_t)[fileHandle seekToEndOfFile];
    self.countOfBytesReceived = seekOffset;
    
    //Create a background handle so the download will continue even if the app is suspended
    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{ [self suspend]; }];
    
    if (seekOffset > 0) {
        smb_fseek(self.downloadSession, fileID, (ssize_t)seekOffset, SMB_SEEK_SET);
        [self didResumeAtOffset:seekOffset totalBytesExpected:self.countOfBytesExpectedToReceive];
    }
    
    //Perform the file download
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
    
    //Set the modification date to match the one on the SMB device so we can compare the two at a later date
    [[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate:self.file.modificationTime} ofItemAtPath:self.tempFilePath error:nil];
    
    free(buffer);
    [fileHandle closeFile];
    
    if (weakOperation.isCancelled) {
        cleanup();
        return;
    }
    
    //---------------------------------------------------------------------------------------
    //Move the finished file to its destination
    
    //Workout the destination of the file and move it
    NSString *finalDestinationPath = [self finalFilePathForDownloadedFile];
    [[NSFileManager defaultManager] moveItemAtPath:self.tempFilePath toPath:finalDestinationPath error:nil];
    
    self.state =TOSMBSessionDownloadTaskStateCompleted;
    
    //Alert the delegate that we finished, so they may perform any additional cleanup operations
    [self didSucceedWithFilePath:finalDestinationPath];
    
    //Perform a final cleanup of all handles and references
    cleanup();
}

@end
