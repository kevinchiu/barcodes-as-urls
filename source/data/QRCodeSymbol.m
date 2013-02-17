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
#import "../ecc/BCH15_5.h"
#import "../reader/pattern/LogicalSeed.h"
#import "QRCodeSymbol.h"

static int numErrorCollectionCode[40][4] =
{ { 7, 10, 13, 17 }, { 10, 16, 22, 28 }, { 15, 26, 36, 44 }, 
	{ 20, 36, 52, 64 }, { 26, 48, 72, 88 }, { 36, 64, 96, 112 }, 
	{ 40, 72, 108, 130 }, { 48, 88, 132, 156 }, { 60, 110, 160, 192 }, 
	{ 72, 130, 192, 224 }, { 80, 150, 224, 264 }, { 96, 176, 260, 308 }, 
	{ 104, 198, 288, 352 }, { 120, 216, 320, 384 }, { 132, 240, 360, 432 }, 
	{ 144, 280, 408, 480 }, { 168, 308, 448, 532 }, { 180, 338, 504, 588 },
	{ 196, 364, 546, 650 }, { 224, 416, 600, 700 }, { 224, 442, 644, 750 }, 
	{ 252, 476, 690, 816 }, { 270, 504, 750, 900 }, { 300, 560, 810, 960 }, 
	{ 312, 588, 870, 1050 }, { 336, 644, 952, 1110 }, { 360, 700, 1020, 1200 }, 
	{ 390, 728, 1050, 1260 }, { 420, 784, 1140, 1350 }, { 450, 812, 1200, 1440 },
	{ 480, 868, 1290, 1530 }, { 510, 924, 1350, 1620 }, { 540, 980, 1440, 1710 }, 
	{ 570, 1036, 1530, 1800 }, { 570, 1064, 1590, 1890 }, { 600, 1120, 1680, 1980 }, 
	{ 630, 1204, 1770, 2100 }, { 660, 1260, 1860, 2220 }, { 720, 1316, 1950, 2310 }, 
	{ 750, 1372, 2040, 2430 } };

static int numRSBlocks[40][4] =
{ { 1, 1, 1, 1 }, { 1, 1, 1, 1 }, { 1, 1, 2, 2 }, { 1, 2, 2, 4 }, 
	{ 1, 2, 4, 4 }, { 2, 4, 4, 4 }, { 2, 4, 6, 5 }, { 2, 4, 6, 6 }, 
	{ 2, 5, 8, 8 }, { 4, 5, 8, 8 }, { 4, 5, 8, 11 }, { 4, 8, 10, 11 }, 
	{ 4, 9, 12, 16 }, { 4, 9, 16, 16 }, { 6, 10, 12, 18 }, { 6, 10, 17, 16 }, 
	{ 6, 11, 16, 19 }, { 6, 13, 18, 21 }, { 7, 14, 21, 25 }, { 8, 16, 20, 25 }, 
	{ 8, 17, 23, 25 }, { 9, 17, 23, 34 }, { 9, 18, 25, 30 }, { 10, 20, 27, 32 },
	{ 12, 21, 29, 35 }, { 12, 23, 34, 37 }, { 12, 25, 34, 40 }, { 13, 26, 35, 42 },
	{ 14, 28, 38, 45 }, { 15, 29, 40, 48 }, { 16, 31, 43, 51 }, { 17, 33, 45, 54 },
	{ 18, 35, 48, 57 }, { 19, 37, 51, 60 }, { 19, 38, 53, 63 }, { 20, 40, 56, 66 },
	{ 21, 43, 59, 70 }, { 22, 45, 62, 74 }, { 24, 47, 65, 77 }, { 25, 49, 68, 81 } };

static char versionReferenceCharacter[] = {'L', 'M', 'Q', 'H'};

int URShift(int number, int bits){
	if (number >= 0)
		return number >> bits;
	else
		return (number >> bits) + (2 << ~bits);
}

