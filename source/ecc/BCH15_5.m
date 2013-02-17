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
#import "BCH15_5.h"

@interface BCH15_5 (Private)
+(IntMatrix*) _createGF16;
-(int)_searchElement:(IntVector*)x;
-(IntVector*)_getCode:(int)input;
-(int)_addGF: (int) arg1 arg2: (int) arg2;
-(IntVector*)_calcSyndrome: (BoolVector*) y;
-(IntVector*)_calcErrorPositionVariable: (IntVector*) s;
-(IntVector*)_detectErrorBitPosition: (IntVector*) s;
-(void)_correctErrorBit:(BoolVector*) y errorPos: (IntVector*) errorPos;
@end

@implementation BCH15_5

-(BCH15_5*)initWithVector: (BoolVector*) source{
	[super init];
	receiveData = source;
	[receiveData retain];
	gf16 = [[BCH15_5 _createGF16] retain];
	return self;
}

-(void)dealloc{
	[gf16 release];
	[receiveData release];
	[super dealloc];
}

-(int)NumCorrectedError{
	return numCorrectedError;
}

-(BoolVector*)correct{
	IntVector *s = [self _calcSyndrome: receiveData]; 
	IntVector *errorPos = [self _detectErrorBitPosition: s];
	[self _correctErrorBit: receiveData errorPos: errorPos];
	return receiveData; // has already been autoreleased, so not our problem anymore.
}

+(IntMatrix*) _createGF16{
	IntMatrix *gf16 = [[IntMatrix alloc] initWithWidth: 16 height: 4];
	int seed[4] = { 1, 1, 0, 0 }, i, j;
	for (i = 0; i < 4; i++){
		[gf16 setValue: 1 X:i Y:i];
	}
	for (i = 0; i < 4; i++){
		[gf16 setValue: seed[i] X: 4 Y: i];
	}
	for (i = 5; i < 16; i++){
		for (j = 1; j < 4; j++){
			[gf16 setValue: [gf16 X: (i - 1) Y: (j - 1)] X: i Y: j];
		}
		if ([gf16 X: (i - 1) Y: 3] == 1){
			for (j = 0; j < 4; j++){
				[gf16 setValue: ([gf16 X:i Y:j]+seed[j]) X: i Y: j];
			}
		}
	}
	return [gf16 autorelease];
}

-(int)_searchElement:(IntVector*)x{
	int k;
	for (k = 0; k < 15; k++){
		if ([x get:0] == [gf16 X: k Y: 0] && [x get: 1] == [gf16 X:k Y:1] 
			&& [x get:2] == [gf16 X:k Y:2] && [x get:3] == [gf16 X:k Y:3]){
			break;
		}
	}
	return k;
}

-(IntVector*)_getCode:(int)input{
	IntVector *f = [[IntVector alloc] initWithLength: 15];
	int r[8], i;
	
	for (i = 0; i < 15; i++){
		int w1, w2;
		int yin;
		
		w1 = r[7];
		if (i < 7){
			yin = (input >> (6 - i)) % 2;
			w2 = (yin + w1) % 2;
		}
		else{
			yin = w1;
			w2 = 0;
		}
		r[7] = (r[6] + w2) % 2;
		r[6] = (r[5] + w2) % 2;
		r[5] = r[4];
		r[4] = (r[3] + w2) % 2;
		r[3] = r[2];
		r[2] = r[1];
		r[1] = r[0];
		r[0] = w2;
		[f setValue: yin at: (14 - i)];
	}
	return [f autorelease];
	
}

-(int)_addGF: (int) arg1 arg2: (int) arg2{
	int m;
	IntVector *p = [[IntVector alloc] initWithLength: 4];
	for (m = 0; m < 4; m++){
		int w1 = (arg1 < 0 || arg1 >= 15)?0:[gf16 X: arg1 Y: m];
		int w2 = (arg2 < 0 || arg2 >= 15)?0:[gf16 X: arg2 Y: m];
		[p setValue:(w1 + w2) % 2 at: m];
	}
	int r = [self _searchElement: p];
	[p release];
	return r;
}

