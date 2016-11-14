//
//  TOSMBSessionDownloadTaskPrivate.h
//  TOSMBClient
//
//  Created by Nicholas Spencer on 11/13/16.
//  Copyright © 2016 TimOliver. All rights reserved.
//

#ifndef TOSMBSessionDownloadTaskPrivate_h
#define TOSMBSessionDownloadTaskPrivate_h

#import "TOSMBSessionDownloadTask.h"
#import "TOSMBSession.h"

@interface TOSMBSessionDownloadTask ()

- (instancetype)initWithSession:(TOSMBSession *)session
                       filePath:(NSString *)filePath
                destinationPath:(NSString *)destinationPath
                       delegate:(id<TOSMBSessionDownloadTaskDelegate>)delegate;

- (instancetype)initWithSession:(TOSMBSession *)session
                       filePath:(NSString *)filePath
                destinationPath:(NSString *)destinationPath
                progressHandler:(id)progressHandler
                 successHandler:(id)successHandler
                    failHandler:(id)failHandler;

@end

#endif /* TOSMBSessionDownloadTaskPrivate_h */
