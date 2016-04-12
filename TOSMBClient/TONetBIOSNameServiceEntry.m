//
// TONetBIOSNameServiceEntry.m
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

#import <arpa/inet.h>

#import "TONetBIOSNameServiceEntry.h"
#import "TONetBIOSNameService.h"
#import "netbios_defs.h"

@interface TONetBIOSNameServiceEntry ()

@property (nonatomic, assign) netbios_ns_entry *entry;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSString *group;
@property (nonatomic, assign, readwrite) TONetBIOSNameServiceType type;
@property (nonatomic, assign, readwrite) uint32_t ipAddress;
@property (nonatomic, copy, readwrite) NSString *ipAddressString;

- (BOOL)isEqualToEntry:(TONetBIOSNameServiceEntry *)entry;

@end

@implementation TONetBIOSNameServiceEntry

- (instancetype)initWithCEntry:(netbios_ns_entry *)entry
{
    if (entry == NULL) {
        return nil;
    }
    
    if (self = [super init]) {
        _entry = entry;
        _name = [NSString stringWithCString:netbios_ns_entry_name(_entry) encoding:NSUTF8StringEncoding];
        _group = [NSString stringWithCString:netbios_ns_entry_group(_entry) encoding:NSUTF8StringEncoding];
        _type = TONetBIOSNameServiceTypeForCType(netbios_ns_entry_type(_entry));
        _ipAddress = netbios_ns_entry_ip(entry);
    }
    
    return self;
}

+ (instancetype)entryWithCEntry:(netbios_ns_entry *)entry
{
    return [[TONetBIOSNameServiceEntry alloc] initWithCEntry:entry];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[TONetBIOSNameServiceEntry class]]) {
        return NO;
    }
    
    return [self isEqualToEntry:object];
}

- (BOOL)isEqualToEntry:(TONetBIOSNameServiceEntry *)entry
{
    BOOL equalNames = [self.name isEqualToString:entry.name];
    BOOL equalGroups = [self.group isEqualToString:entry.group];
    BOOL equalIPAddress = self.ipAddress == entry.ipAddress;
    
    return equalNames && equalGroups && equalIPAddress;
}

- (NSUInteger)hash {
    return ([self.name hash] ^ [self.group hash]) + self.ipAddress;
}

@end
