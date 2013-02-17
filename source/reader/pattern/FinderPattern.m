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
#import "../../Exceptions.h"
#import "../../geom/Axis.h"
#import "../../geom/IntPointHelper.h"
#import "../../QRCommon.h"
#import "../QRCodeImageReader.h"
#import "FinderPattern.h"

static int VersionInfoBit[] = { 
	0x07C94, 0x085BC, 0x09A99, 0x0A4D3, 0x0BBF6, 0x0C762, 0x0D847, 0x0E60D, 
	0x0F928, 0x10B78, 0x1145D, 0x12A17, 0x13532, 0x149A6, 0x15683, 0x168C9, 
	0x177EC, 0x18EC4, 0x191E1, 0x1AFAB, 0x1B08E, 0x1CC1A, 0x1D33F, 0x1ED75, 
	0x1F250, 0x209D5, 0x216F0, 0x228BA, 0x2379F, 0x24B0B, 0x2542E, 0x26A64, 
0x27541, 0x28C69 };
#define VIBLEN 34

@interface FinderPattern (Private)
-(FinderPattern*)initWithCenter: (IntPointVector*) center version: (int) version sincos: (IntVector*) sincos width: (IntVector*) width moduleSize: (int) moduleSize;
+(NSArray*)findLineAcross: (BoolMatrix*) image;
+(NSArray*)findLineCross: (NSArray*) lineAcross;
+(BOOL)checkPattern: (int*) buffer pointer: (int) pointer;
+(BOOL)cantNeighbor: (QRLine*) line1 line2: (QRLine*) line2;
+(IntVector*)getAngle: (IntPointVector*) centers;
+(IntPointVector*)getCenter: (NSArray*) crossLines;
+(IntPointVector*)sort: (IntPointVector*) centers angle: (IntVector*)angle;
+(int)getURQuadant: (IntVector*) angle;
+(IntPoint)getPointAtSide: (IntPointVector*) points side1: (int) side1 side2: (int) side2;
+(IntVector*)getWidth: (BoolMatrix*) image centers: (IntPointVector*) centers sincos: (IntVector*) sincos;
+(int)calcRoughVersion: (IntPointVector*) center width: (IntVector*) width;
+(int)calcExactVersion: (IntPointVector*) center angle: (IntVector*) angle moduleSize: (const int*) moduleSize image: (BoolMatrix*) image;
+(int)checkVersionInfo: (BOOL*) target;
@end

@implementation FinderPattern
+(FinderPattern*)findFinderPattern: (BoolMatrix*) image{
	NSArray *lineAcross = [self findLineAcross: image];
	NSArray *lineCross = [self findLineCross: lineAcross];
	
	IntPointVector *center = nil;
	@try{
		center = [self getCenter: lineCross];
	}
	@catch (FinderPatternNotFoundException *e){
		@throw;
	}
	
	IntVector* sincos = [self getAngle: center];
	center = [self sort: center angle: sincos];
	IntVector *width = [self getWidth: image centers: center sincos: sincos];
	
	// moduleSize for version recognition
	int _moduleSize[2];
	int dp = [QRCodeImageReader DECIMAL_POINT];
	_moduleSize[0] = ([width get:FP_UR] << dp) / 7;
	_moduleSize[1] = ([width get:FP_DL] << dp) / 7;
	
	int version = [self calcRoughVersion: center width: width];
	NSLog(@"Rough version: %d", version);
	if (version > 6){
		@try{
			version = [self calcExactVersion: center angle: sincos moduleSize: _moduleSize image: image];
		}
		@catch (VersionInformationException *e){
			NSLog(@"Exact version failed, using rough version.");
			//use rough version data
			// throw e;
		}
	}
	return [[[FinderPattern alloc] initWithCenter: center version: version sincos: sincos width: width moduleSize: _moduleSize[0]] autorelease];
}

-(int)Version{
	return version;
}

-(int)SqrtNumModules{
	return 17 + 4 * version;
}

-(IntPointVector*)getCenter{
	return center;
}

-(IntPoint)getCenter: (int) position{
	if (position >= FP_UL && position <= FP_DL){
		return [center get: position];
	}
	else{
		IntPoint p = { 0, 0 };
		return p;
	}
}

