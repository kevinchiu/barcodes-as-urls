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
#ifdef RETAIN_DEBUG

#define RETAIN_RELEASE(x) \
-(id) retain { NSLog(@"-->retaining %s %x", #x, self); return [super retain]; } \
-(oneway void) release { int rc = [self retainCount]; NSLog(@"-->releasing %s %x %d", #x, self, [self retainCount]); [super release]; NSLog(@"Done %x %d", self, rc == 1 ? 0 : [self retainCount]); } \
-(id) autorelease { NSLog(@"-->AutoRelease %s %x", #x, self); return [super autorelease]; }

#else

#define RETAIN_RELEASE(x)
#endif
/*
@protocol ProgressCallback
-(void)setProgress: (float) progress;
@end

extern id<ProgressCallback> gProgress;
*/
