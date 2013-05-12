//
//  ScanFXLayer.h
//  Catchoom-iOS-SDK
//
//  Created by David Marimon Sanjuan on 12/5/13.
//  Copyright (c) 2013 Catchoom. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface ScanFXLayer : CALayer
{
    CALayer* _left2RightLayer;
    CALayer* _bottom2TopLayer;
}

- (id) initWithBounds:(CGRect)bounds;
- (void) remove;
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef) ctx;
@end
