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

typedef char byte;

typedef struct{
	int x;
	int y;
} IntPoint;

@interface ValueMatrix : NSObject{
	NSMutableData *data;
	int mWidth;
	int mHeight;
	int mElementSize;
}
-(id) initWithElementsOfSize: (int) elementSize width: (int) width height: (int) height;

-(void*)mutableBytes;
-(int)width;
-(int)height;
-(int)elementSize;
-(void)zero;
@end

@interface BoolMatrix : ValueMatrix{
}

-(id)initWithWidth: (int) width height: (int) height;
-(BOOL)X: (int)x Y: (int)y;
-(void)setValue: (BOOL) v X: (int) x Y: (int) y;
@end

@interface BoolVector : BoolMatrix{
}
-(id)initWithLength: (int) length;
-(int)length;
-(BOOL)get: (int) x;
-(void)setValue: (BOOL) v at: (int) x;
-(void)add: (BOOL) p;
@end

@interface ByteMatrix : ValueMatrix{
}

-(id)initWithWidth: (int) width height: (int) height;
-(byte)X: (int)x Y: (int)y;
-(void)setValue: (byte) v X: (int) x Y: (int) y;
@end

@interface ByteVector : ByteMatrix{
}
-(ByteVector*)initWithLength: (int) length;
-(ByteVector*)initWithBytes: (const byte*) v count: (int) count;
-(int)length;
-(byte)get: (int) x;
-(void)setValue: (byte) v at: (int) x;
-(const byte *)asROArray;
-(void)appendBytes: (const byte*) v count: (int) count;
@end

@class IntVector;

@interface IntMatrix : ValueMatrix{
}

-initWithWidth: (int) width height: (int) height;
-(int)X: (int)x Y: (int)y;
-(void)setValue: (int) v X: (int) x Y: (int) y;
-(IntVector*)column: (int) x;
@end

@interface IntVector : IntMatrix{
}
-(id)initWithLength: (int) length;
-(int)length;
-(int)get: (int) x;
-(void)setValue: (int) v at: (int) x;
-(const int*)asROArray;
+(IntVector*)fromArray: (int*) array count: (int) count;
-(void)add: (int) p;
@end

@interface IntPointMatrix : ValueMatrix{
}

-initWithWidth: (int) width height: (int) height;
-(IntPoint)X: (int)x Y: (int)y;
-(void)setValue: (IntPoint) v X: (int) x Y: (int) y;
-(void)setXValue: (int) v X: (int) x Y: (int) y;
-(void)setYValue: (int) v X: (int) x Y: (int) y;
@end

@interface IntPointVector : IntPointMatrix{
}

-(id)initWithLength: (int) length;
-(int)length;
-(IntPoint)get: (int) x;
-(void)setValue: (IntPoint) v at: (int) x;
-(const IntPoint*)asROArray;
-(void)add: (IntPoint) p;
@end
