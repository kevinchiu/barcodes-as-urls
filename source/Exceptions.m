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
#import "Exceptions.h"
#import <Foundation/Foundation.h>

#define EXCEPTION_CLASS(cname) @implementation cname \
+(id)withMessage: (NSString*) msg \
{ \
 return [[[cname alloc] initWithName: @#cname reason: msg userInfo: nil] autorelease]; \
} \
@end

EXCEPTION_CLASS(FinderPatternNotFoundException)
EXCEPTION_CLASS(InvalidVersionInfoException)
EXCEPTION_CLASS(VersionInformationException)
EXCEPTION_CLASS(AlignmentPatternNotFoundException)
EXCEPTION_CLASS(InvalidDataBlockException)
EXCEPTION_CLASS(IndexOutOfRangeException)
EXCEPTION_CLASS(SymbolNotFoundException)
EXCEPTION_CLASS(InvalidVersionException)
EXCEPTION_CLASS(DecodingFailedException)

@implementation DebugAbortException
+(id)create{
 return [[[DebugAbortException alloc] initWithName: @"DebugAbort" reason: @"none" userInfo: nil] autorelease]; \
}
@end
