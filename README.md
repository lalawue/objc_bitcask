

# About

objc_bitcask was a Key/Value store for ObjC, uses [Bitcask](https://en.wikipedia.org/wiki/Bitcask)  on-disk layout.

only test in MacOS.

# Example

```ObjC
// open
config = [[BitcaskConfig alloc] init];
NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
config.path = [cacheDir stringByAppendingPathComponent:@"bitcask"];
config.maxFileSize = 512;
config.bucketName = @"0";
id<Bitcask> db = [BitcaskDB openDatabase:config];

// change bucket
[db changeBucket:@"hello"];

// get/set
NSData *dat = [db getObject:@"key"];
[db setObject:[@"value" dataUsingEncoding:NSStringEncodingConversionAllowLossy]
      withKey:@"key"];

// delete
[db removeObject:@"key"];

// gc
[db gc:@"hello"];

// close DB
[db closeDB];
```

# Test

in BitcaskTests.
