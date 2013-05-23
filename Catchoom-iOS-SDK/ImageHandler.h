//
// © Catchoom Technologies S.L.
// Licensed under the MIT license.
// http://github.com/Catchoom/ios-crc/blob/master/LICENSE
//  All warranties and liabilities are disclaimed.
//
//  ImageHandler.h
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ImageHandler : NSObject

/* 
 * /brief This function converts the input image to gray scale and rescales it so that the largest side has 300 pixels.
 * /return data pointer to the JPEG converted image compressed at 0.8 ratio.
 */
+ (NSData *)prepareNSDataFromUIImage: (UIImage*)image;

// Helper function to transform a buffer into a UIImage
+ (UIImage*) imageFromSampleBuffer: (CMSampleBufferRef) sampleBuffer;

// block helper to download a image from a URL (handy to create a lazy load).
void UIImageFromURL( NSURL * URL, void (^imageBlock)(UIImage * image), void (^errorBlock)(void));
@end
