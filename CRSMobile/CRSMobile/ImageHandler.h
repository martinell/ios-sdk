//
//© Catchoom Technologies S.L.
//Licensed under the MIT license.
//https://raw.github.com/catchoom/ios-crc/LICENSE
//
//  ImageHandler.h
//  ImageHandler
//
//  Created by David Marimon Sanjuan on 1/6/12.
//  Copyright (c) 2012 Catchoom Advertising Network S.L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ImageHandler : NSObject

/* 
 * /brief This function converts the input image to gray scale and rescales it so that the largest side has 300 pixels.
 * /return data pointer to the JPEG converted image compressed at 0.8 ratio.
 */
+ (NSData *)prepareNSDataFromUIImage: (UIImage*)image;

@end
