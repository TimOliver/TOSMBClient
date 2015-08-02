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

@property (nonatomic, assign) smb_session *session;
@property (nonatomic, assign, readwrite) NSInteger guest;

- (NSError *)attemptConnection;

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
    [self attemptConnection];
    
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
            
            TOSMBFile *share = [[TOSMBFile alloc] initWithShareName:[NSString stringWithCString:shareName encoding:NSASCIIStringEncoding] session:self];
            [shareList addObject:share];
        }
        
        smb_share_list_destroy(list);
        
        return [NSArray arrayWithArray:shareList];
    }
    
    
    
    return nil;
}

- (void)connect
{
    struct in_addr addr;
    smb_tid tid;
    
    inet_aton("192.168.1.3", &addr);
    
    if (!smb_session_connect(self.session, "TITANNAS", addr.s_addr, SMB_TRANSPORT_TCP))
    {
        printf("Unable to connect to host\n");
        return;
    }
    
    smb_session_set_creds(self.session, "TITANNAS", "", "");
    if (smb_session_login(self.session))
    {
        if (smb_session_is_guest(self.session))
            printf("Logged in as GUEST \n");
        else
            printf("Successfully logged in\n");
    }
    else
    {
        printf("Auth failed\n");
        return;
    }
    
    smb_share_list list;
    size_t shareCount = smb_share_get_list(self.session, &list);
    for (NSInteger i = 0; i < shareCount; i++)
        printf("Name %s \n", smb_share_list_at(list, i));
    
    
    tid = smb_tree_connect(self.session, "Books");
    if (!tid)
    {
        printf("Unable to connect to share\n");
        return;
    }
    
    smb_stat_list statList = smb_find(self.session, tid, "\\Manga\\ラブひな\\*");
    size_t listCount = smb_stat_list_count(statList);
    for (NSInteger i = 0; i < listCount; i++) {
        smb_stat item = smb_stat_list_at(statList, i);
        printf("Item : %s\n", smb_stat_name(item));
    }
    
    NSLog(@"WOO");
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
