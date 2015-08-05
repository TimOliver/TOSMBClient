//
// TOSMBSession.m
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

#import <arpa/inet.h>

#import "TOSMBSession.h"
#import "TOSMBFile.h"
#import "TONetBIOSNameService.h"

#import "smb_session.h"
#import "smb_share.h"
#import "smb_stat.h"

@interface TOSMBSession ()

/* The session pointer responsible for this object. */
@property (nonatomic, assign) smb_session *session;

/* 1 == Guest, 0 == Logged in, -1 == Logged out */
@property (nonatomic, assign, readwrite) NSInteger guest;

@property (nonatomic, strong) NSOperationQueue *requestQueue; /* Operation queue for asynchronous requests. */
@property (nonatomic, strong) NSOperationQueue *downloadsQueue; /* Operation queue for file downloads. */

// Connection/Authentication handling
- (NSError *)attemptConnection;

// File path parsing
- (NSString *)shareNameFromPath:(NSString *)path;
- (NSString *)filePathExcludingSharePathFromPath:(NSString *)path;

@end

@implementation TOSMBSession

#pragma mark - Class Creation -
- (instancetype)init
{
    if (self = [super init]) {
        _session = smb_session_new();
        if (_session == NULL)
            return nil;
    }
    
    return self;
}

- (instancetype)initWithHostName:(NSString *)name
{
    if (self = [self init]) {
        _hostName = name;
    }
    
    return self;
}

- (instancetype)initWithIPAddress:(NSString *)address
{
    if (self = [self init]) {
        _ipAddress = address;
    }
    
    return self;
}

- (instancetype)initWithHostName:(NSString *)name ipAddress:(NSString *)ipAddress
{
    if (self = [self init]) {
        _hostName = name;
        _ipAddress = ipAddress;
    }
    
    return self;
}

- (void)dealloc
{
    smb_session_destroy(self.session);
}

#pragma mark - Authorization -
- (void)setLoginCredentialsWithUserName:(NSString *)userName password:(NSString *)password
{
    self.userName = userName;
    self.password = password;
}

