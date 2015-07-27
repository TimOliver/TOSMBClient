//
// TONetBIOSNameService.h
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
#import "TOSMBConstants.h"

@class TONetBIOSNameServiceEntry;
typedef void (^TONetBIOSNameServiceDiscoveryEvent)(TONetBIOSNameServiceEntry *entry);

@interface TONetBIOSNameService : NSObject

@property (nonatomic, readonly) BOOL discovering;

// -------------------------------------------------------------------------------

- (NSString *)resolveIPAddressWithName:(NSString *)name type:(TONetBIOSNameServiceType)type;
- (void)resolveIPAddressWithName:(NSString *)name type:(TONetBIOSNameServiceType)type success:(void (^)(NSString *address))success
                         failure:(void (^)(void))failure;

// -------------------------------------------------------------------------------

- (NSString *)lookupNetworkNameForIPAddress:(NSString *)address;
- (void)lookupNetworkNameForIPAddress:(NSString *)address success:(void (^)(NSString *name))success failure:(void (^)(void))failure;

// -------------------------------------------------------------------------------

- (BOOL)startDiscoveryWithTimeOut:(NSTimeInterval)timeout
                            added:(TONetBIOSNameServiceDiscoveryEvent)addedHandler
                          removed:(TONetBIOSNameServiceDiscoveryEvent)removedHandler;

- (BOOL)stopDiscovery;

@end
