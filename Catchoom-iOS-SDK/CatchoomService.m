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
#import "ImageHandler.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/CGImageProperties.h>

#define MINVIDEOFRAMERATE 30
#define MAXVIDEOFRAMERATE 15

@interface CatchoomService ()
{
    NSMutableArray *_parsedElements;
    AVCaptureVideoDataOutput *_videoCaptureOutput;
    AVCaptureSession *_avCaptureSession;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
    CALayer *_scanFXlayer;
    CALayer *_scanFXlayer2;
    int32_t _NumOfFramesCaptured;
    int32_t _searchRate;
}

// Selector that captures an image triggered by theTimer in Finder Mode and sends it asynchronously.
- (void)captureImageFinderMode:(NSTimer*)theTimer;

// Performs a search call for an image captured in Finder Mode.
// Answers with a delegate didReceiveSearchResponse: or didFailLoadWithError:
- (void)searchFinderMode:(NSData *)imageNSData;

// Helper function to transform a buffer into a UIImage
- (UIImage*) imageFromSampleBuffer: (CMSampleBufferRef) sampleBuffer;

@end


@implementation CatchoomService
@synthesize delegate = _delegate;

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
#pragma mark - Check tokens connections

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

//delegate callback for tokens answer
- (void)didReceiveConnectResponse:(RKResponse *)response {
    
    [self.delegate didReceiveConnectResponse:response];
}




#pragma mark -
#pragma mark - Call to server to send image. this should always be a background thread

