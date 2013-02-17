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
#import <Foundation/Foundation.h>

int fast_sqrt(int val);

@interface QRLine : NSObject{
	int x1;
	int y1;
	int x2;
	int y2;
}
-(QRLine*)init;
-(QRLine*)initWithX1: (int) X1 Y1: (int) Y1 X2: (int) X2 Y2: (int) Y2;
-(QRLine*)initWithP1: (IntPoint) p1 P2: (IntPoint) p2;
-(IntPoint)getP1;
-(IntPoint)getP2;

-(BOOL)Horizontal;
-(BOOL)Vertical;
-(IntPoint)Center;
-(int)Length;
-(void)setLineWithX1: (int) X1 Y1: (int) Y1 X2: (int) X2 Y2: (int) Y2;
-(void)setX1: (int) X1 Y1: (int) Y1;
-(void)setX2: (int) X2 Y2: (int) Y2;
-(void)setP1: (IntPoint) p1;
-(void)setP2: (IntPoint)p2;
-(void)translateDx: (int) dx Dy: (int) dy;

-(BOOL)isNeighbor: (QRLine*) line2;
-(BOOL)isCross: (QRLine*) line2;

+(QRLine*)getLongest: (NSArray*) lines;
+(QRLine*)getLongest: (QRLine**) lines count: (int) count;
+(int)getLength: (IntPoint) p1 p2: (IntPoint) p2;
@end
