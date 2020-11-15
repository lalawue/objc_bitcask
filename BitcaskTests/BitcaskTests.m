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
@property (nonatomic,strong) id<Bitcask> db;
@end

@implementation BitcaskTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    BitcaskConfig *config = [[BitcaskConfig alloc] init];
    NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    config.path = [cacheDir stringByAppendingPathComponent:@"bitcask"];
    config.maxFileSize = 512;
    config.bucketName = @"0";
    self.db = [BitcaskDB openDatabase:config];
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
    NSInteger count = 256;
    NSString *baseString = @"abcdefghijklmnopqrstuvwxyz";
    // set
    for (int i=0; i<count; i++) {
        NSString *keyString = @(i).stringValue;
        NSData *valueData = [self dataWithString:[baseString stringByAppendingString:keyString]];
        [self.db setObject:valueData withKey:keyString];
    }
    // get
    for (int i=0; i<count; i++) {
        NSString *keyString = @(i).stringValue;
        NSString *valueString = [self stringWithData:[self.db getObject:keyString]];
        BOOL ret = [valueString isEqualToString:[baseString stringByAppendingString:keyString]];
        NSAssert(ret, @"invalid get/set value");
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
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
