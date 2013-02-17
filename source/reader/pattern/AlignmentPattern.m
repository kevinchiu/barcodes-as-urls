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
#import "AlignmentPattern.h"
#import "LogicalSeed.h"

BOOL isEdge(BoolMatrix* image, int x, int y, int nx, int ny);

@interface AlignmentPattern (Private)

-(AlignmentPattern*)initWithCenter:(IntPointMatrix*) center distance: (int) patternDistance;
+(IntPointMatrix*) getCenter: (BoolMatrix*) image pattern: (FinderPattern*) finderPattern centers: (IntPointMatrix*) logicalCenters;
+(IntPoint) getPrecisionCenter: (BoolMatrix*) image target: (IntPoint) targetPoint;

@end

@implementation AlignmentPattern
-(int)LogicalDistance{
	return patternDistance;
}

-(IntPointMatrix*)getCenter{
	return center;
}

-(void)setCenter: (IntPointMatrix*) c{
	[center release];
	center = [c retain];
}

+(AlignmentPattern*)findAlignmentPattern:(BoolMatrix*)image pattern:(FinderPattern*)finderPattern{
	IntPointMatrix *logicalCenters = [self getLogicalCenter: finderPattern];
	int logicalDistance = [logicalCenters X:1 Y:0].x - [logicalCenters X:0 Y:0].x;
	//With it converts in order to handle in the same way
	IntPointMatrix *centers = [self getCenter: image pattern: finderPattern centers: logicalCenters];
	return [[AlignmentPattern alloc] initWithCenter: centers distance: logicalDistance];
}

+(IntPointMatrix*)getLogicalCenter: (FinderPattern*) finderPattern{
	int version = [finderPattern Version];
	
	IntVector *logicalSeeds = [LogicalSeed getSeed:version];
	NSLog(@"getSeed returned %x", logicalSeeds);
	NSLog(@"Matrix: %dx%d", [logicalSeeds length]);
	IntPointMatrix *logicalCenters = [[IntPointMatrix alloc] initWithWidth: [logicalSeeds length] height: [logicalSeeds length]];
	
	//create real relative coordinates
	int col, row, len = [logicalCenters width];
	for (col = 0; col < len; col++){
		for (row = 0; row < len; row++){
			IntPoint ip = { [logicalSeeds get: row], [logicalSeeds get: col] };
			[logicalCenters setValue: ip X: row Y:col];
		}
	}
	return [logicalCenters autorelease];
}

-(AlignmentPattern*)initWithCenter:(IntPointMatrix*) c distance: (int) pDistance{
	[super init];
	center = [c retain];
	patternDistance = pDistance;
	return self;
}

-(void)dealloc{
	[center release];
	[super dealloc];
}

+(IntPointMatrix*) getCenter: (BoolMatrix*) image pattern: (FinderPattern*) finderPattern centers: (IntPointMatrix*) logicalCenters{
	int moduleSize = [finderPattern getModuleSize];
	
	Axis *axis = [[Axis alloc] initWithAngle: [[finderPattern getAngle] asROArray] pitch: moduleSize];
	int sqrtCenters = [logicalCenters width];
	IntPointMatrix *centers = [[IntPointMatrix alloc] initWithWidth: sqrtCenters height: sqrtCenters];
	
	[axis setOrigin: [finderPattern getCenter: FP_UL]];
	[centers setValue: [axis translateX: 3 Y: 3] X: 0 Y: 0];
	
	[axis setOrigin: [finderPattern getCenter: FP_UR]];
	[centers setValue: [axis translateX: -3 Y: 3] X: sqrtCenters-1 Y: 0];
	
	[axis setOrigin: [finderPattern getCenter: FP_DL]];
	[centers setValue: [axis translateX: 3 Y: -3] X: 0 Y: sqrtCenters-1];
	
	int x, y;
	
	for (y = 0; y < sqrtCenters; y++){
		for (x = 0; x < sqrtCenters; x++){
			if (x == 1 && y == 0 && sqrtCenters == 3){
				[centers setValue: [IntPointHelper getCenter: [centers X:0 Y:0] p2: [centers X:(sqrtCenters-1) Y:0]] X: x Y: y];
			}
			else if (x == 0 && y == 1 && sqrtCenters == 3){
				[centers setValue: [IntPointHelper getCenter: [centers X:0 Y:0] p2: [centers X:0 Y:(sqrtCenters-1)]] X: x Y: y];
			}
			else{
				if (x < 1 || y < 1){
					continue;
				}
				QRLine *line0 = [[[QRLine alloc] initWithP1: [centers X:(x-1) Y:(y-1)] P2: [centers X:x Y:(y-1)]] autorelease];
				QRLine *line1 = [[[QRLine alloc] initWithP1: [centers X:(x-1) Y:(y-1)] P2: [centers X:x-1 Y:y]] autorelease];
				int dx = [centers X:(x-1) Y:y].x - [centers X:(x-1) Y:(y-1)].x;
				int dy = [centers X:(x-1) Y:y].y - [centers X:(x-1) Y:(y-1)].y;
				[line0 translateDx: dx Dy: dy];
				dx = [centers X:x Y:y-1].x - [centers X:(x-1) Y:(y-1)].x;
				dy = [centers X:x Y:y-1].y - [centers X:(x-1) Y:(y-1)].y;
				[line1 translateDx: dx Dy: dy];
				[centers setValue: [IntPointHelper getCenter: [line0 getP2] p2: [line1 getP2]] X: x Y: y];
			}
			@try{
				[centers setValue: [self getPrecisionCenter: image target: [centers X:x Y:y]] X: x Y: y];
			}
			@catch (AlignmentPatternNotFoundException *e){
				@throw;
			}
		}
	}
	return [centers autorelease];
}

