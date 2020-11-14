//
//  BitcaskDB.m
//  Bitcask
//
//  Created by lii on 2020/11/13.
//  Copyright © 2020年 suchang. All rights reserved.
//

#import "BitcaskDB.h"
#import "DataFile.h"

typedef struct {
    uint32_t ti;
    uint32_t fid;
    uint32_t offset;
    uint32_t ksize;
    uint32_t vsize;
    uint32_t crc32;
} record_t;

@interface Record : NSObject
@property (nonatomic,assign) record_t record;
@end

@implementation Record
@end

#pragma mark -

@interface Bucket : NSObject
@property (nonatomic,copy) NSString *name; ///< bucket name
@property (nonatomic,assign) uint32_t actFid; ///< active file id
@property (nonatomic,assign) uint32_t maxFid; ///< max file id
@property (nonatomic,strong) NSMutableDictionary<NSString*,Record*> *keyInfo; ///< key value map
@end

@implementation Bucket
@end

#pragma mark -

@implementation BitcaskConfig
@end

@interface BitcaskDB () <Bitcask>
@property (nonatomic,copy) NSString *bucketName;
@property (nonatomic,strong) BitcaskConfig *config; ///< db config
@property (nonatomic,strong) NSMutableDictionary<NSString*,Bucket*> *bucketInfo; ///< bucket map
@end

@implementation BitcaskDB

+ (id<Bitcask>)openDatabase:(BitcaskConfig *)config {
    if (config == nil) {
        return nil;
    }
    [BitcaskDB validateBitcaskConfig:config];
    BitcaskDB *db = [[BitcaskDB alloc] init];
    db.config = config;
    db.bucketInfo = [[NSMutableDictionary alloc] init];
    if (![db loadBucketsInfo:config]) {
        return nil;
    }
    if (![db loadKeysInfo:config]) {
        return nil;
    }
    return db;
}

- (bool)changeBucket:(NSString *)name {
    return NO;
}

- (bool)setObject:(NSData *)object withKey:(NSString *)key {
    return NO;
}

- (NSData *)getObject:(NSString *)key {
    return nil;
}

- (id)removeObject:(NSString *)key {
    return nil;
}

- (void)gc:(NSString *)name {
    
}

- (void)closeDB {
    
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
                self.bucketInfo[dirName] = [self _createBucket:dirName maxFid:0];
            }
            uint32_t maxFid = 0;
            for (NSString *filePath in fileList) {
                NSString *fidString = [filePath substringWithRange:NSMakeRange(filePath.length - 14, 9)];
                uint32_t fid = (uint32_t)fidString.integerValue;
                if (fid > maxFid) {
                    maxFid = fid;
                }
            }
            self.bucketInfo[dirName] = [self _createBucket:dirName maxFid:maxFid];
        }
    }
    if (!self.bucketInfo[config.bucketName]) {
        self.bucketInfo[config.bucketName] = [self _createBucket:config.bucketName maxFid:0];
    }
    self.bucketName = config.bucketName;
    return YES;
}

- (BOOL)loadKeysInfo:(BitcaskConfig *)config {
    return NO;
}

- (Bucket *)_createBucket:(NSString *)name maxFid:(uint32_t)maxFid {
    BOOL isDir = NO;
    NSString *path = [self.config.path stringByAppendingPathComponent:name];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    Bucket *bucket = [[Bucket alloc] init];
    bucket.name = name;
    bucket.maxFid = maxFid;
    bucket.keyInfo = @{}.mutableCopy;
    return bucket;
}

- (NSString *)_fidPath:(uint32_t)fid bucketName:(NSString *)bucketName {
    bucketName = bucketName.length > 0 ? bucketName : self.bucketName;
    return [NSString stringWithFormat:@"%@/%@/%09u", self.config.path, bucketName, fid];
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

@end
