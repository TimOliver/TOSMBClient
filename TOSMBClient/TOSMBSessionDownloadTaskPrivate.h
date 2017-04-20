//
// TOSMBSessionDownloadTaskPrivate.h
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

#ifndef TOSMBSessionDownloadTaskPrivate_h
#define TOSMBSessionDownloadTaskPrivate_h

#import "TOSMBSessionDownloadTask.h"
#import "TOSMBSessionTaskPrivate.h"
#import "TOSMBSession.h"

@interface TOSMBSessionDownloadTask () <TOSMBSessionConcreteTask>

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
