//
// TOSMBSession.h
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

#import <Foundation/Foundation.h>
#import  "TOSMBConstants.h"

@interface TOSMBSession : NSObject

@property (nonatomic, copy) NSString *hostName;
@property (nonatomic, copy) NSString *ipAddress;

@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *password;

@property (nonatomic, readonly) TOSMBSessionState state;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, readonly) NSInteger guest;

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
- (void)requestContentsOfDirectoryAtFilePath:(NSString *)path success:(void (^)(NSArray *files))successHandler error:(void (^)(NSError *))error;



- (void)connect;

@end
