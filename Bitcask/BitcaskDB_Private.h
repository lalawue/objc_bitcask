//
//  BitcaskDB_Private.h
//  Bitcask
//
//  Created by lii on 2020/11/15.
//  Copyright © 2020年 suchang. All rights reserved.
//

#import "Bitcask.h"

@interface BitcaskDB (Private)

- (BitcaskConfig *)getConfig;
- (NSString *)fidPath:(uint32_t)fid bucketName:(NSString *)bucketName;

@end
