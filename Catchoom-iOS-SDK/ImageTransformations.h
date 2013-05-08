//
// © Catchoom Technologies S.L.
// Licensed under the MIT license.
// http://github.com/Catchoom/ios-crc/blob/master/LICENSE
//  All warranties and liabilities are disclaimed.
//
//  ImageTransformations.h
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageTransformations : NSObject

+ (UIImage *)convertToGrayScale:(UIImage*)source;
+ (UIImage *)scaleImage:(UIImage *)image withFactor:(double)factor;
+ (UIImage *)scaleImage:(UIImage *)image shortestSide:(GLuint)iPixels;

@end
