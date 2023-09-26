#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "stats.h"
#include "csr.h"

#include "../include/api.h"
#include "../include/randombytes.h"

static void printbytes(const uint8_t *x, size_t xlen) {
    size_t i;
    for (i = 0; i < xlen; i++) {
        printf("%02x", x[i]);
    }
    printf("\n");
    }


int main(void) {

    uint8_t key_b[PQCLEAN_KYBER512_CLEAN_CRYPTO_BYTES];
    uint8_t sendb[PQCLEAN_KYBER512_CLEAN_CRYPTO_CIPHERTEXTBYTES];
    uint8_t pk[PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES];
    int j;

	
	pk[0] = 0x5f;
	pk[1] = 0xc4;
	pk[2] = 0x4b;
	pk[3] = 0x99;
	pk[4] = 0xd7;
	pk[5] = 0x58;
	pk[6] = 0x4f;
	pk[7] = 0x38;
	pk[8] = 0xcd;
	pk[9] = 0x28;
	pk[10] = 0x36;
	pk[11] = 0x0c;
	pk[12] = 0xc5;
	pk[13] = 0x62;
	pk[14] = 0x5a;
	pk[15] = 0x90;
	pk[16] = 0x5b;
	pk[17] = 0x96;
	pk[18] = 0xaf;
	pk[19] = 0x12;
	pk[20] = 0x93;
	pk[21] = 0x0e;
	pk[22] = 0xd5;
	pk[23] = 0xb5;
	pk[24] = 0xfe;
	pk[25] = 0x2a;
	pk[26] = 0x82;
	pk[27] = 0xfc;
	pk[28] = 0x5a;
	pk[29] = 0xa7;
	pk[30] = 0xdc;
	pk[31] = 0x4b;
	pk[32] = 0x82;
	pk[33] = 0x9f;
	pk[34] = 0xe3;
	pk[35] = 0x76;
	pk[36] = 0x35;
	pk[37] = 0xf1;
	pk[38] = 0x3f;
	pk[39] = 0x5a;
	pk[40] = 0xf2;
	pk[41] = 0xa6;
	pk[42] = 0xd3;
	pk[43] = 0x08;
	pk[44] = 0x1d;
	pk[45] = 0xad;
	pk[46] = 0x87;
	pk[47] = 0x87;
	pk[48] = 0x85;
	pk[49] = 0x69;
	pk[50] = 0x8a;
	pk[51] = 0x0a;
	pk[52] = 0xa9;
	pk[53] = 0x14;
	pk[54] = 0x37;
	pk[55] = 0x4c;
	pk[56] = 0x4e;
	pk[57] = 0x43;
	pk[58] = 0xb8;
	pk[59] = 0x9f;
	pk[60] = 0x09;
	pk[61] = 0x4a;
	pk[62] = 0x78;
	pk[63] = 0x92;
	pk[64] = 0xaa;
	pk[65] = 0x14;
	pk[66] = 0x9a;
	pk[67] = 0x38;
	pk[68] = 0xb4;
	pk[69] = 0x9c;
	pk[70] = 0x06;
	pk[71] = 0xa0;
	pk[72] = 0x68;
	pk[73] = 0xd8;
	pk[74] = 0x29;
	pk[75] = 0xa8;
	pk[76] = 0xd2;
	pk[77] = 0x49;
	pk[78] = 0xe7;
	pk[79] = 0x53;
	pk[80] = 0xa3;
	pk[81] = 0x75;
	pk[82] = 0xd0;
	pk[83] = 0x97;
	pk[84] = 0xa0;
	pk[85] = 0xf1;
	pk[86] = 0x62;
	pk[87] = 0xe6;
	pk[88] = 0xc3;
	pk[89] = 0xa4;
	pk[90] = 0xdf;
	pk[91] = 0xe8;
	pk[92] = 0xc7;
	pk[93] = 0x97;
	pk[94] = 0x61;
	pk[95] = 0x41;
	pk[96] = 0x0c;
	pk[97] = 0x60;
	pk[98] = 0x5e;
	pk[99] = 0xd3;
	pk[100] = 0x89;
	pk[101] = 0x9a;
	pk[102] = 0x3f;
	pk[103] = 0xc4;
	pk[104] = 0x43;
	pk[105] = 0x78;
	pk[106] = 0xe1;
	pk[107] = 0x4f;
	pk[108] = 0x28;
	pk[109] = 0x87;
	pk[110] = 0x9e;
	pk[111] = 0x8f;
	pk[112] = 0x14;
	pk[113] = 0x80;
	pk[114] = 0x77;
	pk[115] = 0xe6;
	pk[116] = 0xbc;
	pk[117] = 0x3b;
	pk[118] = 0xb2;
	pk[119] = 0xae;
	pk[120] = 0x56;
	pk[121] = 0x17;
	pk[122] = 0x8c;
	pk[123] = 0x49;
	pk[124] = 0x16;
	pk[125] = 0x11;
	pk[126] = 0xbf;
	pk[127] = 0x6a;
	pk[128] = 0xaf;
	pk[129] = 0x5f;
	pk[130] = 0x9a;
	pk[131] = 0x9c;
	pk[132] = 0xb9;
	pk[133] = 0xb5;
	pk[134] = 0x65;
	pk[135] = 0x92;
	pk[136] = 0x23;
	pk[137] = 0x00;
	pk[138] = 0x79;
	pk[139] = 0x40;
	pk[140] = 0xbc;
	pk[141] = 0xd6;
	pk[142] = 0xf8;
	pk[143] = 0xa2;
	pk[144] = 0x32;
	pk[145] = 0x80;
	pk[146] = 0xa5;
	pk[147] = 0x60;
	pk[148] = 0x15;
	pk[149] = 0x33;
	pk[150] = 0x0e;
	pk[151] = 0x85;
	pk[152] = 0x77;
	pk[153] = 0x25;
	pk[154] = 0x95;
	pk[155] = 0x87;
	pk[156] = 0xb1;
	pk[157] = 0x26;
	pk[158] = 0x06;
	pk[159] = 0xf4;
	pk[160] = 0xc9;
	pk[161] = 0x37;
	pk[162] = 0xea;
	pk[163] = 0x13;
	pk[164] = 0x60;
	pk[165] = 0x6c;
	pk[166] = 0xb3;
	pk[167] = 0xbb;
	pk[168] = 0x04;
	pk[169] = 0x60;
	pk[170] = 0x66;
	pk[171] = 0xad;
	pk[172] = 0x29;
	pk[173] = 0x42;
	pk[174] = 0x61;
	pk[175] = 0xe2;
	pk[176] = 0xb2;
	pk[177] = 0x20;
	pk[178] = 0x22;
	pk[179] = 0xbc;
	pk[180] = 0xc7;
	pk[181] = 0x46;
	pk[182] = 0x78;
	pk[183] = 0xa5;
	pk[184] = 0x52;
	pk[185] = 0x05;
	pk[186] = 0x70;
	pk[187] = 0xd8;
	pk[188] = 0x8e;
	pk[189] = 0x4c;
	pk[190] = 0xeb;
	pk[191] = 0x42;
	pk[192] = 0x69;
	pk[193] = 0x26;
	pk[194] = 0x31;
	pk[195] = 0xe7;
	pk[196] = 0xe3;
	pk[197] = 0x71;
	pk[198] = 0x1c;
	pk[199] = 0x4b;
	pk[200] = 0x2f;
	pk[201] = 0xd5;
	pk[202] = 0x34;
	pk[203] = 0x7f;
	pk[204] = 0x03;
	pk[205] = 0x28;
	pk[206] = 0x59;
	pk[207] = 0x83;
	pk[208] = 0x40;
	pk[209] = 0xcb;
	pk[210] = 0x3c;
	pk[211] = 0x65;
	pk[212] = 0xc8;
	pk[213] = 0xf5;
	pk[214] = 0x5a;
	pk[215] = 0xc0;
	pk[216] = 0x27;
	pk[217] = 0x16;
	pk[218] = 0x83;
	pk[219] = 0x10;
	pk[220] = 0x94;
	pk[221] = 0xcb;
	pk[222] = 0x6e;
	pk[223] = 0xb9;
	pk[224] = 0x0f;
	pk[225] = 0x17;
	pk[226] = 0x5b;
	pk[227] = 0x17;
	pk[228] = 0x3d;
	pk[229] = 0x9c;
	pk[230] = 0x65;
	pk[231] = 0x03;
	pk[232] = 0x29;
	pk[233] = 0xaa;
	pk[234] = 0xf5;
	pk[235] = 0x13;
	pk[236] = 0x63;
	pk[237] = 0x36;
	pk[238] = 0x33;
	pk[239] = 0xbb;
	pk[240] = 0x2c;
	pk[241] = 0xe6;
	pk[242] = 0x85;
	pk[243] = 0x8e;
	pk[244] = 0x74;
	pk[245] = 0x47;
	pk[246] = 0xab;
	pk[247] = 0xc4;
	pk[248] = 0x1b;
	pk[249] = 0x6f;
	pk[250] = 0xb0;
	pk[251] = 0x6d;
	pk[252] = 0xa8;
	pk[253] = 0x78;
	pk[254] = 0x25;
	pk[255] = 0x72;
	pk[256] = 0xc3;
	pk[257] = 0x32;
	pk[258] = 0xb0;
	pk[259] = 0x96;
	pk[260] = 0x60;
	pk[261] = 0x36;
	pk[262] = 0x69;
	pk[263] = 0x26;
	pk[264] = 0xbf;
	pk[265] = 0x52;
	pk[266] = 0x9e;
	pk[267] = 0xd8;
	pk[268] = 0xca;
	pk[269] = 0xaa;
	pk[270] = 0x62;
	pk[271] = 0x43;
	pk[272] = 0xcc;
	pk[273] = 0xdb;
	pk[274] = 0x15;
	pk[275] = 0x2b;
	pk[276] = 0x36;
	pk[277] = 0xba;
	pk[278] = 0x6e;
	pk[279] = 0x47;
	pk[280] = 0xc7;
	pk[281] = 0x14;
	pk[282] = 0x14;
	pk[283] = 0x5c;
	pk[284] = 0x86;
	pk[285] = 0xf5;
	pk[286] = 0xb3;
	pk[287] = 0xb6;
	pk[288] = 0x1d;
	pk[289] = 0xe8;
	pk[290] = 0x4e;
	pk[291] = 0xf1;
	pk[292] = 0x47;
	pk[293] = 0x0d;
	pk[294] = 0x03;
	pk[295] = 0xfa;
	pk[296] = 0x01;
	pk[297] = 0x35;
	pk[298] = 0xe3;
	pk[299] = 0x51;
	pk[300] = 0x94;
	pk[301] = 0xfa;
	pk[302] = 0x1f;
	pk[303] = 0xb3;
	pk[304] = 0xbc;
	pk[305] = 0x86;
	pk[306] = 0x0f;
	pk[307] = 0xa5;
	pk[308] = 0x00;
	pk[309] = 0xd1;
	pk[310] = 0x29;
	pk[311] = 0x9a;
	pk[312] = 0xee;
	pk[313] = 0x88;
	pk[314] = 0xce;
	pk[315] = 0x56;
	pk[316] = 0x05;
	pk[317] = 0x43;
	pk[318] = 0x76;
	pk[319] = 0xc1;
	pk[320] = 0x19;
	pk[321] = 0x9c;
	pk[322] = 0x55;
	pk[323] = 0x3d;
	pk[324] = 0xd9;
	pk[325] = 0x0a;
	pk[326] = 0x8d;
	pk[327] = 0x6f;
	pk[328] = 0x9c;
	pk[329] = 0xc7;
	pk[330] = 0x63;
	pk[331] = 0xc8;
	pk[332] = 0x11;
	pk[333] = 0xd0;
	pk[334] = 0xc6;
	pk[335] = 0x6d;
	pk[336] = 0xa6;
	pk[337] = 0xf8;
	pk[338] = 0x51;
	pk[339] = 0xab;
	pk[340] = 0xf1;
	pk[341] = 0x05;
	pk[342] = 0x66;
	pk[343] = 0x35;
	pk[344] = 0xa3;
	pk[345] = 0x4a;
	pk[346] = 0x68;
	pk[347] = 0xaa;
	pk[348] = 0x78;
	pk[349] = 0x15;
	pk[350] = 0x86;
	pk[351] = 0x8f;
	pk[352] = 0x15;
	pk[353] = 0x3a;
	pk[354] = 0x3a;
	pk[355] = 0x5c;
	pk[356] = 0x77;
	pk[357] = 0xfc;
	pk[358] = 0xc8;
	pk[359] = 0xb1;
	pk[360] = 0xeb;
	pk[361] = 0x18;
	pk[362] = 0x07;
	pk[363] = 0xfb;
	pk[364] = 0xf6;
	pk[365] = 0x2a;
	pk[366] = 0x6f;
	pk[367] = 0xb4;
	pk[368] = 0x3b;
	pk[369] = 0x35;
	pk[370] = 0x57;
	pk[371] = 0x00;
	pk[372] = 0xe7;
	pk[373] = 0x82;
	pk[374] = 0x30;
	pk[375] = 0x94;
	pk[376] = 0x3a;
	pk[377] = 0x2b;
	pk[378] = 0xa1;
	pk[379] = 0xe1;
	pk[380] = 0x1b;
	pk[381] = 0x18;
	pk[382] = 0x13;
	pk[383] = 0x45;
	pk[384] = 0xb1;
	pk[385] = 0x1b;
	pk[386] = 0x4d;
	pk[387] = 0x46;
	pk[388] = 0x26;
	pk[389] = 0x6e;
	pk[390] = 0x7b;
	pk[391] = 0x35;
	pk[392] = 0x9f;
	pk[393] = 0x07;
	pk[394] = 0x4a;
	pk[395] = 0x50;
	pk[396] = 0x0c;
	pk[397] = 0x88;
	pk[398] = 0x57;
	pk[399] = 0xd7;
	pk[400] = 0x9b;
	pk[401] = 0xa6;
	pk[402] = 0x0f;
	pk[403] = 0x64;
	pk[404] = 0x26;
	pk[405] = 0x2d;
	pk[406] = 0x66;
	pk[407] = 0x2c;
	pk[408] = 0xcd;
	pk[409] = 0x9c;
	pk[410] = 0x84;
	pk[411] = 0x89;
	pk[412] = 0xa4;
	pk[413] = 0xc1;
	pk[414] = 0x9d;
	pk[415] = 0xf6;
	pk[416] = 0x74;
	pk[417] = 0x37;
	pk[418] = 0xdb;
	pk[419] = 0x19;
	pk[420] = 0x3f;
	pk[421] = 0x95;
	pk[422] = 0xb9;
	pk[423] = 0x76;
	pk[424] = 0x51;
	pk[425] = 0x81;
	pk[426] = 0xd9;
	pk[427] = 0x15;
	pk[428] = 0x22;
	pk[429] = 0x62;
	pk[430] = 0xb1;
	pk[431] = 0x16;
	pk[432] = 0x6f;
	pk[433] = 0x97;
	pk[434] = 0xbe;
	pk[435] = 0x53;
	pk[436] = 0x49;
	pk[437] = 0x7f;
	pk[438] = 0x00;
	pk[439] = 0x1c;
	pk[440] = 0xb1;
	pk[441] = 0xbe;
	pk[442] = 0x79;
	pk[443] = 0x02;
	pk[444] = 0x4d;
	pk[445] = 0x6a;
	pk[446] = 0x22;
	pk[447] = 0x89;
	pk[448] = 0xbc;
	pk[449] = 0xc7;
	pk[450] = 0x04;
	pk[451] = 0xe1;
	pk[452] = 0xb1;
	pk[453] = 0xd8;
	pk[454] = 0x21;
	pk[455] = 0x01;
	pk[456] = 0x53;
	pk[457] = 0x66;
	pk[458] = 0xa3;
	pk[459] = 0xcc;
	pk[460] = 0x8a;
	pk[461] = 0x48;
	pk[462] = 0x4e;
	pk[463] = 0x6b;
	pk[464] = 0xc2;
	pk[465] = 0xe1;
	pk[466] = 0xf1;
	pk[467] = 0xb8;
	pk[468] = 0x89;
	pk[469] = 0xf1;
	pk[470] = 0x93;
	pk[471] = 0x23;
	pk[472] = 0xe3;
	pk[473] = 0x10;
	pk[474] = 0x1a;
	pk[475] = 0xa0;
	pk[476] = 0x9a;
	pk[477] = 0xd9;
	pk[478] = 0xea;
	pk[479] = 0x62;
	pk[480] = 0xba;
	pk[481] = 0x40;
	pk[482] = 0x05;
	pk[483] = 0x03;
	pk[484] = 0x9b;
	pk[485] = 0xbf;
	pk[486] = 0xb5;
	pk[487] = 0x99;
	pk[488] = 0x80;
	pk[489] = 0x55;
	pk[490] = 0xf9;
	pk[491] = 0x3f;
	pk[492] = 0xbf;
	pk[493] = 0x77;
	pk[494] = 0xb1;
	pk[495] = 0x44;
	pk[496] = 0x33;
	pk[497] = 0x11;
	pk[498] = 0x6d;
	pk[499] = 0x59;
	pk[500] = 0x58;
	pk[501] = 0x42;
	pk[502] = 0x26;
	pk[503] = 0x54;
	pk[504] = 0xda;
	pk[505] = 0xda;
	pk[506] = 0x11;
	pk[507] = 0x27;
	pk[508] = 0x21;
	pk[509] = 0x3f;
	pk[510] = 0x02;
	pk[511] = 0xb7;
	pk[512] = 0x87;
	pk[513] = 0x17;
	pk[514] = 0xa5;
	pk[515] = 0xa0;
	pk[516] = 0x45;
	pk[517] = 0x42;
	pk[518] = 0x71;
	pk[519] = 0xd5;
	pk[520] = 0xb0;
	pk[521] = 0xc0;
	pk[522] = 0x25;
	pk[523] = 0x17;
	pk[524] = 0xa6;
	pk[525] = 0xc2;
	pk[526] = 0x7a;
	pk[527] = 0x3c;
	pk[528] = 0x36;
	pk[529] = 0x10;
	pk[530] = 0x10;
	pk[531] = 0x1d;
	pk[532] = 0x75;
	pk[533] = 0x3c;
	pk[534] = 0x09;
	pk[535] = 0xa2;
	pk[536] = 0x55;
	pk[537] = 0x71;
	pk[538] = 0x77;
	pk[539] = 0x54;
	pk[540] = 0x77;
	pk[541] = 0xdc;
	pk[542] = 0x13;
	pk[543] = 0xb2;
	pk[544] = 0xe4;
	pk[545] = 0x04;
	pk[546] = 0xdb;
	pk[547] = 0x49;
	pk[548] = 0x65;
	pk[549] = 0xb9;
	pk[550] = 0xa9;
	pk[551] = 0x35;
	pk[552] = 0x03;
	pk[553] = 0x30;
	pk[554] = 0xc7;
	pk[555] = 0x3a;
	pk[556] = 0x8a;
	pk[557] = 0x36;
	pk[558] = 0x42;
	pk[559] = 0xd3;
	pk[560] = 0x9a;
	pk[561] = 0xf8;
	pk[562] = 0xa2;
	pk[563] = 0x38;
	pk[564] = 0x39;
	pk[565] = 0xab;
	pk[566] = 0x85;
	pk[567] = 0xc6;
	pk[568] = 0x35;
	pk[569] = 0x5b;
	pk[570] = 0x12;
	pk[571] = 0xf2;
	pk[572] = 0x79;
	pk[573] = 0xf8;
	pk[574] = 0x49;
	pk[575] = 0x81;
	pk[576] = 0x3c;
	pk[577] = 0x28;
	pk[578] = 0x0d;
	pk[579] = 0x54;
	pk[580] = 0xc5;
	pk[581] = 0x91;
	pk[582] = 0x3e;
	pk[583] = 0x99;
	pk[584] = 0xb6;
	pk[585] = 0x94;
	pk[586] = 0x6a;
	pk[587] = 0x0a;
	pk[588] = 0xaf;
	pk[589] = 0x01;
	pk[590] = 0x2c;
	pk[591] = 0x8c;
	pk[592] = 0xab;
	pk[593] = 0x02;
	pk[594] = 0x53;
	pk[595] = 0x96;
	pk[596] = 0xb2;
	pk[597] = 0x55;
	pk[598] = 0xf0;
	pk[599] = 0x02;
	pk[600] = 0xd8;
	pk[601] = 0x37;
	pk[602] = 0xc7;
	pk[603] = 0x61;
	pk[604] = 0xd4;
	pk[605] = 0x2a;
	pk[606] = 0x4a;
	pk[607] = 0xeb;
	pk[608] = 0x38;
	pk[609] = 0xc5;
	pk[610] = 0xf4;
	pk[611] = 0x56;
	pk[612] = 0xaa;
	pk[613] = 0xf7;
	pk[614] = 0x9e;
	pk[615] = 0x16;
	pk[616] = 0x27;
	pk[617] = 0x00;
	pk[618] = 0xc6;
	pk[619] = 0xb4;
	pk[620] = 0x04;
	pk[621] = 0x8e;
	pk[622] = 0xca;
	pk[623] = 0x6f;
	pk[624] = 0x9a;
	pk[625] = 0x73;
	pk[626] = 0x67;
	pk[627] = 0xf9;
	pk[628] = 0x02;
	pk[629] = 0x38;
	pk[630] = 0xd6;
	pk[631] = 0x7b;
	pk[632] = 0xcf;
	pk[633] = 0x8e;
	pk[634] = 0x6a;
	pk[635] = 0x0d;
	pk[636] = 0x8a;
	pk[637] = 0x55;
	pk[638] = 0x3c;
	pk[639] = 0x07;
	pk[640] = 0x15;
	pk[641] = 0x22;
	pk[642] = 0xf9;
	pk[643] = 0xd2;
	pk[644] = 0x39;
	pk[645] = 0x4e;
	pk[646] = 0x28;
	pk[647] = 0x48;
	pk[648] = 0x3d;
	pk[649] = 0x20;
	pk[650] = 0x48;
	pk[651] = 0xbe;
	pk[652] = 0x2a;
	pk[653] = 0x8f;
	pk[654] = 0x9c;
	pk[655] = 0x8c;
	pk[656] = 0x8e;
	pk[657] = 0x39;
	pk[658] = 0x99;
	pk[659] = 0x1a;
	pk[660] = 0x41;
	pk[661] = 0x27;
	pk[662] = 0x3c;
	pk[663] = 0x7e;
	pk[664] = 0xac;
	pk[665] = 0xae;
	pk[666] = 0xfc;
	pk[667] = 0x6a;
	pk[668] = 0x30;
	pk[669] = 0x8b;
	pk[670] = 0xe8;
	pk[671] = 0x70;
	pk[672] = 0xb4;
	pk[673] = 0x5b;
	pk[674] = 0x41;
	pk[675] = 0x17;
	pk[676] = 0x64;
	pk[677] = 0x12;
	pk[678] = 0x95;
	pk[679] = 0x4a;
	pk[680] = 0x1a;
	pk[681] = 0x0f;
	pk[682] = 0xd8;
	pk[683] = 0x3d;
	pk[684] = 0x36;
	pk[685] = 0x2a;
	pk[686] = 0x5a;
	pk[687] = 0xb2;
	pk[688] = 0x88;
	pk[689] = 0x66;
	pk[690] = 0x3d;
	pk[691] = 0xec;
	pk[692] = 0x54;
	pk[693] = 0x56;
	pk[694] = 0xb6;
	pk[695] = 0x28;
	pk[696] = 0x6d;
	pk[697] = 0x0b;
	pk[698] = 0x2c;
	pk[699] = 0xec;
	pk[700] = 0xb0;
	pk[701] = 0x19;
	pk[702] = 0x22;
	pk[703] = 0xfb;
	pk[704] = 0x3d;
	pk[705] = 0x47;
	pk[706] = 0x38;
	pk[707] = 0x02;
	pk[708] = 0xea;
	pk[709] = 0x2b;
	pk[710] = 0x86;
	pk[711] = 0x63;
	pk[712] = 0x9b;
	pk[713] = 0xce;
	pk[714] = 0x02;
	pk[715] = 0x45;
	pk[716] = 0x03;
	pk[717] = 0x39;
	pk[718] = 0x26;
	pk[719] = 0x1c;
	pk[720] = 0xff;
	pk[721] = 0xb1;
	pk[722] = 0x14;
	pk[723] = 0xe1;
	pk[724] = 0xe7;
	pk[725] = 0x25;
	pk[726] = 0xe9;
	pk[727] = 0x06;
	pk[728] = 0x77;
	pk[729] = 0x82;
	pk[730] = 0x6a;
	pk[731] = 0x16;
	pk[732] = 0x88;
	pk[733] = 0xf6;
	pk[734] = 0x86;
	pk[735] = 0xb2;
	pk[736] = 0x9a;
	pk[737] = 0x78;
	pk[738] = 0x77;
	pk[739] = 0x9c;
	pk[740] = 0x98;
	pk[741] = 0x22;
	pk[742] = 0x31;
	pk[743] = 0x5d;
	pk[744] = 0xaf;
	pk[745] = 0xc5;
	pk[746] = 0x57;
	pk[747] = 0x53;
	pk[748] = 0xe9;
	pk[749] = 0x8c;
	pk[750] = 0x8e;
	pk[751] = 0xd3;
	pk[752] = 0x22;
	pk[753] = 0x1f;
	pk[754] = 0x2b;
	pk[755] = 0x32;
	pk[756] = 0x20;
	pk[757] = 0x80;
	pk[758] = 0x5c;
	pk[759] = 0x8a;
	pk[760] = 0x28;
	pk[761] = 0x98;
	pk[762] = 0x33;
	pk[763] = 0x55;
	pk[764] = 0x20;
	pk[765] = 0x7d;
	pk[766] = 0xa3;
	pk[767] = 0x6f;
	pk[768] = 0xb7;
	pk[769] = 0x2f;
	pk[770] = 0x9b;
	pk[771] = 0xc8;
	pk[772] = 0x5c;
	pk[773] = 0x0a;
	pk[774] = 0x13;
	pk[775] = 0xb9;
	pk[776] = 0xd0;
	pk[777] = 0x41;
	pk[778] = 0x58;
	pk[779] = 0x6f;
	pk[780] = 0xd5;
	pk[781] = 0x83;
	pk[782] = 0xfe;
	pk[783] = 0xb1;
	pk[784] = 0x2a;
	pk[785] = 0xfd;
	pk[786] = 0x5a;
	pk[787] = 0x40;
	pk[788] = 0x2d;
	pk[789] = 0xd3;
	pk[790] = 0x3b;
	pk[791] = 0x43;
	pk[792] = 0x54;
	pk[793] = 0x3f;
	pk[794] = 0x5f;
	pk[795] = 0xa4;
	pk[796] = 0xeb;
	pk[797] = 0x43;
	pk[798] = 0x6c;
	pk[799] = 0x8d;
	
	printf("pk:\n");
	printbytes(pk, PQCLEAN_KYBER512_CLEAN_CRYPTO_PUBLICKEYBYTES);

	// Performance regs variables
	unsigned int instr, cycles, ldstall, jrstall, imstall;

	// Key-pair generation
	printf("Keypair starts!\n");
	// Starting the performance counter
	CSR_WRITE(CSR_REG_MCYCLE, 0);

	// Encapsulation
	PQCLEAN_KYBER512_CLEAN_crypto_kem_enc(sendb, key_b, pk);
	CSR_READ(CSR_REG_MCYCLE, &cycles);
	printf("Encapsulation done!\nNumber of clock cycles : %d\n", cycles);
	
	printf("sendb:\n");
	printbytes(sendb, PQCLEAN_KYBER512_CLEAN_CRYPTO_CIPHERTEXTBYTES);
	printf("key_b:\n");
	printbytes(key_b, PQCLEAN_KYBER512_CLEAN_CRYPTO_BYTES);
	    
    return 0;
}
