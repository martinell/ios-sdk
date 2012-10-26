//
//© Catchoom Technologies S.L.
//Licensed under the MIT license.
//https://raw.github.com/catchoom/ios-crc/LICENSE
//
//  CatchoomService.m
//  CRSMobile
//
//  Created by Crisredfi on 10/17/12.
//  Copyright (c) 2012 Catchoom. All rights reserved.
//

#import "CatchoomService.h"
#define KMainUrl @"https://r.catchoom.com/v0"
#import "ImageHandler.h"


@interface CatchoomService ()
{
    NSMutableArray *_parsedElements;
}
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
                                                                message:NSLocalizedString(@"error while uploading the image, something whent wrong", @"")
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


//server callbacks.
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
#pragma mark - block converted to a methdo to downloat the images in background
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
