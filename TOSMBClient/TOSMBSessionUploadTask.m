//
// TOSMBSessionUploadTake.m
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

#import "TOSMBSessionUploadTaskPrivate.h"
#import "TOSMBSessionPrivate.h"

@interface TOSMBSessionUploadTask ()

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSData *data;

@property (nonatomic, strong) TOSMBSessionFile *file;

@property (nonatomic, weak) id <TOSMBSessionUploadTaskDelegate> delegate;
@property (nonatomic, copy) void (^successHandler)();

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
                 successHandler:(id)successHandler
                    failHandler:(id)failHandler {
    if ((self = [self initWithSession:session path:path data:data])) {
        self.successHandler = successHandler;
        self.failHandler = failHandler;
    }
    
    return self;
}

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
    if (self.file == nil) {
        [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileNotFound)];
        self.cleanupBlock(treeID, fileID);
        return;
    }
    
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
    size_t uploadBufferLimit = MIN(bufferSize, 65471);
    
    ssize_t bytesWritten = 0;
    
    do {
        bytesWritten = smb_fwrite(self.smbSession, fileID, buffer, uploadBufferLimit);
        if (bytesWritten < 0) {
            [self fail];
            [self didFailWithError:errorForErrorCode(TOSMBSessionErrorCodeFileDownloadFailed)];
            break;
        }
    } while (bytesWritten > 0);
}


@end
