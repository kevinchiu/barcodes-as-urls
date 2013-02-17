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
#import "../../geom/Line.h"
#import "../../ValueMatrix.h"
#import <Foundation/Foundation.h>

#define FP_UL 0
#define FP_UR 1
#define FP_DL 2

#define POINT_LIGHT NO
#define POINT_DARK YES

@interface FinderPattern : NSObject{
	IntPointVector *center;
	int version;
	IntVector *sincos;
	IntVector *width;
	int moduleSize;
}
-(int)Version;
-(int)SqrtNumModules;
-(IntPointVector*)getCenter;
-(IntPoint)getCenter: (int) position;
-(int)getWidth: (int) position;
-(IntVector*)getAngle;
-(int)getModuleSize;

+(FinderPattern*)findFinderPattern: (BoolMatrix*) image;

@end
