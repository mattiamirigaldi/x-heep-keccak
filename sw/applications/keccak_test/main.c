#include <stdio.h>
#include <inttypes.h>
#include <string.h>

#include "./../../external/keccak/keccak_driver.h"

int main(){

	uint32_t Din[50];
	uint32_t Dout[50];

	uint32_t D_expected[50];
	int i = 0;

	memset(Din, 0, sizeof(Din));
	memset(Dout, 0, sizeof(Dout));
	memset(D_expected, 0, sizeof(D_expected));
	
 
	Din[0] = 0x7369C667;
	Din[1] = 0xEC4AFF51;
	Din[2] = 0xABBACD29;
	Din[3] = 0x00000010;
	Din[31] = 0x80000000;


	D_expected[0] = 0xE1ADB0E2;
	D_expected[1] = 0xE7CB8356;
	D_expected[2] = 0xBB3F5FB8;
	D_expected[3] = 0x573A5BD7;
	D_expected[4] = 0xF7CA02A1;
	D_expected[5] = 0xE9784CC5;
	D_expected[6] = 0x6E54F256;
	D_expected[7] = 0x60A4C685;
	D_expected[8] = 0x77051F83;
	D_expected[9] = 0x243FCBAA;
	D_expected[10] = 0x6459DB0B;
	D_expected[11] = 0x4C063DD5;
	D_expected[12] = 0xE046DE71;
	D_expected[13] = 0xCB4B81C6;
	D_expected[14] = 0x94051793;
	D_expected[15] = 0xDB31F24C;
	D_expected[16] = 0xA13FC86C;
	D_expected[17] = 0xF16E32DD;
	D_expected[18] = 0xB962FC91;
	D_expected[19] = 0xB7737708;
	D_expected[20] = 0xD3CA2E7A;
	D_expected[21] = 0xFA27C801;
	D_expected[22] = 0x53C85108;
	D_expected[23] = 0xF72A3CCA;
	D_expected[24] = 0x73E732CD;
	D_expected[25] = 0xADF0E783;
	D_expected[26] = 0x8470BD54;
	D_expected[27] = 0xC4BDD1BF; 
	D_expected[28] = 0xD10B916F;
	D_expected[29] = 0x7C8C1F77; 
	D_expected[30] = 0x51129474;
	D_expected[31] = 0x440A2670; 
	D_expected[32] = 0x3D77CB49;
	D_expected[33] = 0xE9960C44; 
	D_expected[34] = 0xEC5001EB;
	D_expected[35] = 0xE4251E39; 
	D_expected[36] = 0x77A0EEC5;
	D_expected[37] = 0xEA4FD653;
	D_expected[38] = 0xEBC86BD4;
	D_expected[39] = 0x7B6773E7; 
	D_expected[40] = 0xE77DF6B0;
	D_expected[41] = 0x128FDC4B; 
	D_expected[42] = 0x0DB0D48A;
	D_expected[43] = 0x02F1B12E; 
	D_expected[44] = 0x241B344D;
	D_expected[45] = 0x0DC38AE5;
	D_expected[46] = 0xC3EE4E27;
	D_expected[47] = 0x532483D8;
	D_expected[48] = 0x0271BFE2;
	D_expected[49] = 0x84B1B424;

	printf("Hello Keccak !\n");
    KeccakF1600_StatePermute(Din,Dout);	

	for (i = 0; i< 50; i++ ){
		if (Din[i] != D_expected[i]){
			printf("ERROR keccak output did not match test vector. ");
        	printf("Expected D[%d]: %02X but obtained %02X \n", i, D_expected[i], Din[i]);
		}	
	}	
	printf("Keccak terminated!\n");
	return 0;

}