-(void)search:(UIImage*)image
{
    
    __weak CatchoomService *currentService = self;
    //create post call to server
    [[RKClient sharedClient] post:@"/search" usingBlock:^(RKRequest *request) {
        NSData *newImage = [ImageHandler prepareNSDataFromUIImage: image];
        if(newImage){
            request.method = RKRequestMethodPOST;
            
            
            
            RKParams* imageParams = [RKParams params];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [imageParams setData:newImage MIMEType:@"image/jpg" forParam:@"image"];
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
                if([parsedResponse count] == 0){
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NO MATCH", @"")
                                                                    message:NSLocalizedString(@"there is no object in the collection that matches with any in the picture", @"")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                          otherButtonTitles: nil];
                    [alert show];
                }else{
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

//send image with specific token. Sets the token as the default one and creates the normal callback.

- (void)search:(UIImage*)image withToken:(NSString *)token {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:token forKey:@"token"];
    [self search:image];
}

#pragma mark -
#pragma mark - Finder Mode
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
    
    // Create and Configure the Device and Device Input
    AVCaptureDevice *avCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    AVCaptureDeviceInput *avCaptureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:avCaptureDevice error:&error];
    if (!avCaptureDeviceInput) {
        NSLog(@"ERROR: Couldn't create AVCaptureDeviceInput.");
    }
    /*
     if (![avCaptureDevice lockForConfiguration:&error]) {
     NSLog(@"ERROR: Couldn't lock camera device configuration.");
     }
     if ([avCaptureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
     //CGPoint autofocusPoint = CGPointMake(0.5f, 0.5f);
     //[avCaptureDevice setFocusPointOfInterest:autofocusPoint];
     [avCaptureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
     }
     [avCaptureDevice unlockForConfiguration];
     */
    
    if ( [_avCaptureSession canAddInput:avCaptureDeviceInput] )
    {
        [_avCaptureSession addInput:avCaptureDeviceInput];
    }
    
    // Create and Configure the Data Output
    _videoCaptureOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoCaptureOutput.videoSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    _videoCaptureOutput.alwaysDiscardsLateVideoFrames = YES;
    AVCaptureConnection *videoCaptureConnection = [_videoCaptureOutput connectionWithMediaType:AVMediaTypeVideo];
    [videoCaptureConnection setVideoMinFrameDuration:CMTimeMake(1, MINVIDEOFRAMERATE)];
    [videoCaptureConnection setVideoMaxFrameDuration:CMTimeMake(1, MAXVIDEOFRAMERATE)];
    
    if ( [_avCaptureSession canAddOutput:_videoCaptureOutput] )
    {
        [_avCaptureSession addOutput:_videoCaptureOutput];
    }
    
    if (mainView != nil) {
        // Add video preview
        CALayer *rootLayer = mainView.layer;
        
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_avCaptureSession];
        [_captureVideoPreviewLayer setVideoGravity : AVLayerVideoGravityResizeAspectFill];
        [_captureVideoPreviewLayer setBackgroundColor : [[UIColor blackColor] CGColor]];
        
        //[rootLayer insertSublayer:_captureVideoPreviewLayer atIndex:1];
        
        [rootLayer setMasksToBounds:YES];
        [_captureVideoPreviewLayer setFrame:[rootLayer bounds]];
        [rootLayer addSublayer:_captureVideoPreviewLayer];
        
        // Optional: add layer to draw scanning effect
        _scanFXlayer = [CALayer layer];
        [_scanFXlayer setFrame:[rootLayer bounds]];
        [_scanFXlayer setDelegate:self];
        [_scanFXlayer setNeedsDisplay];
        
        /*CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.translation"];
         [animation setDuration:1.5];
         [animation setRepeatCount:INT_MAX];
         [animation setFromValue:[NSNumber numberWithInt:0] ];
         CGRect layerBounds = rootLayer.bounds;
         [animation setToValue:[NSNumber numberWithInt:layerBounds.size.width]];
         */
        
        CAKeyframeAnimation *animationLeft2Right = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
        [animationLeft2Right setDuration:2.0];
        [animationLeft2Right setRepeatCount:INT_MAX];
        
        NSMutableArray *values = [NSMutableArray array];
        [values addObject:[NSNumber numberWithInt:rootLayer.bounds.origin.x]];
        [values addObject:[NSNumber numberWithInt:rootLayer.bounds.origin.x+rootLayer.bounds.size.width]];
        [values addObject:[NSNumber numberWithInt:rootLayer.bounds.origin.x]];
        [animationLeft2Right setValues:values];
        
        [_scanFXlayer addAnimation:animationLeft2Right forKey:nil];
        
        
        _scanFXlayer2 = [CALayer layer];
        [_scanFXlayer2 setFrame:[rootLayer bounds]];
        [_scanFXlayer2 setDelegate:self];
        [_scanFXlayer2 setNeedsDisplay];
        
        CAKeyframeAnimation *animationBottom2Top = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
        [animationBottom2Top setDuration:2.0];
        [animationBottom2Top setRepeatCount:INT_MAX];
        
        [values removeAllObjects];
        [values addObject:[NSNumber numberWithInt:rootLayer.bounds.origin.y]];
        [values addObject:[NSNumber numberWithInt:rootLayer.bounds.origin.y + rootLayer.bounds.size.height]];
        [values addObject:[NSNumber numberWithInt:rootLayer.bounds.origin.y]];
        [animationBottom2Top setValues:values];
        
        [_scanFXlayer2 addAnimation:animationBottom2Top forKey:nil];
        
        //[rootLayer addSublayer:_scanFXlayer];
        [rootLayer addSublayer:_scanFXlayer2];
        
    }
    
    dispatch_queue_t queue = dispatch_queue_create("SearchFinderModeQueue", NULL);
    [_videoCaptureOutput setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    _searchRate = MINVIDEOFRAMERATE/searchesPerSecond;
    
    _NumOfFramesCaptured = _searchRate/3;
    
    // Start capturing
    NSLog(@"Starting Finder mode.");
    [_avCaptureSession startRunning];
    
}

- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef) ctx
{
    if (layer == _scanFXlayer) {
        CGRect layerBounds = layer.bounds;
        /*
         
         CGContextMoveToPoint(ctx, layerBounds.origin.x, layerBounds.origin.y);
         CGContextAddLineToPoint(ctx, layerBounds.origin.x, layerBounds.origin.y + layerBounds.size.height);
         
         CGContextStrokePath(ctx);
         
         CGRect layerBounds = layer.bounds;*/
        
        CGColorSpaceRef myColorspace=CGColorSpaceCreateDeviceRGB();
        size_t num_locations = 2;
        CGFloat locations[2] = { 1.0, 0.0 };
        CGFloat components[8] =	{ 0.0, 0.0, 0.0, 0.0, 176.0f/255.0f, 1.0f/255.0f, 36.0f/255.0f, 1.0 };
        
        CGGradientRef myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
        
        CGPoint myStartPoint, myEndPoint;
        myStartPoint.x = 0.0;
        myStartPoint.y = 0.0;
        myEndPoint.x = 30.0;
        myEndPoint.y = 0.0;
        CGContextDrawLinearGradient (ctx, myGradient, myStartPoint, myEndPoint, 0);
        
        CGContextSaveGState(ctx);
        CGContextAddRect(ctx, CGRectMake(layerBounds.origin.x, layerBounds.origin.y, 1, layerBounds.size.height));
        CGContextClip(ctx);
        CGContextRestoreGState(ctx);
        
    }
    else if (layer == _scanFXlayer2) {
        CGRect layerBounds = layer.bounds;
        
        CGColorSpaceRef myColorspace=CGColorSpaceCreateDeviceRGB();
        size_t num_locations = 2;
        CGFloat locations[2] = { 1.0, 0.0 };
        CGFloat components[8] =	{ 0.0, 0.0, 0.0, 0.0,    176.0f/255.0f, 1.0f/255.0f, 36.0f/255.0f, 1.0 };
        
        CGGradientRef myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
        
        CGPoint myStartPoint, myEndPoint;
        myStartPoint.x = 0.0;
        myStartPoint.y = 0.0;
        myEndPoint.x = 0.0;
        myEndPoint.y = 30.0;
        CGContextDrawLinearGradient (ctx, myGradient, myStartPoint, myEndPoint, 0);
        
        CGContextSaveGState(ctx);
        CGContextAddRect(ctx, CGRectMake(layerBounds.origin.x, layerBounds.origin.y, layerBounds.size.width, 1));
        CGContextClip(ctx);
        CGContextRestoreGState(ctx);
    }
    
}

