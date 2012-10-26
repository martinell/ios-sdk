//
//© Catchoom Technologies S.L.
//Licensed under the MIT license.
//https://raw.github.com/catchoom/ios-crc/LICENSE
//
//  CatchoomService.h
//  CRSMobile
//
//  Created by Crisredfi on 10/17/12.
//  Copyright (c) 2012 Catchoom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CatchoomSearchResponseItem.h"

@protocol CatchoomServiceProtocol;

@interface CatchoomService : NSObject

@property (nonatomic, weak) id <CatchoomServiceProtocol> delegate;

+ (CatchoomService *)sharedCatchoom;

- (void)beginServerConnection;
- (void)connect:(NSString *)token;
- (void)search:(UIImage *)image;
- (void)search:(UIImage*)image withToken:(NSString *)token;

void UIImageFromURL( NSURL * URL, void (^imageBlock)(UIImage * image), void (^errorBlock)(void));

@end


@protocol CatchoomServiceProtocol <NSObject>

@optional
- (void)didReceiveConnectResponse:(id)sender;
- (void)didReceiveSearchResponse:(NSArray *)response;
- (void)didFailLoadWithError:(NSError *)error;

@end
