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

// inits the server connection with catchoon. without this callback, the service will not work
// this method must be called at the begining of the application.
- (void)beginServerConnection;

// Creates a connection with the server using a token. With this callback, you are autentificating the
// application against catchoom service and connecting the app to a specific collection.
// will answer with the delegate didReceiveConnectResponse: or didFailLoadWithError:
- (void)connect:(NSString *)token;

// Will create a search call for an image taken by the user.
// will answer with a delegate didReceiveSearchResponse: or didFailLoadWithError:
- (void)search:(UIImage *)image;


// block helper to download a image from a URL (handy to create a lazy load).
void UIImageFromURL( NSURL * URL, void (^imageBlock)(UIImage * image), void (^errorBlock)(void));

@end


@protocol CatchoomServiceProtocol <NSObject>

@optional

// delegate answer for connect callback. the return object is a JSON with the information of the
// connection status
- (void)didReceiveConnectResponse:(id)sender;

// delegate answer for the Search callback. Ther return object is an Array of CatchoomSearchResponseItem(s)
// the objects are already parsed and ready to use.
- (void)didReceiveSearchResponse:(NSArray *)response;

// delegate answer in case of answer error.
- (void)didFailLoadWithError:(NSError *)error;

@end
