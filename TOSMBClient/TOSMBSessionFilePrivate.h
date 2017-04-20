//
// TOSMBSessionFilePrivate.h
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

#import "TOSMBSessionFile.h"
#import "smb_stat.h"

@interface TOSMBSessionFile ()

/**
 * Init a new instance representing a file or folder inside a network share
 *
 * @param stat The opaque pointer for this stat value
 * @param session The session in which this item belongs to
 * @param path The absolute file path to this file's parent directory. Used to generate this file's own file path.
 */
- (instancetype)initWithStat:(smb_stat)stat session:(TOSMBSession *)session parentDirectoryFilePath:(NSString *)path;

/**
 * Init a new instance representing the share itself, which in the case of libSMD, is simply another directory
 *
 * @param name The name of the share
 * @param session The session in which this item belongs to
 */
- (instancetype)initWithShareName:(NSString *)name session:(TOSMBSession *)session;

@end
