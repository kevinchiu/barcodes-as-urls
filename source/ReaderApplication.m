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
#import "Exceptions.h"
#import "QRCodeDecoder.h"
#import "ReaderApplication.h"
#import <CoreFoundation/CoreFoundation.h>
#import <CoreSurface/CoreSurface.h>
#import <Foundation/Foundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIPushButton.h>
#import <UIKit/UITable.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UITableColumn.h>
#import <UIKit/UIThreePartButton.h>
#import <UIKit/UITile.h>
#import <UIKit/UITiledView.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIWindow.h>

static ReaderApplication *currentAppliction;
@interface QRPicture{
	UIImage *picture;
	UIImage *preview;
}
@end
@implementation ReaderApplication
- (void) applicationDidFinishLaunching: (id) unused {
	// hide status bar
	[UIHardware _setStatusBarHeight: 0.0f];
	[self setStatusBarMode: 2 orientation: 0 duration: 0.0f fenceID: 0];
	
	// make fullscreen
	CGRect screen= [UIHardware fullScreenApplicationContentRect];
	screen.origin.y = 30.0f;
	UIWindow *window= [[UIWindow alloc] initWithContentRect: screen];
	cameraView = [[CameraView alloc] initWithFrame: screen];
	
	//pack window
	[window setContentView: cameraView];
	[window orderFront: self];
	[window makeKey: self];
	[window _setHidden: NO];
	
	//activate preview
	camController = [CameraController sharedInstance];
	[[CameraController sharedInstance] setDelegate:self];
	[camController startPreview];
	
	//keep track of threading
	recognizing = NO;
	currentAppliction = self;
}
+(ReaderApplication*)application {
	return currentAppliction;
}
- (void)mouseDown:(GSEventRef)event{
	[self takePicture:self];
}
-(void)takePicture:(id)sender{
	if (!recognizing){
		[camController capturePhoto];
	}
}
-(void)cameraController:(id)sender tookPicture:(UIImage*)picture withPreview:(UIImage*)preview jpegData:(NSData*)jpeg imageProperties:(NSDictionary *)exif{
	recognizing = YES;
	[camController stopPreview];
	[preview retain];
	[NSThread detachNewThreadSelector:@selector(process:) toTarget:self withObject:preview];
}
- (void) process: (UIImage*) picture{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	@try{
		//decode
		QRCodeDecoder *decoder = [[QRCodeDecoder alloc] init];
		QRCodeImage *qrc = [[QRCodeImage alloc] init: picture];
		NSString *decodedString = [decoder decode: qrc];
		[qrc release];
		[decoder release];
		[decodedString retain];
		//succeed
		[self performSelectorOnMainThread:@selector(success:) withObject: decodedString waitUntilDone: NO];
	}@catch (DecodingFailedException *de){
		//fail
		[self performSelectorOnMainThread:@selector(failure:) withObject: nil waitUntilDone: NO];
	}@finally{
		recognizing = NO;
		[picture release];
	}
	[pool release];
}
- (void)cameraControllerReadyStateChanged:(id)fp8{
	NSLog(@"required method...ignore");
}
- (void) success: (NSString*) result{
	if (result){
		NSString *baseurl = [[NSURL alloc] initFileURLWithPath:result];
		[self openURL:baseurl];
	}
	[result release];
}
- (void) failure: (NSString*) result{
	NSLog(@"Reading failed.");
}

@end
