//
// TOSMBFile.m
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

#import "TOSMBFile.h"
#import "smb_stat.h"

@interface TOSMBFile ()

@property (nonatomic, assign) smb_stat *stat;
@property (nonatomic, assign) BOOL isShareRoot; /** If this item represents the root network share */

@property (nonatomic, readwrite) TOSMBSession *session;

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) NSInteger fileSize;
@property (nonatomic, strong, readwrite) NSDate *modificationTime;
@property (nonatomic, assign, readwrite) BOOL directory;

@property (nonatomic, assign, readwrite) NSInteger allocationSize;
@property (nonatomic, strong, readwrite) NSDate *creationTime;
@property (nonatomic, strong, readwrite) NSDate *accessTime;
@property (nonatomic, strong, readwrite) NSDate *writeTime;

@end

@implementation TOSMBFile

- (instancetype)init
{
    if (self = [super init]) {
        _fileSize = -1;
        _allocationSize = -1;
    }
    
    return self;
}

- (instancetype)initWithStatPointer:(smb_stat *)stat session:(TOSMBSession *)session
{
    if (stat == NULL)
        return nil;
    
    if (self = [self init]) {
        _stat = stat;
        _session = session;
        
        _name = [NSString stringWithCString:smb_stat_name(*stat) encoding:NSUTF16StringEncoding];
        _fileSize = smb_stat_get(*stat, SMB_STAT_SIZE);
        NSLog(@"MOD TIME: %llu", smb_stat_get(*stat, SMB_STAT_MTIME));
    }
    
    return self;
}

- (instancetype)initWithShareName:(NSString *)name session:(TOSMBSession *)session
{
    if (name.length == 0)
        return nil;
    
    if (self = [self init]) {
        _name = name;
        _isShareRoot = YES;
        _fileSize = 0;
        _allocationSize = 0;
        
        _session = session;
    }
    
    return self;
}

- (void)dealloc
{
    if (self.stat)
        smb_stat_destroy(*self.stat);
}

#pragma mark - Dynamic Accessors -
- (BOOL)isDirectory
{
    return self.isShareRoot || (smb_stat_get(*self.stat, SMB_STAT_ISDIR) != 0);
}


#pragma mark - Debug -
- (NSString *)description
{
    if (self.isShareRoot)
        return [NSString stringWithFormat:@"Share - Name: %@", self.name];
    
    return [NSString stringWithFormat:@"%@ - Name: %@ | Size: %ld", (self.directory ? @"Dir":@"File"), self.name, (long)self.fileSize];
}

@end
