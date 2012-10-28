//
// © Catchoom Technologies S.L.
// Licensed under the MIT license.
// http://github.com/Catchoom/ios-crc/blob/master/LICENSE
//  All warranties and liabilities are disclaimed.
//
//  ImageTransformations.m
//

#import "ImageTransformations.h"

@implementation ImageTransformations

+ (UIImage *)convertToGrayScale:(UIImage*)source {
	
	CGSize size = source.size;
	CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();
	CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, gray, kCGImageAlphaNone);
	
	/*  modified code */     
	CGContextScaleCTM(context, 1, -1);
	CGContextTranslateCTM(context, 0, -size.height);
	/* end modified code */
	
	CGColorSpaceRelease(gray);
	UIGraphicsPushContext(context);
	[source drawAtPoint:CGPointZero blendMode:kCGBlendModeCopy alpha:1.0];
	UIGraphicsPopContext();
	
	CGImageRef img = CGBitmapContextCreateImage(context);
	
	CGContextRelease(context);
	UIImage *newImage = [UIImage imageWithCGImage:img];
	
	CGImageRelease(img);
	
	return newImage;
	
}

+ (UIImage *)scaleImage:(UIImage *)image withFactor:(double)factor{ 
	
	CGSize size = image.size;
	
	CGRect rect = CGRectMake(0.0, 0.0, factor * size.width, factor * size.height);
	
	UIGraphicsBeginImageContext(rect.size);  
	[image drawInRect:rect];  
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();  
	UIGraphicsEndImageContext();  
	
	return newImage;  
}

+ (UIImage *)scaleImage:(UIImage *)image shortestSide:(GLuint)uiPixels
{
	
	CGSize size = image.size;
    
    GLuint uMinSide = MIN(size.height, size.width);
    
    float fScaleFactor = (float)uiPixels / (float)uMinSide;
	
	CGRect rect = CGRectMake(0.0, 0.0, fScaleFactor * size.width, fScaleFactor * size.height);
	
	UIGraphicsBeginImageContext(rect.size);  
	[image drawInRect:rect];  
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();  
	UIGraphicsEndImageContext();  
	
	return newImage;  
}
@end
