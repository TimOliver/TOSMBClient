//
// TOSMBConstants.h
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
#import "netbios_defs.h"
#import "smb_defs.h"

/** NetBIOS Service Device Types */
typedef NS_ENUM(NSInteger, TONetBIOSNameServiceType) {
    TONetBIOSNameServiceTypeWorkStation,
    TONetBIOSNameServiceTypeMessenger,
    TONetBIOSNameServiceTypeFileServer,
    TONetBIOSNameServiceTypeDomainMaster
};

typedef NS_ENUM(NSInteger, TOSMBSessionState) {
    TOSMBSessionStateError = SMB_STATE_ERROR,
    TOSMBSessionStateNetBIOSOK = SMB_STATE_NEW,
    TOSMBSessionStateDialectOK = SMB_STATE_NETBIOS_OK,
    TOSMBSessionStateSessionOK = SMB_STATE_SESSION_OK
};

typedef NS_ENUM(NSInteger, TOSMBSessionDownloadTaskState) {
    TOSMBSessionDownloadTaskStateReady,
    TOSMBSessionDownloadTaskStateRunning,
    TOSMBSessionDownloadTaskStateSuspended,
    TOSMBSessionDownloadTaskStateCanceled,
    TOSMBSessionDownloadTaskStateCompleted
};

extern TONetBIOSNameServiceType TONetBIOSNameServiceTypeForCType(char type);
extern char TONetBIOSNameServiceCTypeForType(char type);