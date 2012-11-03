ios-sdk
=======

iOS Catchoom SDK



Catchoom SDK has several callbacks that will provide you with all the data necessary to use Catchoom service. 

The main headers you will need to add to every file you want to use Catchoom SDK is CRSMobile.h. With this headder you will have acces to all the elements of the library. 

	#import <CRSMobile/CRSMobile.h>

if you really want to use the library in every file of your app, add the header in yourAppName-Prefix.pch and this file will automatically link the library to all your source code files.

Once the header is imported, First thing you will need to do is to start the connection with the Catchoom server. This will be done with a singleton callback to CatchoonService.

    [[CatchoomService sharedCatchoom] beginServerConnection];

Now you have initialized the connection with Catchoon Service, you can create calls to the service. Take into account that 
the SDK can work asynchronously and unasynchronously. The callbacks are calling explicitly  the main queue (using GCD) so is up to you to create the request in background or not.  The available calls are:

- (void)beginServerConnection: Inits the server connection with Catchoom. without this callback, the service will not work. this method must be called at the beginning of the application.

- (void)connect:(NSString *)token: Creates a connection with the server using an existing token. With this callback you are authenticating  the application against Catchoom service and connecting the app to a specific collection. Will answer with the delegate didReceiveConnectionResponse or didFailLoadWithError


- (void)search:(UIImage *)image; Will create a serach call for an image taken by the user. Will answer with the delegate didReceiveSearcgResponse or didFailLoadWithError.


the delegate callbacks are:

- (void)didReceiveConnectResponse:(id)sender; delegate answer for connect callback. The returned object is a JSON with the information of the connection status.

- (void)didReceiveSearchResponse:(NSArray *)response; delegate answer for Search callback. The return object is an Array of CatchoomSerachResponseItem(s). 

- (void)didFailLoadWithError:(NSError *)error; delegate answer in case of answer error.
