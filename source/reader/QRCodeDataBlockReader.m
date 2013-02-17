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
#import "../Exceptions.h"
#import "../QRCommon.h"
#import "QRCodeDataBlockReader.h"

static NSString* tableRomanAndFigure[] = {
	@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9",
	@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J",
	@"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T",
	@"U", @"V", @"W", @"X", @"Y", @"Z", @" ", @"$", @"%", @"*", 
@"+", @"-", @".", @"/", @":"};

@interface QRCodeDataBlockReader (Private)
-(int)NextMode;
-(int)getNextBits: (int) numBits;
-(int)guessMode: (int) mode;
-(int)getDataLength: (int) modeIndicator;
-(NSString*)getFigureString: (int) dataLength;
-(NSString*)getRomanAndFigureString: (int) dataLength;
@end

ByteVector* addToOutput(ByteVector* v, byte *b, int count){
	if (v == nil){
		v = [[ByteVector alloc] initWithBytes: b count: count];
	}
	else{
		[v appendBytes: b count: count];
	}
	return v;
}

@implementation QRCodeDataBlockReader

-(QRCodeDataBlockReader*) initWithBlocks: (IntVector*) blk version: (int) v code: (int) numECC{
	[super init];
	blockPointer = 0;
	bitPointer = 7;
	dataLength = 0;
	blocks = [blk retain];
	numErrorCorrectionCode = numECC;
	version = v;
	return self;
}

-(void)dealloc{
	[blocks release];
	[super dealloc];
}

-(ByteVector*)DataByte{
	ByteVector* output = nil;
	
	@try{
		do {
			int mode = [self NextMode];
			if (mode == 0){
				if (output && [output length] > 0){
					break;
				}
				else{
					NSException *ne = [InvalidDataBlockException withMessage: @"Empty data block"];
					@throw ne;
				}
			}
			if (mode != MODE_NUMBER && mode != MODE_ROMAN_AND_NUMBER && mode != MODE_8BIT_BYTE && mode != MODE_KANJI){
				NSException *ne = [InvalidDataBlockException withMessage: [NSString stringWithFormat: @"Invalid mode: %d in (block: %d bit: %d)", mode, blockPointer, bitPointer]];
				@throw ne;
			}
			dataLength = [self getDataLength: mode];
			if (dataLength < 1){
				NSException *ne = [InvalidDataBlockException withMessage: [NSString stringWithFormat: @"Invalid data length: %d", dataLength]];
				@throw ne;
			}
			NSLog(@"Mode %d Data Length: %d", mode, dataLength);
			switch (mode){
				case MODE_NUMBER: 
					NSLog(@"MODE NUMBER!");
					
					break;
					
				case MODE_ROMAN_AND_NUMBER: {
					NSString *str = [self getRomanAndFigureString: dataLength];
					NSData *nsdata = [str dataUsingEncoding: NSUTF8StringEncoding];
					if (output == nil){
						output = [[ByteVector alloc] initWithBytes: (byte*)[nsdata bytes] count: [nsdata length]];
					}
					else{
						[output appendBytes: (byte*)[nsdata bytes] count: [nsdata length]];
					}
				}
					break;
					
				case MODE_8BIT_BYTE: {
					ByteVector *bv = [self get8bitByteArray: dataLength];
					if (output != nil){
						[output appendBytes: [bv asROArray] count: [bv length]];
					}
					else{
						[bv retain]; // since they autoreleased it, and we will too, bump it up 1.
						output = bv;
					}
				}
					break;
					
				case MODE_KANJI: 
					NSLog(@"MODE KANJI!");
					/*
					 sbyte[] temp_sbyteArray4;
					 temp_sbyteArray4 = SystemUtils.ToSByteArray(SystemUtils.ToByteArray(getKanjiString(dataLength)));
					 output.Write(SystemUtils.ToByteArray(temp_sbyteArray4), 0, temp_sbyteArray4.Length);
					*/
					break;
			}
		}
		while (true);
	}
	@catch (NSException *ns){
		NSLog(@"Data read exception");
		@throw;
	}
	NSLog(@"Returning %d bytes", [output length]);
	if (output)
		return [output autorelease];
	else
		return nil;
}