-(int)getWidth: (int) position{
	return [width get: position];
}

-(IntVector*)getAngle{
	return sincos;
}

-(int)getModuleSize{
	return moduleSize;
}

-(FinderPattern*)initWithCenter: (IntPointVector*) c version: (int) v sincos: (IntVector*) sc width: (IntVector*) w moduleSize: (int) ms{
	[super init];
	center = [c retain];
	version = v;
	sincos = [sc retain];
	width = [w retain];
	moduleSize = ms;
	return self;
}

-(void)dealloc{
	[center release];
	[sincos release];
	[width release];
	[super dealloc];
}

+(NSArray*)findLineAcross: (BoolMatrix*) image{
	int READ_HORIZONTAL = 0;
	int READ_VERTICAL = 1;
	
	int imageWidth = [image width];
	int imageHeight = [image height];
	
	IntPoint current = { 0, 0 };
	NSMutableArray* lineAcross = [[NSMutableArray alloc] init];
	
	//buffer contains recent length of modules which has same brightness
	int lengthBuffer[5];
	int bufferPointer = 0;
	
	int direction = READ_HORIZONTAL; //start to read horizontally
	BOOL lastElement = POINT_LIGHT;
	
	while (true){
		//check points in image
		BOOL currentElement = [image X: current.x Y: current.y];
		if (currentElement == lastElement){
			//target point has same brightness with last point
			lengthBuffer[bufferPointer]++;
		}
		else{
			//target point has different brightness with last point
			if (currentElement == POINT_LIGHT && [self checkPattern: lengthBuffer pointer: bufferPointer]){
				//detected pattern
				int x1, y1, x2, y2, j;
				if (direction == READ_HORIZONTAL){
					//obtain X coordinates of both side of the detected horizontal pattern
					x1 = current.x;
					for (j = 0; j < 5; j++){
						x1 -= lengthBuffer[j];
					}
					x2 = current.x - 1; //right side is last X coordinate
					y1 = y2 = current.y;
				}
				else{
					x1 = x2 = current.x;
					//obtain Y coordinates of both side of the detected vertical pattern
					// upper side is sum of length of buffer
					y1 = current.y;
					for (j = 0; j < 5; j++){
						y1 -= lengthBuffer[j];
					}
					y2 = current.y - 1; // bottom side is last Y coordinate
				}
				QRLine* nln = [[QRLine alloc] initWithX1: x1 Y1: y1 X2: x2 Y2: y2];
				[lineAcross addObject: nln];
				[nln release];
			}
			bufferPointer = (bufferPointer + 1) % 5;
			lengthBuffer[bufferPointer] = 1;
			lastElement = !lastElement;
		}
		
		// determine if read next, change read direction or terminate this loop
		if (direction == READ_HORIZONTAL){
			if (current.x < imageWidth - 1){
				current.x++;
			}
			else if (current.y < imageHeight - 1){
				current.x = 0;
				current.y ++;
				memset(lengthBuffer, 0, 5*sizeof(int));
			}
			else{
				current.x = 0;
				current.y = 0;
				memset(lengthBuffer, 0, 5*sizeof(int));
				direction = READ_VERTICAL; //start to read vertically
			}
			continue;
		}
		
		//reading vertically
		if (current.y < imageHeight - 1){
			current.y++;
			continue;
		}
		if (current.x >= imageWidth - 1)
			break; 
		current.x ++;
		current.y = 0;
		memset(lengthBuffer, 0, 5*sizeof(int));
	}
	
	return [lineAcross autorelease];
}