@interface QRCodeSymbol (Private)
-(void)initialize;
-(BoolVector*)readFormatInformation;
-(void)unmask;
-(BoolMatrix*)generateMaskPattern;
-(int)calcDataCapacity;
-(void)decodeFormatInformation: (BoolVector*)formatInformation;
@end

@implementation QRCodeSymbol

-(QRCodeSymbol*) initWithModuleMatrix: (BoolMatrix*) matrix;{
	[super init];
	moduleMatrix = matrix;
	[matrix retain];
	width = [matrix width];
	height = [matrix height];
	[self initialize];
	return self;
}

-(void)dealloc{
	[moduleMatrix release];
	[alignmentPattern release];
	[super dealloc];
}

-(int)NumErrorCollectionCode { return numErrorCollectionCode[version - 1][errorCollectionLevel]; }
-(int)NumRSBlocks { return numRSBlocks[version-1][errorCollectionLevel]; }
-(int)Version { return version; }
-(NSString*)VersionReference{
	return [NSString stringWithFormat: @"%d-%c", version, versionReferenceCharacter[errorCollectionLevel]];
}
-(IntPointMatrix*)AlignmentPattern { return alignmentPattern; }
-(int)DataCapacity { return dataCapacity; }
-(int)ErrorCollectionLevel { return errorCollectionLevel; }
-(int)MaskPatternReferer { return maskPattern; }
-(NSString*)MaskPatternRefererAsString{
	return [NSString stringWithFormat: @"Octal: %o", maskPattern];
}
-(int)Width { return width; }
-(int)Height { return width; }

-(IntVector*)Blocks{
	int x = width - 1;
	int y = height - 1;
	
	BoolVector *codeBits = nil;
	IntVector *codeWords = nil;
	
	int tempWord = 0;
	int figure = 7;
	int isNearFinish = 0;
	BOOL READ_UP = YES;
	BOOL READ_DOWN = NO;
	BOOL direction = READ_UP;
	
	int x1,y1,s=0,rs=0;
	for (y1 = 0; y1 < height; y1++){
		rs = 0;
		for (x1 = 0; x1 < width; x1++){
			if ([moduleMatrix X: x1 Y: y1]){
				s++;
				rs++;
			}
		}
	}
	do {
		if (!codeBits){
			codeBits = [[BoolVector alloc] initWithLength: 1];
			[codeBits setValue: [moduleMatrix X: x Y: y] at: 0];
		}
		else{
			[codeBits add: [moduleMatrix X: x Y: y]];
		}
		if ([moduleMatrix X:x Y:y] == YES){
			tempWord += (1 << figure);
		}
		figure--;
		if (figure == - 1){
			if (!codeWords){
				codeWords = [[IntVector alloc] initWithLength: 1];
				[codeWords setValue: tempWord at: 0];
			}
			else{
				[codeWords add: tempWord];
			}
			figure = 7;
			tempWord = 0;
		}
		// determine module that read next
		do {
			if (direction == READ_UP){
				if ((x + isNearFinish) % 2 == 0){
					//if right side of two column
					x--;
				}
				// to left
				else{
					if (y > 0){
						//be able to move upper side
						x++;
						y--;
					}
					else{
						//can't move upper side
						x--; //change direction
						if (x == 6){
							x--;
							isNearFinish = 1; // after through horizontal Timing Pattern, move pattern is changed
						}
						direction = READ_DOWN;
					}
				}
			}
			else{
				if ((x + isNearFinish) % 2 == 0){
					//if left side of two column
					x--;
				}
				else{
					if (y < height - 1){
						x++;
						y++;
					}
					else{
						x--;
						if (x == 6){
							x--;
							isNearFinish = 1;
						}
						direction = READ_UP;
					}
				}
			}
		}
		while ([self isInFunctionPatternAtX: x Y: y]);
	}
	while (x != - 1);
	
	if (codeBits)
		[codeBits release];
	if (codeWords)
		return [codeWords autorelease];
	return nil;
}

