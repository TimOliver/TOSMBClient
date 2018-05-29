//
// TOSMBConstants.h
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

#ifndef _TOSMBCLIENT_CONSTANTS_H
#define _TOSMBCLIENT_CONSTANTS_H

#import <Foundation/Foundation.h>

extern NSString * const TOSMBClientErrorDomain;

/** SMB Error Values */
typedef NS_ENUM(NSInteger, TOSMBSessionErrorCode)
{
    TOSMBSessionErrorCodeUnknown = 0,                    /* Error code was not specified. */
    TOSMBSessionErrorNotOnWiFi = 1000,                   /* The device isn't presently connected to a local network. */
    TOSMBSessionErrorCodeUnableToResolveAddress = 1001,  /* Not enough connection information to resolve was supplied. */
    TOSMBSessionErrorCodeUnableToConnect = 1002,         /* The connection attempt failed. */
    TOSMBSessionErrorCodeAuthenticationFailed = 1003,    /* The username/password failed (And guest login is not available) */
    TOSMBSessionErrorCodeShareConnectionFailed = 1004,   /* Connection attempt to a share in the device failed. */
    TOSMBSessionErrorCodeFileNotFound = 1005,            /* Unable to locate the requested file. */
    TOSMBSessionErrorCodeDirectoryDownloaded = 1006,     /* A directory was attempted to be downloaded. */
    TOSMBSessionErrorCodeFileDownloadFailed = 1007,      /* The file could not be downloaded, possible network error. */

};

/** NetBIOS Service Device Types */
typedef NS_ENUM(NSInteger, TONetBIOSNameServiceType) {
    TONetBIOSNameServiceTypeWorkStation,
    TONetBIOSNameServiceTypeMessenger,
    TONetBIOSNameServiceTypeFileServer,
    TONetBIOSNameServiceTypeDomainMaster
};

/** SMB File Download Connection State */
typedef NS_ENUM(NSInteger, TOSMBSessionDownloadTaskState) {
    TOSMBSessionDownloadTaskStateReady,
    TOSMBSessionDownloadTaskStateRunning,
    TOSMBSessionDownloadTaskStateSuspended,
    TOSMBSessionDownloadTaskStateCancelled,
    TOSMBSessionDownloadTaskStateCompleted,
    TOSMBSessionDownloadTaskStateFailed
} __deprecated_enum_msg("Use TOSMBSessionTaskState values instead");

/** SMB Connection State */
typedef NS_ENUM(NSUInteger, TOSMBSessionTaskState) {
    TOSMBSessionTaskStateReady,
    TOSMBSessionTaskStateRunning,
    TOSMBSessionTaskStateSuspended,
    TOSMBSessionTaskStateCancelled,
    TOSMBSessionTaskStateCompleted,
    TOSMBSessionTaskStateFailed
};

#endif

extern TONetBIOSNameServiceType TONetBIOSNameServiceTypeForCType(char type);
extern char TONetBIOSNameServiceCTypeForType(char type);

extern NSString *localizedStringForErrorCode(TOSMBSessionErrorCode errorCode);
extern NSError *errorForErrorCode(TOSMBSessionErrorCode errorCode);