+(NSArray*)findLineCross: (NSArray*) lineAcross{
	NSMutableArray* crossLines = [[NSMutableArray alloc] init];
	NSMutableArray* lineNeighbor = [[NSMutableArray alloc] init];
	NSMutableArray* lineCandidate = [[NSMutableArray alloc] init];
	
	QRLine *compareLine;
	int i, j, k;
	for (i = 0; i < [lineAcross count]; i++){
		[lineCandidate addObject: [lineAcross objectAtIndex: i]];
	}
	
	for (i = 0; i < [lineCandidate count] - 1; i++){
		[lineNeighbor removeAllObjects];
		[lineNeighbor addObject: [lineCandidate objectAtIndex: i]];
		
		for (j = i + 1; j < [lineCandidate count]; j++){
			QRLine* l1 = [lineNeighbor objectAtIndex: [lineNeighbor count] - 1];
			if ([l1 isNeighbor: [lineCandidate objectAtIndex: j]]){
				[lineNeighbor addObject: [lineCandidate objectAtIndex: j]];
				compareLine = [lineNeighbor objectAtIndex: [lineNeighbor count] - 1];
				
				if ([lineNeighbor count] * 5 > [compareLine Length] && j == [lineCandidate count] - 1){
					[crossLines addObject: [lineNeighbor objectAtIndex: [lineNeighbor count] / 2]];
					for (k = 0; k < [lineNeighbor count]; k++){
						[lineCandidate removeObject: [lineNeighbor objectAtIndex:k]];
					}
				}
			}	 
			//terminate comparison if there are no possibility for found neighbour lines
			else if ([self cantNeighbor: [lineNeighbor objectAtIndex: [lineNeighbor count] - 1] line2: [lineCandidate objectAtIndex: j]] || 
					 (j == [lineCandidate count] - 1)){
				compareLine = [lineNeighbor objectAtIndex: [lineNeighbor count] - 1];
				/*
				 * determine lines across Finder Patterns when number of neighbour lines are 
				 * bigger than 1/6 length of theirselves
				*/
				if ([lineNeighbor count] * 6 > [compareLine Length]){
					[crossLines addObject: [lineNeighbor objectAtIndex: [lineNeighbor count] / 2]];
					for (k = 0; k < [lineNeighbor count]; k++){
						[lineCandidate removeObject: [lineNeighbor objectAtIndex: k]];
					}
				}
				break;
			}
		}
	}
	[lineNeighbor release];
	[lineCandidate release];
	/*
	 int jk;
	 for (jk = 0; jk < [crossLines count]; jk++){
	 QRLine *qr = [crossLines objectAtIndex: jk];
	 NSLog(@"Line %d: (%d, %d) (%d, %d)", jk, [qr getP1].x, [qr getP1].y, [qr getP2].x, [qr getP2].y);
	 }
	*/
	return [crossLines autorelease];
}

+(BOOL)checkPattern: (int*) buffer pointer: (int) pointer{
	int modelRatio[5] = {1, 1, 3, 1, 1};
	
	int baselength = 0, i;
	for (i = 0; i < 5; i++){
		baselength += buffer[i];
	}
	// pseudo fixed point calculation. I think it needs smarter code
	baselength <<= [QRCodeImageReader DECIMAL_POINT];
	baselength /= 7;
	
	for (i = 0; i < 5; i++){
		int leastlength = baselength * modelRatio[i] - baselength / 2;
		int mostlength = baselength * modelRatio[i] + baselength / 2;
		
		leastlength -= baselength/8;
		mostlength += baselength/8;
		
		int targetlength = buffer[(pointer + i + 1) % 5] << [QRCodeImageReader DECIMAL_POINT];
		if (targetlength < leastlength || targetlength > mostlength){
			return NO;
		}
	}
	return YES;
}

+(BOOL)cantNeighbor: (QRLine*) line1 line2: (QRLine*) line2{
	if ([line1 isCross: line2]){
		return YES;
	}
	
	if ([line1 Horizontal]){
		if (abs([line1 getP1].y - [line2 getP1].y) > 1)
			return YES;
		else
			return NO;
	}
	else{
		if (abs([line1 getP1].x - [line2 getP1].x) > 1)
			return YES;
		else
			return NO;
	}
}

