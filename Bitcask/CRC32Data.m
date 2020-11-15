//
//  Created by 宣佚 on 15/7/14.
//  Copyright (c) 2015年 宣佚. All rights reserved.
//

#import "CRC32Data.h"

@interface CRC32Data ()
@property (nonatomic,assign) uint32_t *table;
@end

@implementation CRC32Data

+ (instancetype)createCRC32Data
{
    uint32_t *table = malloc(sizeof(uint32_t) * 256);
    for (uint32_t i=0; i<256; i++) {
        table[i] = i;
        for (int j=0; j<8; j++) {
            if (table[i] & 1) {
                table[i] = (table[i] >>= 1) ^ 0xedb88320;
            } else {
                table[i] >>= 1;
            }
        }
    }
    CRC32Data *crc32 = [[CRC32Data alloc] init];
    crc32.table = table;
    return crc32;
}

-(uint32_t)crc32Data:(NSData *)data
{
    if (data.length <= 0) {
        return 0;
    }

    uint32_t crc = 0xffffffff;
    uint8_t *bytes = (uint8_t *)[data bytes];
    uint32_t *table = self.table;
    
    for (int i=0; i<data.length; i++) {
        crc = (crc >> 8) ^ table[(crc & 0xff) ^ bytes[i]];
    }
    crc ^= 0xffffffff;
    
    return crc;
}

@end