-(BOOL)getElementAtX: (int) x Y: (int) y{
	return [moduleMatrix X: x Y: y];
}

-(void)initialize{
	//calculate version by number of side modules
	version = (width - 17) / 4;
	
	IntVector *logicalSeeds;
	if (version >= 2 && version <= 40){
		logicalSeeds = [LogicalSeed getSeed: version];
		alignmentPattern = [[IntPointMatrix alloc] initWithWidth: [logicalSeeds length] height: [logicalSeeds length]];
	}
	else{
		logicalSeeds = [[IntVector alloc] initWithLength: 1];
		alignmentPattern = [[IntPointMatrix alloc] initWithWidth: 1 height: 1];
	}
	
	int lsLen = [logicalSeeds length];
	//obtain alignment pattern's center coodintates by logical seeds
	int col, row;
	
	for (col = 0 ; col < lsLen; col++){
		for (row = 0; row < lsLen; row++){
			IntPoint np = { [logicalSeeds get:row], [logicalSeeds get:col] };
			[alignmentPattern setValue: np X:row Y:col];
		}
	}
	
	dataCapacity = [self calcDataCapacity];
	BoolVector *formatInformation = [self readFormatInformation];
	[self decodeFormatInformation: formatInformation];
	[self unmask];
}

-(BoolVector*)readFormatInformation{
	BoolVector* modules = [[BoolVector alloc] initWithLength: 15];
	
	//obtain format information from symbol
	int i;
	for (i = 0; i <= 5; i++){
		[modules setValue: [moduleMatrix X: 8 Y: i] at: i];
	}
	
	[modules setValue: [moduleMatrix X: 8 Y: 7] at: 6];
	[modules setValue: [moduleMatrix X: 8 Y: 8] at: 7];
	[modules setValue: [moduleMatrix X: 7 Y: 8] at: 8];
	
	for (i = 9; i <= 14; i++){
		[modules setValue: [moduleMatrix X: 14 - i Y: 8] at: i];
	}
	
	//unmask Format Information's with given mask pattern. (JIS-X-0510(2004), p65)
	int cmaskPattern = 0x5412;
	
	for (i = 0; i <= 14; i++){
		BOOL xorBit = NO;
		if (((URShift(cmaskPattern, i)) & 1) == 1){
			xorBit = YES;
		}
		else{
			xorBit = NO;
		}
		
		// get unmasked format information with bit shift
		if ([modules get:i] == xorBit){
			[modules setValue: NO at: i];
		}
		else{
			[modules setValue: YES at: i];
		}
	}
	
	BCH15_5 *corrector = [[BCH15_5 alloc] initWithVector: modules];
	BoolVector *output = [corrector correct];
	BoolVector *formatInformation = [[BoolVector alloc] initWithLength: 5];
	for (i = 0; i < 5; i++){
		[formatInformation setValue: [output get: 10 + i] at: i];
	}
	
	[corrector release];
	[modules release];
	return [formatInformation autorelease];
}

-(void)unmask{
	BoolMatrix *bmaskPattern = [self generateMaskPattern];
	
	int size = width, y, x;
	
	for (y = 0; y < size; y++){
		for (x = 0; x < size; x++){
			if ([bmaskPattern X:x Y:y] == YES){
				[self reverseElementAtX: x Y: y];
			}
		}
	}
}