-(NSString*)DataString{
	NSLog(@"Reading data blocks...");
	NSMutableString *dataString = [[NSMutableString alloc] init];
	
	do {
		int mode = [self NextMode];
		NSLog(@"mode: %d", mode);
		if (mode == 0){
			break;
		}
		
		dataLength = [self getDataLength: mode];
		NSLog(@"length: %d", dataLength);
		
		switch (mode){
			case MODE_NUMBER: 
				[dataString appendString: [self getFigureString: dataLength]];
				break;
				
			case MODE_ROMAN_AND_NUMBER: 
				[dataString appendString: [self getRomanAndFigureString: dataLength]];
				break;
				
			case MODE_8BIT_BYTE: 
				[dataString appendString: [self get8bitByteString: dataLength]];
				break;
				
			case MODE_KANJI: 
				[dataString appendString: [self getKanjiString: dataLength]];
				break;
		}
	}
	while (true);
	NSLog(@"Done reading data blocks.");
	return dataString;
}

-(ByteVector*)get8bitByteArray: (int) length{
	int intData = 0;
	ByteVector *output = nil;
	
	do {
		intData = [self getNextBits: 8];
		byte b = (byte) intData;
		output = addToOutput(output, &b, 1);
		length--;
	}
	while (length > 0);
	return [output autorelease];
}

-(NSString*)get8bitByteString: (int) length{
	ByteVector* b = [self get8bitByteArray: length];
	NSString* strData = [[NSString alloc] initWithBytes: [b asROArray] length: [b length] encoding: NSISOLatin1StringEncoding];
	[b release];
	return [strData autorelease];
}

-(NSString*)getKanjiString: (int) length{
	int intData = 0;
	NSMutableString* unicodeString = [[NSMutableString alloc] init];
	do {
		intData = [self getNextBits: 13];
		int lowerByte = intData % 0xC0;
		int higherByte = intData / 0xC0;
		
		int tempWord = (higherByte << 8) + lowerByte;
		int shiftjisWord = 0;
		if (tempWord + 0x8140 <= 0x9FFC){
			// between 8140 - 9FFC on Shift_JIS character set
			shiftjisWord = tempWord + 0x8140;
		}
		else{
			// between E040 - EBBF on Shift_JIS character set
			shiftjisWord = tempWord + 0xC140;
		}
		
		byte tempByte[2];
		tempByte[0] = (byte) (shiftjisWord >> 8);
		tempByte[1] = (byte) (shiftjisWord & 0xFF);
		NSString *ns = [[NSString alloc] initWithBytes: tempByte length: 2 encoding: NSShiftJISStringEncoding];
		[unicodeString appendString: ns];
		length--;
	}
	while (length > 0);
	
	return [unicodeString autorelease];
}

-(int)NextMode{
	if ((blockPointer > [blocks length] - numErrorCorrectionCode - 2))
		return 0;
	else
		return [self getNextBits: 4];
}

-(int)getNextBits: (int) numBits{
	int bits = 0, i;
	if (numBits < bitPointer + 1){
		// next word fits into current data block
		int mask = 0;
		for (i = 0; i < numBits; i++){
			mask += (1 << i);
		}
		mask <<= (bitPointer - numBits + 1);
		
		bits = ([blocks get:blockPointer] & mask) >> (bitPointer - numBits + 1);
		bitPointer -= numBits;
		return bits;
	}
	else if (numBits < bitPointer + 1 + 8){
		// next word crosses 2 data blocks
		int mask1 = 0;
		for (i = 0; i < bitPointer + 1; i++){
			mask1 += (1 << i);
		}
		bits = ([blocks get:blockPointer] & mask1) << (numBits - (bitPointer + 1));
		blockPointer++;
		bits += [blocks get:blockPointer] >> (8 - (numBits - (bitPointer + 1)));
		
		bitPointer = bitPointer - numBits % 8;
		if (bitPointer < 0){
			bitPointer = 8 + bitPointer;
		}
		return bits;
	}
	else if (numBits < bitPointer + 1 + 16){
		// next word crosses 3 data blocks
		int mask1 = 0; // mask of first block
		int mask3 = 0; // mask of 3rd block
		//bitPointer + 1 : number of bits of the 1st block
		//8 : number of the 2nd block (note that use already 8bits because next word uses 3 data blocks)
		//numBits - (bitPointer + 1 + 8) : number of bits of the 3rd block 
		for (i = 0; i < bitPointer + 1; i++){
			mask1 += (1 << i);
		}
		int bitsFirstBlock = ([blocks get:blockPointer] & mask1) << (numBits - (bitPointer + 1));
		blockPointer++;
		
		int bitsSecondBlock = [blocks get: blockPointer] << (numBits - (bitPointer + 1 + 8));
		blockPointer++;
		
		for (i = 0; i < numBits - (bitPointer + 1 + 8); i++){
			mask3 += (1 << i);
		}
		mask3 <<= 8 - (numBits - (bitPointer + 1 + 8));
		int bitsThirdBlock = ([blocks get:blockPointer] & mask3) >> (8 - (numBits - (bitPointer + 1 + 8)));
		
		bits = bitsFirstBlock + bitsSecondBlock + bitsThirdBlock;
		bitPointer = bitPointer - (numBits - 8) % 8;
		if (bitPointer < 0){
			bitPointer = 8 + bitPointer;
		}
		return bits;
	}
	else{
		NSLog(@"error in getNextBits");
		return 0;
	}
}