+(IntVector*)getAngle: (IntPointVector*) centers{
	QRLine* additionalLine[3];
	int alLen = 3, i;
	
	for (i = 0; i < alLen; i++){
		additionalLine[i] = [[QRLine alloc] initWithP1: [centers get:i] P2: [centers get: ((i + 1) % alLen)]];
	}
	
	// remoteLine - does not contain UL center
	QRLine *remoteLine = [QRLine getLongest: additionalLine count: alLen];
	IntPoint originPoint = { 0, 0 };
	for (i = 0; i < [centers length]; i++){
		if (![IntPointHelper equals: [remoteLine getP1] p2: [centers get:i]] && 
			![IntPointHelper equals: [remoteLine getP2] p2: [centers get:i]]){
			originPoint = [centers get:i];
			break;
		}
	}
	
	IntPoint remotePoint = { 0, 0 };
	
	//with origin that the center of Left-Up Finder Pattern, determine other two patterns center.
	//then calculate symbols angle
	if ((originPoint.y <= [remoteLine getP1].y) & (originPoint.y <= [remoteLine getP2].y)){
		if ([remoteLine getP1].x < [remoteLine getP2].x){
			remotePoint = [remoteLine getP2];
		}
		else{
			remotePoint = [remoteLine getP1];
		}
	}
	else if ((originPoint.x >= [remoteLine getP1].x) & (originPoint.x >= [remoteLine getP2].x)){
		if ([remoteLine getP1].y < [remoteLine getP2].y){
			remotePoint = [remoteLine getP2];
		}
		else{
			remotePoint = [remoteLine getP1];
		}
	}
	else if ((originPoint.y >= [remoteLine getP1].y) & (originPoint.y >= [remoteLine getP2].y)){
		if ([remoteLine getP1].x < [remoteLine getP2].x){
			remotePoint = [remoteLine getP1];
		}
		else{
			remotePoint = [remoteLine getP2];
		}
	}
	//1st or 4th quadrant
	else if ([remoteLine getP1].y < [remoteLine getP2].y){
		remotePoint = [remoteLine getP1];
	}
	else{
		remotePoint = [remoteLine getP2];
	}
	
	int r = [QRLine getLength: originPoint p2: remotePoint];
	
	IntVector *angle = [[IntVector alloc] initWithLength: 2];
	int dp = [QRCodeImageReader DECIMAL_POINT];
	[angle setValue: ((remotePoint.y - originPoint.y) << dp) / r at: 0]; //Sin
	[angle setValue: ((remotePoint.x - originPoint.x) << dp) / r at: 1]; //Cos
	
	return [angle autorelease];
}

+(IntPointVector*)getCenter: (NSArray*) crossLines{
	IntPointVector* centers = nil;
	
	int cl = [crossLines count], i, j;
	for (i = 0; i < cl - 1; i++){
		QRLine *compareLine = [crossLines objectAtIndex: i];
		for (j = i + 1; j < cl; j++){
			QRLine *comparedLine = [crossLines objectAtIndex: j];
			if ([compareLine isCross: comparedLine]){
				int x = 0;
				int y = 0;
				if ([compareLine Horizontal]){
					x = [compareLine Center].x;
					y = [comparedLine Center].y;
				}
				else{
					x = [comparedLine Center].x;
					y = [compareLine Center].y;
				}
				
				IntPoint np = { x, y };
				if (centers == nil){
					centers = [[IntPointVector alloc] initWithLength: 1];
					[centers setValue: np at: 0];
				}
				else{
					[centers add: np];
				}
			}
		}
	}
	
	if (!centers || [centers length] != 3){
		FinderPatternNotFoundException *ex = [FinderPatternNotFoundException withMessage: @"Invalid number of Finder Pattern detected"];
		@throw ex;
	}
	
	int jk;
	for (jk = 0; jk < [centers length]; jk++){
		IntPoint qr = [centers get: jk];
		NSLog(@"Center %d: (%d, %d)", jk, qr.x,qr.y);
	}
	
	return [centers autorelease];
}

