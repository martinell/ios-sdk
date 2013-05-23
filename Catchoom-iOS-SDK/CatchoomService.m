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
    
    int32_t _NumOfFramesCaptured;
    int32_t _searchRate;
    BOOL _isFinderModeON;
    CGFloat _fScaleFactor;
}

// Performs a search call for an image stored in imageNSData that is formatted for best performance.
// Answers with a delegate didReceiveSearchResponse: or didFailLoadWithError:
- (void)searchWithData:(NSData *)imageNSData;

@end


@implementation CatchoomService
@synthesize delegate = _delegate;
@synthesize _isFinderModeON;

#pragma mark -
#pragma mark - RESTKit connection management

//sets the new RKClient connection. Future library implementations for start up should go here
- (void)beginServerConnection {
    
    
    [RKClient clientWithBaseURL:[NSURL URLWithString:KMainUrl]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityStatusChanged:)
                                                 name:RKReachabilityDidChangeNotification object:nil];
    
    
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

#pragma mark -
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




#pragma mark -
#pragma mark - Call to server to send image. this should always be a background thread

-(void)search:(UIImage*)image
{
    NSData *newImage = [ImageHandler prepareNSDataFromUIImage: image];
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
                if([parsedResponse count] > 0){
                    if(response.statusCode == 200){
                        
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
                }
                [currentService didReceiveSearchResponse:parsedResponse];
                
            };
            
        }
        
    }];
    
}

#pragma mark -
#pragma mark - Finder Mode

#define MAXVIDEOFRAMERATE 30
#define MINVIDEOFRAMERATE 15

// Creates an AVCaptureSession suitable for Finder Mode.
- (void)startFinderMode:(int32_t)searchesPerSecond withPreview:(UIView*)mainView
{
    
    if  (searchesPerSecond <= 0)
    {
        searchesPerSecond = 2;
    }
    
    // Create and Configure a Capture Session with Low preset = 192x144
    _avCaptureSession = [[AVCaptureSession alloc] init];
    _avCaptureSession.sessionPreset = AVCaptureSessionPresetMedium;
    _fScaleFactor = 240.0f/360.0f; // for AVCaptureSessionPresetMedium
    //_fScaleFactor = 240.0f/144.0f; // for AVCaptureSessionPresetLow
    
    // Create and Configure the Device and Device Input
    AVCaptureDevice *avCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    AVCaptureDeviceInput *avCaptureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:avCaptureDevice error:&error];
    if (!avCaptureDeviceInput) {
        NSLog(@"ERROR: Couldn't create AVCaptureDeviceInput.");
    }
    
    if ( [_avCaptureSession canAddInput:avCaptureDeviceInput] )
    {
        [_avCaptureSession addInput:avCaptureDeviceInput];
    }
    
    // Create and Configure the Data Output
    _videoCaptureOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoCaptureOutput.videoSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    _videoCaptureOutput.alwaysDiscardsLateVideoFrames = YES;
    
    if ( [_avCaptureSession canAddOutput:_videoCaptureOutput] )
    {
        [_avCaptureSession addOutput:_videoCaptureOutput];
    }
    
    AVCaptureConnection *videoCaptureConnection = [_videoCaptureOutput connectionWithMediaType:AVMediaTypeVideo];
    [videoCaptureConnection setVideoMinFrameDuration:CMTimeMake(1, MAXVIDEOFRAMERATE)];
    [videoCaptureConnection setVideoMaxFrameDuration:CMTimeMake(1, MINVIDEOFRAMERATE)];
    
    //[Optional] add layer to draw scanning effect
    if (mainView != nil) {

        CALayer *rootLayer = mainView.layer;
        [rootLayer setMasksToBounds:YES];
        
        _scanFXlayer = [[ScanFXLayer alloc] initWithBounds:[rootLayer bounds] withSession:_avCaptureSession];
        
        [rootLayer addSublayer:_scanFXlayer];
        
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
        
        [_scanFXlayer remove];
        _scanFXlayer = nil;
        
        NSLog(@"Stopped Finder mode.");
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    if (_NumOfFramesCaptured == 0 && _isFinderModeON) {
        //UIImage *resultUIImage = [ImageHandler imageFromSampleBuffer:sampleBuffer];
        
        UIImage *resultUIImage = [ImageHandler imageFromSampleBuffer:sampleBuffer andScaling:_fScaleFactor];
        NSData *imageData = UIImageJPEGRepresentation(resultUIImage, 0.65);
        
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

#pragma mark -
#pragma mark - Server Callbacks

//this method creates the CatchoomItems and send them as an array to the application.

- (void)didReceiveSearchResponse:(NSArray *)response {
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
    if([self.delegate respondsToSelector:@selector(didFailLoadWithError:)]){
        [self.delegate didFailLoadWithError:error];
    }
}



@end