-(int)guessMode: (int) mode{
	//correct modes: 0001 0010 0100 1000
	//possible data: 0000 0011 0101 1001 0110 1010 1100
	// 0111 1101 1011 1110 1111
	//		MODE_NUMBER = 1;
	//		MODE_ROMAN_AND_NUMBER = 2;
	//		MODE_8BIT_BYTE = 4;
	//		MODE_KANJI = 8;
	switch (mode){
		case 3: 
			return MODE_NUMBER;
			
		case 5: 
			return MODE_8BIT_BYTE;
			
		case 6: 
			return MODE_8BIT_BYTE;
			
		case 7: 
			return MODE_8BIT_BYTE;
			
		case 9: 
			return MODE_KANJI;
			
		case 10: 
			return MODE_KANJI;
			
		case 11: 
			return MODE_KANJI;
			
		case 12: 
			return MODE_8BIT_BYTE;
			
		case 13: 
			return MODE_8BIT_BYTE;
			
		case 14: 
			return MODE_8BIT_BYTE;
			
		case 15: 
			return MODE_8BIT_BYTE;
			
		default: 
			return MODE_KANJI; 
	}
}

-(int)getDataLength: (int) mode{
	switch(mode){
		case 1: // '\001'
			if(version <= 9)
				return [self getNextBits:10];
			if(version >= 10 && version <= 26)
				return [self getNextBits:12];
			// fall through
			
			case 2: // '\002'
			if(version <= 9)
				return [self getNextBits:9];
			if(version >= 10 && version <= 26)
				return [self getNextBits:11];
			// fall through
			
			case 4: // '\004'
			if(version <= 9)
				return [self getNextBits:8];
			if(version >= 10 && version <= 26)
				return [self getNextBits:16];
			// fall through
			
			case 8: // '\b'
			if(version <= 9)
				return [self getNextBits:8];
			if(version >= 10 && version <= 26)
				return [self getNextBits:10];
			// fall through
			
			case 3: // '\003'
			case 5: // '\005'
			case 6: // '\006'
			case 7: // '\007'
			default:
			return 0;
	}
}

-(NSString*)getFigureString: (int) length{
	int intData = 0;
	NSMutableString* strData = [[NSMutableString alloc] init];
	
	do {
		if (length >= 3){
			intData = [self getNextBits: 10];
			if (intData < 100)
				[strData appendString: @"0"];
			if (intData < 10)
				[strData appendString: @"0"];
			length -= 3;
		}
		else if (length == 2){
			intData = [self getNextBits: 7];
			if (intData < 10)
				[strData appendString: @"0"];
			length -= 2;
		}
		else if (length == 1){
			intData = [self getNextBits:4];
			length -= 1;
		}
		[strData appendFormat: @"%d", intData];
	}
	while (length > 0);
	
	return [strData autorelease];
}

-(NSString*)getRomanAndFigureString: (int) length{
	int intData = 0;
	NSMutableString* strData = [[NSMutableString alloc] init];
	
	do {
		if (length > 1){
			intData = [self getNextBits: 11];
			int firstLetter = intData / 45;
			int secondLetter = intData % 45;
			[strData appendString: tableRomanAndFigure[firstLetter]];
			[strData appendString: tableRomanAndFigure[secondLetter]];
			length -= 2;
		}
		else if (length == 1){
			intData = [self getNextBits: 6];
			[strData appendString: tableRomanAndFigure[intData]];
			length -= 1;
		}
	}
	while (length > 0);
	
	return [strData autorelease];
}

RETAIN_RELEASE(QRCodeDataBlockReader)
@end