+(IntPoint) getPrecisionCenter: (BoolMatrix*) image target: (IntPoint) targetPoint{
	// find nearest dark point and update it as new rough center point 
	// when original rough center points light point 
	int tx = targetPoint.x, ty = targetPoint.y;
	if ((tx < 0 || ty < 0) || (tx > [image width] - 1 || ty > [image height] - 1)){
		NSException *ns = [AlignmentPatternNotFoundException withMessage: @"Alignment Pattern finder exceeded out of image"];
		@throw ns;
	}
	
	if ([image X: targetPoint.x Y: targetPoint.y] == POINT_LIGHT){
		int scope = 0, dy, dx;
		BOOL found = NO;
		while (!found){
			for (dy = ++scope; dy > - scope; dy--){
				for (dx = scope; dx > - scope; dx--){
					int x = targetPoint.x + dx;
					int y = targetPoint.y + dy;
					if ((x < 0 || y < 0) || (x > [image width] - 1 || y > [image height] - 1)){
						NSException *ns = [AlignmentPatternNotFoundException withMessage: @"Alignment Pattern finder exceeded out of image"];
						@throw ns;
					}
					if ([image X:x Y:y] == POINT_DARK){
						targetPoint.x += dx;
						targetPoint.y += dy;
						found = YES;
					}
				}
			}
		}
	}
	int x, y, dy, lx, rx, uy, iwidth = [image width], iheight = [image height];
	x = lx = rx = targetPoint.x;
	y = uy = dy = targetPoint.y;
	
	// Zone in from all four sides finding edges.
	while (lx >= 1 && !isEdge(image, lx, y, lx-1, y)){
		lx--;
	}
	while (lx < iwidth - 1 && !isEdge(image, rx, y, rx + 1, y)){
		rx++;
	}
	while (uy >= 1 && !isEdge(image, x, uy, x, uy - 1)){
		uy--;
	}
	while (dy < iheight - 1 && !isEdge(image, x, dy, x, dy + 1)){
		dy++;
	}
	
	IntPoint ip = { (lx + rx + 1) / 2, (uy + dy + 1) / 2 };
	return ip;
}

RETAIN_RELEASE(AlignmentPattern)
@end

BOOL isEdge(BoolMatrix* image, int x, int y, int nx, int ny){
	if (x < 0 || y < 0 || nx < 0 || ny < 0 || x > [image width] || y > [image height] ||
		nx > [image width] || ny > [image height]){
		NSException *ns = [AlignmentPatternNotFoundException withMessage: @"Alignment Pattern Finder exceeded image edge"];
		@throw ns;
		//return true;
	}
	else{
		return ([image X:x Y:y] == POINT_LIGHT && [image X:nx Y:ny] == POINT_DARK);
	}
}
