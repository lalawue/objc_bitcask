//
//  DataFile.m
//  Bitcask
//
//  Created by lii on 2020/11/14.
//  Copyright © 2020年 suchang. All rights reserved.
//

#import "DataFile.h"
#import <sys/stat.h>

@interface DataFile ()
@property (nonatomic,assign) uint32_t fid;
@property (nonatomic,copy) NSString *path;
@property (nonatomic,assign) BOOL readonly;
@property (nonatomic,strong) NSFileHandle *fh;
@property (nonatomic,assign) uint32_t offset;
@property (nonatomic,assign) uint32_t mod_time;
@end

@implementation DataFile

+ (instancetype)createDataFileWith:(uint32_t)fid path:(NSString *)path readonly:(BOOL)readonly {
    struct stat st;
    st.st_size = 0;
    st.st_mtimespec.tv_sec = 0;
    if (stat(path.UTF8String, &st) != 0) {
        if (readonly) {
            return nil;
        }
        [(NSString *)@"" writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
    DataFile *df = [[DataFile alloc] init];
    if (readonly) {
        df.fh = [NSFileHandle fileHandleForReadingAtPath:path];
    } else {
        df.fh = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    if (df.fh == nil) {
        return nil;
    }
    df.fid = fid;
    df.path = path;
    df.readonly = readonly;
    df.offset = (uint32_t)st.st_size;
    df.mod_time = (uint32_t)st.st_mtimespec.tv_sec;
    return df;
}

- (uint32_t)fileID {
    return self.fid;
}

- (void)sync {
    [self.fh synchronizeFile];
}

- (void)close {
    [self sync];
    [self.fh closeFile];
    self.fh = nil;
}

- (uint32_t)size {
    return self.offset;
}

- (NSData*)readAt:(uint32_t)offset size:(uint32_t)size {
    if (!self.fh) {
        return nil;
    }
    [self.fh seekToFileOffset:offset];
    return [self.fh readDataOfLength:size];
}

- (BOOL)write:(NSData *)data {
    if (!self.fh) {
        return nil;
    }
    [self.fh seekToEndOfFile];
    [self.fh writeData:data];
    self.offset += (uint32_t)data.length;
    self.mod_time = (uint32_t)time(nil);
    return YES;
}

- (uint32_t)modTime {
    return self.mod_time;
}

@end
