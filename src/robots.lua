-- robots.lua: Enemy robot logic

local robotSprite = {
    -- [1] sprite index 0
    {
        {7968,14816,6624,3872,40704,24448,65472,24064,40896,8064,3584,7936,48032,29120,8320,4352},
        {1988,3708,1660,9156,6080,6112,16368,6128,6128,10208,896,896,1728,1728,7280,1728},
        {498,926,414,242,2544,1528,4092,1504,2556,504,224,224,224,224,224,496},
        {125,231,103,61,124,127,1020,120,124,127,56,56,108,108,455,108},
        {48640,59136,58880,48128,15872,65024,16320,7680,15872,65024,7168,7168,13824,13824,58240,13824},
        {20352,31168,31104,20224,3984,8096,16368,1952,16272,8064,1792,1792,1792,1792,1792,3968},
        {9184,15984,15968,9156,1000,2024,4092,4072,4072,2020,448,448,864,864,3640,864},
        {1272,1948,1944,1264,249,506,1023,122,1017,504,112,248,1501,910,260,136},
    },
    -- [2] sprite index 1
    {
        {3072,7680,6912,7872,14592,12800,14848,15616,27904,26880,26880,24832,28928,48640,2048,7680},
        {768,1920,1728,1968,3648,3200,3968,3520,6976,6976,5696,6208,7232,12160,1344,3968},
        {192,480,432,492,912,800,928,976,1744,1680,1680,1552,1808,3048,592,2016},
        {48,120,108,123,228,200,232,244,436,404,404,388,452,760,84,248},
        {3072,7680,13824,56832,9984,4864,5888,12032,11648,10624,10624,8576,9088,8000,10752,7936},
        {768,1920,3456,14208,2496,1216,1472,3008,2912,2400,2400,2144,2272,6096,2624,2016},
        {192,480,864,3552,624,304,496,944,728,728,616,536,568,500,672,496},
        {48,120,216,888,156,76,92,188,182,150,150,134,142,125,16,120},
    },
    -- [3] sprite index 2
    {
        {768,1664,1984,768,384,192,48832,58240,16640,43776,32512,15872,2048,2048,2048,5120},
        {192,416,496,192,96,48,12208,14560,6336,12480,5568,2688,5376,512,1280,0},
        {48,104,124,48,24,12,3052,3640,1040,2736,2032,992,128,320,0,0},
        {12,26,31,172,342,171,859,902,268,1020,508,248,32,32,80,0},
        {12288,22528,63488,13568,27264,54528,56000,25024,12416,16320,16256,7936,1024,1024,2560,0},
        {3072,5632,15872,3072,6144,12288,14288,7280,2080,3408,4064,1984,256,640,0,0},
        {768,1408,3968,768,1536,3072,3572,1820,792,780,936,336,168,64,160,0},
        {192,352,992,192,384,768,893,455,130,213,254,124,16,16,16,40},
    },
    -- [4] sprite index 3
    {
        {1792,2944,5056,5056,5056,2944,1792,256,1792,1280,1792,1920,20352,24512,65216,15424},
        {448,736,1488,1488,1488,736,448,64,448,320,448,480,9184,12272,32688,7952},
        {112,232,484,484,484,232,112,16,112,80,112,248,8696,10236,32748,4036},
        {28,54,99,99,99,54,28,4,28,20,28,30,1086,1279,4091,1009},
        {14336,27648,50688,50688,50688,27648,14336,8192,14336,10240,14336,30720,31776,65312,57328,36800},
        {3584,5888,10112,10112,10112,5888,3584,2048,3584,2560,3584,7936,8068,16356,14334,9200},
        {896,1856,2976,2976,2976,1856,896,512,896,640,896,1920,1988,4084,3582,2296},
        {224,464,968,968,968,464,224,128,224,160,224,480,498,1018,895,572},
    },
    -- [5] sprite index 4 (Eugene - single frame)
    {
        {960,4080,8184,8184,12684,3696,28662,44661,45453,40953,39897,35889,18402,576,576,3696},
    },
    -- [6] sprite index 5
    {
        {49152,49152,49152,49152,49152,49152,49152,57280,57280,65472,8128,3968,30592,65280,57088,57088},
        {12288,12288,12288,12288,12320,12480,13056,13312,14320,16368,2032,992,7648,16320,14272,14272},
        {3072,3072,3104,3136,3136,3200,3200,3328,3580,4092,508,248,1912,4080,3568,3568},
        {768,768,768,768,770,780,816,832,895,1023,127,62,478,1020,892,892},
        {192,192,192,192,16576,12480,3264,704,65216,65472,65024,31744,31616,16320,16064,16064},
        {48,48,1072,560,560,304,304,176,16304,16368,16256,7936,7904,4080,4016,4016},
        {12,12,12,12,1036,780,204,44,4076,4092,4064,1984,1976,1020,1004,1004},
        {3,3,3,3,3,3,3,1019,1019,1023,1016,496,494,255,251,251},
    },
    -- [7] sprite index 6
    {
        {7936,32704,29664,62336,65024,63488,65024,65408,32736,32704,7936,2560,2560,2560,2560,7936},
        {1984,8176,7792,15992,16376,15872,16376,16376,8176,8176,1984,640,640,1984,0,0},
        {496,2044,1854,3896,4064,3968,4064,4088,2046,2044,496,496,0,0,0,0},
        {124,463,462,1020,1008,992,1008,1020,510,511,124,40,40,124,0,0},
        {15872,62336,29568,16320,4032,1984,4032,16320,32640,65408,15872,5120,5120,15872,0,0},
        {3968,16352,31968,7408,2032,496,2032,8176,32736,16352,3968,3968,0,0,0,0},
        {992,4088,3704,7804,8188,124,8188,8188,4088,4088,992,320,320,992,0,0},
        {248,1022,1998,463,127,31,127,511,2046,1022,248,80,80,80,80,248},
    },
    -- [8] sprite index 7
    {
        {6144,7168,2688,3968,3072,7168,7680,7424,15360,15872,15872,28160,17408,16896,33024,0},
        {0,0,1536,1792,672,992,896,1792,1920,1856,3840,3968,3968,7040,13056,16576},
        {0,0,0,0,384,448,168,248,224,448,480,464,960,992,2016,16120},
        {0,0,96,112,42,62,56,112,120,116,240,248,504,432,780,1024},
        {0,0,1536,3584,21504,31744,7168,3584,7680,11776,3840,7936,8064,3456,12480,32},
        {0,0,0,0,384,896,5376,7936,1792,896,1920,2944,960,1984,2016,8060},
        {0,0,96,224,1344,1984,448,224,480,736,240,496,496,472,204,770},
        {24,56,336,496,48,56,120,184,60,124,124,118,34,66,129,0},
    },
    -- [9] sprite index 8 (Kong)
    {
        {5064,7608,4080,1632,1440,576,2016,4080,8184,13260,25542,18018,11316,1632,576,3696},
        {3024,3504,4080,1632,1440,576,960,8184,32766,59367,33729,51171,1632,3120,2064,14364},
        {7224,1632,3120,26214,9156,26598,14316,8184,4080,2016,576,1440,1632,4080,3504,3024},
        {28686,6168,3120,1632,25542,10212,26598,14316,8184,4080,576,1440,5736,4080,3504,960},
    },
    -- [10] sprite index 9
    {
        {2048,1280,2176,9472,18560,8448,19456,13056,17536,17536,34880,33856,18560,18560,13056,3072},
        {512,4384,2624,4384,2624,4128,768,3264,4128,4192,8848,9488,6176,4128,3264,768},
        {64,544,1096,548,1096,516,200,816,1032,1032,2884,2228,1032,1032,816,192},
        {68,290,580,290,580,258,560,204,322,290,529,545,274,266,204,48},
    },
    -- [11] sprite index 10
    {
        {2592,5736,336,14690,26062,976,65518,34801,30692,51199,35825,12972,25766,18850,4752,13976},
        {0,1312,832,12660,7628,976,16364,2036,16352,26620,3058,12972,9380,2960,6872,192},
        {0,0,544,2400,1480,976,8160,2040,8160,6136,4080,4776,1440,2736,192,0},
        {0,1312,832,12660,7628,976,16364,2036,16352,26620,3058,12972,9380,2960,6872,192},
    },
    -- [12] sprite index 11
    {
        {3072,3072,3072,3072,3072,3072,3072,3072,3072,3072,65472,3072,24960,53952,45888,24960},
        {768,768,768,768,768,768,768,768,768,768,16368,768,6240,9424,15568,6240},
        {192,192,192,192,192,192,192,192,192,192,4092,192,1560,2868,3372,1560},
        {48,48,48,48,48,48,48,48,48,48,1023,48,390,589,973,390},
    },
    -- [13] sprite index 12
    {
        {28672,20480,31744,13312,15872,15872,6144,15360,32256,32256,63232,64256,15360,30208,28160,30464},
        {7168,5120,7936,3328,3968,3968,1536,3840,7040,7040,7040,7552,3840,1536,1536,1792},
        {1792,1280,1984,832,992,992,384,960,2016,2016,3952,4016,960,1888,1760,1904},
        {448,320,496,208,248,248,96,240,504,1020,2046,1782,248,474,782,900},
        {896,1664,3968,2816,7936,7936,1536,3840,8064,16320,32736,28512,7936,23424,28864,8640},
        {224,416,992,704,1984,1984,384,960,2016,2016,3824,3568,960,1760,1888,3808},
        {56,104,248,176,496,496,96,240,504,472,472,440,240,96,96,224},
        {14,26,62,44,124,124,24,60,126,126,239,223,60,110,118,238},
    },
    -- [14] sprite index 13
    {
        {0,0,16380,25542,60375,59415,4080,2016,3120,3024,7128,7224,16380,16380,16380,16380},
        {15360,32704,32760,25542,2135,2071,4087,2016,3120,3024,7128,7224,16380,16380,16380,16380},
        {0,0,16380,25542,60375,59415,4080,2016,3120,3024,7128,7224,16380,16380,16380,16380},
        {60,1022,8190,25542,59920,59408,61424,2016,3120,3024,7128,7224,16380,16380,16380,16380},
    },
    -- [15] sprite index 14
    {
        {3072,5632,11520,19584,35904,35904,19584,11520,5632,3072,14080,19456,32704,65472,16512,11776},
        {768,768,1408,1920,2880,2880,1920,1408,768,768,3776,800,16352,16368,4128,1856},
        {192,192,192,192,128,128,192,192,192,192,464,1224,4092,4088,8,944},
        {48,104,180,180,306,306,180,180,104,48,184,306,1023,511,256,220},
    },
    -- [16] sprite index 15
    {
        {0,0,0,960,3120,4104,8196,16386,32769,16386,8196,53259,11316,19410,4680,576},
        {0,0,0,960,3120,4104,8196,16386,63519,22506,11220,4680,3120,960,0,0},
        {1056,1056,4680,19410,11316,37833,42981,18018,34401,18402,9156,4104,3120,960,0,0},
        {0,0,0,960,3120,4680,10836,24570,63103,18402,9156,4104,3120,960,0,0},
    },
    -- [17] sprite index 16
    {
        {24960,45632,46016,24960,3072,65472,21120,4608,4608,7680,3072,3072,3072,3072,7680,16128},
        {6240,9424,15568,6240,768,16368,5280,1152,1152,1920,768,768,1920,4032,0,0},
        {1560,3388,3364,1560,192,4092,1320,288,288,480,480,1008,0,0,0,0},
        {390,971,587,390,48,1023,330,72,72,120,48,48,120,252,0,0},
    },
    -- [18] sprite index 17 (Skylab)
    {
        {960,65535,43989,65535,5064,10644,5544,3024,1440,960,960,1440,2640,5160,10260,4104},
        {0,0,960,65535,43989,65535,5064,10644,5544,3024,1440,960,960,9632,19028,5162},
        {0,0,0,7,1021,65495,44024,65472,960,384,5540,19410,1444,9154,3024,9640},
        {0,0,0,32,514,21,974,4052,52168,47042,58312,12673,2020,50120,6082,9212},
        {0,256,0,2080,0,0,8450,17,906,3728,19392,14082,25280,12545,1506,49988},
        {0,0,0,0,0,512,0,32,4104,2692,32,25856,8808,2208,976,6112},
        {0,0,0,0,0,0,0,0,512,32,4096,0,1296,104,8864,3536},
        {0,0,0,0,0,0,0,0,0,0,0,128,32,2048,704,1888},
    },
    -- [19] sprite index 18
    {
        {24966,40953,40953,24966,960,65535,32769,43689,40957,46425,36877,46425,40957,43689,32769,65535},
        {7608,8948,8948,7608,960,65535,54613,49151,60077,45063,58701,45063,60077,49151,54613,65535},
        {2016,2064,2064,2016,960,65535,65535,54615,57347,51879,59379,51879,57347,54615,65535,65535},
        {7608,12100,12100,7608,960,65535,43691,49153,38227,53241,39603,53241,38227,49153,43691,65535},
    },
    -- [20] sprite index 19
    {
        {0,0,0,0,0,0,0,0,0,0,65472,33216,65472,33344,65088,65472},
        {0,0,0,0,0,0,16368,8304,16368,8336,16272,16368,0,0,0,0},
        {0,0,0,0,4092,2076,4092,2084,4068,4092,0,0,0,0,0,0},
        {0,0,0,0,0,0,1023,519,1023,521,1017,1023,0,0,0,0},
    },
    -- [21] sprite index 20
    {
        {0,2048,5120,10752,21760,18944,33792,32960,32960,16640,32640,16320,8064,3840,2688,4672},
        {10752,5376,10752,5376,8192,8192,8192,8240,8240,4160,8160,4080,2016,960,672,1168},
        {0,4096,10240,21504,43520,20736,8448,268,524,528,1016,1020,504,240,168,292},
        {1344,2688,1344,2688,64,64,64,67,131,132,254,255,126,60,42,73},
        {672,336,672,336,512,512,512,49664,49408,8448,32512,65280,32256,15360,21504,37376},
        {0,8,20,42,85,138,132,12416,12352,2112,8128,16320,8064,3840,5376,9344},
        {84,168,84,168,4,4,4,3076,3076,520,2040,4080,2016,960,1344,2336},
        {0,16,40,84,170,82,33,769,769,130,510,1020,504,240,336,584},
    },
    -- [22] sprite index 21
    {
        {32256,39168,65280,56064,59136,32256,9216,9216,9216,16896,16896,16896,33024,33024,49920,49920},
        {0,8064,9792,16320,14016,14784,8064,4224,8256,8256,16416,16416,32784,32816,49200,49152},
        {0,0,0,2016,2448,4080,3504,3696,2016,2064,4104,8196,16386,32769,49155,49155},
        {0,504,612,1020,876,924,504,264,516,516,1026,1026,2049,3073,3075,3},
    },
    -- [23] sprite index 22
    {
        {832,3952,16188,16204,24422,24438,40831,127,36352,36607,18174,16626,8196,12300,3120,704},
        {960,4080,16300,16332,24518,18358,39359,40575,36479,36255,17894,16882,8196,12300,3120,960},
        {960,4080,12220,14280,23526,24038,40671,40511,35967,35711,18366,16834,4,12292,3120,960},
        {960,3056,15804,15820,24038,24308,40675,40479,34943,34687,1918,16818,8196,12300,3088,960},
    },
    -- [24] sprite index 23
    {
        {1536,3072,6144,14336,29696,51840,34240,960,1600,52928,55360,65472,57856,51328,54592,2176},
        {384,768,1536,3584,7424,12960,8560,240,400,25520,26128,32752,30848,25120,25936,544},
        {96,192,384,896,1856,3240,2140,60,100,12524,12676,16380,15904,12424,12628,136},
        {24,48,96,224,464,810,535,15,25,1595,1633,2047,1928,1570,1621,34},
    },
    -- [25] sprite index 24
    {
        {4608,3072,7680,48960,29568,29568,48960,24192,19584,21120,32640,3072,24960,37568,45632,24960},
        {768,1920,1920,7392,15216,15216,7392,6048,6048,4896,8160,768,6240,9360,13488,6240},
        {480,480,288,3804,3564,3564,3804,1320,1512,1512,2040,192,1560,3364,2356,1560},
        {120,72,48,891,765,765,891,306,330,378,510,48,390,717,585,390},
    },
    -- [26] sprite index 25
    {
        {21845,65535,65535,2064,2064,2064,63519,21845,65535,65535,2064,2064,2064,22549,65535,65535},
        {0,21845,65535,65535,2064,63519,2064,16382,14366,2064,24565,65535,65535,0,65535,0},
        {0,0,65535,21845,65535,65535,2064,14366,16382,2064,63519,24565,65535,65535,0,0},
        {0,21845,65535,63519,2064,21845,65535,65535,30749,63519,63519,2064,21845,65535,65535,0},
    },
    -- [27] sprite index 26
    {
        {14,51,197,793,3173,12701,50813,39325,50717,61853,31869,7965,2013,509,127,28},
        {960,1856,1568,3744,3216,7504,6472,15016,12964,29780,25682,65514,65513,65525,16387,32766},
        {14336,65024,49024,48096,47352,48702,47503,47203,47513,48739,47500,42544,39104,41728,52224,28672},
        {32766,49154,45055,38911,22527,18982,10798,9548,5468,4760,2744,2352,1392,1120,736,960},
    },
    -- [28] sprite index 27
    {
        {960,3696,5064,12684,14748,24570,36274,33956,18724,10514,9353,16969,33362,1168,2184,64},
        {960,3696,5064,12684,14748,24570,19889,34065,33938,18596,10532,10514,17545,584,592,1024},
        {960,3696,5064,12684,14748,24570,19889,17553,33353,33354,17556,9508,10530,2192,1096,64},
        {960,3696,5064,12684,14748,24570,19890,10514,9361,16969,33354,33866,18577,2336,2304,128},
    },
    -- [29] sprite index 28
    {
        {0,3120,576,384,2016,28662,6552,2640,63903,7800,7224,31790,39897,3248,2016,384},
        {0,0,3696,16770,10212,8184,36849,31326,6552,7800,64575,5160,8152,3184,2016,384},
        {0,3120,576,384,2016,20466,16380,3696,55707,15996,7224,13356,56315,3632,2016,384},
        {1056,1056,576,384,2016,4080,32766,2641,6552,32382,39993,5176,15324,19762,18402,384},
    },
}

