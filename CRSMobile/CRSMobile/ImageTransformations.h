//
//© Catchoom Technologies S.L.
//Licensed under the MIT license.
//https://raw.github.com/catchoom/ios-crc/LICENSE
//
//  ImageTransformations.h
//
//  Created by David Marimon Sanjuan on 10/2/12.
//  Copyright (c) 2012 Catchoom Advertising Network S.L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageTransformations : NSObject

+ (UIImage *)convertToGrayScale:(UIImage*)source;
+ (UIImage *)scaleImage:(UIImage *)image withFactor:(double)factor;
+ (UIImage *)scaleImage:(UIImage *)image shortestSide:(GLuint)iPixels;

@end
