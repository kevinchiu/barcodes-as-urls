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
#import "../geom/Axis.h"
#import "../QRCommon.h"
#import "pattern/AlignmentPattern.h"
#import "pattern/FinderPattern.h"
#import "QRCodeImageReader.h"

#define TRANSLATE(p,dx,dy) p.x += (dx), p.y += (dy)

static int decimal_point = 21;

@interface ModulePitch : NSObject{
@public
	QRCodeImageReader *enclosingInstance;
	
	int top;
	int left;
	int bottom;
	int right;
}
-(ModulePitch*)initFromReader: (QRCodeImageReader*) enclosing;
@end

@interface QRCodeImageReader (Private)
-(void)getSamplingGrid: (FinderPattern*) finderPattern alignment: (AlignmentPattern*) alignmentPattern;
-(void)getSamplingGrid2_6: (FinderPattern*) finderPattern alignment: (AlignmentPattern*) alignmentPattern;
-(int)getAreaModulePitch: (IntPoint) start end: (IntPoint) end distance: (int) logicalDistance;
-(BoolMatrix*)getQRCodeMatrix: (BoolMatrix*) image grid: (SamplingGrid*) gridLines;
-(ModulePitch*)initFromReader: (QRCodeImageReader*) enclosing;
-(BoolMatrix*)applyMedianFilter: (BoolMatrix*) image threshold: (int) threshold;
-(BoolMatrix*)applyCrossMaskingMedianFilter: (BoolMatrix*) image threshold: (int) threshold;
-(BoolMatrix*)filterImage: (IntMatrix*) image;
-(void)imageToGrayScale: (IntMatrix*) image;
-(BoolMatrix*)grayScaleToBitmap: (IntMatrix*) grayScale;
-(IntMatrix*)getMiddleBrightnessPerArea: (IntMatrix*) image;
@end

@implementation QRCodeImageReader
+(int)DECIMAL_POINT{
	return decimal_point;
}

-(QRCodeImageReader*)initReader{
	[super init];
	return self;
}
-(void)dealloc{
	if (_samplingGrid){
		[_samplingGrid release];
		_samplingGrid = nil;
	}
	[super dealloc];
}
-(QRCodeSymbol*)getQRCodeSymbol: (IntMatrix*) image{
	int longSide = ([image width] < [image height])?[image height]:[image width];
	decimal_point = 23 - fast_sqrt(longSide / 256);
	
	_bitmap = [self filterImage: image];
	
	NSLog(@"Scanning Finder Pattern.");
	FinderPattern *finderPattern = nil;
	@try{
		finderPattern = [FinderPattern findFinderPattern: _bitmap];
	}
	@catch (FinderPatternNotFoundException *e){
		NSLog(@"Not found, now retrying...");
		_bitmap = [self applyCrossMaskingMedianFilter: _bitmap threshold: 5];
		@try{
			finderPattern = [FinderPattern findFinderPattern: _bitmap];
		}
		@catch (FinderPatternNotFoundException *e2){
			NSException *ns = [SymbolNotFoundException withMessage: [e2 name]];
			@throw ns;
		}
		@catch (VersionInformationException *e2){
			NSException *ns = [SymbolNotFoundException withMessage: [e2 name]];
			@throw ns;
		}
	}
	@catch (VersionInformationException *e){
		NSException *ns = [SymbolNotFoundException withMessage: [e name]];
		@throw ns;
	}
	if (_bitmap)
		[_bitmap retain];
	
	IntVector *iv = [finderPattern getAngle];
	NSLog(@"Angle*4098: Sin %d Cos %d", [iv get:0], [iv get:1]);
	
	int version = [finderPattern Version];
	NSLog(@"Version: %d", version);
	if (version < 1 || version > 40){
		NSException *ns = [InvalidVersionException withMessage: [NSString stringWithFormat: @"Invalid version: %d", version]];
		@throw ns;
	}
	
	AlignmentPattern *alignmentPattern = nil;
	@try{
		alignmentPattern = [AlignmentPattern findAlignmentPattern: _bitmap pattern: finderPattern];
	}
	@catch (AlignmentPatternNotFoundException *e){
		NSLog(@"No alignment pattern found.");
		NSException *ns = [SymbolNotFoundException withMessage: [e name]];
		@throw ns;
	}
	
	int matrixLength = [[alignmentPattern getCenter] width], x, y;
	NSLog(@"AlignmentPatterns at");
	for (y = 0; y < matrixLength; y++){
		for (x = 0; x < matrixLength; x++){
			IntPoint p = [[alignmentPattern getCenter] X: x Y: y];
			printf("(%d,%d)",p.x,p.y);
		}
		printf("\n");
	}
	
	if(version >= 2 && version <= 6){
		[self getSamplingGrid2_6: finderPattern alignment: alignmentPattern];
	}
	else{
		[self getSamplingGrid: finderPattern alignment: alignmentPattern];
	}
	
	BoolMatrix *qRCodeMatrix = nil;
	
	@try{
		qRCodeMatrix = [self getQRCodeMatrix: _bitmap grid: _samplingGrid];
	}
	@catch (IndexOutOfRangeException *e){
		NSException *ns = [SymbolNotFoundException withMessage: @"Sampling grid exceeded image boundary"];
		@throw ns;
	}
	QRCodeSymbol *qrc = [[QRCodeSymbol alloc] initWithModuleMatrix: qRCodeMatrix];
	return [qrc autorelease];
}

