//
//© Catchoom Technologies S.L.
//Licensed under the MIT license.
//https://raw.github.com/catchoom/ios-crc/LICENSE
//
//  ObjectModel.h
//  Catchoom
//
//  Created by Crisredfi on 9/18/12.
//  Copyright (c) 2012 Catchoom. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CatchoomSearchResponseItem : NSObject

@property (nonatomic) NSString *itemId;
@property (nonatomic) NSString *thumbnail;
@property (nonatomic) NSString *score;
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *imageId;
@property (nonatomic) NSData *iconImage;
@property (nonatomic) NSString *iconName;


@end
