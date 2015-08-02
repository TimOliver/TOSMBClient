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

@interface TOSMBFile ()

@property (nonatomic, assign) BOOL isShareRoot; /** If this item represents the root network share */

@property (nonatomic, readwrite) TOSMBSession *session;

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) NSInteger fileSize;
@property (nonatomic, assign, readwrite) NSInteger allocationSize;
@property (nonatomic, strong, readwrite) NSDate *creationTime;
@property (nonatomic, strong, readwrite) NSDate *accessTime;
@property (nonatomic, strong, readwrite) NSDate *writeTime;
@property (nonatomic, strong, readwrite) NSDate *modificationTime;

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

@end
