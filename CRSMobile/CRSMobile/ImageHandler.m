//
//© Catchoom Technologies S.L.
//Licensed under the MIT license.
//https://raw.github.com/catchoom/ios-crc/LICENSE
//
//  ImageHandler.m
//  ImageHandler
//
//  Created by David Marimon Sanjuan on 1/6/12.
//  Copyright (c) 2012 Catchoom Advertising Network S.L. All rights reserved.
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