-(BoolMatrix*)generateMaskPattern{
	int maskPatternReferer = maskPattern, x, y;
	
	BoolMatrix *bmaskPattern = [[BoolMatrix alloc] initWithWidth: width height: height];
	
	for (y = 0; y < height; y++){
		for (x = 0; x < width; x++){
			if ([self isInFunctionPatternAtX: x Y:y]){
				continue;
			}
			switch (maskPatternReferer){
				case 0: // 000
					if ((y + x) % 2 == 0){
						[bmaskPattern setValue: YES X:x Y:y];
					}
					break;
					
					case 1: // 001
					if (y % 2 == 0){
						[bmaskPattern setValue: YES X: x Y:y];
					}
					break;
					
					case 2: // 010
					if (x % 3 == 0)
						[bmaskPattern setValue: YES X: x Y:y];
					break;
					
					case 3: // 011
					if ((y + x) % 3 == 0)
						[bmaskPattern setValue: YES X: x Y:y];
					break;
					
					case 4: // 100
					if ((y / 2 + x / 3) % 2 == 0)
						[bmaskPattern setValue: YES X: x Y:y];
					break;
					
					case 5: // 101
					if ((y * x) % 2 + (y * x) % 3 == 0)
						[bmaskPattern setValue: YES X: x Y:y];
					break;
					
					case 6: // 110
					if (((y * x) % 2 + (y * x) % 3) % 2 == 0)
						[bmaskPattern setValue: YES X: x Y:y];
					break;
					
					case 7: // 111
					if (((y * x) % 3 + (y + x) % 2) % 2 == 0)
						[bmaskPattern setValue: YES X: x Y:y];
					break;
			}
		}
	}
	return [bmaskPattern autorelease];
}

-(int)calcDataCapacity{
	int numFunctionPatternModule = 0;
	int numFormatAndVersionInfoModule = 0;
	
	if (version <= 6){
		numFormatAndVersionInfoModule = 31;
	}
	else{
		numFormatAndVersionInfoModule = 67;
	}
	
	// the number of finder patterns :
	int sqrtCenters = (version / 7) + 2;
	// the number of modules left when we remove the patterns modules
	// 3*64 for the 3 big ones,
	// sqrtCenters*sqrtCenters)-3)*25 for the small ones
	int modulesLeft = (version == 1?192:192 + ((sqrtCenters * sqrtCenters) - 3) * 25);
	
	numFunctionPatternModule = modulesLeft + 8 * version + 2 - (sqrtCenters - 2) * 10;			
	int _dataCapacity = (width * width - numFunctionPatternModule - numFormatAndVersionInfoModule) / 8;
	return _dataCapacity;
}

-(void)decodeFormatInformation: (BoolVector*)formatInformation{
	if ([formatInformation get: 4] == NO)
		if ([formatInformation get: 3] == YES)
			errorCollectionLevel = 0;
		else
			errorCollectionLevel = 1;
		else if ([formatInformation get:3] == YES)
			errorCollectionLevel = 2;
		else
			errorCollectionLevel = 3;
	
	int i;
	for (i = 2; i >= 0; i--){
		if ([formatInformation get:i] == YES){
			maskPattern += (1 << i);
		}
	}
}

-(void)reverseElementAtX: (int) x Y: (int) y{
	[moduleMatrix setValue: ![moduleMatrix X: x Y: y] X: x Y: y];
}

-(BOOL)isInFunctionPatternAtX: (int) targetX Y: (int) targetY{
	if (targetX < 9 && targetY < 9){
		//in Left-Up Finder Pattern or function patterns around it
		return YES;
	}
	if (targetX > width - 9 && targetY < 9){
		//in Right-up Finder Pattern or function patterns around it
		return YES;
	}
	if (targetX < 9 && targetY > height - 9){
		//in Left-bottom Finder Pattern or function patterns around it
		return YES;
	}
	
	if (version >= 7){
		if (targetX > width - 12 && targetY < 6)
			return YES;
		if (targetX < 6 && targetY > height - 12)
			return YES;
	}
	// in timing pattern
	if (targetX == 6 || targetY == 6)
		return YES;
	
	// in alignment pattern.
	int sideLength = [alignmentPattern width], x, y;
	
	for (y = 0; y < sideLength; y++){
		for (x = 0; x < sideLength; x++){
			if (!(x == 0 && y == 0) && !(x == sideLength - 1 && y == 0) && !(x == 0 && y == sideLength - 1))
				if (abs([alignmentPattern X:x Y:y].x - targetX) < 3 && abs([alignmentPattern X:x Y:y].y - targetY) < 3)
					return YES;
		}
	}
	return NO;
}

@end