-(QRCodeSymbol*)getQRCodeSymbolWithAdjustedGrid: (IntPoint) adjust{
	if (_bitmap == nil || _samplingGrid == nil){
		NSException *ns = [NSException exceptionWithName: @"SystemException" reason: @"This method must be called after QRCodeImageReader.getQRCodeSymbol() called" userInfo: nil];
		@throw ns;
	}
	[_samplingGrid adjust: adjust];
	
	BoolMatrix *qRCodeMatrix = nil;
	@try{
		qRCodeMatrix = [self getQRCodeMatrix: _bitmap grid: _samplingGrid];
	}
	@catch (IndexOutOfRangeException *e){
		@throw [SymbolNotFoundException withMessage: @"Sampling grid exceeded image boundary"];
	}
	return [[[QRCodeSymbol alloc] initWithModuleMatrix: qRCodeMatrix] autorelease];
}

-(BoolMatrix*)applyMedianFilter: (BoolMatrix*) image threshold: (int) threshold{
	BoolMatrix *filteredMatrix = [[BoolMatrix alloc] initWithWidth: [image width] height: [image height]];
	
	//filtering noise in image with median filter
	int numPointDark, x, y, fx, fy;
	for (y = 1; y < [image height] - 1; y++){
		for (x = 1; x < [image width] - 1; x++){
			numPointDark = 0;
			for (fy = - 1; fy < 2; fy++){
				for (fx = - 1; fx < 2; fx++){
					if ([image X: (x + fx) Y: (y + fy)] == YES){
						numPointDark++;
					}
				}
			}
			if (numPointDark > threshold){
				[filteredMatrix setValue: POINT_DARK X:x Y:y];
			}
		}
	}
	return [filteredMatrix autorelease];
}

-(BoolMatrix*)applyCrossMaskingMedianFilter: (BoolMatrix*) image threshold: (int) threshold{
	BoolMatrix *filteredMatrix = [[BoolMatrix alloc] initWithWidth: [image width] height: [image height]];
	
	int width = [image width], height = [image height], x, y;
	for(y = 1; y < height - 1; y++){
		for(x = 1; x < width - 1; x++){
			int numPointDark = 0, fx, fy;
			for(fy = -1; fy < 2; fy++){
				for(fx = -1; fx < 2; fx++){
					if([image X: (x + fx) Y:(y + fy)]){
						numPointDark++;
					}
				}
				
			}
			
			if(numPointDark > threshold){
				[filteredMatrix setValue: YES X:x Y:y];
			}
		}
		
	}
	
	return filteredMatrix;
}

-(BoolMatrix*)filterImage: (IntMatrix*) image{
	[self imageToGrayScale: image];
	BoolMatrix* bmp = [self grayScaleToBitmap: image];
	return bmp;
}

-(void)imageToGrayScale: (IntMatrix*) image{
	int x, y;
	for (y = 0; y < [image height]; y++){
		for (x = 0; x < [image width]; x++){
			int m = [image X: x Y: y];
			[image setValue: m X:x Y:y];
		}
	}
}

