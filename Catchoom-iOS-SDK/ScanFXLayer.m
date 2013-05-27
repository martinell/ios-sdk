//
//  ScanFXLayer.m
//  Catchoom-iOS-SDK
//
//  Created by David Marimon Sanjuan on 12/5/13.
//  Copyright (c) 2013 Catchoom. All rights reserved.
//

#import "ScanFXLayer.h"

@implementation ScanFXLayer

- (id) initWithViewController:(UIViewController*)rootViewController withSession:(AVCaptureSession*)avCaptureSession
{
    self = [super init];
    if (self) {
        
        if (rootViewController == nil || avCaptureSession == nil) {
            return nil;
        }

        UIView* rootView = rootViewController.view;
        CALayer *rootLayer = rootView.layer;
        [rootLayer setMasksToBounds:YES];
        CGRect bounds = rootLayer.bounds;
        
        [self setFrame:bounds];
        
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:avCaptureSession];
        [_captureVideoPreviewLayer setVideoGravity : AVLayerVideoGravityResizeAspect];
        [_captureVideoPreviewLayer setBackgroundColor : [[UIColor blackColor] CGColor]];
        
        [_captureVideoPreviewLayer setFrame:[self bounds]];

        /*
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [_captureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationLandscapeRight];
        }*/
        
        switch ([rootViewController interfaceOrientation]) {
            case UIInterfaceOrientationPortrait:
                [_captureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationPortrait];
                break;
            case UIInterfaceOrientationLandscapeRight:
                [_captureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationLandscapeRight];
                break;
            case UIInterfaceOrientationLandscapeLeft:
                [_captureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationLandscapeLeft];
                break;
            default:
                [_captureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationPortrait];
                break;
        }

        
        [self addSublayer:_captureVideoPreviewLayer];
     
        
        // Animation Left to Right
        _left2RightLayer = [CALayer layer];
        [_left2RightLayer setFrame:self.bounds];
        [_left2RightLayer setDelegate:self];
        [_left2RightLayer setNeedsDisplay];
        
        
        // Animation Bottom to Top
        _bottom2TopLayer = [CALayer layer];
        [_bottom2TopLayer setFrame:self.bounds];
        [_bottom2TopLayer setDelegate:self];
        [_bottom2TopLayer setNeedsDisplay];
        
        [rootLayer addSublayer:self];
        
    }
    return self;
    
}

- (void)startAnimations
{

    
    CAKeyframeAnimation *animationLeft2Right = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    [animationLeft2Right setDuration:2.0];
    [animationLeft2Right setRepeatCount:INT_MAX];
    
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSNumber numberWithInt:self.bounds.origin.x]];
    [values addObject:[NSNumber numberWithInt:self.bounds.origin.x + self.bounds.size.width]];
    [values addObject:[NSNumber numberWithInt:self.bounds.origin.x]];
    [animationLeft2Right setValues:values];
    
    [_left2RightLayer addAnimation:animationLeft2Right forKey:nil];
    
    //[self addSublayer:_left2RightLayer];
    
    CAKeyframeAnimation *animationBottom2Top = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    [animationBottom2Top setDuration:2.0];
    [animationBottom2Top setRepeatCount:INT_MAX];
    
    [values removeAllObjects];
    [values addObject:[NSNumber numberWithInt:self.bounds.origin.y]];
    [values addObject:[NSNumber numberWithInt:self.bounds.origin.y + self.bounds.size.height]];
    [values addObject:[NSNumber numberWithInt:self.bounds.origin.y]];
    [animationBottom2Top setValues:values];
    
    [_bottom2TopLayer addAnimation:animationBottom2Top forKey:nil];
    
    [self addSublayer:_bottom2TopLayer];
}

- (void)remove
{
    if (_captureVideoPreviewLayer != nil) {
        [_captureVideoPreviewLayer removeFromSuperlayer];
        _captureVideoPreviewLayer = nil;
    }
    
    if (_left2RightLayer != nil) {
        [_left2RightLayer removeFromSuperlayer];
        _left2RightLayer = nil;
    }
    
    if (_bottom2TopLayer != nil) {
        [_bottom2TopLayer removeFromSuperlayer];
        _bottom2TopLayer = nil;
    }
    
    [self removeFromSuperlayer];
}

- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef) ctx
{
    if (layer == _left2RightLayer) {
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
        myEndPoint.x = 20.0;
        myEndPoint.y = 0.0;
        CGContextDrawLinearGradient (ctx, myGradient, myStartPoint, myEndPoint, 0);
        
        CGContextSaveGState(ctx);
        CGContextAddRect(ctx, CGRectMake(layerBounds.origin.x, layerBounds.origin.y, 1, layerBounds.size.height));
        CGContextClip(ctx);
        CGContextRestoreGState(ctx);
        
    }
    else if (layer == _bottom2TopLayer) {
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
        myEndPoint.y = 20.0;
        CGContextDrawLinearGradient (ctx, myGradient, myStartPoint, myEndPoint, 0);
        
        CGContextSaveGState(ctx);
        CGContextAddRect(ctx, CGRectMake(layerBounds.origin.x, layerBounds.origin.y, layerBounds.size.width, 1));
        CGContextClip(ctx);
        CGContextRestoreGState(ctx);
    }
    
}
@end
