//
//  BitcaskDB.m
//  Bitcask
//
//  Created by lii on 2020/11/13.
//  Copyright © 2020年 suchang. All rights reserved.
//

#import "BitcaskDB.h"
#import "Bucket.h"
#import "CRC32Data.h"

@implementation BitcaskConfig
@end

@interface BitcaskDB () <Bitcask>
@property (nonatomic,copy) NSString *bucketName;
@property (nonatomic,strong) BitcaskConfig *config; ///< db config
@property (nonatomic,strong) NSMutableDictionary<NSString*,Bucket*> *bucketInfo; ///< bucket map
@property (nonatomic,strong) CRC32Data *crc32;
@end

@implementation BitcaskDB

+ (id<Bitcask>)openDatabase:(BitcaskConfig *)config {
    if (config == nil) {
        return nil;
    }
    [BitcaskDB validateBitcaskConfig:config];
    BitcaskDB *db = [[BitcaskDB alloc] init];
    db.crc32 = [CRC32Data createCRC32Data];
    db.config = config;
    db.bucketInfo = [[NSMutableDictionary alloc] init];
    if (![db loadBucketsInfo:config]) {
        return nil;
    }
    [db loadKeysInfo:config];
    return db;
}

- (BOOL)changeBucket:(NSString *)name {
    if (name.length <= 0) {
        return NO;
    }
    if ([self.bucketName isEqualToString:name]) {
        return YES;
    }
    Bucket *bi = self.bucketInfo[name];
    if (!bi) {
        bi = [Bucket createBucket:name maxFid:0 path:self.config.path];
        self.bucketInfo[name] = bi;
    }
    self.bucketName = name;
    return YES;
}

- (BOOL)setObject:(NSData *)object withKey:(NSString *)key {
    if (object==nil || key.length<=0) {
        return NO;
    }
    [self removeObject:key];
    Bucket *bi = self.bucketInfo[self.bucketName];
    if (!bi) {
        return NO;
    }
    fid_t dt = [bi activeFid:self];
    record_t r;
    r.ti = (uint32_t)time(NULL);
    r.fid = dt.fid;
    r.offset = dt.offset;
    r.ksize = (uint32_t)key.length;
    r.vsize = (uint32_t)object.length;
    NSMutableData *mdata = [NSMutableData dataWithData:object];
    [mdata appendData:[key dataUsingEncoding:NSStringEncodingConversionAllowLossy]];
    r.crc32 = [self.crc32 crc32Data:mdata];
    Record *ri = [[Record alloc] init];
    ri.r = r;
    BOOL ret = [bi writeRecord:ri key:key value:object];
    if (ret) {
        bi.keyInfo[key] = ri;
    }
    return ret;
}

- (NSData *)getObject:(NSString *)key {
    if (key.length <= 0) {
        return nil;
    }
    Bucket *bi = self.bucketInfo[self.bucketName];
    if (!bi) {
        return nil;
    }
    Record *ri = bi.keyInfo[key];
    if (!ri) {
        return nil;
    }
    DataFile *df = [DataFile openDataFileWith:ri.r.fid path:[self fidPath:ri.r.fid bucketName:bi.name] readonly:YES];
    Record *rr = [bi readRecord:df offset:ri.r.offset readValue:YES];
    if (df) {
        [df close];
    }
    return rr.value;
}

- (void)removeObject:(NSString *)key {
    if (key.length <= 0) {
        return;
    }
    Bucket *bi = self.bucketInfo[self.bucketName];
    if (!bi) {
        return;
    }
    Record *ri = bi.keyInfo[key];
    if (!ri) {
        return;
    }
    record_t r = ri.r;
    r.vsize = 0; // mark delete
    ri.r = r;
    [bi activeFid:self];
    if ([bi writeRecord:ri key:key value:nil]) {
        [bi.keyInfo removeObjectForKey:key];
    }
}

- (void)gc:(NSString *)name {
    
}

