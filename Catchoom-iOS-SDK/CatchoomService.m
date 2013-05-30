//
// © Catchoom Technologies S.L.
// Licensed under the MIT license.
// http://github.com/Catchoom/ios-crc/blob/master/LICENSE
//  All warranties and liabilities are disclaimed.
//
//  CatchoomService.m
//

#import "CatchoomService.h"
#define KMainUrl @"https://r.catchoom.com/v0"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/CGImageProperties.h>
#import "ScanFXLayer.h"

@interface CatchoomService ()
{
    NSMutableArray *_parsedElements;
    AVCaptureVideoDataOutput *_videoCaptureOutput;
    AVCaptureSession *_avCaptureSession;

    ScanFXLayer *_scanFXlayer;
    
    SearchType _searchType;
        
    // Finder Mode
    int32_t _NumOfFramesCaptured;
    int32_t _searchRate;
    BOOL _isFinderModeON;
    CGFloat _fScaleFactor;
    UIButton *_uiStopFinderModeButton;
    
    // One-shot Mode
    AVCaptureStillImageOutput *_stillImageOutput;
    BOOL _isOneShotModeON;
    UIButton *_uiTakePictureButton;
}

// Performs a search call for an image stored in imageNSData that is formatted for best performance.
// Answers with a delegate didReceiveSearchResponse: or didFailLoadWithError:
- (void)searchWithData:(NSData *)imageNSData;

@end


@implementation CatchoomService
@synthesize delegate = _delegate;
//@synthesize _isFinderModeON;
//@synthesize _isOneShotModeON;

- (SearchType)getSearchType
{
    return _searchType;
}

#pragma mark - RESTKit connection management

//sets the new RKClient connection. Future library implementations for start up should go here
- (void)beginServerConnection {
    
    
    [RKClient clientWithBaseURL:[NSURL URLWithString:KMainUrl]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityStatusChanged:)
                                                 name:RKReachabilityDidChangeNotification object:nil];
    
    if (_isOneShotModeON) {
        [self stopOneShotMode];
    }
    if (_isFinderModeON)
    {
        [self stopFinderMode];
    }

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleBecameActive)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    
}
- (void)reachabilityStatusChanged:(NSNotification *)aNotification {
    if ([[[RKClient sharedClient] reachabilityObserver] isReachabilityDetermined]
        && ![[RKClient sharedClient] isNetworkReachable]) {
        UIAlertView *reachAV = [[UIAlertView alloc]
                                initWithTitle:NSLocalizedString(@"Cannot connect to Internet", @"")
                                message:NSLocalizedString(@"Catchoom cannot reach the Internet. Please be sure that your device is connected to the Internet and try again.",@"")
                                delegate:self
                                cancelButtonTitle:NSLocalizedString(@"Retry", @"")
                                otherButtonTitles:nil];
        reachAV.tag = 0;
        [reachAV show];
        
        NSLog(@"Cannot reach the Internet.");
        
        // Clean any ongoing search
        if (_isOneShotModeON) {
            [self stopOneShotMode];
        }
        if (_isFinderModeON)
        {
            [self stopFinderMode];
        }
        
        NSError *error = [[NSError alloc] init];
        [self didFailLoadWithError:error];
    }
    
    
}

-(void)handleBecameActive
{
    if (_isFinderModeON) {
        [_scanFXlayer startAnimations];
    }
}

+ (CatchoomService *)sharedCatchoom
{
    static dispatch_once_t once;
    static CatchoomService *sharedCatchoom;
    dispatch_once(&once, ^ { sharedCatchoom = [[CatchoomService alloc] init];
        [sharedCatchoom beginServerConnection];
    });
    return sharedCatchoom;

}


#pragma mark - Check tokens and server connectivity

