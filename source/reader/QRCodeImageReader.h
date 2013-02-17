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
#import "../data/QRCodeSymbol.h"
#import "../geom/SamplingGrid.h"
#import "../ValueMatrix.h"
#import <Foundation/Foundation.h>

@interface QRCodeImageReader : NSObject{
	SamplingGrid *_samplingGrid;
	BoolMatrix *_bitmap;
}
-(QRCodeImageReader*)initReader;
-(QRCodeSymbol*)getQRCodeSymbol: (IntMatrix*) image;
-(QRCodeSymbol*)getQRCodeSymbolWithAdjustedGrid: (IntPoint) adjust;
-(BOOL)hasSamplingGrid;
+(int)DECIMAL_POINT;
@end
