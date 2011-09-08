//
//  GCAsset.h
//
//  Created by Brandon Coston on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GCResource.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface GCAsset : GCResource {
    
}

- (NSString*)urlStringForImageWithWidth:(NSUInteger)width andHeight:(NSUInteger)height;

- (UIImage *)imageForWidth:(NSUInteger)width andHeight:(NSUInteger)height;

- (void)imageForWidth:(NSUInteger)width 
            andHeight:(NSUInteger)height 
inBackgroundWithCompletion:(void (^)(UIImage *))aResponseBlock;

@end
