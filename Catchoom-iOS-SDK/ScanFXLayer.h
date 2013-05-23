//
//  ScanFXLayer.h
//  Catchoom-iOS-SDK
//
//  Created by David Marimon Sanjuan on 12/5/13.
//  Copyright (c) 2013 Catchoom. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

@interface ScanFXLayer : CALayer
{
    CALayer* _left2RightLayer;
    CALayer* _bottom2TopLayer;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
}

- (id) initWithBounds:(CGRect)bounds withSession:(AVCaptureSession*)avCaptureSession;
- (void) remove;
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef) ctx;
@end