- (void)connect:(NSString *)token {
    
    if (token == nil) {
        token = @"";
    }
    __weak CatchoomService *currentService = self;
    
    [[RKClient sharedClient] post:@"/timestamp" usingBlock:^(RKRequest *request) {
        
        RKParams* serverRequest = [RKParams params];
        [serverRequest setValue: token
                       forParam:@"token"];
        
        request.params = serverRequest;
        
        request.onDidLoadResponse = ^(RKResponse *response) {
            
            [currentService didReceiveConnectResponse:response];
        };
        [request setOnDidFailLoadWithError:^(NSError *error){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR" ,@"")
                                                            message:NSLocalizedString(@"Error while trying to connect", @"")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles: nil];
            [alert show];
            
            [currentService didFailLoadWithError:error];
        }];
        
        
        
    }];
    
}


- (void)didReceiveConnectResponse:(RKResponse *)response {
    
    [self.delegate didReceiveConnectResponse:response];
}





#pragma mark - Call to server to send image. this should always be a background thread

-(void)search:(UIImage*)image
{
    NSData *newImage = [ImageHandler imageNSDataFromUIImage: image];
    _searchType = kSearchTypeImage;
    [self searchWithData:newImage];
}

- (void)search:(UIImage*)image withToken:(NSString *)token {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:token forKey:@"token"];
    [self search:image];
}


- (void)searchWithData:(NSData *)imageNSData
{
    __weak CatchoomService *currentService = self;
    
    //create post call to server
    [[RKClient sharedClient] post:@"/search" usingBlock:^(RKRequest *request) {
        if(imageNSData){
            request.method = RKRequestMethodPOST;
            
            NSLog(@"Sending imageData.");
            
            RKParams* imageParams = [RKParams params];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [imageParams setData:imageNSData MIMEType:@"image/jpg" forParam:@"image"];
            [imageParams setValue: [defaults stringForKey:@"token"]
                         forParam:@"token"];
            request.params = imageParams;
            //handle error during connection
            [request setOnDidFailLoadWithError:^(NSError *error){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR" ,@"")
                                                                message:NSLocalizedString(@"error while uploading the image, something went wrong", @"")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                      otherButtonTitles: nil];
                [alert show];
                
                [currentService didFailLoadWithError:error];
            }];
            
            
            request.onDidLoadResponse = ^(RKResponse *response) {

                NSArray *parsedResponse = [response parsedBody:NULL];
                
                if(response.statusCode == 200){
                    // Check if the request was correctly formatted
                    if([[parsedResponse lastObject ]valueForKey:@"message"]){
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Token Invalid", @"")
                                                                        message:[parsedResponse valueForKey:@"message"]
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                              otherButtonTitles: nil];
                        [alert show];
                        
                    }
                }else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
                                                                    message:NSLocalizedString(@"there has been an error while uploading the picture to the server, please try it again later.", @"")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"OK",@"")
                                                          otherButtonTitles: nil];
                    [alert show];
                }
                
                [currentService didReceiveSearchResponse:parsedResponse];
                
            };
            
        }
        
    }];
    
}

#pragma mark - Video Capture Error handler
- (void)showAlertOfErrorWithVideoCapture
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ERROR" ,@"")
                                                    message:@"Error while initializing the Video Capture Device."
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                          otherButtonTitles: nil];
    [alert show];
}

#pragma mark - One-shot Mode