#pragma mark - Requests -
- (NSError *)attemptConnection
{
    if (self.state == TOSMBSessionStateSessionOK)
        return nil;
    
    if (self.ipAddress.length == 0 && self.hostName.length == 0) {
        return [NSError errorWithDomain:@"TOSMBClient"
                                   code:1001
                               userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Insufficient login information supplied.", @"")}];
    }
    
    if (self.ipAddress.length == 0 || self.hostName.length == 0) {
        TONetBIOSNameService *nameService = [[TONetBIOSNameService alloc] init];
        
        if (self.ipAddress == nil)
            self.ipAddress = [nameService resolveIPAddressWithName:self.hostName type:TONetBIOSNameServiceTypeFileServer];
        else
            self.hostName = [nameService lookupNetworkNameForIPAddress:self.ipAddress];
    }
    
    struct in_addr addr;
    inet_aton([self.ipAddress cStringUsingEncoding:NSASCIIStringEncoding], &addr);
    
    const char *hostName = [self.hostName cStringUsingEncoding:NSASCIIStringEncoding];
    if (!smb_session_connect(self.session, hostName, addr.s_addr, SMB_TRANSPORT_TCP)) {
        return [NSError errorWithDomain:@"TOSMBClient"
                                   code:1002
                               userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unable to connect to host.", @"")}];
    }
    
    //If the username or password wasn't supplied, use empty strings as oppsoed to NULL
    const char *userName = (self.userName ? [self.userName cStringUsingEncoding:NSASCIIStringEncoding] : "");
    const char *password = (self.password ? [self.password cStringUsingEncoding:NSASCIIStringEncoding] : "");
    
    smb_session_set_creds(self.session, hostName, userName, password);
    
    if (smb_session_login(self.session)) {
        self.guest = smb_session_is_guest(self.session);
    }
    else
    {
        return [NSError errorWithDomain:@"TOSMBClient"
                                   code:1003
                               userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unable to authenticate.", @"")}];
    }
    
    return nil;
}

- (NSArray *)requestContentsOfDirectoryAtFilePath:(NSString *)path error:(NSError **)error
{
    //Attempt a connection attempt (If it has not already been done)
    NSError *resultError = [self attemptConnection];
    if (error && resultError)
        *error = resultError;
    
    if (resultError)
        return nil;
    
    //-----------------------------------------------------------------------------
    
    //If the path is nil, or '/', we'll be specifically requesting the
    //parent network share names
    if (path.length == 0 || [path isEqualToString:@"/"]) {
        smb_share_list list;
        size_t shareCount = smb_share_get_list(self.session, &list);
        if (shareCount == 0)
            return nil;
        
        NSMutableArray *shareList = [NSMutableArray array];
        for (NSInteger i = 0; i < shareCount; i++) {
            const char *shareName = smb_share_list_at(list, i);
            
            //Skip system shares suffixed by '$'
            if (shareName[strlen(shareName)-1] == '$')
                continue;
            
            NSString *shareNameString = [NSString stringWithCString:shareName encoding:NSUTF8StringEncoding];
            TOSMBFile *share = [[TOSMBFile alloc] initWithShareName:shareNameString session:self];
            [shareList addObject:share];
        }
        
        smb_share_list_destroy(list);
        
        return [NSArray arrayWithArray:shareList];
    }
    
    //-----------------------------------------------------------------------------
    
    //Replace any backslashes with forward slashes
    path = [path stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    
    //Work out just the share name from the path (The first directory in the string)
    NSString *shareName = [self shareNameFromPath:path];
    
    //Connect to that share
    //If not, make a new connection
    const char *cStringName = [shareName cStringUsingEncoding:NSASCIIStringEncoding];
    smb_tid shareID = smb_tree_connect(self.session, cStringName);
    if (shareID == 0) {
        if (error) {
            resultError = [NSError errorWithDomain:@"TOSMBClient"
                                              code:1004
                                          userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Unable to connect to share.", @"")}];
            
            *error = resultError;
        }
        
        return nil;
    }
    
    //work out the remainder of the file path and create the search query
    NSString *relativePath = [self filePathExcludingSharePathFromPath:path];
    
    //Append a slash at the end if one isn't already present
    if (relativePath.length > 0 && [relativePath characterAtIndex:relativePath.length-1] != '/')
        relativePath = [relativePath stringByAppendingString:@"/"];
    
    relativePath = [relativePath stringByAppendingString:@"*"]; //wildcard to search for all files

    //Query for a list of files in this directory
    smb_stat_list statList = smb_find(self.session, shareID, [relativePath cStringUsingEncoding:NSUTF8StringEncoding]);
    size_t listCount = smb_stat_list_count(statList);
    if (listCount == 0)
        return nil;
    
    NSMutableArray *fileList = [NSMutableArray array];
    
    for (NSInteger i = 0; i < listCount; i++) {
        smb_stat item = smb_stat_list_at(statList, i);
        const char* name = smb_stat_name(item);
        if (name[0] == '.') {
            continue;
        }
        
        TOSMBFile *file = [[TOSMBFile alloc] initWithStat:item session:self parentDirectoryFilePath:path];
        [fileList addObject:file];
    }
    smb_stat_list_destroy(statList);
    smb_tree_disconnect(self.session, shareID);
    
    if (fileList.count == 0)
        return nil;
    
    return [fileList sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
}

#pragma mark - String Parsing -
- (NSString *)shareNameFromPath:(NSString *)path
{
    path = [path copy];
    
    //Remove any potential slashes at the start
    if ([[path substringToIndex:2] isEqualToString:@"//"]) {
        path = [path substringFromIndex:2];
    }
    else if ([[path substringToIndex:1] isEqualToString:@"/"]) {
        path = [path substringFromIndex:1];
    }
    
    NSRange range = [path rangeOfString:@"/"];
    
    if (range.location != NSNotFound)
        path = [path substringWithRange:NSMakeRange(0, range.location)];
    
    return path;
}

- (NSString *)filePathExcludingSharePathFromPath:(NSString *)path
{
    path = [path copy];
    
    //Remove any potential slashes at the start
    if ([[path substringToIndex:2] isEqualToString:@"//"]) {
        path = [path substringFromIndex:2];
    }
    else if ([[path substringToIndex:1] isEqualToString:@"/"]) {
        path = [path substringFromIndex:1];
    }
    
    NSRange range = [path rangeOfString:@"/"];
    
    if (range.location != NSNotFound)
        path = [path substringFromIndex:range.location+1];
    
    return path;
}

#pragma mark - Accessors -
- (NSInteger)guest
{
    if (self.session == NULL)
        return -1;
    
    return smb_session_is_guest(self.session);
}

- (TOSMBSessionState)state
{
    if (self.session == NULL)
        return TOSMBSessionStateError;
    
    return smb_session_state(self.session);
}

@end
