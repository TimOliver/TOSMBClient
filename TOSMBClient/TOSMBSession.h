//
// TOSMBSession.h
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

@class TOSMBSessionDownloadTask;
@class TOSMBSessionUploadTask;

@protocol TOSMBSessionDownloadTaskDelegate;

@interface TOSMBSession : NSObject

@property (nonatomic, copy) NSString *hostName;
@property (nonatomic, copy) NSString *ipAddress;

@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *password;

@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, readonly) NSInteger guest;

@property (nonatomic, readonly) NSArray <TOSMBSessionDownloadTask *> *downloadTasks;
@property (nonatomic, readonly) NSArray <TOSMBSessionUploadTask *> *uploadTasks;

@property (nonatomic, readonly) dispatch_queue_t serialQueue;
@property (nonatomic, readonly) NSOperationQueue *taskQueue;

/** Defines the number of concurrent task operations. Default:
 * NSOperationQueueDefaultMaxConcurrentOperationCount. */
@property (nonatomic) NSInteger maxTaskOperationCount;

/**
 Creates a new SMB object, but doesn't try to connect until the first request is made.
 For a successful connection, most devices require both the host name and the IP address.
 If only one of these two values is supplied, this library will attempt to resolve the other via
 NetBIOS, but whereever possible, you should endeavour to supply both values on instantiation.
 
 @param name The host name of the network device
 @param address The IP address of the network device
 @return A new instance of a session object
 
 */
- (instancetype)initWithHostName:(NSString *)name;
- (instancetype)initWithIPAddress:(NSString *)address;
- (instancetype)initWithHostName:(NSString *)name ipAddress:(NSString *)ipAddress;

/**
 Sets both the username and password for this login session. This should be set before any
 requests are made.
 
 @param userName The login user name
 @param password The login password
 */
- (void)setLoginCredentialsWithUserName:(NSString *)userName password:(NSString *)password;

/**
 Performs a synchronous request for a list of files from the network device for the given file path.
 
 @param path The file path to request. Supplying nil or "" will reuest the root list of share folders
 @param error A pointer to an NSError object that will be non-nil if an error occurs.
 @return An NSArray of TOSMBFile objects describing the contents of the file path
 */
- (NSArray *)requestContentsOfDirectoryAtFilePath:(NSString *)path error:(NSError **)error;

/**
 Performs an asynchronous request for a list of files from the network device for the given file path.
 
 @param path The file path to request. Supplying nil or "" will reuest the root list of share folders
 @param error A pointer to an NSError object that will be non-nil if an error occurs.
 @return An NSArray of TOSMBFile objects describing the contents of the file path
 */
- (void)requestContentsOfDirectoryAtFilePath:(NSString *)path success:(void (^)(NSArray *files))successHandler error:(void (^)(NSError *))errorHandler;

/**
 Cancels any and all file contents requests both actively occurring, and pending.
 */
- (void)cancelAllRequests;

/**
 Creates a download task object for asynchronously downloading a file to
 disk. Only files may be downloaded; folders will return an error.
 
 File downloads are done to the '/tmp' directory and are only copied to the destination when they successfully complete.
 If a file already exists in the destination directory with the same name, then this file's name will be changed before moving.
 
 If a partial file is found in the tmp directory, the download will attempt to resume it, or simply fail in the process.
 
 @param path The path on the SMB device for the file to download.
 @param destinationPath The destination path (Either just the directory, or even a new name) for this file.
 @param delegate A delegate object that will call update methods during the download.
 
 @return A download task object ready to be started, or nil upon failure.
 */
- (TOSMBSessionDownloadTask *)downloadTaskForFileAtPath:(NSString *)path destinationPath:(NSString *)destinationPath delegate:(id <TOSMBSessionDownloadTaskDelegate>)delegate;

/**
 Same as above, creates a download task object for asynchronously downloading a file to disk.
 
 @param path The path on the SMB device for the file to download.
 @param destinationPath The destination path (Either just the directory, or even a new name) for this file.
 @param progressHandler A block periodically called as the download progresses.
 @param completionHandler A block called once the download has completed.
 @param failHandler A block called if the download fails
 
 @return A download task object ready to be started, or nil upon failure.
 */
- (TOSMBSessionDownloadTask *)downloadTaskForFileAtPath:(NSString *)path
                                        destinationPath:(NSString *)destinationPath
                                        progressHandler:(void (^)(uint64_t totalBytesWritten, uint64_t totalBytesExpected))progressHandler
                                      completionHandler:(void (^)(NSString *filePath))completionHandler
                                            failHandler:(void (^)(NSError *error))failHandler;
/**
 Creates an upload task object for asynchronously uploading a file to disk.
 
 @param path The destination path (Either just the directory, or even a new name) for this file.
 @param data The path on the SMB device for the file to download.
 @param completionHandler A block called once the download has completed.
 @param failHandler A block called if the download fails
 
 @return An upload task object ready to be started, or nil upon failure.
 */
- (TOSMBSessionUploadTask *)uploadTaskForFileAtPath:(NSString *)path
                                               data:(NSData *)data
                                    progressHandler:(void (^)(uint64_t totalBytesWritten, uint64_t totalBytesExpected))progressHandler
                                  completionHandler:(void (^)(void))completionHandler
                                        failHandler:(void (^)(NSError *error))failHandler;

@end

@interface TOSMBSession (Deprecated)

@property (nonatomic) NSInteger maxDownloadOperationCount __deprecated_msg("Use maxTaskOperationCount instead");

@end
