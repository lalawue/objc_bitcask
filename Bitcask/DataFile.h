//
//  DataFile.h
//  Bitcask
//
//  Created by lii on 2020/11/14.
//  Copyright © 2020年 suchang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataFile : NSObject

+ (instancetype)createDataFileWith:(uint32_t)fid path:(NSString *)path readonly:(BOOL)readonly;

- (uint32_t)fileID;
- (void)sync;
- (void)close;
- (uint32_t)size;
- (NSData*)readAt:(uint32_t)offset size:(uint32_t)size;
- (BOOL)write:(NSData *)data;
- (uint32_t)modTime;

@end