-- Robot alignment values (indexed by y & 7, 0-based)
local robotAlign = {4, 6, 6, 6, 6, 6, 6, 6}  -- 1-indexed: robotAlign[1]=4, [2]=6...

-- Robot start data for each level
-- Fields: x, y, min, max, speed, move, gfx, ink, nframes, frame, tile
-- move is one of: "right","left","up","down","kong","skylab"
-- speed: for horiz robots = bitmask for gameTicks (0=always move); for vert = y pixels/tick
local robotStartData = {
    -- level 0
    {
        {x=8,  y=7,  min=64,  max=120, speed=0, move="right", gfx=0,  ink=0x6, nframes=7, frame=0, tile=0},
    },
    -- level 1
    {
        {x=18, y=3,  min=8,   max=144, speed=0, move="left",  gfx=1,  ink=0x7, nframes=7, frame=7, tile=0},
        {x=29, y=13, min=96,  max=232, speed=0, move="left",  gfx=1,  ink=0x7, nframes=7, frame=7, tile=0},
    },
    -- level 2
    {
        {x=19, y=13, min=8,   max=152, speed=0, move="left",  gfx=2,  ink=0x3, nframes=7, frame=7, tile=0},
        {x=16, y=3,  min=8,   max=128, speed=0, move="left",  gfx=2,  ink=0x5, nframes=7, frame=7, tile=0},
        {x=18, y=3,  min=144, max=232, speed=0, move="right", gfx=2,  ink=0xe, nframes=7, frame=0, tile=0},
    },
    -- level 3
    {
        {x=1,  y=13, min=8,   max=80,  speed=0, move="right", gfx=3,  ink=0x5, nframes=7, frame=0, tile=0},
        {x=7,  y=13, min=48,  max=120, speed=0, move="right", gfx=3,  ink=0x8, nframes=7, frame=0, tile=0},
    },
    -- level 4 (EUGENE)
    {
        {x=12, y=3,  min=8,   max=96,  speed=0, move="left",  gfx=5,  ink=0x6, nframes=7, frame=7, tile=0},
        {x=4,  y=7,  min=32,  max=96,  speed=0, move="right", gfx=5,  ink=0x0, nframes=7, frame=0, tile=0},
        {x=15, y=0,  min=0,   max=88,  speed=1, move="down",  gfx=4,  ink=0x7, nframes=0, frame=0, tile=0},
    },
    -- level 5
    {
        {x=6,  y=8,  min=48,  max=104, speed=0, move="right", gfx=6,  ink=0xe, nframes=7, frame=0, tile=0},
        {x=14, y=8,  min=112, max=168, speed=0, move="right", gfx=6,  ink=0x3, nframes=7, frame=1, tile=0},
        {x=8,  y=13, min=64,  max=160, speed=0, move="right", gfx=6,  ink=0x5, nframes=7, frame=2, tile=0},
        {x=24, y=13, min=192, max=232, speed=0, move="right", gfx=6,  ink=0x2, nframes=7, frame=3, tile=0},
    },
    -- level 6
    {
        {x=15, y=1,  min=120, max=232, speed=0, move="right", gfx=7,  ink=0x7, nframes=7, frame=0, tile=0},
        {x=10, y=8,  min=16,  max=80,  speed=0, move="left",  gfx=7,  ink=0x2, nframes=7, frame=7, tile=0},
        {x=17, y=13, min=136, max=232, speed=0, move="right", gfx=7,  ink=0xe, nframes=7, frame=0, tile=0},
    },
    -- level 7
    {
        {x=15, y=0,  min=0,   max=100, speed=4, move="kong",  gfx=8,  ink=0xe, nframes=1, frame=0, tile=0},
        {x=9,  y=13, min=8,   max=72,  speed=0, move="left",  gfx=9,  ink=0x2, nframes=3, frame=7, tile=0},
        {x=11, y=11, min=88,  max=120, speed=1, move="right", gfx=9,  ink=0xe, nframes=3, frame=0, tile=0},
        {x=18, y=7,  min=144, max=168, speed=0, move="right", gfx=9,  ink=0x6, nframes=3, frame=0, tile=0},
    },
    -- level 8
    {
        {x=12, y=3,  min=96,  max=144, speed=0, move="right", gfx=11, ink=0xa, nframes=3, frame=0, tile=0},
        {x=16, y=10, min=96,  max=144, speed=1, move="right", gfx=11, ink=0x6, nframes=3, frame=0, tile=0},
        {x=5,  y=1,  min=5,   max=100, speed=1, move="down",  gfx=10, ink=0x3, nframes=3, frame=0, tile=0},
        {x=10, y=1,  min=5,   max=100, speed=2, move="down",  gfx=10, ink=0x4, nframes=3, frame=1, tile=0},
        {x=20, y=1,  min=5,   max=100, speed=1, move="down",  gfx=10, ink=0x1, nframes=3, frame=2, tile=0},
        {x=25, y=1,  min=5,   max=100, speed=2, move="down",  gfx=10, ink=0x2, nframes=3, frame=3, tile=0},
    },
    -- level 9
    {
        {x=9,  y=7,  min=72,  max=112, speed=0, move="right", gfx=12, ink=0xb, nframes=7, frame=0, tile=0},
        {x=12, y=10, min=64,  max=112, speed=1, move="right", gfx=12, ink=0xe, nframes=7, frame=0, tile=0},
        {x=8,  y=13, min=32,  max=208, speed=0, move="right", gfx=12, ink=0x6, nframes=7, frame=0, tile=0},
        {x=18, y=5,  min=136, max=168, speed=0, move="right", gfx=12, ink=0xf, nframes=7, frame=0, tile=0},
    },
    -- level 10
    {
        {x=15, y=3,  min=120, max=192, speed=0, move="right", gfx=14, ink=0xe, nframes=3, frame=0, tile=0},
        {x=14, y=7,  min=112, max=144, speed=1, move="right", gfx=14, ink=0xc, nframes=3, frame=0, tile=0},
        {x=15, y=13, min=40,  max=152, speed=0, move="left",  gfx=14, ink=0xa, nframes=3, frame=7, tile=0},
        {x=12, y=1,  min=2,   max=56,  speed=2, move="down",  gfx=13, ink=0x3, nframes=3, frame=0, tile=0},
        {x=3,  y=4,  min=32,  max=100, speed=1, move="down",  gfx=13, ink=0x4, nframes=3, frame=1, tile=0},
        {x=21, y=6,  min=48,  max=100, speed=1, move="down",  gfx=13, ink=0x6, nframes=3, frame=2, tile=0},
        {x=26, y=6,  min=4,   max=100, speed=3, move="up",    gfx=13, ink=0x2, nframes=3, frame=3, tile=0},
    },
    -- level 11
    {
        {x=15, y=0,  min=0,   max=100, speed=4, move="kong",  gfx=8,  ink=0xe, nframes=1, frame=0, tile=0},
        {x=9,  y=13, min=8,   max=72,  speed=0, move="left",  gfx=9,  ink=0x6, nframes=3, frame=7, tile=0},
        {x=11, y=11, min=88,  max=120, speed=1, move="right", gfx=9,  ink=0x2, nframes=3, frame=0, tile=0},
        {x=25, y=6,  min=200, max=224, speed=0, move="right", gfx=9,  ink=0x3, nframes=3, frame=0, tile=0},
    },
    -- level 12
    {
        {x=7,  y=1,  min=56,  max=232, speed=0, move="right", gfx=16, ink=0x3, nframes=3, frame=0, tile=0},
        {x=16, y=4,  min=56,  max=232, speed=1, move="right", gfx=16, ink=0xc, nframes=3, frame=0, tile=0},
        {x=20, y=7,  min=80,  max=208, speed=0, move="left",  gfx=16, ink=0x6, nframes=3, frame=7, tile=0},
        {x=18, y=10, min=56,  max=232, speed=1, move="right", gfx=16, ink=0x2, nframes=3, frame=0, tile=0},
        {x=5,  y=1,  min=8,   max=100, speed=2, move="down",  gfx=15, ink=0x7, nframes=3, frame=0, tile=0},
    },
    -- level 13 (SKYLAB)
    {
        {x=1,  y=0,  min=0,   max=72,  speed=4, move="skylab", gfx=17, ink=0xa, nframes=7, frame=0, tile=0},
        {x=11, y=0,  min=0,   max=32,  speed=1, move="skylab", gfx=17, ink=0x5, nframes=7, frame=0, tile=0},
        {x=21, y=2,  min=2,   max=56,  speed=3, move="skylab", gfx=17, ink=0xc, nframes=7, frame=0, tile=0},
    },
    -- level 14
    {
        {x=17, y=13, min=136, max=152, speed=0, move="right", gfx=19, ink=0x7, nframes=3, frame=0, tile=0},
        {x=9,  y=5,  min=36,  max=102, speed=2, move="down",  gfx=18, ink=0xc, nframes=3, frame=0, tile=0},
        {x=15, y=8,  min=36,  max=102, speed=1, move="down",  gfx=18, ink=0xa, nframes=3, frame=1, tile=0},
        {x=21, y=10, min=32,  max=104, speed=3, move="up",    gfx=18, ink=0x6, nframes=3, frame=2, tile=0},
    },
    -- level 15
    {
        {x=9,  y=13, min=8,   max=144, speed=0, move="right", gfx=20, ink=0xc, nframes=7, frame=0, tile=0},
        {x=1,  y=10, min=8,   max=56,  speed=0, move="right", gfx=20, ink=0x6, nframes=7, frame=0, tile=0},
        {x=18, y=7,  min=144, max=184, speed=0, move="right", gfx=20, ink=0x3, nframes=7, frame=0, tile=0},
        {x=26, y=5,  min=200, max=232, speed=1, move="right", gfx=20, ink=0x5, nframes=7, frame=0, tile=0},
    },
    -- level 16
    {
        {x=5,  y=13, min=40,  max=64,  speed=1, move="right", gfx=21, ink=0x9, nframes=3, frame=0, tile=0},
        {x=12, y=13, min=96,  max=200, speed=0, move="right", gfx=21, ink=0xe, nframes=3, frame=0, tile=0},
        {x=3,  y=8,  min=64,  max=102, speed=2, move="down",  gfx=25, ink=0x6, nframes=3, frame=0, tile=0},
        {x=10, y=8,  min=3,   max=96,  speed=3, move="up",    gfx=25, ink=0x3, nframes=3, frame=1, tile=0},
        {x=19, y=6,  min=0,   max=64,  speed=1, move="down",  gfx=25, ink=0x7, nframes=3, frame=2, tile=0},
        {x=27, y=0,  min=4,   max=96,  speed=4, move="down",  gfx=25, ink=0x1, nframes=3, frame=3, tile=0},
    },
    -- level 17
    {
        {x=12, y=3,  min=96,  max=144, speed=1, move="right", gfx=11, ink=0x4, nframes=3, frame=0, tile=0},
        {x=16, y=10, min=96,  max=136, speed=1, move="right", gfx=11, ink=0x5, nframes=3, frame=0, tile=0},
        {x=16, y=6,  min=96,  max=136, speed=0, move="right", gfx=11, ink=0x3, nframes=3, frame=0, tile=0},
        {x=16, y=13, min=96,  max=144, speed=0, move="left",  gfx=11, ink=0x6, nframes=3, frame=7, tile=0},
        {x=5,  y=1,  min=5,   max=104, speed=3, move="down",  gfx=27, ink=0x7, nframes=3, frame=0, tile=0},
        {x=10, y=1,  min=5,   max=104, speed=2, move="down",  gfx=27, ink=0xc, nframes=3, frame=1, tile=0},
        {x=20, y=1,  min=5,   max=104, speed=4, move="down",  gfx=27, ink=0x9, nframes=3, frame=2, tile=0},
        {x=25, y=1,  min=5,   max=104, speed=1, move="down",  gfx=27, ink=0xe, nframes=3, frame=3, tile=0},
    },
    -- level 18 (SPG)
    {
        {x=24, y=3,  min=184, max=232, speed=0, move="right", gfx=23, ink=0x8, nframes=3, frame=0, tile=0, spg=true},
        {x=28, y=6,  min=176, max=232, speed=0, move="right", gfx=23, ink=0x5, nframes=3, frame=0, tile=0, spg=true},
        {x=29, y=9,  min=184, max=232, speed=1, move="left",  gfx=23, ink=0x9, nframes=3, frame=7, tile=0, spg=true},
        {x=16, y=13, min=104, max=232, speed=0, move="right", gfx=23, ink=0x1, nframes=3, frame=0, tile=0, spg=true},
        {x=5,  y=8,  min=2,   max=102, speed=3, move="down",  gfx=22, ink=0x9, nframes=3, frame=0, tile=0, spg=true},
        {x=11, y=7,  min=48,  max=102, speed=2, move="up",    gfx=22, ink=0x1, nframes=3, frame=1, tile=0, spg=true},
        {x=16, y=10, min=4,   max=80,  speed=1, move="down",  gfx=22, ink=0x8, nframes=3, frame=2, tile=0, spg=true},
    },
    -- level 19 (TWENTY)
    {
        {x=7,  y=13, min=56,  max=176, speed=0, move="right", gfx=24, ink=0x6, nframes=3, frame=0, tile=0},
        {x=24, y=6,  min=40,  max=103, speed=1, move="down",  gfx=15, ink=0x7, nframes=3, frame=0, tile=0},
    },
}

