//
// TOSMBFile.m
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

#import "TOSMBSessionFile.h"
#import "smb_stat.h"

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
@property (nonatomic, strong, readwrite) NSDate *modificationTime;

@property (nonatomic, assign) uint64_t creationTimestamp;
@property (nonatomic, strong, readwrite) NSDate *creationTime;

@property (nonatomic, assign) uint64_t accessTimestamp;
@property (nonatomic, strong, readwrite) NSDate *accessTime;

@property (nonatomic, assign) uint64_t writeTimestamp;
@property (nonatomic, strong, readwrite) NSDate *writeTime;

- (NSDate *)dateFromLDAPTimeStamp:(uint64_t)timestamp;

@end

@implementation TOSMBSessionFile

- (instancetype)init
{
    if (self = [super init]) {
        _fileSize = -1;
        _allocationSize = -1;
    }
    
    return self;
}

- (instancetype)initWithStat:(smb_stat)stat session:(TOSMBSession *)session parentDirectoryFilePath:(NSString *)path
{
    if (stat == NULL)
        return nil;
    
    if (self = [self init]) {
        _stat = stat;
        
        const char *name = smb_stat_name(stat);
        _name = [[NSString alloc] initWithBytes:name length:strlen(name) encoding:NSUTF8StringEncoding];
        _fileSize = smb_stat_get(stat, SMB_STAT_SIZE);
        _allocationSize = smb_stat_get(stat, SMB_STAT_ALLOC_SIZE);
        _directory = (smb_stat_get(self.stat, SMB_STAT_ISDIR) != 0);
        _modificationTimestamp = smb_stat_get(stat, SMB_STAT_MTIME);
        _creationTimestamp = smb_stat_get(stat, SMB_STAT_CTIME);
        _accessTimestamp = smb_stat_get(stat, SMB_STAT_ATIME);
        _writeTimestamp = smb_stat_get(stat, SMB_STAT_WTIME);
        
        _modificationTime = [self dateFromLDAPTimeStamp:_modificationTimestamp];
        _creationTime = [self dateFromLDAPTimeStamp:_creationTimestamp];
        
        _filePath = [path stringByAppendingPathComponent:_name];
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
        _directory = YES;
        _filePath = [NSString stringWithFormat:@"//%@/", name];
        
        _session = session;
    }
    
    return self;
}

//SO Answer by Dave DeLong - http://stackoverflow.com/a/11978614/599344
- (NSDate *)dateFromLDAPTimeStamp:(uint64_t)timestamp
{
    NSDateComponents *base = [[NSDateComponents alloc] init];
    [base setDay:1];
    [base setMonth:1];
    [base setYear:1601];
    [base setEra:1]; // AD
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *baseDate = [gregorian dateFromComponents:base];
    
    NSTimeInterval newTimestamp = timestamp / 10000000.0f;
    NSDate *finalDate = [baseDate dateByAddingTimeInterval:newTimestamp];
    
    return finalDate;
}

- (NSDate *)accessTime
{
    if (_accessTime)
        return _accessTime;
    
    _accessTime = [self dateFromLDAPTimeStamp:_accessTimestamp];
    return _accessTime;
}

- (NSDate *)writeTime
{
    if (_writeTime)
        return _writeTime;
    
    _writeTime = [self dateFromLDAPTimeStamp:_writeTimestamp];
    return _writeTime;
}

#pragma mark - Debug -
- (NSString *)description
{
    if (self.isShareRoot)
        return [NSString stringWithFormat:@"Share - Name: %@", self.name];
    
    return [NSString stringWithFormat:@"%@ - Name: %@ | Size: %ld", (self.directory ? @"Dir":@"File"), self.name, (long)self.fileSize];
}

@end
