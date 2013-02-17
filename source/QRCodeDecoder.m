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
#import "ecc/ReedSolomon.h"
#import "Exceptions.h"
#import "QRCodeDecoder.h"
#import "QRCommon.h"
#import "reader/QRCodeDataBlockReader.h"

BOOL isUniCode(const char *str, int len){
	//TODO: detect unicode
	return false;
}

@interface DecodeResult : NSObject{
@public
	int numCorrections;
	BOOL correctionSucceeded;
	ByteVector* decodedBytes;
	QRCodeDecoder *enclosingInstance;
}
-(DecodeResult*)init: (QRCodeDecoder*)enclosing decoded: (ByteVector*) decoded numErrors: (int) numErrors succeeded: (BOOL) succeeded;
@end

@interface QRCodeDecoder (Private)
-(IntPointVector*)AdjustPoints;
-(DecodeResult*) decode: (QRCodeImage*) qrCodeImage adjust: (IntPoint) adjust;
-(IntMatrix*) imageToIntArray: (QRCodeImage*) image;
-(IntVector*) correctDataBlocks: (IntVector*) blocks;
-(ByteVector*) getDecodedByteArray: (IntVector*) blocks version: (int) version errors: (int) numErrorCorrectionCode;
-(NSString*) getDecodedString: (IntVector*) blocks version: (int) version errors: (int) numErrorCorrectionCode;
@end

@implementation QRCodeDecoder
-(QRCodeDecoder*)init{
	[super init];
	numTryDecode = 0;
	results = [[NSMutableArray alloc] init]; 
	return self;
}

-(ByteVector*) decodeBytes: (QRCodeImage*) qrCodeImage{
	IntPointVector *adjusts = [self AdjustPoints];
	NSMutableArray *nResults = [[NSMutableArray alloc] init];
	
	while (numTryDecode < [adjusts length]){
		@try{
			DecodeResult *result = [self decode: qrCodeImage adjust: [adjusts get: numTryDecode]];
			
			if (result->correctionSucceeded){
				return result->decodedBytes;
			}
			else{
				[nResults addObject: result];
				NSLog(@"Decoding succeeded but could not correct all errors. Retrying...");
			}
		}
		@catch (DecodingFailedException *dfe){
			if ([[dfe name] rangeOfString: @"Finder Pattern"].location != NSNotFound){
				@throw;
			}
		}
		@finally{
			numTryDecode += 1;
		}
		if (![imageReader hasSamplingGrid]){
			break;
		}
	}
	
	if ([nResults count] == 0){
		[nResults release];
		@throw [DecodingFailedException withMessage: @"Give up decoding"];
	}
	
	int lowestErrorIndex = -1, i;
	int lowestError = 0x7FFFFFFF;
	for (i = 0; i < [nResults count]; i++){
		DecodeResult *result = (DecodeResult*) [nResults objectAtIndex:i];
		if (result->numCorrections < lowestError){
			lowestError = result->numCorrections;
			lowestErrorIndex = i;
		}
	}
	NSLog(@"All trials need for correct error");
	NSLog(@"Reporting #%d that,",lowestErrorIndex);
	NSLog(@"corrected minimum errors (%d)", lowestError);
	
	NSLog(@"Decoding finished.");
	ByteVector *bv = ((DecodeResult*)[nResults objectAtIndex: lowestErrorIndex])->decodedBytes;
	[bv retain];
	[nResults release];
	return [bv autorelease];
}

-(NSString*) decode: (QRCodeImage*) qrCodeImage encoding: (NSStringEncoding) encoding{
	ByteVector *data = [self decodeBytes: qrCodeImage];
	return [[[NSString alloc] initWithBytes: [data asROArray] length: [data length] encoding: encoding] autorelease];
}

-(NSString*) decode: (QRCodeImage*) qrCodeImage{
	ByteVector *data = [self decodeBytes: qrCodeImage];
	
	if (isUniCode([data asROArray], [data length]) == YES){
		return [[[NSString alloc] initWithBytes: [data asROArray] length: [data length] encoding: NSUnicodeStringEncoding] autorelease];
	}
	else{
		return [[[NSString alloc] initWithBytes: [data asROArray] length: [data length] encoding: NSASCIIStringEncoding] autorelease];
	}
}

-(IntPointVector*)AdjustPoints{
	// note that adjusts affect dependently
	// i.e. below means (0,0), (2,3), (3,4), (1,2), (2,1), (1,1), (-1,-1)
	IntPointVector *adjustPoints = [[IntPointVector alloc] initWithLength: 4];
	int x, y;
	IntPoint defPoint = { 1, 1 };
	for (x = 0; x < 4; x++){
		[adjustPoints setValue: defPoint at: x];
	}
	
	int lastX = 0, lastY = 0;
	for (y = 0; y > - 4; y--){
		for (x = 0; x > - 4; x--){
			if (x != y && ((x + y) % 2 == 0)){
				defPoint.x = x - lastX;
				defPoint.y = y - lastY;
				[adjustPoints add: defPoint];
				lastX = x;
				lastY = y;
			}
		}
	}
	return [adjustPoints autorelease];
}