-- Live robot state
local robotThis = {}
for i = 1, 8 do
    robotThis[i] = {x=0, y=0, min=0, max=0, move="", gfx=0, ink=0, nframes=0, frame=0, tile=0, DoSpg=nil}
end

local curRobot  -- points to current robot during iteration

-- Forward declarations for move functions
local DoRobotLeft, DoRobotRight, DoRobotUp, DoRobotDown, DoRobotKong, DoRobotSkylab

DoRobotLeft = function()
    if band(gameTicks, curRobot.speed) ~= 0 then return end

    curRobot.frame = curRobot.frame - 1
    if curRobot.frame > 4 then return end

    if curRobot.x > curRobot.min then
        curRobot.x = curRobot.x - 8
        curRobot.tile = curRobot.tile - 1
        curRobot.frame = 7
        return
    end
    curRobot.DoMove = DoRobotRight
    curRobot.frame = 0
end

DoRobotRight = function()
    if band(gameTicks, curRobot.speed) ~= 0 then return end

    curRobot.frame = curRobot.frame + 1
    if curRobot.frame < 3 then return end  -- note: post-increment means check <3 (was <3 before increment)

    if curRobot.x < curRobot.max then
        curRobot.x = curRobot.x + 8
        curRobot.tile = curRobot.tile + 1
        curRobot.frame = 0
        return
    end
    curRobot.DoMove = DoRobotLeft
    curRobot.frame = 7
