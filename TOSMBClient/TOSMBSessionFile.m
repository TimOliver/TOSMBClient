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
#import "TOSMBSessionFilePrivate.h"
#import "smb_stat.h"

@interface TOSMBSessionFile ()

@property (nonatomic, strong, readwrite) NSDate *accessTime;
@property (nonatomic, strong, readwrite) NSDate *writeTime;

- (NSDate *)dateFromLDAPTimeStamp:(uint64_t)timestamp;

@end

@implementation TOSMBSessionFile

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
    
    _accessTime = [self dateFromLDAPTimeStamp:self.accessTimestamp];
    return _accessTime;
}

- (NSDate *)writeTime
{
    if (_writeTime)
        return _writeTime;
    
    _writeTime = [self dateFromLDAPTimeStamp:self.writeTimestamp];
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
