//
// © Catchoom Technologies S.L.
// Licensed under the MIT license.
// http://github.com/Catchoom/ios-crc/blob/master/LICENSE
//  All warranties and liabilities are disclaimed.
//
//  CatchoomSearchResponseItem.h


#import <Foundation/Foundation.h>

@interface CatchoomSearchResponseItem : NSObject

@property (nonatomic) NSString *itemId;
@property (nonatomic) NSString *thumbnail;
@property (nonatomic) NSString *score;
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *imageId;
@property (nonatomic) NSData   *iconImage;
@property (nonatomic) NSString *iconName;


@end