end

DoRobotUp = function()
    local pos = curRobot.y - curRobot.speed

    if pos < curRobot.min then
        curRobot.DoMove = DoRobotDown
    else
        if band(pos, 120) < band(curRobot.y, 120) then
            curRobot.tile = curRobot.tile - 32
        end
        curRobot.y = pos
    end

    curRobot.frame = curRobot.frame + 1
end

DoRobotDown = function()
    local pos = curRobot.y + curRobot.speed

    if pos < curRobot.max then
        if band(pos, 120) > band(curRobot.y, 120) then
            curRobot.tile = curRobot.tile + 32
        end
        curRobot.y = pos
    else
        curRobot.DoMove = DoRobotUp
    end

    curRobot.frame = curRobot.frame + 1
end

DoRobotKong = function()
    robotThis[1].frame = band(robotThis[1].frame, 2)
    robotThis[1].frame = bor(robotThis[1].frame, band(rshift(gameTicks, 3), 1))
end

local function DoRobotFall()
    if curRobot.y == curRobot.max then
        curRobot.DoMove = DoNothing
        curRobot.DoDraw = DoNothing
    else
        curRobot.y = curRobot.y + curRobot.speed
        -- call kong animation using robotThis[1] as curRobot context
        robotThis[1].frame = band(robotThis[1].frame, 2)
        robotThis[1].frame = bor(robotThis[1].frame, band(rshift(gameTicks, 3), 1))
        Game_ScoreAdd(100)
    end