-(BoolMatrix*)grayScaleToBitmap: (IntMatrix*) grayScale{
	IntMatrix *middle = [self getMiddleBrightnessPerArea:grayScale];
	int sqrtNumArea = [middle width];
	int areaWidth = [grayScale width] / sqrtNumArea;
	int areaHeight = [grayScale height] / sqrtNumArea;
	BoolMatrix *bmp = [[BoolMatrix alloc] initWithWidth: [grayScale width] height: [grayScale height]];
	
	int ay, ax, dy, dx, off=0;
	for (ay = 0; ay < sqrtNumArea; ay++){
		for (ax = 0; ax < sqrtNumArea; ax++){
			for (dy = 0; dy < areaHeight; dy++){
				for (dx = 0; dx < areaWidth; dx++){
					int xpos = areaWidth * ax + dx;
					int ypos = areaHeight * ay + dy;
					int mdl = [middle X:ax Y:ay];
					BOOL v = ([grayScale X: (areaWidth * ax + dx) Y:(areaHeight * ay + dy)] < mdl)?YES:NO;
					if (v){
						off++;
					}
					[bmp setValue: v X: xpos Y: ypos];
				}
			}
		}
	}
	return [bmp autorelease];
}

-(IntMatrix*)getMiddleBrightnessPerArea: (IntMatrix*) image{
	int numSqrtArea = 4, ax, ay, dx, dy;
	//obtain middle brightness((min + max) / 2) per area
	int areaWidth = [image width] / numSqrtArea;
	int areaHeight = [image height] / numSqrtArea;
	IntPointMatrix *minmax = [[IntPointMatrix alloc] initWithWidth: numSqrtArea height: numSqrtArea];
	
	for (ay = 0; ay < numSqrtArea; ay++){
		for (ax = 0; ax < numSqrtArea; ax++){
			[minmax setXValue: 0xFF X: ax Y:ay];
			for (dy = 0; dy < areaHeight; dy++){
				for (dx = 0; dx < areaWidth; dx++){
					int target = [image X:(areaWidth * ax + dx) Y:(areaHeight * ay + dy)];
					if (target < [minmax X:ax Y:ay].x){
						[minmax setXValue: target X:ax Y:ay];
					}
					if (target > [minmax X:ax Y:ay].y){
						[minmax setYValue: target X:ax Y:ay];
					}
				}
			}
		}
	}
	IntMatrix *middle = [[IntMatrix alloc] initWithWidth: numSqrtArea height: numSqrtArea];
	for (ay = 0; ay < numSqrtArea; ay++){
		for (ax = 0; ax < numSqrtArea; ax++){
			IntPoint ip = [minmax X:ax Y:ay];
			[middle setValue: (ip.x + ip.y)/2 X: ax Y: ay];
		}
	}
	
	[minmax release];
	return [middle autorelease];
}