+(IntPointVector*)sort: (IntPointVector*) centers angle: (IntVector*)angle{
	IntPointVector* sortedCenters = [[IntPointVector alloc] initWithLength: 3];
	
	int quadant = [self getURQuadant: angle];
	switch (quadant){
		case 1: 
			[sortedCenters setValue: [self getPointAtSide: centers side1: IPRIGHT side2: IPBOTTOM] at: 1];
			[sortedCenters setValue: [self getPointAtSide: centers side1: IPBOTTOM side2: IPLEFT] at: 2];
			break;
			
		case 2: 
			[sortedCenters setValue: [self getPointAtSide: centers side1: IPBOTTOM side2: IPLEFT] at: 1];
			[sortedCenters setValue: [self getPointAtSide: centers side1: IPTOP side2: IPLEFT] at: 2];
			break;
			
		case 3: 
			[sortedCenters setValue: [self getPointAtSide: centers side1: IPLEFT side2: IPTOP] at: 1];
			[sortedCenters setValue: [self getPointAtSide: centers side1: IPRIGHT side2: IPTOP] at: 2];
			break;
			
		case 4: 
			[sortedCenters setValue: [self getPointAtSide: centers side1: IPTOP side2: IPRIGHT] at: 1];
			[sortedCenters setValue: [self getPointAtSide: centers side1: IPBOTTOM side2: IPRIGHT] at: 2];
			break;
	}
	
	//last of centers is Left-Up patterns one
	int i;
	for (i = 0; i < [centers length]; i++){
		if (![IntPointHelper equals: [centers get: i] p2: [sortedCenters get: 1]] && 
			![IntPointHelper equals: [centers get: i] p2: [sortedCenters get: 2]]){
			[sortedCenters setValue: [centers get: i] at: 0];
		}
	}
	
	return [sortedCenters autorelease];
}

+(int)getURQuadant: (IntVector*) angle{
	int sin = [angle get: 0];
	int cos = [angle get: 1];
	
	if (sin >= 0 && cos > 0)
		return 1;
	else if (sin > 0 && cos <= 0)
		return 2;
	else if (sin <= 0 && cos < 0)
		return 3;
	else if (sin < 0 && cos >= 0)
		return 4;
	
	return 0;
}

+(IntPoint)getPointAtSide: (IntPointVector*) points side1: (int) side1 side2: (int) side2{
	int x = ((side1 == IPRIGHT || side2 == IPRIGHT)?0:0x7FFFFFFF);
	int y = ((side1 == IPBOTTOM || side2 == IPBOTTOM)?0:0x7FFFFFFF);
	IntPoint sidePoint = { x, y };
	int i, len = [points length];
	
	for (i = 0; i < len; i++){
		switch (side1){
			case IPRIGHT: 
				if (sidePoint.x < [points get: i].x){
					sidePoint = [points get: i];
				}
				else if (sidePoint.x == [points get: i].x){
					if (side2 == IPBOTTOM){
						if (sidePoint.y < [points get: i].y){
							sidePoint = [points get: i];
						}
					}
					else{
						if (sidePoint.y > [points get: i].y){
							sidePoint = [points get: i];
						}
					}
				}
				break;
				
				case IPBOTTOM: 
				if (sidePoint.y < [points get: i].y){
					sidePoint = [points get: i];
				}
				else if (sidePoint.y == [points get: i].y){
					if (side2 == IPRIGHT){
						if (sidePoint.x < [points get: i].x){
							sidePoint = [points get: i];
						}
					}
					else{
						if (sidePoint.x > [points get: i].x){
							sidePoint = [points get: i];
						}
					}
				}
				break;
				
				case IPLEFT: 
				if (sidePoint.x > [points get: i].x){
					sidePoint = [points get: i];
				}
				else if (sidePoint.x == [points get: i].x){
					if (side2 == IPBOTTOM){
						if (sidePoint.y < [points get: i].y){
							sidePoint = [points get: i];
						}
					}
					else{
						if (sidePoint.y > [points get: i].y){
							sidePoint = [points get: i];
						}
					}
				}
				break;
				
				case IPTOP: 
				if (sidePoint.y > [points get: i].y){
					sidePoint = [points get: i];
				}
				else if (sidePoint.y == [points get: i].y){
					if (side2 == IPRIGHT){
						if (sidePoint.x < [points get: i].x){
							sidePoint = [points get: i];
						}
					}
					else{
						if (sidePoint.x > [points get: i].x){
							sidePoint = [points get: i];
						}
					}
				}
				break;
		}
	}
	return sidePoint;
}