end

DoRobotSkylab = function()
    if curRobot.y < curRobot.max then
        curRobot.y = curRobot.y + curRobot.speed
    else
        curRobot.frame = curRobot.frame + 1
        if curRobot.frame == 8 then
            curRobot.frame = 0
            curRobot.x = curRobot.x + 64
            curRobot.y = curRobot.min
        end
    end
end

local function DoRobotEugene()
    if curRobot.y < curRobot.max then
        curRobot.y = curRobot.y + curRobot.speed
    end
    curRobot.ink = band(curRobot.ink - 1, 0x7)
end

local function DoRobotDraw()
    local gfxSet = robotSprite[curRobot.gfx + 1]
    if not gfxSet then return end
    local frameIdx = band(curRobot.frame, curRobot.nframes) + 1
    local gfx = gfxSet[frameIdx]
    if gfx then
        Video_SpriteBlend(bor(lshift(curRobot.y, 8), curRobot.x), gfx, curRobot.ink)
    end
end

local function DoRobotSpg()
    local tile = curRobot.tile
    local adj = 1
    local ymod = band(curRobot.y, 7)
    local count = robotAlign[ymod + 1]  -- 1-indexed
    for i = 0, count - 1 do
        Level_SetSpgTile(tile, B_ROBOT)
        tile = tile + adj
        adj = bxor(adj, 30)
    end
