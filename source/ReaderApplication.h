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
#import "photoLibrary.h"
#import "QRCommon.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIImageAndTextTableCell.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIPushButton.h>
#import <UIKit/UITableCell.h>

@class CameraController;
@interface ReaderApplication : UIApplication{
	CameraView *cameraView;
	CameraController* camController;
	UIView *mainView;
	BOOL recognizing;
}
+(ReaderApplication*)application;
- (void)cameraControllerReadyStateChanged:(id)fp8;
- (void) takePicture:(id)sender;
- (void) process: (UIImage*) picture;
- (void) success: (NSString*) result;
- (void) failure: (NSString*) result;
@end
