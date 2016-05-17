//
// TONetBIOSNameService.h
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

#import <Foundation/Foundation.h>

@class TONetBIOSNameServiceEntry;

// -------------------------------------------------------------------------------
// A block that is called whenever a device entry is added or removed from discovery
typedef void (^TONetBIOSNameServiceDiscoveryEvent)(TONetBIOSNameServiceEntry *entry);

// -------------------------------------------------------------------------------

@interface TONetBIOSNameService : NSObject

/** True when device discovery has been started */
@property (nonatomic, readonly) BOOL discovering;

// -------------------------------------------------------------------------------

/**
 Perform a lookup to resolve the IP address of the supplied host name.
 This operation is performed synchronously, and should be called on a background queue.
 
 @param name The host name in which to resolve.
 @param type The NetBIOS device type of the device
 @return A string of the IP address, or if the resolution failed, nil.
 */
- (NSString *)resolveIPAddressWithName:(NSString *)name type:(TONetBIOSNameServiceType)type;

/**
 Perform a lookup to resolve the IP address of the supplied host name.
 This operation is performed asynchronously and returns the result in a block when completed.
 
 @param name The host name in which to resolve.
 @param type The NetBIOS device type of the device.
 @param success The block that is executed when resolution is successful.
 @param failure The block that is executed when resolution fails.
 */
- (void)resolveIPAddressWithName:(NSString *)name type:(TONetBIOSNameServiceType)type success:(void (^)(NSString *address))success
                         failure:(void (^)(void))failure;

// -------------------------------------------------------------------------------

/**
 Perform a reverse lookup to resolve the host name from an IP address on the local network.
 This operation is performed synchronously, and should be called on a background queue.
 
 @param address The IP address in which to resolve.
 @return A string of the resolved host name, or nil upon failure.
 */
- (NSString *)lookupNetworkNameForIPAddress:(NSString *)address;

/**
 Perform a lookup to resolve the IP address of the supplied host name.
 This operation is performed asynchronously and returns the result in a block when completed.
 
 @param address The IP address in which to resolve.
 @param success The block that is executed when resolution is successful.
 @param failure The block that is executed when resolution fails.
 */
- (void)lookupNetworkNameForIPAddress:(NSString *)address success:(void (^)(NSString *name))success failure:(void (^)(void))failure;

// -------------------------------------------------------------------------------

/**
 Starts a broadcast service on a background thread in order to detect any devices on the local network with a
 NetBIOS name, and executes a block whenever one is added, or removed.
 
 @param timeout The timeout delay, in seconds, between broadcasts. Default value is 4 seconds.
 @param addedHandler A block that is executed each time a new name is added.
 @param removedHandler A block that is executed each time a name that was previously added is removed.
 @return A bool value as to whether the start of discovery was successful
 */
- (BOOL)startDiscoveryWithTimeOut:(NSTimeInterval)timeout
                            added:(TONetBIOSNameServiceDiscoveryEvent)addedHandler
                          removed:(TONetBIOSNameServiceDiscoveryEvent)removedHandler;

/**
 Stops broadcasting of device discovery
 
 @return A bool value as to whether the service was successfully stopped.
 */
- (BOOL)stopDiscovery;

@end
