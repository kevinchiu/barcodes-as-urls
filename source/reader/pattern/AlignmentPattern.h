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
#import "../../ValueMatrix.h"
#import "FinderPattern.h"
#import <Foundation/Foundation.h>

#define RIGHT 1
#define BOTTOM 2
#define LEFT 3
#define TOP 4

@interface AlignmentPattern : NSObject{
	IntPointMatrix *center;
	int patternDistance;
}

-(int) LogicalDistance;
-(IntPointMatrix*) getCenter;
-(void)setCenter: (IntPointMatrix*) center;

+(AlignmentPattern*) findAlignmentPattern: (BoolMatrix*) image pattern: (FinderPattern*) finderPattern;
+(IntPointMatrix*) getLogicalCenter: (FinderPattern*) finderPattern;
@end
