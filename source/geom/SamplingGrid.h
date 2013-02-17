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
#import "../ValueMatrix.h"
#import "Line.h"
#import <Foundation/Foundation.h>

@interface SamplingGrid : NSObject{
	NSObject **grids;
	int dim;
}
-(SamplingGrid*)initWithAreas: (int) count;
-(void)initGrid: (int) ax ay: (int) ay width: (int) width height: (int) height;
-(void)setXLine: (int) ax ay: (int) ay X: (int) x line: (QRLine*) line;
-(void)setYLine: (int) ax ay: (int) ay Y: (int) y line: (QRLine*) line;
-(QRLine*)getXLine: (int) ax ay: (int) ay X: (int) x;
-(QRLine*)getYLine: (int) ax ay: (int) ay Y: (int) y;
-(NSArray*)getXLines: (int) ax ay: (int) ay;
-(NSArray*)getYLines: (int) ax ay: (int) ay;
-(int) getWidth;
-(int) getHeight;
-(int) getWidth: (int) ax ay: (int) ay;
-(int) getHeight: (int) ax ay: (int) ay;
-(int) getX: (int) ax x: (int) x;
-(int) getY: (int) ay y: (int) y;
-(void) adjust: (IntPoint) adjust;

-(int)TotalWidth;
-(int)TotalHeight;

@end