-(void)getSamplingGrid2_6: (FinderPattern*) finderPattern alignment: (AlignmentPattern*) alignmentPattern{
	int version = [finderPattern Version];
	int sqrtNumArea = 1;
	int sqrtNumModules = 17 + 4 * version;
	int sqrtNumAreaModules = sqrtNumModules / sqrtNumArea;
	
	IntPointMatrix *centers = [alignmentPattern getCenter];
	[centers setValue: [finderPattern getCenter: FP_UL] X:0 Y:0];
	[centers setValue: [finderPattern getCenter: FP_UR] X:1 Y:0];
	[centers setValue: [finderPattern getCenter: FP_DL] X:0 Y:1] ;
	
	_samplingGrid = [[SamplingGrid alloc] initWithAreas: 1];
	[_samplingGrid initGrid: 0 ay: 0 width: sqrtNumAreaModules height: sqrtNumAreaModules];
	
	int logicalDistance = [alignmentPattern LogicalDistance];
	Axis *axis = [[Axis alloc] initWithAngle: [[finderPattern getAngle] asROArray] pitch: [finderPattern getModuleSize]];
	[axis autorelease];
	
	int modulePitch[4];
	modulePitch[0] = [self getAreaModulePitch: [centers X:0 Y:0] end: [centers X:1 Y:0] distance: logicalDistance + 6];
	modulePitch[1] = [self getAreaModulePitch: [centers X:0 Y:0] end: [centers X:0 Y:1] distance: logicalDistance + 6];
	[axis setModulePitch: modulePitch[0]];
	[axis setOrigin: [centers X:0 Y:1]];
	
	modulePitch[2] = [self getAreaModulePitch: [axis translateX: 0 Y: -3] end: [centers X:1 Y:1] distance: logicalDistance + 3];
	[axis setModulePitch: modulePitch[1]];
	[axis setOrigin: [centers X:1 Y:0]];
	
	modulePitch[3] = [self getAreaModulePitch: [axis translateX: -3 Y: 0] end: [centers X:1 Y:1] distance: logicalDistance + 3];
	
	QRLine *baseLineX = [[QRLine alloc] init];
	QRLine *baseLineY = [[QRLine alloc] init];
	
	[axis setOrigin: [centers X:0 Y:0]];
	modulePitch[0] = [self getAreaModulePitch: [centers X:0 Y:0] end: [centers X: 1 Y:0] distance: logicalDistance + 6];
	modulePitch[1] = [self getAreaModulePitch: [centers X:0 Y:0] end: [centers X: 0 Y:1] distance: logicalDistance + 6];
	[axis setModulePitch: modulePitch[0]];
	[axis setOrigin: [centers X:0 Y:1]];
	
	modulePitch[2] = [self getAreaModulePitch: [axis translateX: 0 Y: -3] end: [centers X:1 Y:1] distance: logicalDistance + 3];
	[axis setModulePitch: modulePitch[1]];
	[axis setOrigin: [centers X:1 Y:0]];
	
	modulePitch[3] = [self getAreaModulePitch: [axis translateX:-3 Y: 0] end: [centers X:1 Y:1] distance: logicalDistance + 3];
	[axis setOrigin: [centers X:0 Y:0]];
	[axis setModulePitch: modulePitch[0]];
	
	[baseLineX setP1: [axis translateX: -3 Y: -3]];
	[axis setModulePitch: modulePitch[1]];
	
	[baseLineY setP1: [axis translateX: -3 Y: -3]];
	[axis setOrigin: [centers X:0 Y:1]];
	[axis setModulePitch: modulePitch[2]];
	
	[baseLineX setP2: [axis translateX: -3 Y: 3]];
	[axis setOrigin: [centers X:1 Y:0]];
	[axis setModulePitch: modulePitch[3]];
	
	[baseLineY setP2: [axis translateX: 3 Y: -3]];
	
	[baseLineX translateDx: 1 Dy: 1];
	[baseLineY translateDx: 1 Dy: 1];
	
	int i;
	for(i = 0; i < sqrtNumModules; i++){
		QRLine *gridLineX = [[QRLine alloc] initWithP1: [baseLineX getP1] P2: [baseLineX getP2]];
		[axis setOrigin: [gridLineX getP1]];
		[axis setModulePitch: modulePitch[0]];
		
		[gridLineX setP1: [axis translateX: i Y: 0]];
		[axis setOrigin: [gridLineX getP2]];
		[axis setModulePitch: modulePitch[2]];
		
		[gridLineX setP2: [axis translateX: i Y: 0]];
		
		QRLine *gridLineY = [[QRLine alloc] initWithP1: [baseLineY getP1] P2: [baseLineY getP2]];
		[axis setOrigin: [gridLineY getP1]];
		[axis setModulePitch: modulePitch[1]];
		
		[gridLineY setP1: [axis translateX: 0 Y: i]];
		[axis setOrigin: [gridLineY getP2]];
		[axis setModulePitch: modulePitch[3]];
		[gridLineY setP2: [axis translateX: 0 Y: i]];
		[_samplingGrid setXLine: 0 ay: 0 X: i line: gridLineX];
		[_samplingGrid setYLine: 0 ay: 0 Y: i line: gridLineY];
	}
	
	
}

