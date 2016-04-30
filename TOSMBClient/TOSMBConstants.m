//
// TOSMBConstants.m
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

#import "TOSMBConstants.h"

TONetBIOSNameServiceType TONetBIOSNameServiceTypeForCType(char type)
{
    switch (type) {
        default:
        case NETBIOS_WORKSTATION:   return TONetBIOSNameServiceTypeWorkStation;
        case NETBIOS_MESSENGER:     return TONetBIOSNameServiceTypeMessenger;
        case NETBIOS_FILESERVER:    return TONetBIOSNameServiceTypeFileServer;
        case NETBIOS_DOMAINMASTER:  return TONetBIOSNameServiceTypeDomainMaster;
    }
}

char TONetBIOSNameServiceCTypeForType(char type)
{
    switch (type) {
        default:
        case TONetBIOSNameServiceTypeWorkStation:   return NETBIOS_WORKSTATION;
        case TONetBIOSNameServiceTypeMessenger:     return NETBIOS_MESSENGER;
        case TONetBIOSNameServiceTypeFileServer:    return NETBIOS_FILESERVER;
        case TONetBIOSNameServiceTypeDomainMaster:  return NETBIOS_DOMAINMASTER;
    }
}

NSString *localizedStringForErrorCode(TOSMBSessionErrorCode errorCode)
{
    NSString *errorMessage;
    
    switch (errorCode) {
        case TOSMBSessionErrorNotOnWiFi:
            errorMessage = @"Device isn't on a WiFi network.";
            break;
        case TOSMBSessionErrorCodeUnableToResolveAddress:
            errorMessage = @"Unable to resolve device address.";
            break;
        case TOSMBSessionErrorCodeUnableToConnect:
            errorMessage = @"Unable to connect to device.";
            break;
        case TOSMBSessionErrorCodeAuthenticationFailed:
            errorMessage = @"Login authentication failed.";
            break;
        case TOSMBSessionErrorCodeShareConnectionFailed:
            errorMessage = @"Unable to connect to share.";
            break;
        case TOSMBSessionErrorCodeFileNotFound:
            errorMessage = @"Unable to locate file.";
            break;
        case TOSMBSessionErrorCodeDirectoryDownloaded:
            errorMessage = @"Unable to download a directory.";
            break;
        case TOSMBSessionErrorCodeUnknown:
        default:
            errorMessage = @"Unknown Error Occurred.";
            break;
    }
    
    return NSLocalizedString(errorMessage, @"");
}

NSError *errorForErrorCode(TOSMBSessionErrorCode errorCode)
{
    return [NSError errorWithDomain:@"TOSMBClient" code:errorCode userInfo:@{NSLocalizedDescriptionKey:localizedStringForErrorCode(errorCode)}];
}