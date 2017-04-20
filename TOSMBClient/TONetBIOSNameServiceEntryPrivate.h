//
// TONetBIOSNameServiceEntryPrivate.h
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
#import "TONetBIOSNameServiceEntry.h"
#import "netbios_ns.h"

// Private Category for exposing the C-level data values
@interface TONetBIOSNameServiceEntry ()

- (instancetype)initWithCEntry:(netbios_ns_entry *)entry;
+ (instancetype)entryWithCEntry:(netbios_ns_entry *)entry;

@end
