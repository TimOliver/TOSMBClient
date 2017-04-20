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

#import <Foundation/Foundation.h>

#import "TOSMBConstants.h"

@class TOSMBSessionTask;
@class TOSMBSession;

@protocol TOSMBSessionTaskDelegate <NSObject>
@optional
/**
 Delegate event that is called when the file did not successfully complete.
 
 @param downloadTask The download task object calling this delegate method.
 @param error The error describing why the task failed.
 */
- (void)task:(TOSMBSessionTask *)task didCompleteWithError:(NSError *)error;

@end

@interface TOSMBSessionTask : NSObject

/** The parent session that is managing this download task. (Retained by this class) */
@property (readonly, weak) TOSMBSession *session;

/** Returns if download data from a suspended task exists */
@property (readonly) BOOL canBeResumed;

/** The state of the task. */
@property (readonly) TOSMBSessionTaskState state;

/**
 Resumes an existing task, or starts a new one otherwise.
 
 Downloads are resumed if there is already data for this file on disk,
 and the modification date of that file matches the one on the network device.
 */
- (void)resume;

/**
 Suspends a task and halts network activity.
 */
- (void)suspend;

/**
 Cancels a task, and deletes all related transient data on disk.
 */
- (void)cancel;

@end
