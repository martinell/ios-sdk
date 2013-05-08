iOS Catchoom SDK
====================

Description
-----------
iOS Catchoom SDK is an iOS library that acts as interface between an iOS Catchoom client app and the Recognition API of the Catchoom Recognition Service. You can find an implementation example on the [Catchoom Recognition Client](https://github.com/Catchoom/ios-crc "Catchoom Recognition Client") project.

Requirements
------------
To build the project or use the library, you will need XCode, and at least the iOS 5.0 library.

Installation
------------
You can find the instructions about how to use the iOS-SDK in conjunction with your app [here](https://github.com/Catchoom/ios-sdk/wiki/Installation-of-the-iOS-SDK-into-your-own-app).

Usage
-----

iOS Catchoom SDK has several callbacks that will provide you with all the data necessary to use Catchoom Recognition Service. 

The main header you need to use the SDK is CRSMobile.h. This header provides acces to all the elements of the library. 

	#import <CRSMobile/CRSMobile.h>

Tip: If you want to use the library in every file of your app, add the header in yourAppName-Prefix.pch and this file will automatically link the library to all your source code files.

The available methods are described below.

The SDK can work asynchronously and synchronously. The callbacks are calling explicitly the main queue (using GCD) so it is up to you to create the request in background or not.


* `- (void)connect:(NSString *)token`: checks if `token` is a valid token for a collection in the server. This callback answers with the delegates `didReceiveConnectionResponse` or `didFailLoadWithError`.

* `- (void)search:(UIImage*)image withToken:(NSString *)token`: performs a search call sending `image` to the server for recognition against the collection identified by `token`. This callback answers with the delegates `didReceiveSearchResponse` or `didFailLoadWithError`.


The delegate callbacks are:

* `- (void)didReceiveConnectResponse:(id)sender`: delegate answer for `connect` callback. The returned object is a `JSON` with the information of the connection status.

* `- (void)didReceiveSearchResponse:(NSArray *)response`: delegate answer for `search` callback. The returned object is an `Array` of `CatchoomSearchResponseItem`(s). 

* `- (void)didFailLoadWithError:(NSError *)error`: delegate answer in case of answer error.
