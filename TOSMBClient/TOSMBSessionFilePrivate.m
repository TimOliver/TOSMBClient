//
// TOSMBSessionFilePrivate.h
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

#import "TOSMBSessionFilePrivate.h"

@interface TOSMBSessionFile ()

@property (nonatomic, strong, readwrite) NSString *filePath;

@property (nonatomic, assign) smb_stat stat;
@property (nonatomic, assign) BOOL isShareRoot; /** If this item represents the root network share */

@property (nonatomic, readwrite) TOSMBSession *session;

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) uint64_t fileSize;
@property (nonatomic, assign, readwrite) uint64_t allocationSize;
@property (nonatomic, assign, readwrite) BOOL directory;

@property (nonatomic, assign) uint64_t modificationTimestamp;
@property (nonatomic, assign) uint64_t creationTimestamp;
@property (nonatomic, assign) uint64_t accessTimestamp;
@property (nonatomic, assign) uint64_t writeTimestamp;

@property (nonatomic, strong, readwrite) NSDate *modificationTime;
@property (nonatomic, strong, readwrite) NSDate *creationTime;

- (NSDate *)dateFromLDAPTimeStamp:(uint64_t)timestamp;

@end

@implementation TOSMBSessionFile (Private)

- (instancetype)init
{
    if (self = [super init]) {
        self.fileSize = -1;
        self.allocationSize = -1;
    }
    
    return self;
}

- (instancetype)initWithStat:(smb_stat)stat session:(TOSMBSession *)session parentDirectoryFilePath:(NSString *)path
{
    if (stat == NULL)
        return nil;
    
    if (self = [self init]) {
        self.stat = stat;
        
        const char *name = smb_stat_name(stat);
        self.name = [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSUTF8StringEncoding];
        self.fileSize = smb_stat_get(stat, SMB_STAT_SIZE);
        self.allocationSize = smb_stat_get(stat, SMB_STAT_ALLOC_SIZE);
        self.directory = (smb_stat_get(self.stat, SMB_STAT_ISDIR) != 0);
        self.modificationTimestamp = smb_stat_get(stat, SMB_STAT_MTIME);
        self.creationTimestamp = smb_stat_get(stat, SMB_STAT_CTIME);
        self.accessTimestamp = smb_stat_get(stat, SMB_STAT_ATIME);
        self.writeTimestamp = smb_stat_get(stat, SMB_STAT_WTIME);
        
        self.modificationTime = [self dateFromLDAPTimeStamp:self.modificationTimestamp];
        self.creationTime = [self dateFromLDAPTimeStamp:self.creationTimestamp];
        
        self.filePath = [path stringByAppendingPathComponent:self.name];
    }
    
    return self;
}

- (instancetype)initWithShareName:(NSString *)name session:(TOSMBSession *)session
{
    if (name.length == 0)
        return nil;
    
    if (self = [self init]) {
        self.name = name;
        self.isShareRoot = YES;
        self.fileSize = 0;
        self.allocationSize = 0;
        self.directory = YES;
        self.filePath = [NSString stringWithFormat:@"//%@/", name];
        
        self.session = session;
    }
    
    return self;
}

@end
