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
#import "../../QRCommon.h"
#import "LogicalSeed.h"

static LogicalSeed *singleton = nil;

static int s0[] = {6, 14};
static int s1[] = {6, 18};
static int s2[] = {6, 22};
static int s3[] = {6, 26};
static int s4[] = {6, 30};
static int s5[] = {6, 34};

static int s6[] = {6, 22, 38};
static int s7[] = {6, 24, 42};
static int s8[] = {6, 26, 46};
static int s9[] = {6, 28, 50};
static int s10[] = {6, 30, 54};
static int s11[] = {6, 32, 58};
static int s12[] = {6, 34, 62};

static int s13[] = {6, 26, 46, 66};
static int s14[] = {6, 26, 48, 70};
static int s15[] = {6, 26, 50, 74};
static int s16[] = {6, 30, 54, 78};
static int s17[] = {6, 30, 56, 82};
static int s18[] = {6, 30, 58, 86};
static int s19[] = {6, 34, 62, 90};

static int s20[] = {6, 28, 50, 72, 94};
static int s21[] = {6, 26, 50, 74, 98};
static int s22[] = {6, 30, 54, 78, 102};
static int s23[] = {6, 28, 54, 80, 106};
static int s24[] = {6, 32, 58, 84, 110};
static int s25[] = {6, 30, 58, 86, 114};
static int s26[] = {6, 34, 62, 90, 118};

static int s27[] = {6, 26, 50, 74, 98, 122};
static int s28[] = {6, 30, 54, 78, 102, 126};
static int s29[] = {6, 26, 52, 78, 104, 130};
static int s30[] = {6, 30, 56, 82, 108, 134};
static int s31[] = {6, 34, 60, 86, 112, 138};
static int s32[] = {6, 30, 58, 86, 114, 142};
static int s33[] = {6, 34, 62, 90, 118, 146};

static int s34[] = {6, 30, 54, 78, 102, 126, 150};
static int s35[] = {6, 24, 50, 76, 102, 128, 154};
static int s36[] = {6, 28, 54, 80, 106, 132, 158};
static int s37[] = {6, 32, 58, 84, 110, 136, 162};
static int s38[] = {6, 26, 54, 82, 110, 138, 166};
static int s39[] = {6, 30, 58, 86, 114, 142, 170};

#define ADDELT(x,l) v = [IntVector fromArray: s##x count: l]; [nsa addObject: v]

@interface LogicalSeed (private)
+(void)ensure;
@end

@implementation LogicalSeed
+(void)ensure{
	if (singleton == nil){
		LogicalSeed *s = [[LogicalSeed alloc] init];
		NSMutableArray *nsa = [[NSMutableArray alloc] init];
		IntVector *v;
		
		ADDELT(0,2);
		ADDELT(1,2);
		ADDELT(2,2);
		ADDELT(3,2);
		ADDELT(4,2);
		ADDELT(5,2);
		
		ADDELT(6,3);
		ADDELT(7,3);
		ADDELT(8,3);
		ADDELT(9,3);
		ADDELT(10,3);
		ADDELT(11,3);
		ADDELT(12,3);
		
		ADDELT(13,4);
		ADDELT(14,4);
		ADDELT(15,4);
		ADDELT(16,4);
		ADDELT(17,4);
		ADDELT(18,4);
		ADDELT(19,4);
		
		ADDELT(20,5);
		ADDELT(21,5);
		ADDELT(22,5);
		ADDELT(23,5);
		ADDELT(24,5);
		ADDELT(25,5);
		ADDELT(26,5);
		
		ADDELT(27,6);
		ADDELT(28,6);
		ADDELT(29,6);
		ADDELT(30,6);
		ADDELT(31,6);
		ADDELT(32,6);
		ADDELT(33,6);
		
		ADDELT(34,7);
		ADDELT(35,7);
		ADDELT(36,7);
		ADDELT(37,7);
		ADDELT(38,7);
		ADDELT(39,7);
		
		s->seed = nsa;
		singleton = s;
	}
}

+(IntVector*)getSeed: (int) version{
	[LogicalSeed ensure];
	if (!singleton || !singleton->seed){
		NSLog(@"LogicalSeed singledton disappeared!");
	}
	IntVector *iv = [singleton->seed objectAtIndex: version-1];
	return iv;
}

+(int)getSeed: (int) version pattern: (int) patternNumber{
	[LogicalSeed ensure];
	if (!singleton || !singleton->seed){
		NSLog(@"LogicalSeed singledton disappeared!");
	}
	IntVector* iv = [singleton->seed objectAtIndex: version-1];
	if (!iv){
		NSLog(@"Failed to get LogicalSeed instance");
	}
	int pn = [iv get: patternNumber];
	return pn;
}

RETAIN_RELEASE(LogicalSeed)
@end
