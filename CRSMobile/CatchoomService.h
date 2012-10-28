//
// © Catchoom Technologies S.L.
// Licensed under the MIT license.
// http://github.com/Catchoom/ios-crc/blob/master/LICENSE
//  All warranties and liabilities are disclaimed.
//
//  CatchoomService.h
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
