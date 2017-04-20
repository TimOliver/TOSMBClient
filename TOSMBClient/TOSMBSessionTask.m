//
// TOSMBSessionTask.h
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

#import "TOSMBSessionTaskPrivate.h"

@implementation TOSMBSessionTask

- (instancetype)initWithSession:(TOSMBSession *)session {
    if((self = [super init])) {
        self.session = session;
    }
    
    return self;
}

#pragma mark - Properties

- (NSBlockOperation *)taskOperation {
    if (!_taskOperation) {
        _taskOperation = [[NSBlockOperation alloc] init];
        
        __weak typeof(self) weakSelf = self;
        __weak NSBlockOperation *weakOperation = _taskOperation;
        [_taskOperation addExecutionBlock:^{
            [weakSelf performTaskWithOperation:weakOperation];
        }];
        
        _taskOperation.completionBlock = ^{
            weakSelf.taskOperation = nil;
        };
    }
    return _taskOperation;
}

- (void (^)(smb_tid treeID, smb_fd fileID))cleanupBlock {
    return ^(smb_tid treeID, smb_fd fileID) {
        
        //Release the background task handler, making the app eligible to be suspended now
        if (self.backgroundTaskIdentifier) {
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
            self.backgroundTaskIdentifier = 0;
        }
        
        if (self.taskOperation && treeID) {
            smb_tree_disconnect(self.smbSession, treeID);
        }
        
        if (self.smbSession && fileID) {
            smb_fclose(self.smbSession, fileID);
        }

        
        if (self.smbSession) {
            smb_session_destroy(self.smbSession);
            self.smbSession = nil;
        }
    };
}

#pragma mark - Task Methods

- (TOSMBSessionFile *)requestFileForItemAtPath:(NSString *)filePath inTree:(smb_tid)treeID
{
    const char *fileCString = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
    smb_stat fileStat = smb_fstat(self.smbSession, treeID, fileCString);
    if (!fileStat)
        return nil;
    
    TOSMBSessionFile *file = [[TOSMBSessionFile alloc] initWithStat:fileStat session:nil parentDirectoryFilePath:filePath];
    
    smb_stat_destroy(fileStat);
    
    return file;
}

- (void)performTaskWithOperation:(__weak NSBlockOperation *)operation {
    return;
}

#pragma mark - Public Control Methods

- (void)resume
{
    if (self.state == TOSMBSessionTaskStateRunning)
        return;
    
    [self.session.taskQueue addOperation:self.taskOperation];
    self.state = TOSMBSessionTaskStateRunning;
}

- (void)suspend
{
    if (self.state != TOSMBSessionTaskStateRunning)
        return;
    
    [self.taskOperation cancel];
    self.state = TOSMBSessionTaskStateSuspended;
    self.taskOperation = nil;
}

- (void)cancel
{
    if (self.state != TOSMBSessionTaskStateRunning)
        return;
    
    [self.taskOperation cancel];
    self.state = TOSMBSessionTaskStateCancelled;
    
    self.taskOperation = nil;
}

#pragma mark - Private Control Methods

- (void)fail
{
    if (self.state != TOSMBSessionTaskStateRunning)
        return;
    
    [self cancel];
    
    self.state = TOSMBSessionTaskStateFailed;
}

#pragma mark - Feedback Methods -

- (void)didFailWithError:(NSError *)error
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(task:didCompleteWithError:)])
            [self.delegate task:self didCompleteWithError:error];
        if (self.failHandler)
            self.failHandler(error);
    });
}

@end
