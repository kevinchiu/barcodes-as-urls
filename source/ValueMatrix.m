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

#import "ValueMatrix.h"
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

@implementation ValueMatrix
-(id) initWithElementsOfSize: (int) elementSize width: (int) width height: (int) height{
	[super init];
	data = [[NSMutableData alloc] initWithLength: (width*height*elementSize)];
	mWidth = width;
	mHeight = height;
	mElementSize = elementSize;
	return self;
}

-(int)width { return mWidth; }
-(int)height { return mHeight; }
-(int)elementSize { return mElementSize; }
-(void)zero{
	[data resetBytesInRange: NSMakeRange(0,[data length])];
}
-(void*)mutableBytes{
	return [data mutableBytes];
}
-(void)dealloc{
	[data release];
	[super dealloc];
}
@end


@implementation BoolMatrix : ValueMatrix
-(id)initWithWidth: (int) width height: (int) height{
	[super initWithElementsOfSize: 1 width: width height: height];
	return self;
}
-(BOOL)X: (int)x Y: (int)y{
	char c = ((char*)[data bytes])[y*mWidth+x];
	return c == 1 ? YES : NO;
}
-(void)setValue: (BOOL) v X: (int) x Y: (int) y{
	((char*) [data mutableBytes])[y*mWidth+x] = v ? 1 : 0;
}
@end


@implementation BoolVector
-(id)initWithLength: (int) length{
	[super initWithWidth: length height: 1];
	return self;
}
-(int)length{
	return mWidth;
}
-(BOOL)get: (int) x{
	return [self X: x Y: 0];
}
-(void)setValue: (BOOL) v at: (int) x{
	[self setValue: v X: x Y: 0];
}
-(void)add: (BOOL) p{
	[data appendBytes: &p length: sizeof(BOOL)];
	mWidth++;
}
@end


@implementation ByteMatrix : ValueMatrix
-(id)initWithWidth: (int) width height: (int) height{
	[super initWithElementsOfSize: 1 width: width height: height];
	return self;
}
-(byte)X: (int)x Y: (int)y{
	return ((byte*)[data bytes])[y*mWidth+x];
}
-(void)setValue: (byte) v X: (int) x Y: (int) y{
	((byte*) [data mutableBytes])[y*mWidth+x] = v ? 1 : 0;
}
@end


@implementation ByteVector
-(ByteVector*)initWithLength: (int) length{
	[super initWithWidth: length height: 1];
	return self;
}
-(ByteVector*)initWithBytes: (const byte*) v count: (int) len{
	[self initWithLength: len];
	memcpy([data mutableBytes], v, len);
	return self;
}
-(int)length{
	return mWidth;
}
-(byte)get: (int) x{
	return [self X: x Y: 0];
}
-(void)setValue: (byte) v at: (int) x{
	[self setValue: v X: x Y: 0];
}
-(const byte*)asROArray{
	return (byte*)[data bytes];
}
-(void)appendBytes: (const byte*) v count: (int) count{
	[data appendBytes: v length: count];
	mWidth += count;
}
@end


@implementation IntMatrix
-initWithWidth: (int) width height: (int) height{
	[super initWithElementsOfSize: sizeof(int) width: width height: height];
	return self;
}

-(int)X: (int)x Y: (int)y{
	return *(((int*)[data bytes])+(y*mWidth+x));
}

-(void)setValue: (int) v X: (int) x Y: (int) y{
	int *mb = ((int*)[data mutableBytes]) + (y*mWidth+x);
	*mb = v;
}
-(IntVector*)column: (int) x{
	int h = [self height], i;
	IntVector *v = [[IntVector alloc] initWithLength: h];
	for (i = 0; i < h; i++){
		[v setValue: [self X: x Y: i] at: i];
	}
	return [v autorelease];
}
@end


@implementation IntVector
-(id)initWithLength: (int) length{
	[super initWithWidth: length height: 1];
	return self;
}
-(int)length{
	return mWidth;
}
-(int)get: (int) x{
	return [self X: x Y: 0];
}
-(void)setValue: (int) v at: (int) x{
	[self setValue: v X: x Y: 0];
}
-(const int*)asROArray{
	return (int*)[data bytes];
}
+(IntVector*)fromArray: (int*) array count: (int) count{
	IntVector *v = [[IntVector alloc] initWithLength: count];
	int i;
	for (i = 0; i < count; i++){
		[v setValue: array[i] at: i];
	}
	return [v autorelease];
}
-(void)add: (int) p{
	[data appendBytes: &p length: sizeof(int)];
	mWidth++;
}
@end


@implementation IntPointMatrix
-(id)initWithWidth: (int) width height: (int) height{
	[super initWithElementsOfSize: (2*sizeof(int)) width: width height: height];
	return self;
}
-(IntPoint)X: (int)x Y: (int)y{
	int* pstart = ((int*)[data bytes])+((y*mWidth+x)*2);
	IntPoint r = { *pstart, *(pstart+1) };
	return r;
}
-(void)setValue: (IntPoint) v X: (int) x Y: (int) y{
	int* pstart = ((int*)[data mutableBytes])+((y*mWidth+x)*2);
	*pstart = v.x;
	*(pstart+1) = v.y;
	pstart = ((int*)[data bytes])+((y*mWidth+x)*2);
}
-(void)setXValue: (int) v X: (int) x Y: (int) y{
	int* pstart = ((int*)[data mutableBytes])+((y*mWidth+x)*2);
	*pstart = v;
}
-(void)setYValue: (int) v X: (int) x Y: (int) y{
	int* pstart = ((int*)[data mutableBytes])+((y*mWidth+x)*2);
	*(pstart+1) = v;
}
@end

@implementation IntPointVector
-(id)initWithLength: (int) length{
	[super initWithWidth: length height: 1];
	return self;
}
-(int)length{
	return mWidth;
}
-(IntPoint)get: (int) x{
	return [self X: x Y: 0];
}
-(void)setValue: (IntPoint) v at: (int) x{
	[self setValue: v X: x Y: 0];
}
-(const IntPoint*)asROArray{
	return (const IntPoint*)[data bytes];
}
-(void)add: (IntPoint) p{
	[data increaseLengthBy: (2*sizeof(int))];
	[self setValue: p X: mWidth Y: 0];
	mWidth++;
}
@end
