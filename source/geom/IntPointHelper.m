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
#import "IntPointHelper.h"

@implementation IntPointHelper

+(IntPoint) translate: (IntPoint) p X: (int) x Y: (int) y{
	IntPoint r = { p.x + x, p.y + y };
	return r;
}

+(IntPoint) getCenter: (IntPoint) p1 p2: (IntPoint) p2{
	IntPoint r = {
		(p1.x + p2.x) / 2,
		(p1.y + p2.y) / 2
	};
	return r;
}

+(BOOL) equals: (IntPoint)p1 p2: (IntPoint)p2{
	return (p1.x == p2.x && p1.y == p2.y) ? YES : NO;
}

+(int) distanceOf: (IntPoint)p1 to: (IntPoint)p2{
	int x1 = p1.x - p2.x, y1 = p1.y - p2.y;
	return sqrt(x1*x1+y1*y1);
}
@end
