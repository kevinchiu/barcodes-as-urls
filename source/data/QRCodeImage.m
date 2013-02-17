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

#import <CoreGraphics/CGColor.h>
#import <Foundation/Foundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIImage.h>
#import "QRCodeImage.h"

CGContextRef CreateBitmapContext (CGImageRef inImage, BOOL rgb){
	CGContextRef context = NULL;
	CGColorSpaceRef colorSpace = NULL;
	void * bitmapData;
	int bitmapByteCount;
	int bitmapBytesPerRow;
	
	size_t pixelsWide = CGImageGetWidth(inImage);
	size_t pixelsHigh = CGImageGetHeight(inImage);
	
	bitmapBytesPerRow = pixelsWide * (rgb ? 4 : 1);
	bitmapByteCount = (bitmapBytesPerRow * pixelsHigh);
	
	// Use the generic grayscale color space.
	if (!rgb){
		colorSpace = CGColorSpaceCreateWithName(rgb ? kCGColorSpaceGenericRGB : kCGColorSpaceGenericGray);
		if (colorSpace == NULL){
			fprintf(stderr, "Error allocating color space\n");
			return NULL;
	 	}
	}
	
	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	bitmapData = malloc( bitmapByteCount );
	if (bitmapData == NULL){
		fprintf (stderr, "Memory not allocated!");
		CGColorSpaceRelease( colorSpace );
		return NULL;
	}
	
	context = CGBitmapContextCreate (bitmapData,
									 pixelsWide,
									 pixelsHigh,
									 8, // bits per component
									 bitmapBytesPerRow,
									 (colorSpace == NULL) ? CGImageGetColorSpace(inImage) : colorSpace,
									 rgb ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaNone);
	if (context == NULL){
		free (bitmapData);
		fprintf (stderr, "Context not created!");
	}
	// Make sure and release colorspace before returning
	if (colorSpace) {
		CGColorSpaceRelease( colorSpace );
	}
	
	return context;
}

@implementation QRCodeImage
-(QRCodeImage*)init:(UIImage*)image{
	
	[super init];
	rotate90 = NO;
	rgbSpace = NO;
	CGImageRef imgRef = [image imageRef];
	
	cgctx = CreateBitmapContext(imgRef, rgbSpace);
	
	width = CGImageGetWidth(imgRef);
	height = CGImageGetHeight(imgRef);
	CGRect rect = {{0,0},{width,height}};
	
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextDrawImage(cgctx, rect, imgRef);
	imageData = CGBitmapContextGetData (cgctx);
	
	return self;
}
-(void)dealloc{
	
	// When finished, release the context
	CGContextRelease(cgctx);
	// Free image data memory for the context
	if (imageData){
		
		free(imageData);
	}
	[super dealloc];
}

-(int) Width{
	
	if (rotate90){
		
		return height;
	}
	return width;
}

-(int) Height{
	
	if (rotate90){
		
		return width;
	}
	return height;
}

-(int)X: (int) x Y: (int) y{
	
	if (rotate90){
		
		int xo = x, yo = y;
		x = yo;
		y = height - xo - 1;
	}
	if (isJpeg){
		
		unsigned char *px = imageData + (3 * ((y*width)+x));
		int r = px[0], g = px[1], b = px[2];
		return (r * 30 + g * 59 + b * 11) / 100;
	}
	else 
		if (rgbSpace){
			
			int px = *(((int*) imageData)+(y*width)+x);
			// bgra - color order on iPhone
			int r = px >> 8 & 0xFF;
			int g = px >> 16 & 0xFF;
			int b = px >> 24 & 0xFF;
			return (r * 30 + g * 59 + b * 11) / 100;
		}
		else{
			
			unsigned char *pixel = (unsigned char*) (imageData + (y * width) + x);
			int p = (int) *pixel;
			return p*3;
		}
}

-(BOOL)isGrayscale{
	
	return !rgbSpace;
}
@end
