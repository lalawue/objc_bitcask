//
//  BitcaskDB.h
//  Bitcask
//
//  Created by lii on 2020/11/13.
//  Copyright © 2020年 suchang. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Bucket database interface
 */
@protocol Bitcask

/** change bucket
 */
- (BOOL)changeBucket:(NSString *)name;

/** set object with key
 */
- (BOOL)setObject:(NSData *)object withKey:(NSString *)key;

/** get object with key
 */
- (NSData *)getObject:(NSString *)key;

/** remove object with key
 */
- (void)removeObject:(NSString *)key;

/** collect bucket name
 */
- (void)gc:(NSString *)name;

/** close database
 */
- (void)closeDB;

@end

#pragma mark -

/** bitcask database config
 */
@interface BitcaskConfig : NSObject
@property (nonatomic, copy) NSString *path; ///< default '~/Caches/bitcask'
@property (nonatomic, copy) NSString *bucketName; ///< default '0'
@property (nonatomic, assign) NSInteger maxFileSize; ///< default 64*1024*1024
@end

#pragma mark -

/** bitcask database open
 */
@interface BitcaskDB : NSObject

/** open database with config
 */
+ (id<Bitcask>)openDatabase:(BitcaskConfig *)config;

@end
