//
// TOSMBSessionUploadTake.m
// Copyright 2015-2017 Timothy Oliver
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

#import "TOSMBSessionUploadTaskPrivate.h"
#import "TOSMBSessionPrivate.h"

@interface TOSMBSessionUploadTask ()

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSData *data;

@property (nonatomic, strong) TOSMBSessionFile *file;

@property (nonatomic, weak) id <TOSMBSessionUploadTaskDelegate> delegate;
@property (nonatomic, copy) void (^successHandler)(void);

@end

@implementation TOSMBSessionUploadTask

@dynamic delegate;

- (instancetype)initWithSession:(TOSMBSession *)session
                           path:(NSString *)path
                           data:(NSData *)data {
    if ((self = [super initWithSession:session])) {
        self.path = path;
        self.data = data;
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                           path:(NSString *)path
                           data:(NSData *)data
                       delegate:(id<TOSMBSessionUploadTaskDelegate>)delegate {
    if ((self = [self initWithSession:session path:path data:data])) {
        self.delegate = delegate;
    }
    
    return self;
}

- (instancetype)initWithSession:(TOSMBSession *)session
                           path:(NSString *)path
                           data:(NSData *)data
                progressHandler:(id)progressHandler
                 successHandler:(id)successHandler
                    failHandler:(id)failHandler {
    if ((self = [self initWithSession:session path:path data:data])) {
        self.progressHandler = progressHandler;
        self.successHandler = successHandler;
        self.failHandler = failHandler;
    }
    
    return self;
}

#pragma mark - delegate helpers

- (void)didSendBytes:(NSInteger)recentCount bytesSent:(NSInteger)totalCount {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(uploadTaskForFileAtPath:data:progressHandler:completionHandler:failHandler:)]) {
            [weakSelf.delegate uploadTask:self didSendBytes:recentCount totalBytesSent:totalCount totalBytesExpectedToSend:weakSelf.data.length];
        }
        if (weakSelf.progressHandler) {
            weakSelf.progressHandler(totalCount, weakSelf.data.length);
        }
    });
}

- (void)didFinish {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.delegate respondsToSelector:@selector(uploadTaskDidFinishUploading:)]) {
            [weakSelf.delegate uploadTaskDidFinishUploading:self];
        }
        if (weakSelf.successHandler) {
            weakSelf.successHandler();
        }
    });
}

#pragma mark - task

- (void)performTaskWithOperation:(NSBlockOperation * _Nonnull __weak)weakOperation {
    if (weakOperation.isCancelled)
        return;
    
    smb_tid treeID = 0;
    smb_fd fileID = 0;
    
    //---------------------------------------------------------------------------------------
    //Connect to SMB device
    
    self.smbSession = smb_session_new();
    
    //First, check to make sure the server is there, and to acquire its attributes
    __block NSError *error = nil;
    dispatch_sync(self.session.serialQueue, ^{
        error = [self.session attemptConnectionWithSessionPointer:self.smbSession];
    });
    if (error) {
        [self didFailWithError:error];
        self.cleanupBlock(treeID, fileID);
        return;
    }
    
    if (weakOperation.isCancelled) {
        self.cleanupBlock(treeID, fileID);
        return;
    }
    
    //---------------------------------------------------------------------------------------
    //Connect to share
    
    //Next attach to the share we'll be using
    NSString *shareName = [self.session shareNameFromPath:self.path];
    const char *shareCString = [shareName cStringUsingEncoding:NSUTF8StringEncoding];
    smb_tree_connect(self.smbSession, shareCString, &treeID);
    if (!treeID) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeShareConnectionFailed)];
        self.cleanupBlock(treeID, fileID);
        return;
    }
    
    if (weakOperation.isCancelled) {
        self.cleanupBlock(treeID, fileID);
        return;
    }
    
    //---------------------------------------------------------------------------------------
    //Find the target file
    
    NSString *formattedPath = [self.session filePathExcludingSharePathFromPath:self.path];
    formattedPath = [NSString stringWithFormat:@"\\%@",formattedPath];
    formattedPath = [formattedPath stringByReplacingOccurrencesOfString:@"/" withString:@"\\\\"];
    
    //Get the file info we'll be working off
    self.file = [self requestFileForItemAtPath:formattedPath inTree:treeID];
    
    if (weakOperation.isCancelled) {
        self.cleanupBlock(treeID, fileID);
        return;
    }
    
    if (self.file.directory) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeDirectoryDownloaded)];
        self.cleanupBlock(treeID, fileID);
        return;
    }
    
    //---------------------------------------------------------------------------------------
    //Open the file handle
    
    smb_fopen(self.smbSession, treeID, [formattedPath cStringUsingEncoding:NSUTF8StringEncoding], SMB_MOD_RW, &fileID);
    if (!fileID) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileNotFound)];
        self.cleanupBlock(treeID, fileID);
        return;
    }
    
    if (weakOperation.isCancelled) {
        self.cleanupBlock(treeID, fileID);
        return;
    }
    
    NSUInteger bufferSize = self.data.length;
    void *buffer = malloc(bufferSize);
    [self.data getBytes:buffer length:bufferSize];
    // change the limit size to 63488(62KB)
    // (if still crash, change the limit size < 63488)
    size_t uploadBufferLimit = MIN(bufferSize, 63488);
    
    ssize_t bytesWritten = 0;
    ssize_t totalBytesWritten = 0;
    
    do {
        // change the the size of last part
        if (bufferSize - totalBytesWritten < uploadBufferLimit) {
            uploadBufferLimit = bufferSize - totalBytesWritten;
        }
        bytesWritten = smb_fwrite(self.smbSession, fileID, buffer+totalBytesWritten, uploadBufferLimit);
        if (bytesWritten < 0) {
            [self fail];
            [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileDownloadFailed)];
            break;
        }
        totalBytesWritten += bytesWritten;
        [self didSendBytes:bytesWritten bytesSent:totalBytesWritten];
    } while (totalBytesWritten < bufferSize);
    
    free(buffer);
    
    [self didFinish];
}


@end
