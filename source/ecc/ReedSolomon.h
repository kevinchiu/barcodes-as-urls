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

@interface ReedSolomon : NSObject{
	IntVector *yyyyy;
	
	int NPAR;
	int MAXDEG;
	
	IntVector *synBytes;
	
	/* The Error Locator Polynomial, also known as Lambda or Sigma. Lambda[0] == 1*/
	IntVector *Lambda;
	
	/* The Error Evaluator Polynomial*/
	IntVector *Omega;
	
	/* local ANSI declarations*/
	
	/* error locations found using Chien's search*/
	int ErrorLocs[256];
	int NErrors;
	
	/* erasure flags*/
	int ErasureLocs[256];
	int NErasures;
	
	BOOL correctionSucceeded;
}
-(ReedSolomon*)initWithSource: (IntVector*)source NPAR: (int) NPAR;

-(BOOL)CorrectionSucceeded;
-(int) NumCorrectedErrors;

-(void)correct;
@end