- (void)closeDB {
    for (NSString *bucketName in self.bucketInfo) {
        Bucket *bi = self.bucketInfo[bucketName];
        if (bi.df) {
            [bi.df close];
            bi.df = nil;
        }
    }
    self.bucketInfo = @{}.mutableCopy;
    self.bucketName = @"";
    self.crc32 = nil;
}

#pragma mark - Internal

/** find bucket max fid
 */
- (BOOL)loadBucketsInfo:(BitcaskConfig *)config {
    NSFileManager *fs = [NSFileManager defaultManager];
    NSArray<NSString *> *bucketList = NULL;
    NSError *error = nil;
    // create database dir when not exist
    do {
        bucketList = [fs contentsOfDirectoryAtPath:config.path error:nil];
        if (bucketList == nil) {
            [fs createDirectoryAtPath:config.path
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&error];
        }
    } while (bucketList == nil && error == nil);
    if (error != nil) {
        return NO;
    }
    // load bucket or create not exist
    for (NSString *dirName in bucketList) {
        @autoreleasepool {
            BOOL isDir = NO;
            NSString *bucketPath = [self.config.path stringByAppendingPathComponent:dirName];
            if (![fs fileExistsAtPath:bucketPath isDirectory:&isDir] || !isDir) {
                continue;
            }
            NSArray *fileList = [fs contentsOfDirectoryAtPath:bucketPath error:nil];
            if (fileList == nil) {
                self.bucketInfo[dirName] = [Bucket createBucket:dirName maxFid:0 path:self.config.path];
            }
            uint32_t maxFid = 0;
            for (NSString *filePath in fileList) {
                NSString *fidString = [filePath substringWithRange:NSMakeRange(0, 9)];
                uint32_t fid = (uint32_t)fidString.integerValue;
                if (fid > maxFid) {
                    maxFid = fid;
                }
            }
            self.bucketInfo[dirName] = [Bucket createBucket:dirName maxFid:maxFid path:self.config.path];
        }
    }
    if (!self.bucketInfo[config.bucketName]) {
        self.bucketInfo[config.bucketName] = [Bucket createBucket:config.bucketName maxFid:0 path:self.config.path];
    }
    self.bucketName = config.bucketName;
    return YES;
}

- (void)loadKeysInfo:(BitcaskConfig *)config {
    for (NSString *bucketName in self.bucketInfo) {
        @autoreleasepool {
            Bucket *bi = self.bucketInfo[bucketName];
            for (uint32_t fid = 0; fid <= bi.maxFid; fid++) {
                DataFile *df = [DataFile openDataFileWith:fid path:[self fidPath:fid bucketName:bi.name] readonly:YES];
                if (df == nil) {
                    [bi.freeFids addObject:@(fid)];
                    continue;
                }
                uint32_t offset = 0;
                while (YES) {
                    Record *ri = [bi readRecord:df offset:offset readValue:NO];
                    if (ri == nil) {
                        break;
                    }
                    if (ri.r.vsize > 0) {
                        bi.keyInfo[ri.key] = ri;
                    } else {
                        [bi.keyInfo removeObjectForKey:ri.key];
                    }
                    offset += [ri size];
                }
                [df close];
            }
        }
    }
}

+ (void)validateBitcaskConfig:(BitcaskConfig *)config {
    if (config.path.length <= 0) {
        NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        config.path = [path stringByAppendingPathComponent:@"bitcask"];
    }
    if (config.maxFileSize <= 0) {
        config.maxFileSize = 64 * 1024 * 1024;
    }
    if(config.bucketName.length <= 0) {
        config.bucketName = @"0";
    }
}

- (NSString *)fidPath:(uint32_t)fid bucketName:(NSString *)bucketName {
    bucketName = bucketName.length > 0 ? bucketName : self.bucketName;
    return [NSString stringWithFormat:@"%@/%@/%09u.dat", self.config.path, bucketName, fid];
}

- (BitcaskConfig *)getConfig {
    return self.config;
}

@end
