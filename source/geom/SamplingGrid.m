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
#import "SamplingGrid.h"

#define CELL(x,y) ((AreaGrid*) *(grids+(y*dim)+x))

@interface AreaGrid : NSObject{
	SamplingGrid *enclosingInstance;
	NSMutableArray *xLine;
	NSMutableArray *yLine;
}
-(AreaGrid*) initWithGrid: (SamplingGrid*) enclosing width: (int) width height: (int) height;
-(int)Width;
-(int)Height;
-(NSArray*)XLines;
-(NSArray*)YLines;
-(QRLine*)getXLine: (int) x;
-(QRLine*)getYLine: (int) y;
-(void)setXLine: (int) x line: (QRLine*) line;
-(void)setYLine: (int) y line: (QRLine*) line;
@end

@implementation AreaGrid
-(AreaGrid*) initWithGrid: (SamplingGrid*) enclosing width: (int) width height: (int) height{
	[super init];
	enclosingInstance = enclosing;
	
	xLine = [[NSMutableArray alloc] initWithCapacity: width];
	int i;
	for (i = 0; i < width; i++){
		[xLine addObject: self];
	}
	yLine = [[NSMutableArray alloc] initWithCapacity: height];
	for (i = 0; i < height; i++){
		[yLine addObject: self];
	}
	return self;
}
-(void)dealloc{
	[xLine release];
	[yLine release];
	[super dealloc];
}
-(int)Width{
	return [xLine count];
}
-(int)Height{
	return [yLine count];
}
-(NSArray*)XLines{
	return xLine;
}
-(NSArray*)YLines{
	return yLine;
}
-(QRLine*)getXLine: (int) x{
	NSObject *s = [xLine objectAtIndex: x];
	if (s == self){
		return nil;
	}
	return (QRLine*)s;
}
-(QRLine*)getYLine: (int) y{
	NSObject *s = [yLine objectAtIndex: y];
	if (s == self){
		return nil;
	}
	return (QRLine*)s;
}

-(void)setXLine: (int) x line: (QRLine*) line{
	[xLine replaceObjectAtIndex: x withObject: line];
}

-(void)setYLine: (int) y line: (QRLine*) line{
	[yLine replaceObjectAtIndex: y withObject: line];
}
@end

@implementation SamplingGrid

-(SamplingGrid*)initWithAreas: (int) count{
	[super init];
	dim = count;
	grids = malloc(sizeof(NSObject*)*dim*dim);
	memset(grids, 0, sizeof(NSObject*)*dim*dim);
	return self;
}

-(void) dealloc{
	int i, l = dim * dim;
	for (i = 0; i < l; i++){
		if (grids[i]){
			[grids[i] dealloc];
		}
	}
	free(grids);
	[super dealloc];
}

-(void)initGrid: (int) ax ay: (int) ay width: (int) width height: (int) height{
	*(grids + (ay*dim) + ax) = [[AreaGrid alloc] initWithGrid: self width: width height: height];
}

-(void)setXLine: (int) ax ay: (int) ay X: (int) x line: (QRLine*) line{
	AreaGrid *ag = CELL(ax,ay);
	[ag setXLine: x line: line];
}

-(void)setYLine: (int) ax ay: (int) ay Y: (int) y line: (QRLine*) line{
	AreaGrid *ag = CELL(ax,ay);
	[ag setYLine: y line: line];
}

-(QRLine*)getXLine: (int) ax ay: (int) ay X: (int) x{
	AreaGrid *ag = CELL(ax,ay);
	return [ag getXLine: x];
}

-(QRLine*)getYLine: (int) ax ay: (int) ay Y: (int) y{
	AreaGrid *ag = CELL(ax,ay);
	return [ag getYLine: y];
}

-(NSArray*)getXLines: (int) ax ay: (int) ay{
	AreaGrid *ag = CELL(ax,ay);
	return [ag XLines];
}

-(NSArray*)getYLines: (int) ax ay: (int) ay{
	AreaGrid *ag = CELL(ax,ay);
	return [ag YLines];
}

-(int) getWidth{
	return dim;
}

-(int) getHeight{
	return dim;
}

-(int) getWidth: (int) ax ay: (int) ay{
	AreaGrid *ag = CELL(ax,ay);
	return [ag Width];
}

-(int) getHeight: (int) ax ay: (int) ay{
	AreaGrid *ag = CELL(ax,ay);
	return [ag Height];
}

-(int) getX: (int) ax x: (int) x{
	int total = x, i;
	for (i = 0; i < ax; i++){
		AreaGrid *ag = CELL(i,0);
		total += [ag Width] - 1;
	}
	return total;
}

-(int) getY: (int) ay y: (int) y{
	int total = y, i;
	for (i = 0; i < ay; i++){
		AreaGrid *ag = CELL(0,i);
		total += [ag Height] - 1;
	}
	return total;
}

-(void) adjust: (IntPoint) adjust{
	int dx = adjust.x, dy = adjust.y, ay, ax;
	for (ay = 0; ay < dim; ay++){
		for (ax = 0; ax < dim; ax++){
			AreaGrid *ag = CELL(ax,ay);
			int xlen = [[ag XLines] count], ylen = [[ag YLines] count], i, j;
			for (i = 0; i < xlen; i++){
				QRLine *l = [[ag XLines] objectAtIndex: i];
				[l translateDx: dx Dy: dy];
			}
			for (j = 0; j < ylen; j++){
				QRLine *l = [[ag YLines] objectAtIndex: j];
				[l translateDx: dx Dy: dy];
			}
		}
	}
}

-(int)TotalWidth{
	int total = 0, i;
	for (i = 0; i < dim; i++){
		total += [CELL(i,0) Width];
		if (i > 0){
			total -= 1;
		}
	}
	return total;
}

-(int)TotalHeight{
	int total = 0, i;
	for (i = 0; i < dim; i++){
		total += [CELL(0,i) Height];
		if (i > 0){
			total -= 1;
		}
	}
	return total;
}

@end
