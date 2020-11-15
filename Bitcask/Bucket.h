//
//  Bucket.h
//  Bitcask
//
//  Created by lii on 2020/11/15.
//  Copyright © 2020年 suchang. All rights reserved.
//

#import "BitcaskDB_Private.h"
#import "DataFile.h"

typedef struct {
    uint32_t ti;
    uint32_t fid;
    uint32_t offset;
    uint32_t ksize;
    uint32_t vsize;
    uint32_t crc32;
} record_t;

typedef struct {
    uint32_t fid;
    uint32_t offset;
} fid_t;

@interface Record : NSObject
@property (nonatomic,assign) record_t r;
@property (nonatomic,copy) NSString *key;
@property (nonatomic,strong) NSData *value;
- (uint32_t)size;
@end

@interface Bucket : NSObject
@property (nonatomic,copy) NSString *name; ///< bucket name
@property (nonatomic,assign) uint32_t actFid; ///< active file id
@property (nonatomic,assign) uint32_t maxFid; ///< max file id
@property (nonatomic,strong) NSMutableDictionary<NSString*,Record*> *keyInfo; ///< key value map
@property (nonatomic,strong) DataFile *df;
@property (nonatomic,strong) NSMutableArray<NSNumber *> *freeFids;

+ (Bucket *)createBucket:(NSString *)name maxFid:(uint32_t)maxFid path:(NSString *)path;

- (fid_t)activeFid:(BitcaskDB *)db;
- (void)nextActFid:(BitcaskDB *)db;

- (Record *)readRecord:(DataFile *)df offset:(uint32_t)offset readValue:(BOOL)readValue;
- (BOOL)writeRecord:(Record *)ri key:(NSString *)key value:(NSData *)value;

- (uint32_t)readBucketInfo:(BitcaskDB *)db name:(NSString *)name;
- (BOOL)writeBucketInfo:(BitcaskDB *)db name:(NSString *)name;

@end