-(void)getSamplingGrid: (FinderPattern*) finderPattern alignment: (AlignmentPattern*) alignmentPattern{
	IntPointMatrix *centers = [alignmentPattern getCenter];
	
	int version = [finderPattern Version];
	int sqrtCenters = (version / 7) + 2;
	
	[centers setValue: [finderPattern getCenter: FP_UL] X: 0 Y: 0];
	[centers setValue: [finderPattern getCenter: FP_UR] X: sqrtCenters - 1 Y:0];
	[centers setValue: [finderPattern getCenter: FP_DL] X:0 Y:sqrtCenters - 1] ;
	int sqrtNumArea = sqrtCenters - 1;
	
	_samplingGrid = [[SamplingGrid alloc] initWithAreas: sqrtNumArea];
	
	QRLine *baseLineX, *baseLineY, *gridLineX, *gridLineY;
	
	Axis *axis = [[Axis alloc] initWithAngle: [[finderPattern getAngle] asROArray] pitch: [finderPattern getModuleSize]];
	[axis autorelease];
	ModulePitch *modulePitch;
	
	int ax, ay, i;
	// for each area :
	for (ay = 0; ay < sqrtNumArea; ay++){
		for (ax = 0; ax < sqrtNumArea; ax++){
			modulePitch = [[ModulePitch alloc] initFromReader: self]; // Housing to order
			baseLineX = [[QRLine alloc] init];
			baseLineY = [[QRLine alloc] init];
			
			[axis setModulePitch: [finderPattern getModuleSize]];
			
			IntPointMatrix *logicalCenters = [AlignmentPattern getLogicalCenter: finderPattern];
			
			IntPoint upperLeftPoint = [centers X:ax Y:ay];
			IntPoint upperRightPoint = [centers X:ax + 1 Y:ay];
			IntPoint lowerLeftPoint = [centers X:ax Y:ay + 1];
			IntPoint lowerRightPoint = [centers X:ax + 1 Y:ay + 1];
			
			IntPoint logicalUpperLeftPoint = [logicalCenters X:ax Y:ay];
			IntPoint logicalUpperRightPoint = [logicalCenters X:ax + 1 Y:ay];
			IntPoint logicalLowerLeftPoint = [logicalCenters X:ax Y:ay + 1];
			IntPoint logicalLowerRightPoint = [logicalCenters X:ax + 1 Y:ay + 1];
			
			if (ax == 0 && ay == 0){
				// left upper corner
				
				if (sqrtNumArea == 1){
					upperLeftPoint = [axis translate: upperLeftPoint X: - 3 Y: - 3];
					upperRightPoint = [axis translate: upperRightPoint X: 3 Y: - 3];
					lowerLeftPoint = [axis translate: lowerLeftPoint X: - 3 Y: 3];
					lowerRightPoint = [axis translate: lowerRightPoint X: 6 Y: 6];
					
					TRANSLATE(logicalUpperLeftPoint, -6, -6);
					TRANSLATE(logicalUpperRightPoint, 3, -3);
					TRANSLATE(logicalLowerLeftPoint, -3, 3);
					TRANSLATE(logicalLowerRightPoint, 6, 6);
				}
				else{
					upperLeftPoint = [axis translate: upperLeftPoint X: -3 Y: -3];
					upperRightPoint = [axis translate: upperRightPoint X: 0 Y: -6];
					lowerLeftPoint = [axis translate: lowerLeftPoint X: -6 Y: 0];
					
					TRANSLATE(logicalUpperLeftPoint, -6, -6);
					TRANSLATE(logicalUpperRightPoint, 0, -6);
					TRANSLATE(logicalLowerLeftPoint, -6, 0);
				}
			}
			else if (ax == 0 && ay == sqrtNumArea - 1){
				// left bottom corner
				
				upperLeftPoint = [axis translate: upperLeftPoint X: -6 Y: 0];
				lowerLeftPoint = [axis translate: lowerLeftPoint X: -3 Y: 3];
				lowerRightPoint = [axis translate: lowerRightPoint X: 0 Y: 6];
				
				TRANSLATE(logicalUpperLeftPoint, -6, 0);
				TRANSLATE(logicalLowerLeftPoint,- 6, 6);
				TRANSLATE(logicalLowerRightPoint,0, 6);
			}
			else if (ax == sqrtNumArea - 1 && ay == 0){
				// right upper corner
				
				upperLeftPoint = [axis translate: upperLeftPoint X: 0 Y: -6];
				upperRightPoint = [axis translate: upperRightPoint X: 3 Y: -3];
				lowerRightPoint = [axis translate: lowerRightPoint X: 6 Y: 0];
				
				TRANSLATE(logicalUpperLeftPoint,0, - 6);
				TRANSLATE(logicalUpperRightPoint,6, - 6);
				TRANSLATE(logicalLowerRightPoint,6, 0);
			}
			else if (ax == sqrtNumArea - 1 && ay == sqrtNumArea - 1){
				// right bottom corner
				
				lowerLeftPoint = [axis translate: lowerLeftPoint X: 0 Y: 6];
				upperRightPoint = [axis translate: upperRightPoint X: 6 Y: 0];
				lowerRightPoint = [axis translate: lowerRightPoint X: 6 Y: 6];
				
				TRANSLATE(logicalLowerLeftPoint,0, 6);
				TRANSLATE(logicalUpperRightPoint,6, 0);
				TRANSLATE(logicalLowerRightPoint,6, 6);
			}
			else if (ax == 0){
				// left side
				
				upperLeftPoint = [axis translate: upperLeftPoint X: -6 Y: 0];
				lowerLeftPoint = [axis translate: lowerLeftPoint X: -6 Y: 0];
				
				TRANSLATE(logicalUpperLeftPoint,- 6, 0);
				TRANSLATE(logicalLowerLeftPoint,- 6, 0);
			}
			else if (ax == sqrtNumArea - 1){
				// right
				
				upperRightPoint = [axis translate: upperRightPoint X: 6 Y: 0];
				lowerRightPoint = [axis translate: lowerRightPoint X: 6 Y: 0];
				
				TRANSLATE(logicalUpperRightPoint,6, 0);
				TRANSLATE(logicalLowerRightPoint,6, 0);
			}
			else if (ay == 0){
				// top
				
				upperLeftPoint = [axis translate: upperLeftPoint X: 0 Y: -6];
				upperRightPoint = [axis translate: upperRightPoint X: 0 Y: - 6];
				
				TRANSLATE(logicalUpperLeftPoint,0, - 6);
				TRANSLATE(logicalUpperRightPoint,0, - 6);
			}
			else if (ay == sqrtNumArea - 1){
				// bottom
				
				lowerLeftPoint = [axis translate: lowerLeftPoint X: 0 Y: 6];
				lowerRightPoint = [axis translate: lowerRightPoint X: 0 Y: 6];
				
				TRANSLATE(logicalLowerLeftPoint,0, 6);
				TRANSLATE(logicalLowerRightPoint,0, 6);
			}
			
			if (ax == 0){
				TRANSLATE(logicalUpperRightPoint,1, 0);
				TRANSLATE(logicalLowerRightPoint,1, 0);
			}
			else{
				TRANSLATE(logicalUpperLeftPoint,- 1, 0);
				TRANSLATE(logicalLowerLeftPoint,- 1, 0);
			}
			
			if (ay == 0){
				TRANSLATE(logicalLowerLeftPoint,0, 1);
				TRANSLATE(logicalLowerRightPoint,0, 1);
			}
			else{
				TRANSLATE(logicalUpperLeftPoint,0, - 1);
				TRANSLATE(logicalUpperRightPoint,0, - 1);
			}
			
			int logicalWidth = logicalUpperRightPoint.x - logicalUpperLeftPoint.x;
			int logicalHeight = logicalLowerLeftPoint.y - logicalUpperLeftPoint.y;
			
			if (version < 7){
				logicalWidth += 3;
				logicalHeight += 3;
			}
			modulePitch->top = [self getAreaModulePitch: upperLeftPoint end: upperRightPoint distance: logicalWidth - 1];
			modulePitch->left = [self getAreaModulePitch: upperLeftPoint end: lowerLeftPoint distance: logicalHeight - 1];
			modulePitch->bottom = [self getAreaModulePitch: lowerLeftPoint end: lowerRightPoint distance: logicalWidth - 1];
			modulePitch->right = [self getAreaModulePitch: upperRightPoint end: lowerRightPoint distance: logicalHeight - 1];
			
			[baseLineX setP1: upperLeftPoint];
			[baseLineY setP1: upperLeftPoint];
			[baseLineX setP2: lowerLeftPoint];
			[baseLineY setP2: upperRightPoint];
			
			[_samplingGrid initGrid: ax ay: ay width: logicalWidth height: logicalHeight];
			
			for (i = 0; i < logicalWidth; i++){
				gridLineX = [[QRLine alloc] initWithP1: [baseLineX getP1] P2: [baseLineX getP2]];
				
				[axis setOrigin: [gridLineX getP1]];
				[axis setModulePitch: modulePitch->top];
				[gridLineX setP1: [axis translateX: i Y: 0]];
				
				[axis setOrigin: [gridLineX getP2]];
				[axis setModulePitch: modulePitch->bottom];
				[gridLineX setP2: [axis translateX: i Y: 0]];
				
				[_samplingGrid setXLine: ax ay: ay X: i line: gridLineX];
			}
			
			for (i = 0; i < logicalHeight; i++){
				gridLineY = [[QRLine alloc] initWithP1: [baseLineY getP1] P2: [baseLineY getP2]];
				
				[axis setOrigin: [gridLineY getP1]];
				[axis setModulePitch: modulePitch->left];
				[gridLineY setP1: [axis translateX: 0 Y: i]];
				
				[axis setOrigin: [gridLineY getP2]];
				[axis setModulePitch: modulePitch->right];
				[gridLineY setP2: [axis translateX: 0 Y:i]];
				
				[_samplingGrid setYLine: ax ay: ay Y: i line: gridLineY];
			}
		}
	}
	
	[modulePitch release];
	[baseLineX release];
	[baseLineY release];
	[gridLineX release];
	[gridLineY release];
}

