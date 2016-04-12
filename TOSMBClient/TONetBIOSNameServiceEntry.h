//
// TONetBIOSNameServiceEntry.h
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
#import "TOSMBConstants.h"
#import "netbios_ns.h"

@interface TONetBIOSNameServiceEntry : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *group;
@property (nonatomic, assign, readonly) TONetBIOSNameServiceType type;
@property (nonatomic, assign, readonly) uint32_t ipAddress;
@property (nonatomic, copy, readonly) NSString *ipAddressString;

- (instancetype)initWithCEntry:(netbios_ns_entry *)entry;
+ (instancetype)entryWithCEntry:(netbios_ns_entry *)entry;

@end
