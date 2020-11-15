//
//  BitcaskTests.m
//  BitcaskTests
//
//  Created by lii on 2020/11/13.
//  Copyright © 2020年 suchang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Bitcask.h"

@interface BitcaskTests : XCTestCase
@property (nonatomic,strong) BitcaskConfig *config;
@property (nonatomic,strong) id<Bitcask> db;
@property (nonatomic,assign) NSInteger count;
@property (nonatomic,copy) NSString *baseString;
@end

@implementation BitcaskTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.config = [[BitcaskConfig alloc] init];
    NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    self.config.path = [cacheDir stringByAppendingPathComponent:@"bitcask"];
    self.config.maxFileSize = 512;
    self.config.bucketName = @"0";
    self.db = [BitcaskDB openDatabase:self.config];
    NSLog(@"opendb at %@", self.config.path);
    self.count = 256;
    self.baseString = @"abcdefghijklmnopqrstuvwxyz";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [self.db closeDB];
}

/** test bucket name space
 */
- (void)testBucket {
    [self.db changeBucket:@"hello"];
    NSString *numString = @"a";
    [self.db setObject:[self dataWithString:numString] withKey:numString];
    NSString *valueString = [self stringWithData:[self.db getObject:numString]];
    NSAssert([valueString isEqualToString:numString], @"invalid value in 'hello'");
    // test bucket 0
    [self.db changeBucket:@"0"];
    valueString = [self stringWithData:[self.db getObject:numString]];
    NSAssert(![valueString isEqualToString:numString], @"invalid value in '0'");
}

- (void)testGetSet {
    // set
    for (int i=0; i<self.count; i++) {
        NSString *keyString = @(i).stringValue;
        NSData *valueData = [self dataWithString:[self.baseString stringByAppendingString:keyString]];
        [self.db setObject:valueData withKey:keyString];
    }
    // get
    for (int i=0; i<self.count; i++) {
        NSString *keyString = @(i).stringValue;
        NSString *valueString = [self stringWithData:[self.db getObject:keyString]];
        BOOL ret = [valueString isEqualToString:[self.baseString stringByAppendingString:keyString]];
        NSAssert(ret, @"invalid get/set value");
    }
}

- (void)testDelete {
    for (int i=0; i<self.count; i+=2) {
        NSString *keyString = @(i).stringValue;
        [self.db removeObject:keyString];
    }
    for (int i=0; i<self.count; i+=2) {
        NSString *keyString = @(i).stringValue;
        NSData *retData = [self.db getObject:keyString];
        NSAssert(retData == nil, @"invalid delete");
    }
}

// test after get/set/delete
- (void)testGC {
    [self.db gc:@"0"];
    [self.db closeDB];
    self.db = nil;
    self.db = [BitcaskDB openDatabase:self.config];
    for (int i=0; i<self.count; i++) {
        NSString *keyString = @(i).stringValue;
        NSData *retData = [self.db getObject:keyString];
        if (i%2 == 0) {
            NSAssert(retData == nil, @"invalid gc deleted");
        } else {
            BOOL ret = [[self stringWithData:retData] isEqualToString:[self.baseString stringByAppendingString:keyString]];
            NSAssert(ret, @"invalid gc remained");
        }
    }
}


- (NSData *)dataWithString:(NSString *)str {
    if (str.length <= 0) {
        return nil;
    }
    return [str dataUsingEncoding:NSStringEncodingConversionAllowLossy];
}

- (NSString *)stringWithData:(NSData *)dat {
    if (dat.length <= 0) {
        return nil;
    }
    return [[NSString alloc] initWithData:dat encoding:NSStringEncodingConversionAllowLossy];
}

@end
