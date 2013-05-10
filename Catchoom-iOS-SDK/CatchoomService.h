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

@protocol CatchoomServiceProtocol;

@interface CatchoomService : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, weak) id <CatchoomServiceProtocol> delegate;

+ (CatchoomService *)sharedCatchoom;


// Creates a connection with the server using a token. With this callback, you are authenticating the
// application against catchoom service and connecting the app to a specific collection.
// will answer with the delegate didReceiveConnectResponse: or didFailLoadWithError:
- (void)connect:(NSString *)token;

// Performs a search call for an image taken by the user.
// Answers with a delegate didReceiveSearchResponse: or didFailLoadWithError:
- (void)search:(UIImage *)image;

//send image with specific token. Sets the token as the default one and creates the normal callback.
- (void)search:(UIImage*)image withToken:(NSString *)token;

/// Finder Mode: performs a continuous scan of information in the viewfinder.

// Creates an AVCaptureSession suitable for Finder Mode.
- (void)startFinderMode:(int32_t)searchesPerSecond withPreview:(UIView*)mainView;

// Stops the AVCaptureSession and bails other elements necessary for Finder Mode.
- (void)stopFinderMode;

/*
// Selector that captures an image triggered by theTimer in Finder Mode and sends it asynchronously.
- (void)captureImageFinderMode:(NSTimer*)theTimer;

// Performs a search call for an image captured in Finder Mode.
// Answers with a delegate didReceiveSearchResponse: or didFailLoadWithError:
- (void)searchFinderMode:(NSData *)imageNSData;
*/

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