- (void)startOneShotModeWithPreview:(UIViewController*)mainViewController
{
    // Create and Configure a Capture Session with Low preset = 192x144
    _avCaptureSession = [[AVCaptureSession alloc] init];
    if (_avCaptureSession == nil) {
        NSLog(@"ERROR: Couldn't create AVCaptureSession.");
        
        [self showAlertOfErrorWithVideoCapture];
        return;
    }
    _avCaptureSession.sessionPreset = AVCaptureSessionPresetMedium;

    
    // Create and Configure the Device and Device Input
    AVCaptureDevice *avCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (avCaptureDevice == nil) {
        NSLog(@"ERROR: Couldn't create AVCaptureDevice with AVMediaTypeVideo.");

        [self showAlertOfErrorWithVideoCapture];
        return;
    }
    
    
    NSError *error = nil;
    AVCaptureDeviceInput *avCaptureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:avCaptureDevice error:&error];
    if (avCaptureDeviceInput == nil) {
        NSLog(@"ERROR: Couldn't define AVCaptureDeviceInput for AVCaptureDevice.");
        
        [self showAlertOfErrorWithVideoCapture];
        return;
    }
    
    if ( [_avCaptureSession canAddInput:avCaptureDeviceInput] )
    {
        [_avCaptureSession addInput:avCaptureDeviceInput];
    }
    else{
        NSLog(@"ERROR: Couldn't add AVCaptureDeviceInput.");
        
        [self showAlertOfErrorWithVideoCapture];
        return;
    }
    
    // Create and Configure the Data Output
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    if (_stillImageOutput == nil) {
        NSLog(@"ERROR: Couldn't create AVCaptureStillImageOutput.");
        
        [self showAlertOfErrorWithVideoCapture];
        return;
    }
    
    
    NSDictionary *outputSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    [_stillImageOutput setOutputSettings:outputSettings];
    
    if ( [_avCaptureSession canAddOutput:_stillImageOutput] )
    {
        [_avCaptureSession addOutput:_stillImageOutput];
    }
    else
    {
        NSLog(@"ERROR: Couldn't add AVCaptureStillImageOutput.");
        
        [self showAlertOfErrorWithVideoCapture];
        return;
    }
    
    // Add video preview
    if (mainViewController != nil) {
        _scanFXlayer = [[ScanFXLayer alloc] initWithViewController:mainViewController withSession:_avCaptureSession];
    
        _uiTakePictureButton = [ScanFXLayer createUIButtonWithText:@"Take Picture" andFrame:CGRectMake(mainViewController.view.frame.size.width/2-80.0, mainViewController.view.frame.size.height-60.0, 160.0, 40.0)];
        [_uiTakePictureButton addTarget:self
                                 action:@selector(captureImage)
                       forControlEvents:UIControlEventTouchUpInside];
        
        [mainViewController.view addSubview:_uiTakePictureButton];
    }
    
    // Start Capture
    _isOneShotModeON = TRUE;
    _searchType = kSearchTypeOneShotMode;
    [_avCaptureSession startRunning];
    
}

- (void)captureImage
{
    
    AVCaptureConnection *stillImageConnection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:
     ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
         
         if (error != nil) {
             NSLog(@"error with captureStillImageAsynchronouslyFromConnection %@", [error localizedDescription]);
         }
         
          /*// Uncomment if exif details are needed.
          CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
          if (exifAttachments) {
          NSLog(@"attachments: %@", exifAttachments);
          } else {
          NSLog(@"no attachments");
          }*/

         NSLog(@"Captured Still Image. Preparing to Send.");
         
         // Convert CMSampleBufferRef to UIImage
         //NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation: imageSampleBuffer];
         NSData *imageData = [ImageHandler imageNSDataFromSampleBuffer:imageSampleBuffer];
         //UIImage *image = [[UIImage alloc] initWithData:imageData];
         
         // Send image to CRS asynchronously
         dispatch_queue_t backgroundQueue;
         backgroundQueue = dispatch_queue_create("com.catchoom.catchoom.background", NULL);
         dispatch_async(backgroundQueue, ^(void) {
             [self searchWithData:imageData];
         });
         dispatch_release(backgroundQueue);
         
         // Stop Camera Capture
         [_avCaptureSession stopRunning];
         
         [_scanFXlayer startAnimations];
         
         [_uiTakePictureButton removeFromSuperview];
         _uiTakePictureButton = nil;
         
         _stillImageOutput = nil;
     }];

}

-(void)stopOneShotMode
{
    _isOneShotModeON = FALSE;
    if (_scanFXlayer != nil) {
        [_scanFXlayer remove];
        _scanFXlayer = nil;
    }

    if (_uiTakePictureButton != nil) {
        [_uiTakePictureButton removeFromSuperview];
        _uiTakePictureButton = nil;
    }

}

#pragma mark - Finder Mode

