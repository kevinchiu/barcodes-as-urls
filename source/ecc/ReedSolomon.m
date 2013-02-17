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
#import "ReedSolomon.h"

static int gexp[] = {
	1, 2, 4, 8, 16, 32, 64, 128, 29, 58, 116, 232, 205, 135, 19, 38, 
	76, 152, 45, 90, 180, 117, 234, 201, 143, 3, 6, 12, 24, 48, 96, 192, 
	157, 39, 78, 156, 37, 74, 148, 53, 106, 212, 181, 119, 238, 193, 159, 35, 
	70, 140, 5, 10, 20, 40, 80, 160, 93, 186, 105, 210, 185, 111, 222, 161, 
	95, 190, 97, 194, 153, 47, 94, 188, 101, 202, 137, 15, 30, 60, 120, 240, 
	253, 231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163, 91, 182, 113, 226, 
	217, 175, 67, 134, 17, 34, 68, 136, 13, 26, 52, 104, 208, 189, 103, 206, 
	129, 31, 62, 124, 248, 237, 199, 147, 59, 118, 236, 197, 151, 51, 102, 204, 
	133, 23, 46, 92, 184, 109, 218, 169, 79, 158, 33, 66, 132, 21, 42, 84, 
	168, 77, 154, 41, 82, 164, 85, 170, 73, 146, 57, 114, 228, 213, 183, 115, 
	230, 209, 191, 99, 198, 145, 63, 126, 252, 229, 215, 179, 123, 246, 241, 255, 
	227, 219, 171, 75, 150, 49, 98, 196, 149, 55, 110, 220, 165, 87, 174, 65, 
	130, 25, 50, 100, 200, 141, 7, 14, 28, 56, 112, 224, 221, 167, 83, 166, 
	81, 162, 89, 178, 121, 242, 249, 239, 195, 155, 43, 86, 172, 69, 138, 9, 
	18, 36, 72, 144, 61, 122, 244, 245, 247, 243, 251, 235, 203, 139, 11, 22, 
	44, 88, 176, 125, 250, 233, 207, 131, 27, 54, 108, 216, 173, 71, 142, 1
};
static int glog[] ={
	0, 0, 1, 25, 2, 50, 26, 198, 3, 223, 51, 238, 27, 104, 199, 75, 
	4, 100, 224, 14, 52, 141, 239, 129, 28, 193, 105, 248, 200, 8, 76, 113, 
	5, 138, 101, 47, 225, 36, 15, 33, 53, 147, 142, 218, 240, 18, 130, 69, 
	29, 181, 194, 125, 106, 39, 249, 185, 201, 154, 9, 120, 77, 228, 114, 166, 
	6, 191, 139, 98, 102, 221, 48, 253, 226, 152, 37, 179, 16, 145, 34, 136, 
	54, 208, 148, 206, 143, 150, 219, 189, 241, 210, 19, 92, 131, 56, 70, 64, 
	30, 66, 182, 163, 195, 72, 126, 110, 107, 58, 40, 84, 250, 133, 186, 61, 
	202, 94, 155, 159, 10, 21, 121, 43, 78, 212, 229, 172, 115, 243, 167, 87, 
	7, 112, 192, 247, 140, 128, 99, 13, 103, 74, 222, 237, 49, 197, 254, 24, 
	227, 165, 153, 119, 38, 184, 180, 124, 17, 68, 146, 217, 35, 32, 137, 46, 
	55, 63, 209, 91, 149, 188, 207, 205, 144, 135, 151, 178, 220, 252, 190, 97, 
	242, 86, 211, 171, 20, 42, 93, 158, 132, 60, 57, 83, 71, 109, 65, 162, 
	31, 45, 67, 216, 183, 123, 164, 118, 196, 23, 73, 236, 127, 12, 111, 246, 
	108, 161, 59, 82, 41, 157, 85, 170, 251, 96, 134, 177, 187, 204, 62, 90, 
	203, 89, 95, 176, 156, 169, 160, 81, 11, 245, 22, 235, 122, 117, 44, 215, 
	79, 174, 213, 233, 230, 231, 173, 232, 116, 214, 244, 234, 168, 80, 88, 175
};

/* multiplication using logarithms*/
int gmult(int a, int b){
	int i, j;
	if (a == 0 || b == 0){
		return (0);
	}
	i = glog[a];
	j = glog[b];
	return (gexp[(i + j) % 255]);
}

int ginv(int elt){
	return (gexp[255 - glog[elt]]);
}

int compute_discrepancy(const int* lambda, const int* S, int L, int n){
	int i, sum = 0;
	
	for (i = 0; i <= L; i++){
		sum ^= gmult(lambda[i], S[n - i]);
	}
	return (sum);
}