end

function Robots_Barrel()
    robotThis[3].max = 18 * 8
end

function Robots_Kong()
    robotThis[1].frame = bor(robotThis[1].frame, 2)
    robotThis[1].nframes = bor(robotThis[1].nframes, 2)
    robotThis[1].ink = 0xf
    robotThis[1].DoMove = DoRobotFall
    Audio_Sfx(SFX_KONG)
end

function Robots_Eugene()
    robotThis[3].DoMove = DoRobotEugene
end

function Robots_Version(version)
    -- Set gfx for specific robots in levels 16 and 17
    -- Level index 16 (0-based) = robotStartData[17] (1-indexed)
    -- Level index 17 (0-based) = robotStartData[18] (1-indexed)
    if robotStartData[17] then
        for _, i in ipairs({3,4,5,6}) do
            if robotStartData[17][i] then
                robotStartData[17][i].gfx = 25 + version
            end
        end
    end
    if robotStartData[18] then
        for _, i in ipairs({5,6,7,8}) do
            if robotStartData[18][i] then
                robotStartData[18][i].gfx = 27 + version
            end
        end
    end
end

local moveMap = {
    right  = DoRobotRight,
    left   = DoRobotLeft,
    up     = DoRobotUp,
    down   = DoRobotDown,
    kong   = DoRobotKong,
    skylab = DoRobotSkylab,
}

