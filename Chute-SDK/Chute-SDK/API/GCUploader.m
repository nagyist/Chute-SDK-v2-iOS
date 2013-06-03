//
//  GCUploader.m
//  Chute-SDK
//
//  Created by Aleksandar Trpeski on 5/7/13.
//  Copyright (c) 2013 Aleksandar Trpeski. All rights reserved.
//

#import "GCUploader.h"
#import "GCClient.h"
#import "GCResponseStatus.h"
#import "GCFile.h"
#import "GCUploads.h"
#import "GCResponse.h"
#import "AFJSONRequestOperation.h"
#import "GCUploadingAsset.h"
#import "GCUploadInfo.h"
#import "AFHTTPRequestOperation.h"

static NSString * const kGCFiles = @"files";
static NSString * const kGCAlbums = @"albums";
static NSString * const kGCData = @"data";
static NSString * const kGCAuthorization = @"Authorization";
static NSString * const kGCDate = @"Date";
static NSString * const kGCContentType = @"Content-Type";
static int const kGCUploaderMaxConcurrentOperationCount = 3;

static NSString * const kGCBaseURLString = @"https://upload.getchute.com/";
static dispatch_queue_t serialQueue;

@implementation GCUploader

@synthesize assetsUploadedCount, assetsTotalCount, maxFileSize;

+ (GCUploader *)sharedUploader {
    static GCUploader *_sharedUploader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        serialQueue = dispatch_queue_create("com.getchute.gcuploader.serialqueue", NULL);
        _sharedUploader = [[GCUploader alloc] initWithBaseURL:[NSURL URLWithString:kGCBaseURLString]];
    });
    
    [_sharedUploader setParameterEncoding:AFJSONParameterEncoding];
    
    return _sharedUploader;
}

- (id)initWithBaseURL:(NSURL *)url {
    
    /*
     NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kGCClient];
     GCClient *client = [NSKeyedUnarchiver unarchiveObjectWithData:data];
     
     if (client) {
     self = client;
     return self;
     }
     */
    
    self = [super initWithBaseURL:url];
    
    if (!self) {
        return nil;
    }
    
    //    [self setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
    //        if (status == AFNetworkReachabilityStatusNotReachable) {
    //            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"No Internet connection detected." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //            [alertView show];
    //        }
    //    }];
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    //	[self setDefaultHeader:@"Accept" value:@"application/json"];
    [self.operationQueue setMaxConcurrentOperationCount:kGCUploaderMaxConcurrentOperationCount];
    
    return self;
}

+ (NSString *)generateTimestamp
{
    //var timestamp =  ("" + (d.getTime()-d.getMilliseconds())/1000 + "-" + Math.random()).replace("0.", "")
    
    NSDate *date = [NSDate date];
    NSNumber *epochTime = @(floor([date timeIntervalSince1970]));
    NSString *timestamp = [NSString stringWithFormat:@"%@-%u%u", epochTime, arc4random(), arc4random()];
    return [timestamp substringToIndex:28];
}

- (void)uploadFiles:(NSArray *)files success:(void (^) (NSArray *files))success failure:(void (^)(NSError *error))failure
{
    [self requestFilesForUpload:files inAlbumsWithIDs:nil success:^(GCUploads *uploads) {
        [self uploadData:uploads success:^(NSString *uploadID) {
            [self completeUpload:uploadID success:^(NSArray *files) {
                success(files);
            } failure:^(NSError *error) {
                failure(error);
            }];
        }];
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)uploadFiles:(NSArray *)files inAlbumsWithIDs:(NSArray *)albumIDs success:(void (^) (NSArray *files))success failure:(void (^)(NSError *error))failure
{
    [self requestFilesForUpload:files inAlbumsWithIDs:albumIDs success:^(GCUploads *uploads) {
        [self uploadData:uploads success:^(NSString *uploadID) {
            [self completeUpload:uploadID success:^(NSArray *files) {
                success(files);
            } failure:^(NSError *error) {
                failure(error);
            }];
        }];
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)requestFilesForUpload:(NSArray *)files inAlbumsWithIDs:(NSArray *)albumIDs success:(void (^)(GCUploads *uploads))success failure:(void (^)(NSError *error))failure
{
    GCClient *apiClient = [GCClient sharedClient];
    
    __block NSMutableArray *fileDictionaries = [[NSMutableArray alloc] initWithCapacity:[files count]];
    
    [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        GCFile *file = (GCFile *)obj;
        [fileDictionaries addObject:[file serialize]];
    }];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{kGCFiles:fileDictionaries}];
    if (albumIDs)
        [params setObject:albumIDs forKey:kGCAlbums];
    
    NSMutableURLRequest *request = [apiClient requestWithMethod:kGCClientPOST path:@"uploads" parameters:params];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        GCUploads *uploads = [GCUploads uploadsFromDictionary:[JSON objectForKey:kGCData]];
        success(uploads);
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"<KXLog> Failure: %@", JSON);
        
        failure(error);
        
    }];
    [apiClient enqueueHTTPRequestOperation:operation];
}

- (void)uploadData:(GCUploads *)uploads success:(void (^)(NSString *uploadID))success
{
    __block NSMutableArray *operations = [NSMutableArray new];
    [uploads.assets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        GCUploadingAsset *asset = obj;
        NSMutableURLRequest *request = [self multipartFormRequestWithMethod:kGCClientPUT path:asset.uploadInfo.uploadUrl parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            NSString *name = asset.caption ? asset.caption : @"";
#warning TODO: implement in-memory upload functionality
            // If the image is already in an instance variable
            //            [formData appendPartWithFileData:UIImageJPEGRepresentation(image1, 0.7) name:@"image1" fileName:@"image1.jpg" mimeType:@"image/jpeg"];
            
            // If the image is on disk
            [formData appendPartWithFileURL:[NSURL fileURLWithPath:asset.uploadInfo.filePath] name:name error:nil];
        }];
        [request setValue:asset.uploadInfo.signature forHTTPHeaderField:kGCAuthorization];
        [request setValue:asset.uploadInfo.date forHTTPHeaderField:kGCDate];
        [request setValue:asset.uploadInfo.contentType forHTTPHeaderField:kGCContentType];
        [request setValue:@"public-read" forHTTPHeaderField:@"x-amz-acl"];
        
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
            CGFloat progress = ((CGFloat)totalBytesWritten) / totalBytesExpectedToWrite;
            [asset setUploadProgress:@(progress)];
            NSLog(@"<KXLog> %@ progress: %f", asset.url, progress);
        }];
        
        [operations addObject:operation];
    }];
    [self enqueueBatchOfHTTPRequestOperations:operations progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
        
        NSLog(@"<KXLog> %d out of %d is uploaded", numberOfCompletedOperations, totalNumberOfOperations);
    } completionBlock:^(NSArray *operations) {
        NSLog(@"<KXLog> All data is uploaded");
        success(uploads.id);
    }];
    
}

- (void)completeUpload:(NSString *)uploadID success:(void (^) (NSArray *files))success failure:(void (^) (NSError *error))failure
{
    GCClient *apiClient = [GCClient sharedClient];
    NSString *path = [NSString stringWithFormat:@"uploads/%@/complete", uploadID];
    NSMutableURLRequest *request = [apiClient requestWithMethod:kGCClientPOST path:path parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"success: %@", JSON);
        success(@[@"lala"]);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"failure: %@", error);
        failure(error);
    }];
    [apiClient enqueueHTTPRequestOperation:operation];
}

@end
