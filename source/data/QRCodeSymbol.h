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
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#import "../ValueMatrix.h"

@interface QRCodeSymbol : NSObject{
	
	int version;
	int errorCollectionLevel;
	int maskPattern;
	int dataCapacity;
	
	BoolMatrix *moduleMatrix;
	int width;
	int height;
	
	IntPointMatrix *alignmentPattern;
}

-(QRCodeSymbol*)initWithModuleMatrix: (BoolMatrix*) matrix;
-(int)NumErrorCollectionCode;
-(int)NumRSBlocks;
-(int)Version;
-(NSString*)VersionReference;
-(IntPointMatrix*)AlignmentPattern;
-(int)DataCapacity;
-(int)ErrorCollectionLevel;
-(int)MaskPatternReferer;
-(NSString*)MaskPatternRefererAsString;
-(int)Width;
-(int)Height;
-(IntVector*)Blocks;
-(BOOL)getElementAtX: (int) x Y: (int) y;
-(void)reverseElementAtX: (int) x Y: (int) y;
-(BOOL)isInFunctionPatternAtX: (int) targetX Y: (int) targetY;
@end

