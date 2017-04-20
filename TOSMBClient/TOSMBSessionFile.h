//
// TOSMBFile.h
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

#import <Foundation/Foundation.h>

@class TOSMBSession;

@interface TOSMBSessionFile : NSObject

@property (nonatomic, readonly) TOSMBSession *session;      /** The SMB session of this file entry. */
@property (nonatomic, readonly) NSString *filePath;         /** The filepath of this file, excluding the share name. */
@property (nonatomic, readonly) BOOL isShareRoot;

@property (nonatomic, readonly) BOOL directory;             /** Whether this file is a directory or not */

@property (nonatomic, readonly) NSString *name;             /** The name of the file */
@property (nonatomic, readonly) uint64_t fileSize;         /** The file size, in bytes of this folder (0 if it's a folder) */
@property (nonatomic, readonly) uint64_t allocationSize;   /** The allocation size (ie how big it will be on disk) of this file */
@property (nonatomic, readonly) NSDate *creationTime;       /** The date and time that this file was created */
@property (nonatomic, readonly) NSDate *accessTime;         /** The date when this file was last accessed. */
@property (nonatomic, readonly) NSDate *writeTime;          /** The date when this file was last written to. */
@property (nonatomic, readonly) NSDate *modificationTime;   /** The date when this file was last modified. */

@end
