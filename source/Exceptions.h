/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.

 This program is based on the Open Source QR Code Library,
 downloadable from http://qrcode.sourceforge.jp .

 Modified by Kevin Chiu, kevin.gc+iphone@gmail.com
*/
#import <Foundation/Foundation.h>

@interface FinderPatternNotFoundException : NSException
+(id)withMessage: (NSString*) msg;
@end

@interface InvalidVersionInfoException : NSException
+(id)withMessage: (NSString*) msg;
@end

@interface VersionInformationException : NSException
+(id)withMessage: (NSString*) msg;
@end

@interface AlignmentPatternNotFoundException : NSException
+(id)withMessage: (NSString*) msg;
@end

@interface InvalidDataBlockException : NSException
+(id)withMessage: (NSString*) msg;
@end

@interface IndexOutOfRangeException : NSException
+(id)withMessage: (NSString*) msg;
@end

@interface SymbolNotFoundException : NSException
+(id)withMessage: (NSString*) msg;
@end

@interface InvalidVersionException : NSException
+(id)withMessage: (NSString*) msg;
@end

@interface DecodingFailedException : NSException
+(id)withMessage: (NSString*) msg;
@end

@interface DebugAbortException : NSException
+(id)create;
@end