function Robots_Ticker()
    for i = 1, 8 do
        curRobot = robotThis[i]
        if curRobot.DoMove then
            curRobot.DoMove()
        end
    end
end

function Robots_Drawer()
    for i = 1, 8 do
        curRobot = robotThis[i]
        if curRobot.DoDraw then
            curRobot.DoDraw()
        end
        if curRobot.DoSpg then
            curRobot.DoSpg()
        end
    end
end

function Robots_Init()
    local startList = robotStartData[gameLevel + 1] or {}

    for i = 1, 8 do
        local s = startList[i]
        if s then
            local r = robotThis[i]
            r.DoMove  = moveMap[s.move] or DoNothing
            r.DoDraw  = DoRobotDraw
            r.DoSpg   = s.spg and DoRobotSpg or DoNothing
            r.x       = s.x * 8
            if gameLevel == SKYLAB then
                r.y = s.min
            else
                r.y = s.y * 8
                if gameLevel == SPG then
                    r.tile = s.y * 32 + s.x
                end
            end
            r.min     = s.min
            r.max     = s.max
            r.speed   = s.speed or 0
            r.gfx     = s.gfx
            r.ink     = s.ink
            r.nframes = s.nframes
            r.frame   = s.frame
        else
            local r = robotThis[i]
            r.DoMove  = DoNothing
            r.DoDraw  = DoNothing
            r.DoSpg   = DoNothing
            r.x = 0; r.y = 0; r.min = 0; r.max = 0
            r.speed = 0; r.gfx = 0; r.ink = 0; r.nframes = 0; r.frame = 0; r.tile = 0
        end
    end
end