#define MAXVIDEOFRAMERATE 30
#define MINVIDEOFRAMERATE 15

// Creates an AVCaptureSession suitable for Finder Mode.
- (void)startFinderMode:(int32_t)searchesPerSecond withPreview:(UIViewController*)mainViewController
{
    
    if  (searchesPerSecond <= 0)
    {
        searchesPerSecond = 2;
    }
    
    // Create and Configure a Capture Session with Low preset = 192x144
    _avCaptureSession = [[AVCaptureSession alloc] init];
    if (_avCaptureSession == nil) {
        NSLog(@"ERROR: Couldn't create AVCaptureSession.");
        
        [self showAlertOfErrorWithVideoCapture];
        return;
    }
    _avCaptureSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    // Create and Configure the Device and Device Input
    AVCaptureDevice *avCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (avCaptureDevice == nil) {
        NSLog(@"ERROR: Couldn't create AVCaptureDevice with AVMediaTypeVideo.");
        
        [self showAlertOfErrorWithVideoCapture];
        return;
    }
    
    if ([avCaptureDevice isFocusPointOfInterestSupported]) {
        NSError *lockError;
        if ([avCaptureDevice lockForConfiguration:&lockError]) {
            NSLog(@"Focus forced on the center of the camera viewfinder.");
            avCaptureDevice.focusPointOfInterest = CGPointMake(0.5f, 0.5f);
            
            [avCaptureDevice unlockForConfiguration];
        }

    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *avCaptureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:avCaptureDevice error:&error];
    if (avCaptureDeviceInput == nil) {
        NSLog(@"ERROR: Couldn't define AVCaptureDeviceInput for AVCaptureDevice.");
        
        [self showAlertOfErrorWithVideoCapture];
        return;
    }

    
    if ( [_avCaptureSession canAddInput:avCaptureDeviceInput] )
    {
        [_avCaptureSession addInput:avCaptureDeviceInput];
    }
    else{
        NSLog(@"ERROR: Couldn't add AVCaptureDeviceInput.");
        
        [self showAlertOfErrorWithVideoCapture];
        return;
    }

    
    // Create and Configure the Data Output
    _videoCaptureOutput = [[AVCaptureVideoDataOutput alloc] init];
    if (_videoCaptureOutput == nil) {
        NSLog(@"ERROR: Couldn't create AVCaptureVideoDataOutput.");
        
        [self showAlertOfErrorWithVideoCapture];
        return;
    }
    _videoCaptureOutput.videoSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    _videoCaptureOutput.alwaysDiscardsLateVideoFrames = YES;
    
    if ( [_avCaptureSession canAddOutput:_videoCaptureOutput] )
    {
        [_avCaptureSession addOutput:_videoCaptureOutput];
    }
    else
    {
        NSLog(@"ERROR: Couldn't add AVCaptureVideoDataOutput.");
        
        [self showAlertOfErrorWithVideoCapture];
        return;
    }
    
    AVCaptureConnection *videoCaptureConnection = [_videoCaptureOutput connectionWithMediaType:AVMediaTypeVideo];
    [videoCaptureConnection setVideoMinFrameDuration:CMTimeMake(1, MAXVIDEOFRAMERATE)];
    [videoCaptureConnection setVideoMaxFrameDuration:CMTimeMake(1, MINVIDEOFRAMERATE)];
    
    //[Optional] add layer to draw scanning effect
    if (mainViewController != nil) {
        
        _scanFXlayer = [[ScanFXLayer alloc] initWithViewController:mainViewController withSession:_avCaptureSession];
        
        _uiStopFinderModeButton = [ScanFXLayer createUIButtonWithText:@"Stop capturing" andFrame:CGRectMake(mainViewController.view.frame.size.width/2-80.0, mainViewController.view.frame.size.height-60.0, 160.0, 40.0)];
        [_uiStopFinderModeButton addTarget:self
                                 action:@selector(stopFinderModeAndDelegate)
                       forControlEvents:UIControlEventTouchUpInside];
        
        [mainViewController.view addSubview:_uiStopFinderModeButton];
        
    }
    
    dispatch_queue_t queue = dispatch_queue_create("SearchFinderModeQueue", NULL);
    [_videoCaptureOutput setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    // Setup FinderMode rate
    _searchRate = MAXVIDEOFRAMERATE/searchesPerSecond;
    _NumOfFramesCaptured = _searchRate/3; // shortens the time until the first image is sent
    
    // Start capturing
    NSLog(@"Starting Finder mode.");
    _isFinderModeON = TRUE;
    _searchType = kSearchTypeFinderMode;
    [_scanFXlayer startAnimations];
    [_avCaptureSession startRunning];
    
}

// Stops the AVCaptureSession and bails other elements necessary for Finder Mode.
- (void)stopFinderMode
{
    if (_isFinderModeON) {
        _isFinderModeON = FALSE;
        
        // Stop Camera Capture
        [_avCaptureSession stopRunning];
        
        _videoCaptureOutput = nil;
        
        if (_scanFXlayer != nil) {
            [_scanFXlayer remove];
            _scanFXlayer = nil;
        }

        if (_uiStopFinderModeButton != nil) {
            [_uiStopFinderModeButton removeFromSuperview];
            _uiStopFinderModeButton = nil;
        }
        
        NSLog(@"Finder Mode stopped.");
    }
}

- (void)stopFinderModeAndDelegate
{
    [self stopFinderMode];
    NSMutableArray *emptyArray = [NSMutableArray array];
    [self.delegate didReceiveSearchResponse:emptyArray];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    if (_NumOfFramesCaptured == 0 && _isFinderModeON) {
        //UIImage *resultUIImage = [ImageHandler imageFromSampleBuffer:sampleBuffer];
        
        NSData *imageData = [ImageHandler imageNSDataFromSampleBuffer:sampleBuffer];
        
        // Send image to CRS asynchronously
        dispatch_queue_t backgroundQueue;
        backgroundQueue = dispatch_queue_create("com.catchoom.catchoom.background", NULL);
        dispatch_async(backgroundQueue, ^(void) {
            [self searchWithData:imageData];
        });
        dispatch_release(backgroundQueue);
        _NumOfFramesCaptured = _searchRate;
    }
    _NumOfFramesCaptured--;
    
}


#pragma mark - Server Callbacks

//this method creates the CatchoomItems and send them as an array to the application.

- (void)didReceiveSearchResponse:(NSArray *)response {

    if (_searchType == kSearchTypeOneShotMode) {
        [self stopOneShotMode];
    }
    
    if (_searchType == kSearchTypeFinderMode) {
        if (([response count] > 0) && _isFinderModeON ){
            [self stopFinderMode];
        }
        else {
            // Ignore empty responses or incoming responses after Finder Mode is stopped.
            return;
        }
    }
    
    if (_parsedElements == nil) {
        _parsedElements = [NSMutableArray array];
    }else {
        [_parsedElements removeAllObjects];
    }
    
    
    [response enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        CatchoomSearchResponseItem *model = [[CatchoomSearchResponseItem alloc] init];
        model.itemId = [obj valueForKey:@"item_id"];
        model.score = [obj valueForKey:@"score"];
        model.thumbnail = [[obj valueForKey:@"metadata"]valueForKey:@"thumbnail"];
        model.url = [[obj valueForKey:@"metadata"]valueForKey:@"url"];
        model.iconName = [[obj valueForKey:@"metadata"] valueForKey:@"name"];
        [_parsedElements addObject:model];
    }];
    
    [self.delegate didReceiveSearchResponse:_parsedElements];
}

// in case of error we will call this method.

- (void)didFailLoadWithError:(NSError *)error {
    if (_isOneShotModeON) {
        [self stopOneShotMode];
    }
    if (_isFinderModeON)
    {
        [self stopFinderMode];
    }
    if([self.delegate respondsToSelector:@selector(didFailLoadWithError:)]){
        [self.delegate didFailLoadWithError:error];
    }
}



@end