-(IntVector*)_calcSyndrome: (BoolVector*) y{
	IntVector *s = [[IntVector alloc] initWithLength: 5];
	IntVector *p = [[IntVector alloc] initWithLength: 4];
	
	int k, m;
	for (k = 0; k < 15; k++){
		if ([y get:k] == true){
			for (m = 0; m < 4; m++){
				int nv = ([p get:m] + [gf16 X:k Y:m]) % 2;
				[p setValue: nv at: m];
			}
		}
	}
	k = [self _searchElement: p];
	[s setValue: ((k >= 15)?- 1:k) at: 0];
	
	[p zero];
	for (k = 0; k < 15; k++){
		if ([y get: k]){
			for (m = 0; m < 4; m++){
				int nv = ([p get: m] + [gf16 X: ((k * 3) % 15) Y:m]) % 2;
				[p setValue: nv at: m];
			}
		}
	}
	
	k = [self _searchElement: p];
	[s setValue: ((k >= 15)?- 1:k) at: 2];
	
	[p zero];
	for (k = 0; k < 15; k++){
		if ([y get:k]){
			for (m = 0; m < 4; m++){
				int nv = ([p get:m] + [gf16 X:((k * 5) % 15) Y:m]) % 2;
				[p setValue: nv at: m];
			}
		}
	}
	k = [self _searchElement: p];
	[s setValue: ((k >= 15)?- 1:k) at: 4];
	
	[p release];
	return [s autorelease];
}

-(IntVector*)_calcErrorPositionVariable: (IntVector*) s{
	IntVector *e = [[IntVector alloc] initWithLength: 4];
	
	// calc d1
	[e setValue: [s get: 0] at: 0];
	
	// calc d2
	int t = ([s get:0] + [s get:1]) % 15;
	int mother = [self _addGF: [s get:2] arg2: t];
	mother = (mother >= 15)?- 1:mother;
	
	t = ([s get:2] + [s get:1]) % 15;
	int child = [self _addGF: [s get:4] arg2: t];
	child = (child >= 15)?- 1:child;
	[e setValue: (child < 0 && mother < 0)?- 1:(child - mother + 15) % 15 at: 1];
	
	// calc d3
	t = ([s get:1] + [e get:0]) % 15;
	int t1 = [self _addGF: [s get:2] arg2: t];
	t = ([s get:0] + [e get:1]) % 15;
	[e setValue: [self _addGF: t1 arg2: t] at: 2];
	
	return [e autorelease];
}

-(IntVector*)_detectErrorBitPosition: (IntVector*) s{
	IntVector *e = [self _calcErrorPositionVariable: s];
	IntVector *errorPos = [[IntVector alloc] initWithLength: 4];
	
	if ([e get:0] == - 1){
	}
	else if ([e get:1] == - 1){
		[errorPos setValue: 1 at: 0];
		[errorPos setValue: [e get: 0] at: 1];
	}
	else{
		int x3, x2, x1;
		int t, t1, t2, anError, i;
		//error detection
		for (i = 0; i < 15; i++){
			x3 = (i * 3) % 15;
			x2 = (i * 2) % 15;
			x1 = i;
			
			t = ([e get:0] + x2) % 15;
			t1 = [self _addGF:x3 arg2: t];
			
			t = ([e get:1] + x1) % 15;
			t2 = [self _addGF: t arg2: [e get:2]];
			
			anError = [self _addGF: t1 arg2: t2];
			
			if (anError >= 15){
				[errorPos setValue: [errorPos get: 0]+1 at: 0];
				[errorPos setValue: i at: [errorPos get: 0]];
			}
		}
	}
	return [errorPos autorelease];
}

-(void)_correctErrorBit:(BoolVector*) y errorPos: (IntVector*) errorPos{
	int i, nc = [y get: 0];
	NSLog(@"Error Count: %d", nc);
	for (i = 1; i <= nc; i++){
		BOOL b = ![y get: [errorPos get: i]];
		NSLog(@"Error bit %d: %d", i, b);
		[y setValue: b at: [errorPos get: i]];
	}
	
	numCorrectedError = nc;
}

@end