void mult_polys(int *dst, const int *p1, const int *p2, const int maxDeg){
	int i, j;
	int *tmp1 = malloc(sizeof(int) * maxDeg * 2);
	
	for (i = 0; i < (maxDeg * 2); i++){
		dst[i] = 0;
	}
	
	for (i = 0; i < maxDeg; i++){
		for (j = maxDeg; j < (maxDeg * 2); j++){
			tmp1[j] = 0;
		}
		
		/* scale tmp1 by p1[i]*/
		for (j = 0; j < maxDeg; j++){
			tmp1[j] = gmult(p2[j], p1[i]);
		}
		/* and mult (shift) tmp1 right by i*/
		for (j = (maxDeg * 2) - 1; j >= i; j--){
			tmp1[j] = tmp1[j - i];
		}
		for (j = 0; j < i; j++){
			tmp1[j] = 0;
		}
		
		/* add into partial product*/
		for (j = 0; j < (maxDeg * 2); j++){
			dst[j] ^= tmp1[j];
		}
	}
	free(tmp1);
}

@interface ReedSolomon (Private)
-(void)decode_data: (IntVector*)data;
-(void)Modified_Berlekamp_Massey;
-(void)compute_modified_omega;
-(void)init_gamma:(int*)gamma;
-(void)compute_next_omega: (int) d A: (const int*) A dst: (int*) dst src: (const int*) src;
-(void)add_polys: (int*) dst src: (const int*) src;
-(void)copy_poly: (int*) dst src: (const int*) src;
-(void)scale_poly: (int) k src: (int*) poly;
-(void)mul_z_poly: (int*) src;
-(void)Find_Roots;
-(BOOL)correct_errors_erasures: (IntVector*) codeword nerasures: (int) nerasures erasures: (int*) erasures;
@end

@implementation ReedSolomon

-(ReedSolomon*)initWithSource: (IntVector*)source NPAR: (int) npar{
	[super init];
	NPAR = npar;
	MAXDEG = NPAR * 2;
	synBytes = [[IntVector alloc] initWithLength: MAXDEG];
	Lambda = [[IntVector alloc] initWithLength: MAXDEG];
	Omega = [[IntVector alloc] initWithLength: MAXDEG];
	yyyyy = [source retain];
	memset(ErrorLocs, 0, sizeof(ErrorLocs));
	memset(ErasureLocs, 0, sizeof(ErasureLocs));
	NErasures = 0;
	correctionSucceeded = YES;
	return self;
}

-(void) dealloc{
	[yyyyy release];
	[synBytes release];
	[Lambda release];
	[Omega release];
	[super dealloc];
}

-(BOOL)CorrectionSucceeded { return correctionSucceeded; }
-(int) NumCorrectedErrors { return NErrors; }

-(void)correct{
	[self decode_data: yyyyy];
	correctionSucceeded = true;
	BOOL hasError = NO;
	int i;
	for (i = 0; i < NPAR; i++){
		if ([synBytes get:i] != 0){
			hasError = true;
			break;
		}
	}
	if (hasError){
		int erasures[1];
		erasures[0] = 0;
		correctionSucceeded = [self correct_errors_erasures: yyyyy nerasures: 0 erasures: erasures];
	}
}

-(void)decode_data: (IntVector*)data{
	int i, j, sum, l = [data length];
	for (j = 0; j < NPAR; j++){
		sum = 0;
		for (i = 0; i < l; i++){
			sum = [data get:i] ^ gmult(gexp[j], sum);
		}
		[synBytes setValue: sum at: j];
	}
}

-(void)Modified_Berlekamp_Massey{
	int n, L, L2, k, d, i, aSz = sizeof(int)*MAXDEG;
	int *psi = malloc(aSz);
	int *psi2 = malloc(aSz);
	int *D = malloc(aSz);
	int *gamma = malloc(aSz);
	
	/* initialize Gamma, the erasure locator polynomial*/
	[self init_gamma:gamma];
	
	/* initialize to z*/
	[self copy_poly: D src: gamma];
	[self mul_z_poly: D];
	[self copy_poly:psi src: gamma];
	
	k = - 1; 
	L = NErasures;
	
	for (n = NErasures; n < NPAR; n++){
		d = compute_discrepancy(psi, [synBytes asROArray], L, n);
		
		if (d != 0){
			/* psi2 = psi - d*D*/
			for (i = 0; i < MAXDEG; i++){
				psi2[i] = psi[i] ^ gmult(d, D[i]);
			}
			
			
			if (L < (n - k)){
				L2 = n - k;
				k = n - L;
				/* D = scale_poly(ginv(d), psi);*/
				for (i = 0; i < MAXDEG; i++){
					D[i] = gmult(psi[i],ginv(d));
				}
				L = L2;
			}
			
			/* psi = psi2*/
			for (i = 0; i < MAXDEG; i++){
				psi[i] = psi2[i];
			}
		}
		[self mul_z_poly: D];
	}
	
	for (i = 0; i < MAXDEG; i++){
		[Lambda setValue: psi[i] at: i];
	}
	[self compute_modified_omega];
	
	free(psi);
	free(psi2);
	free(D);
	free(gamma);
}