-(int)getAreaModulePitch: (IntPoint) start end: (IntPoint) end distance: (int) logicalDistance{
	QRLine *tempLine = [[QRLine alloc] initWithP1: start P2: end];
	int realDistance = [tempLine Length];
	int modulePitch = (realDistance << decimal_point) / logicalDistance;
	[tempLine release];
	return modulePitch;
}

-(BoolMatrix*)getQRCodeMatrix: (BoolMatrix*) image grid: (SamplingGrid*) gridLines{
	int gridSize = [gridLines TotalWidth];
	
	IntPoint bottomRightPoint = { 0, 0 };
	BoolMatrix *sampledMatrix = [[BoolMatrix alloc] initWithWidth: gridSize height: gridSize];
	
	int ax, ay, x, y;
	for (ay = 0; ay < [gridLines getHeight]; ay++){
		for (ax = 0; ax < [gridLines getWidth]; ax++){
			for (y = 0; y < [gridLines getHeight: ax ay: ay]; y++){
				for (x = 0; x < [gridLines getWidth: ax ay: ay]; x++){
					int x1 = [[gridLines getXLine: ax ay: ay X: x] getP1].x;
					int y1 = [[gridLines getXLine: ax ay: ay X: x] getP1].y;
					int x2 = [[gridLines getXLine: ax ay: ay X: x] getP2].x;
					int y2 = [[gridLines getXLine: ax ay: ay X: x] getP2].y;
					int x3 = [[gridLines getYLine: ax ay: ay Y: y] getP1].x;
					int y3 = [[gridLines getYLine: ax ay: ay Y: y] getP1].y;
					int x4 = [[gridLines getYLine: ax ay: ay Y: y] getP2].x;
					int y4 = [[gridLines getYLine: ax ay: ay Y: y] getP2].y;
					
					int e = (y2 - y1) * (x3 - x4) - (y4 - y3) * (x1 - x2);
					int f = (x1 * y2 - x2 * y1) * (x3 - x4) - (x3 * y4 - x4 * y3) * (x1 - x2);
					int g = (x3 * y4 - x4 * y3) * (y2 - y1) - (x1 * y2 - x2 * y1) * (y4 - y3);
					BOOL nv = [image X: f/e Y: g/e];
					
					[sampledMatrix setValue: nv X: ([gridLines getX: ax x: x]) Y:([gridLines getY: ay y: y])];
					
					if ((ay == [gridLines getHeight] - 1 && ax == [gridLines getWidth] - 1) && 
						y == [gridLines getHeight: ax ay: ay] - 1 && x == [gridLines getWidth: ax ay: ay] - 1){
						bottomRightPoint.x = f/e;
						bottomRightPoint.y = g/e;
					}
				}
			}
		}
	}
	if (bottomRightPoint.x > [image width] - 1 || bottomRightPoint.y > [image height] - 1){
		NSException *nse = [IndexOutOfRangeException withMessage:@"Sampling grid pointed out of image"];
		@throw nse;
	}
	
	return [sampledMatrix autorelease];
}

-(BOOL)hasSamplingGrid{
	return _samplingGrid != nil;
}

RETAIN_RELEASE(QRCodeImageReader)
@end

@implementation ModulePitch
-(ModulePitch*)initFromReader: (QRCodeImageReader*) enclosing{
	[super init];
	enclosingInstance = enclosing;
	return self;
}

RETAIN_RELEASE(ModulePitch)
@end
