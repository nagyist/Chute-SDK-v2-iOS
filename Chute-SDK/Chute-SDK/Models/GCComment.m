//
//  GCComent.m
//  Chute-SDK
//
//  Created by Aleksandar Trpeski on 4/22/13.
//  Copyright (c) 2013 Aleksandar Trpeski. All rights reserved.
//

#import "GCComment.h"
#import "GCServiceComment.h"

@implementation GCComment

@synthesize id, links, createdAt, updatedAt, commentText, name, email;

- (void)deleteCommentForAssetWithID:(NSNumber *)assetID inAlbumWithID:(NSNumber *)albumID success:(void(^)(GCResponseStatus *responseStatus, GCComment *comment))success failure:(void(^)(NSError *error))failure
{
    [GCServiceComment deleteCommentWithID:self.id forAssetWithID:assetID inAlbumWithID:albumID success:^(GCResponseStatus *responseStatus, GCComment *comment) {
        success(responseStatus,comment);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

@end
