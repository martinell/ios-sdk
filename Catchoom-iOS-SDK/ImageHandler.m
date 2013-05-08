//
// © Catchoom Technologies S.L.
// Licensed under the MIT license.
// http://github.com/Catchoom/ios-crc/blob/master/LICENSE
//  All warranties and liabilities are disclaimed.
//
//  ImageHandler.m
//  

#import "ImageHandler.h"
#import "ImageTransformations.h"

@implementation ImageHandler

+ (NSData *)prepareNSDataFromUIImage: (UIImage*)image
{
    //UIImage *imageGRAY = [ImageTransformations convertToGrayScale: image];
    
    //UIImage *imgGrayScaled = [ImageTransformations scaleImage:imageGRAY shortestSide:300];
    UIImage *imgScaled = [ImageTransformations scaleImage:image shortestSide:300];
    return UIImageJPEGRepresentation( imgScaled , 0.75 );
}


@end
