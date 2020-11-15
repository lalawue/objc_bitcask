//
//  NSData+CRC32.h
//  CRC32_iOS
//
//  Created by 宣佚 on 15/7/14.
//  Copyright (c) 2015年 宣佚. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CRC32Data : NSObject

+ (instancetype)createCRC32Data;

- (uint32_t)crc32Data:(NSData *)data;

@end