+(IntVector*)getWidth: (BoolMatrix*) image centers: (IntPointVector*) centers sincos: (IntVector*) sincos{
	IntVector *width = [[IntVector alloc] initWithLength: 3];
	int i;
	
	for (i = 0; i < 3; i++){
		BOOL flag = NO;
		int lx, rx;
		int y = [centers get:i].y;
		
		for (lx = [centers get:i].x; lx > 0; lx--){
			if ([image X:lx Y:y] == POINT_DARK && [image X:(lx - 1) Y:y] == POINT_LIGHT){
				if (flag == NO){
					flag = YES;
				}
				else{
					break;
				}
			}
		}
		flag = NO;
		for (rx = [centers get:i].x; rx < [image width]; rx++){
			if ([image X:rx Y:y] == POINT_DARK && [image X:(rx + 1) Y:y] == POINT_LIGHT){
				if (flag == NO){
					flag = YES;
				}
				else{
					break;
				}
			}
		}
		[width setValue: (rx - lx + 1) at: i];
	}
	return [width autorelease];
}

+(int)calcRoughVersion: (IntPointVector*) center width: (IntVector*) width{
	int dp = [QRCodeImageReader DECIMAL_POINT];
	int lengthAdditionalLine = [QRLine getLength: [center get: FP_UL] p2: [center get: FP_UR]] << dp;
	
	int averageWidth = (([width get: FP_UL] + [width get: FP_UR]) << dp) / 14;
	int roughVersion = ((lengthAdditionalLine / averageWidth) - 10) / 4;
	if (((lengthAdditionalLine / averageWidth) - 10) % 4 >= 2){
		roughVersion++;
	}
	
	return roughVersion;
}

+(int)calcExactVersion: (IntPointVector*) center angle: (IntVector*) angle moduleSize: (const int*) moduleSize image: (BoolMatrix*) image{
	BOOL versionInformation[18];
	IntPoint points[18];
	
	memset(versionInformation, 0, 18*sizeof(BOOL));
	memset(points, 0, sizeof(IntPoint)*18);
	
	IntPoint target;
	Axis *axis = [[Axis alloc] initWithAngle: [angle asROArray] pitch: moduleSize[0]];
	[axis setOrigin: [center get:FP_UR]];
	
	int x, y;
	for (y = 0; y < 6; y++){
		for (x = 0; x < 3; x++){
			target = [axis translateX: (x - 7) Y: (y - 3)];
			versionInformation[x + y * 3] = [image X: target.x Y: target.y];
			points[x + y * 3] = target;
		}
	}
	
	int exactVersion = 0;
	@try{
		exactVersion = [self checkVersionInfo: versionInformation];
	}
	@catch (InvalidVersionInfoException *e){
		NSLog(@"Version info error. now retry with other place one.");
		[axis setOrigin: [center get: FP_DL]];
		[axis setModulePitch: moduleSize[1]];
		
		for (x = 0; x < 6; x++){
			for (y = 0; y < 3; y++){
				target = [axis translateX: (x - 3) Y: (y - 7)];
				versionInformation[y + x * 3] = [image X: target.x Y:target.y];
				points[x + y * 3] = target;
			}
		}
		
		@try{
			exactVersion = [self checkVersionInfo: versionInformation];
		}
		@catch (VersionInformationException *e2){
			@throw;
		}
	}
	return exactVersion;
}

+(int)checkVersionInfo: (BOOL*) target{
	// note that this method includes BCH 18-6 Error Correction
	// see page 67 on JIS-X-0510(2004) 
	int errorCount = 0, versionBase, j;
	for (versionBase = 0; versionBase < VIBLEN; versionBase++){
		errorCount = 0;
		for (j = 0; j < 18; j++){
			BOOL mybit = ((VersionInfoBit[versionBase] >> j)%2) == 1 ? YES : NO;
			if (!(target[j] == mybit)){
				errorCount++;
			}
		}
		if (errorCount <= 3){
			break;
		}
	}
	if (errorCount <= 3){
		return 7 + versionBase;
	}
	else{
		NSException *e = [InvalidVersionInfoException withMessage: @"Too many errors in version information"];
		@throw e;
	}
}

RETAIN_RELEASE(FinderPattern)
@end