-(DecodeResult*) decode: (QRCodeImage*) qrCodeImage adjust: (IntPoint) adjust{
	@try{
		if (numTryDecode == 0){
			IntMatrix *intImage = [self imageToIntArray: qrCodeImage];
			imageReader = [[QRCodeImageReader alloc] initReader];
			qrCodeSymbol = [imageReader getQRCodeSymbol: intImage];
		}
		else{
			NSLog(@"Decoding restarted #%d", (numTryDecode));
			qrCodeSymbol = [imageReader getQRCodeSymbolWithAdjustedGrid: adjust];
		}
	}
	@catch (SymbolNotFoundException *e){
		@throw [DecodingFailedException withMessage: [e name]];
	}
	
	NSLog(@"Version: %@", [qrCodeSymbol VersionReference]);
	NSLog(@"Mask pattern: %@", [qrCodeSymbol MaskPatternRefererAsString]);
	
	// blocks contains all (data and RS) blocks in QR Code symbol
	IntVector *blocks = [qrCodeSymbol Blocks];
	NSLog(@"Correcting data errors.");
	// now blocks turn to data blocks (corrected and extracted from original blocks)
	blocks = [self correctDataBlocks: blocks];
	
	@try{
		ByteVector *decodedByteArray = [self getDecodedByteArray: blocks version: [qrCodeSymbol Version] errors: [qrCodeSymbol NumErrorCollectionCode]];
		return [[[DecodeResult alloc] init: self decoded: decodedByteArray numErrors: numLastCorrections succeeded: correctionSucceeded] autorelease];
	}
	@catch (InvalidDataBlockException *e){
		NSLog([e name]);
		@throw [DecodingFailedException withMessage: [e name]];
	}
	// Unnecessary except for the compiler warning.
	return nil;
}

-(IntMatrix*) imageToIntArray: (QRCodeImage*) image{
	int width = [image Width];
	int height = [image Height];
	
	IntMatrix *intImage = [[IntMatrix alloc] initWithWidth: width height: height];
	int x, y;
	for (y = 0; y < height; y++){
		for (x = 0; x < width; x++){
			int nValue = [image X:x Y:y];
			[intImage setValue: nValue X: x Y: y];
		}
	}
	return [intImage autorelease];
}