/* given Psi (called Lambda in Modified_Berlekamp_Massey) and synBytes,
 compute the combined erasure/error evaluator polynomial as 
 Psi*S mod z^4
*/
-(void)compute_modified_omega{
	int i;
	int *product = malloc(sizeof(int)*(MAXDEG * 2));
	
	mult_polys(product, [Lambda asROArray], [synBytes asROArray], MAXDEG);
	[Omega zero];
	for (i = 0; i < NPAR; i++){
		[Omega setValue: product[i] at: i];
	}
	free(product);
}

-(void)init_gamma:(int*)gamma{
	int e;
	int *tmp = malloc(sizeof(int)*MAXDEG);
	
	memset(gamma, 0, sizeof(int)*MAXDEG);
	memset(tmp, 0, sizeof(int)*MAXDEG);
	
	gamma[0] = 1;
	
	for (e = 0; e < NErasures; e++){
		[self copy_poly: tmp src: gamma];
		[self scale_poly: gexp[ErasureLocs[e]] src: tmp];
		[self mul_z_poly: tmp];
		[self add_polys: gamma src: tmp];
	}
}

-(void)compute_next_omega: (int) d A: (const int*) A dst: (int*) dst src: (const int*) src{
	int i;
	for (i = 0; i < MAXDEG; i++){
		dst[i] = src[i] ^ gmult(d, A[i]);
	}
}

-(void)add_polys: (int*) dst src: (const int*) src{
	int i;
	for (i = 0; i < MAXDEG; i++){
		dst[i] ^= src[i];
	}
}

-(void)copy_poly: (int*) dst src: (const int*) src{
	memcpy(dst, src, sizeof(int)*MAXDEG);
}

-(void)scale_poly: (int) k src: (int*) poly{
	int i;
	for (i = 0; i < MAXDEG; i++){
		poly[i] = gmult(k, poly[i]);
	}
}

-(void)mul_z_poly: (int*) src{
	int i;
	for (i = MAXDEG - 1; i > 0; i--){
		src[i] = src[i - 1];
	}
	src[0] = 0;
}

/* Finds all the roots of an error-locator polynomial with coefficients
 * Lambda[j] by evaluating Lambda at successive values of alpha. 
 * 
 * This can be tested with the decoder's equations case.
*/		
-(void)Find_Roots{
	int sum, r, k;
	NErrors = 0;
	
	for (r = 1; r < 256; r++){
		sum = 0;
		/* evaluate lambda at r*/
		for (k = 0; k < NPAR + 1; k++){
			sum ^= gmult(gexp[(k * r) % 255], [Lambda get:k]);
		}
		if (sum == 0){
			ErrorLocs[NErrors] = (255 - r); NErrors++;
		}
	}
}

/* Combined Erasure And Error Magnitude Computation 
 * 
 * Pass in the codeword, its size in bytes, as well as
 * an array of any known erasure locations, along the number
 * of these erasures.
 * 
 * Evaluate Omega(actually Psi)/Lambda' at the roots
 * alpha^(-i) for error locs i. 
 *
 * Returns 1 if everything ok, or 0 if an out-of-bounds error is found
 *
*/
-(BOOL)correct_errors_erasures: (IntVector*) codeword nerasures: (int) nerasures erasures: (int*) erasures{
	int r, i, j, err, csize = [codeword length];
	
	/* If you want to take advantage of erasure correction, be sure to
	 set NErasures and ErasureLocs[] with the locations of erasures. 
	*/
	NErasures = nerasures;
	for (i = 0; i < NErasures; i++){
		ErasureLocs[i] = erasures[i];
	}
	
	[self Modified_Berlekamp_Massey];
	[self Find_Roots];
	
	if (NErrors == 0){
		return YES;
	}
	if ((NErrors <= NPAR) || NErrors > 0){
		/* first check for illegal error locs*/
		for (r = 0; r < NErrors; r++){
			if (ErrorLocs[r] >= csize){
				return NO;
			}
		}
		
		for (r = 0; r < NErrors; r++){
			int num, denom, loc, tmp;
			loc = ErrorLocs[r];
			/* evaluate Omega at alpha^(-i)*/
			
			num = 0;
			for (j = 0; j < MAXDEG; j++){
				num ^= gmult([Omega get:j], gexp[((255 - loc) * j) % 255]);
			}
			
			/* evaluate Lambda' (derivative) at alpha^(-i) ; all odd powers disappear*/
			denom = 0;
			for (j = 1; j < MAXDEG; j += 2){
				denom ^= gmult([Lambda get:j], gexp[((255 - loc) * j) % 255]);
			}
			
			err = gmult(num, ginv(denom));
			tmp = csize - loc - 1;
			
			int nval = [codeword get: tmp] ^ err;
			[codeword setValue: nval at: tmp];
		}
		
		return YES;
	}
	else{
		return NO;
	}
}

@end
