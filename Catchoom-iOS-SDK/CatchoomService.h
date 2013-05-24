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
#import <AVFoundation/AVFoundation.h>
#import "ImageHandler.h"

@protocol CatchoomServiceProtocol;

@interface CatchoomService : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, weak) id <CatchoomServiceProtocol> delegate;
@property BOOL _isFinderModeON;
@property BOOL _isOneShotModeON;

+ (CatchoomService *)sharedCatchoom;


// Creates a connection with the server using a token. With this callback, you are authenticating the
// application against catchoom service and connecting the app to a specific collection.
// will answer with the delegate didReceiveConnectResponse: or didFailLoadWithError:
- (void)connect:(NSString *)token;

// Performs a search call for an image taken by the user.
// Collection Token must be set previously with connect or a previous call to search:withToken
// Answers with a delegate didReceiveSearchResponse: or didFailLoadWithError:
- (void)search:(UIImage *)image;

// Performs a search call with a specific token. Sets the token as the default one and calls search.
// Answers with a delegate didReceiveSearchResponse: or didFailLoadWithError:
- (void)search:(UIImage*)image withToken:(NSString *)token;

/// Finder Mode: performs a continuous scan of information in the viewfinder.
// Creates an AVCaptureSession suitable for Finder Mode.
- (void)startFinderMode:(int32_t)searchesPerSecond withPreview:(UIView*)mainView;

// Stops the AVCaptureSession and bails other elements necessary for Finder Mode.
- (void)stopFinderMode;

- (void)startOneShotModeWithPreview:(UIView*)mainView;

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