// Stops the AVCaptureSession and bails other elements necessary for Finder Mode.
- (void)stopFinderMode
{
    
    // Stop Camera Capture
    [_avCaptureSession stopRunning];
    
    _videoCaptureOutput = nil;
    //_stillImageOutput = nil;
    
    [_captureVideoPreviewLayer removeFromSuperlayer];
    _captureVideoPreviewLayer = nil;
    
    [_scanFXlayer removeFromSuperlayer];
    _scanFXlayer = nil;
    [_scanFXlayer2 removeFromSuperlayer];
    _scanFXlayer2 = nil;
    
    NSLog(@"Stopped Finder mode.");
}

- (UIImage*) imageFromSampleBuffer: (CMSampleBufferRef) sampleBuffer
{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer.
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    // Get the number of bytes per row for the pixel buffer.
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height.
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space.
    static CGColorSpaceRef colorSpace = NULL;
    if (colorSpace == NULL) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace == NULL) {
            // Handle the error appropriately.
            return nil;
        }
    }
    
    // Get the base address of the pixel buffer.
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    
    // Create a Quartz direct-access data provider that uses data we supply.
    CGDataProviderRef dataProvider =
    CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    // Create a bitmap image from data supplied by the data provider.
    CGImageRef cgImage =
    CGImageCreate(width, height, 8, 32, bytesPerRow,
                  colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                  dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    // Create and return an image object to represent the Quartz image.
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return image;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    if (_NumOfFramesCaptured == 0) {
        UIImage *resultUIImage = [self imageFromSampleBuffer:sampleBuffer];
        NSData *imageData = UIImageJPEGRepresentation(resultUIImage, 0.75);
        
        // Send image to CRS asynchronously
        dispatch_queue_t backgroundQueue;
        backgroundQueue = dispatch_queue_create("com.catchoom.catchoom.background", NULL);
        dispatch_async(backgroundQueue, ^(void) {
            [self searchFinderMode:imageData];
        });
        dispatch_release(backgroundQueue);
        _NumOfFramesCaptured = _searchRate;
    }
    //NSLog(@"_NumOfFramesCaptured: %d",_NumOfFramesCaptured);
    _NumOfFramesCaptured--;
    
}

// Performs a search call for an image captured in Finder Mode.
// Answers with a delegate didReceiveSearchResponse: or didFailLoadWithError:
- (void)searchFinderMode:(NSData *)imageNSData
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
    /*
     NSArray *parsedResponse = [[NSArray alloc]init];
     [currentService didReceiveSearchResponse:parsedResponse];
     */
}

#pragma mark -
#pragma mark - Server Callbacks

//this method creates the CatchoomItems and send them as an array to the application.

- (void)didReceiveSearchResponse:(NSArray *)response {
    if (_parsedElements == nil) {
        _parsedElements = [NSMutableArray array];
    }else{
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



#pragma mark -
#pragma mark - block converted to a method to download the images in background
//this snippet of code is a method that will download the icon image using different threads
//and in the background. very usefull snipped with blocks and GCD

void UIImageFromURL( NSURL * URL, void (^imageBlock)(UIImage * image), void (^errorBlock)(void) )
{
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^(void)
                   {
                       NSData * data = [[NSData alloc] initWithContentsOfURL:URL] ;
                       UIImage * image = [[UIImage alloc] initWithData:data] ;
                       dispatch_async( dispatch_get_main_queue(), ^(void){
                           if( image != nil )
                           {
                               imageBlock( image );
                           } else {
                               errorBlock();
                           }
                       });
                       
                   });
}



@end
