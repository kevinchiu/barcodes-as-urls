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
#import "../QRCommon.h"
#import "../reader/QRCodeImageReader.h"
#import "Axis.h"
#import "IntPointHelper.h"

@implementation Axis
-(Axis*)initWithAngle: (const int*) sinAndCos pitch: (int) pitch{
	[super init];
	_sin = sinAndCos[0];
	_cos = sinAndCos[1];
	_modulePitch = pitch;
	return self;
}

-(void)setOrigin: (IntPoint) p{
	_origin = p;
}

-(void)setModulePitch: (int) p{
	_modulePitch = p;
}

-(IntPoint)translate: (IntPoint) offset{
	return [self translateX: offset.x Y: offset.y];
}

-(IntPoint)translate: (IntPoint) origin offset: (IntPoint) offset{
	_origin = origin;
	return [self translateX: offset.x Y: offset.y];
}

-(IntPoint)translate: (IntPoint) origin X: (int) moveX Y: (int) moveY{
	_origin = origin;
	return [self translateX: moveX Y: moveY];
}

-(IntPoint)translate: (IntPoint) origin pitch: (int) modulePitch X: (int) moveX Y: (int) moveY{
	_origin = origin;
	_modulePitch = modulePitch;
	return [self translateX: moveX Y: moveY];
}

-(IntPoint)translateX: (int) moveX Y: (int) moveY{
	int dp = [QRCodeImageReader DECIMAL_POINT];
	
	int yf = 0;
	if((moveX >= 0) & (moveY >= 0)){
		yf = 1;
	}
	else{
		if((moveX < 0) & (moveY >= 0)){
			yf = -1;
		}
		else{
			if((moveX >= 0) & (moveY < 0)){
				yf = -1;
			}
			else{
				if((moveX < 0) & (moveY < 0)){
					yf = 1;
				}
			}
		}
	}
	
	int dx = (moveX == 0)?0:(_modulePitch * moveX) >> dp;
	int dy = (moveY == 0)?0:(_modulePitch * moveY) >> dp;
	IntPoint p = { 0, 0 };
	if (dx != 0 && dy != 0){
		p = [IntPointHelper translate: p X: ((dx * _cos - dy * _sin) >> dp) Y: (yf * (dx * _cos + dy * _sin)) >> dp];
	}
	else if (dy == 0){
		if (dx < 0){
			yf = -yf;
		}
		p = [IntPointHelper translate: p X: ((dx * _cos) >> dp) Y: (yf * (dx * _sin)) >> dp];
	}
	else if (dx == 0){
		if (dy < 0){
			yf = -yf;
		}
		p = [IntPointHelper translate: p X: ((-yf * (dy * _sin)) >> dp) Y: (dy * _cos) >> dp];
	}
	p = [IntPointHelper translate: p X: _origin.x Y: _origin.y];
	return p;
}

RETAIN_RELEASE(Axis)
@end
