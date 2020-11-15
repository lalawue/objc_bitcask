//
//  Bucket.m
//  Bitcask
//
//  Created by lii on 2020/11/15.
//  Copyright © 2020年 suchang. All rights reserved.
//

#import "Bucket.h"
#import "BitcaskDB_Private.h"

@implementation Record
- (uint32_t)size {
    return sizeof(record_t) + self.r.ksize + self.r.vsize;
}
@end

@interface Bucket ()
@property (nonatomic,copy) NSString *path;
@end

@implementation Bucket

+ (Bucket *)createBucket:(NSString *)name maxFid:(uint32_t)maxFid path:(NSString *)path {
    if (name.length<=0 || path.length<=0) {
        return nil;
    }
    BOOL isDir = NO;
    NSString *bucketPath = [path stringByAppendingPathComponent:name];
    if (![[NSFileManager defaultManager] fileExistsAtPath:bucketPath isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:bucketPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    Bucket *bucket = [[Bucket alloc] init];
    bucket.path = path;
    bucket.name = name;
    bucket.maxFid = maxFid;
    bucket.keyInfo = @{}.mutableCopy;
    bucket.freeFids = @[].mutableCopy;
    return bucket;
}

- (fid_t)activeFid:(BitcaskDB *)db {
    fid_t dt = {self.actFid, 0};
    if (self.df) {
        dt.offset = [self.df size];
        if (dt.offset < [db getConfig].maxFileSize) {
            return dt;
        }
        [self.df close];
    }
    // try free
    if (self.freeFids.count > 0) {
        dt.fid = [self.freeFids.lastObject unsignedIntValue];
        [self.freeFids removeLastObject];
        self.df = [DataFile openDataFileWith:dt.fid path:[db fidPath:dt.fid bucketName:self.name] readonly:NO];
        if (self.df) {
            dt.offset = [self.df size];
            if (dt.offset < [db getConfig].maxFileSize) {
                self.actFid = dt.fid;
                return dt;
            }
            [self.df close];
        }
    }
    // try max fid, or max + 1
    while (YES) {
        dt.fid = self.maxFid;
        self.df = [DataFile openDataFileWith:dt.fid path:[db fidPath:dt.fid bucketName:self.name] readonly:NO];
        if (self.df) {
            dt.offset = [self.df size];
            if (dt.offset < [db getConfig].maxFileSize) {
                self.actFid = dt.fid;
                return dt;
            }
        }
        self.maxFid += 1;
    }
    return dt;
}

- (void)nextActFid:(BitcaskDB *)db {
    if (self.df) {
        [self.df close];
    }
    if (self.freeFids.count > 0) {
        self.actFid = [self.freeFids.lastObject unsignedIntValue];
        [self.freeFids removeLastObject];
    } else {
        self.actFid = self.maxFid + 1;
        self.maxFid = self.actFid;
    }
    self.df = [DataFile openDataFileWith:self.actFid path:[db fidPath:self.actFid bucketName:self.name] readonly:NO];
}

- (Record *)readRecord:(DataFile *)df offset:(uint32_t)offset readValue:(BOOL)readValue {
    NSData *dat = [df readAt:offset size:sizeof(record_t)];
    if (dat.length <= 0) {
        return nil;
    }
    record_t r;
    [dat getBytes:&r length:sizeof(r)];
    if (r.ksize <= 0) {
        return nil;
    }
    Record *ri = [[Record alloc] init];
    ri.r = r;
    dat = [df readAt:offset + sizeof(r) size:r.ksize];
    if (dat.length <= 0) {
        return nil;
    }
    ri.key = [[NSString alloc] initWithData:dat encoding:NSStringEncodingConversionAllowLossy];
    if (readValue && r.vsize > 0) {
        ri.value = [df readAt:offset + sizeof(r) + r.ksize size:r.vsize];
    }
    return ri;
}

- (BOOL)writeRecord:(Record *)ri key:(NSString *)key value:(NSData *)value {
    record_t r = ri.r;
    uint8_t *buf = malloc(sizeof(r));
    memcpy(buf, &r, sizeof(r));
    NSMutableData *mdata = [NSMutableData dataWithBytesNoCopy:buf length:sizeof(r) freeWhenDone:YES];
    [mdata appendData:[key dataUsingEncoding:NSStringEncodingConversionAllowLossy]];
    if (value.length > 0) {
        [mdata appendData:value];
    }
    return [self.df write:mdata];
}

- (uint32_t)readBucketInfo:(BitcaskDB *)db name:(NSString *)name {
    NSString *infoPath = [NSString stringWithFormat:@"%@/%@.info", [db getConfig].path, name];
    NSString *dataString = [[NSString alloc] initWithContentsOfFile:infoPath encoding:NSStringEncodingConversionAllowLossy error:nil];
    if (dataString.length > 0) {
        return (uint32_t)[dataString integerValue];
    }
    return 0;
}

- (BOOL)writeBucketInfo:(BitcaskDB *)db name:(NSString *)name {
    NSString *infoPath = [NSString stringWithFormat:@"%@/%@.info", [db getConfig].path, name];
    NSString *dataString = [NSString stringWithFormat:@"%lu", time(NULL)];
    return [dataString writeToFile:infoPath atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
}

@end
