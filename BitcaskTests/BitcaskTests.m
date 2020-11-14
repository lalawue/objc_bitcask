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
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