-(IntVector*) correctDataBlocks: (IntVector*) blocks{
	int numCorrections = 0;
	int dataCapacity = [qrCodeSymbol DataCapacity];
	
	int numErrorCollectionCode = [qrCodeSymbol NumErrorCollectionCode];
	int numRSBlocks = [qrCodeSymbol NumRSBlocks];
	int eccPerRSBlock = numErrorCollectionCode / (numRSBlocks?numRSBlocks:1);
	IntVector *dataBlocks = [[IntVector alloc] initWithLength: dataCapacity];
	
	if (numRSBlocks == 1){
		ReedSolomon *corrector = [[ReedSolomon alloc] initWithSource: blocks NPAR: eccPerRSBlock];
		[corrector autorelease];
		[corrector correct];
		numCorrections += [corrector NumCorrectedErrors];
		if (numCorrections > 0){
			NSLog(@"%d data errors corrected.", numCorrections);
		}
		else{
			NSLog(@"No errors found.");
		}
		numLastCorrections = numCorrections;
		correctionSucceeded = [corrector CorrectionSucceeded];
		return blocks;
	}
	else{
		//we have to interleave data blocks because symbol has 2 or more RS blocks
		int numLongerRSBlocks = dataCapacity % numRSBlocks;
		if (numLongerRSBlocks == 0){
			//symbol has only 1 type of RS block
			int lengthRSBlock = dataCapacity / numRSBlocks;
			IntMatrix *RSBlocks = [[IntMatrix alloc] initWithWidth: numRSBlocks height: lengthRSBlock];
			[RSBlocks autorelease];
			
			//obtain RS blocks
			int i, j;
			for (i = 0; i < numRSBlocks; i++){
				for (j = 0; j < lengthRSBlock; j++){
					[RSBlocks setValue: [blocks get: j*numRSBlocks+i] X: i Y: j];
				}
				IntVector *cvec = [RSBlocks column: i];
				ReedSolomon *corrector = [[ReedSolomon alloc] initWithSource: cvec NPAR: eccPerRSBlock];
				[corrector autorelease];
				[corrector correct];
				for (j = 0; j < lengthRSBlock; j++){
					[RSBlocks setValue: [cvec get: j] X: i Y: j];
				}
				numCorrections += [corrector NumCorrectedErrors];
				correctionSucceeded = [corrector CorrectionSucceeded];
			}
			//obtain only data part
			int p = 0;
			for (i = 0; i < numRSBlocks; i++){
				for (j = 0; j < lengthRSBlock - eccPerRSBlock; j++){
					[dataBlocks setValue: [RSBlocks X:i Y:j] at: p];
					p++;
				}
			}
		}
		else{
			//symbol has 2 types of RS blocks
			int lengthShorterRSBlock = dataCapacity / numRSBlocks;
			int lengthLongerRSBlock = dataCapacity / numRSBlocks + 1;
			int numShorterRSBlocks = numRSBlocks - numLongerRSBlocks;
			IntMatrix *shorterRSBlocks = [[IntMatrix alloc] initWithWidth: numShorterRSBlocks height: lengthShorterRSBlock];
			IntMatrix *longerRSBlocks = [[IntMatrix alloc] initWithWidth: numLongerRSBlocks height: lengthLongerRSBlock];
			[shorterRSBlocks autorelease];
			[longerRSBlocks autorelease];
			int i, j;
			for (i = 0; i < numRSBlocks; i++){
				if (i < numShorterRSBlocks){
					//get shorter RS Block(s)
					int mod = 0;
					for (j = 0; j < lengthShorterRSBlock; j++){
						if (j == lengthShorterRSBlock - eccPerRSBlock){
							mod = numLongerRSBlocks;
						}
						[shorterRSBlocks setValue: [blocks get: (j*numRSBlocks+i+mod)] X:i Y:j];
					}
					
					ReedSolomon *corrector = [[ReedSolomon alloc] initWithSource: [shorterRSBlocks column: i] NPAR: eccPerRSBlock];
					[corrector autorelease];
					[corrector correct];
					numCorrections += [corrector NumCorrectedErrors];
					correctionSucceeded = [corrector CorrectionSucceeded];
				}
				else{
					//get longer RS Blocks
					int mod = 0;
					for (j = 0; j < lengthLongerRSBlock; j++){
						if (j == lengthShorterRSBlock - eccPerRSBlock)
							mod = numShorterRSBlocks;
						[longerRSBlocks setValue: [blocks get:(j*numRSBlocks+i-mod)] X: (i - numShorterRSBlocks) Y:j];
					}
					
					ReedSolomon *corrector = [[ReedSolomon alloc] initWithSource: [longerRSBlocks column: i - numShorterRSBlocks] NPAR: eccPerRSBlock];
					[corrector autorelease];
					[corrector correct];
					numCorrections += [corrector NumCorrectedErrors];
					correctionSucceeded = [corrector CorrectionSucceeded];
				}
			}
			int p = 0;
			for (i = 0; i < numRSBlocks; i++){
				if (i < numShorterRSBlocks){
					for (j = 0; j < lengthShorterRSBlock - eccPerRSBlock; j++){
						if (dataBlocks == nil){
							dataBlocks = [[IntVector alloc] initWithLength: 1];
							[dataBlocks setValue: [shorterRSBlocks X:i Y:j] at: 0];
						}
						else{
							[dataBlocks add: [shorterRSBlocks X:i Y:j]];
						}
						p++;
					}
				}
				else{
					for (j = 0; j < lengthLongerRSBlock - eccPerRSBlock; j++){
						int v = [longerRSBlocks X:(i-numShorterRSBlocks) Y: j];
						if (dataBlocks == nil){
							dataBlocks = [[IntVector alloc] initWithLength: 1];
							[dataBlocks setValue: v at: 0];
						}
						else{
							[dataBlocks add: v];
						}
						p++;
					}
				}
			}
		}
		if (numCorrections > 0)
			NSLog(@"%d data errors corrected.", numCorrections);
		else
			NSLog(@"No errors found.");
		numLastCorrections = numCorrections;
		return [dataBlocks autorelease];
	}
}

-(ByteVector*) getDecodedByteArray: (IntVector*) blocks version: (int) version errors: (int) numErrorCorrectionCode{
	ByteVector *byteArray;
	QRCodeDataBlockReader *reader = [[QRCodeDataBlockReader alloc] initWithBlocks: blocks version: version code: numErrorCorrectionCode];
	
	[reader autorelease];
	
	@try{
		byteArray = [reader DataByte];
	}
	@catch (InvalidDataBlockException *e){
		@throw;
	}
	return byteArray;
}

-(NSString*) getDecodedString: (IntVector*) blocks version: (int) version errors: (int) numErrorCorrectionCode{
	QRCodeDataBlockReader *reader = [[QRCodeDataBlockReader alloc] initWithBlocks: blocks version: version code: numErrorCorrectionCode];
	[reader autorelease];
	NSString *dataString = nil;
	
	@try{
		dataString = [reader DataString];
	}
	@catch (IndexOutOfRangeException *e){
		@throw [InvalidDataBlockException withMessage: [e name]];
	}
	return dataString;
}
RETAIN_RELEASE(QRCodeDecoder)
@end

@implementation DecodeResult
-(DecodeResult*)init: (QRCodeDecoder*)enclosing decoded: (ByteVector*) decoded numErrors: (int) numErrors succeeded: (BOOL) succeeded{
	[super init];
	enclosingInstance = enclosing;
	decodedBytes = decoded;
	if (decodedBytes)
		[decodedBytes retain];
	correctionSucceeded = succeeded;
	return self;
}

-(void)dealloc{
	if (decodedBytes)
		[decodedBytes release];
	[super dealloc];
}

RETAIN_RELEASE(DecodeResult)
@end
