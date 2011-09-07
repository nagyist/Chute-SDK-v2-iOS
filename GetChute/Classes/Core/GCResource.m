//
//  ChuteResource.m
//
//  Created by Achal Aggarwal on 26/08/11.
//  Copyright 2011 NA. All rights reserved.
//

#import "GCResource.h"
#import "GCResponse.h"

@interface GCResource()

+ (NSString *)elementName;
- (id) initWithDictionary:(NSDictionary *) dictionary;

@end

@implementation GCResource

#pragma mark - All 
/* Get all Objects of this class */
+ (GCResponse *)all {
    NSString *_path                 = [[NSString alloc] initWithFormat:@"%@/me/%@", API_URL, [self elementName]];
    GCRequest *gcRequest                  = [[GCRequest alloc] init];
    GCResponse *_response     = [[gcRequest getRequestWithPath:_path] retain];
    
    NSMutableArray *_result = [[NSMutableArray alloc] init];
    for (NSDictionary *_dic in [_response object]) {
        id _obj = [self objectWithDictionary:_dic];
        [_result addObject:_obj];
    }
    [_response setData:_result];
    [_result release];
    [gcRequest release];
    [_path release];
    return [_response autorelease]; 
}

+ (void)allInBackgroundWithCompletion:(GCResponseBlock) aResponseBlock {      
    DO_IN_BACKGROUND([self all], aResponseBlock);
}

+ (GCResponse *)findById:(NSUInteger) objectID {
    NSString *_path     = [[NSString alloc] initWithFormat:@"%@%@/%d", API_URL, [self elementName], objectID];
    GCRequest *gcRequest      = [[GCRequest alloc] init];

    GCResponse *_response        = [[gcRequest getRequestWithPath:_path] retain];
    [_response setData:[self objectWithDictionary:[_response object]]];
    
    [gcRequest release];
    [_path release];
    return [_response autorelease];
}

+ (void)findById:(NSUInteger) objectID inBackgroundWithCompletion:(GCResponseBlock) aResponseBlock {
    DO_IN_BACKGROUND([self findById:objectID], aResponseBlock);
}

#pragma mark - Override these methods in every Subclass
+ (NSString *)elementName {
    //for example, this should return the string "chutes", "assets", "bundles", "parcels"
    NSAssert(0, @"Please override the elementName class method in your subclass");
    return nil;
}

+ (BOOL)supportsMetaData {
    return YES;
}

#pragma mark - Instance Methods
#pragma mark - Init

- (id) init {
    self = [super init];
    if (self) {
        _content = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (id) objectWithDictionary:(NSDictionary *) dictionary {
    return [[[self alloc] initWithDictionary:dictionary] autorelease];
}

- (id) initWithDictionary:(NSDictionary *) dictionary {
    [self init];
    for (NSString *key in [dictionary allKeys]) {
        [self setObject:[dictionary objectForKey:key] forKey:key];
    }
    return self;
}

- (void) dealloc {
    [_content release];
    [super dealloc];
}

- (void)setObject:(id) aObject forKey:(id)aKey {
    [_content setObject:aObject forKey:aKey];
}

- (id)objectForKey:(id)aKey {
    return [_content objectForKey:aKey];
}

#pragma mark - Proxy for JSONRepresentation
- (id)proxyForJson {
    return _content;
}

#pragma mark - Common Meta Data Methods

+ (GCResponse *) searchMetaDataForKey:(NSString *) key andValue:(NSString *) value {
    NSString *_path     = [[NSString alloc] initWithFormat:@"%@%@/meta/%@/%@", API_URL, [[self class] elementName], IS_NULL(key)?@"":key, IS_NULL(value)?@"":value];
    GCRequest *gcRequest                     = [[GCRequest alloc] init];
    GCResponse *_response        = [[gcRequest getRequestWithPath:_path] retain];
    
    NSMutableArray *_result = [[NSMutableArray alloc] init];
    for (NSDictionary *_dic in [[_response object] objectForKey:[self elementName]]) {
        id _obj = [self objectWithDictionary:_dic];
        [_result addObject:_obj];
    }
    [_response setData:_result];
    [_result release];
    [gcRequest release];
    [_path release];
    return [_response autorelease];
}

+ (void) searchMetaDataForKey:(NSString *) key andValue:(NSString *) value inBackgroundWithCompletion:(GCResponseBlock) aResponseBlock {
    DO_IN_BACKGROUND([self searchMetaDataForKey:key andValue:value], aResponseBlock);
}

- (GCResponse *) getMetaData {
    NSString *_path     = [[NSString alloc] initWithFormat:@"%@%@/%d/meta", API_URL, [[self class] elementName], [self objectID]];
    GCRequest *gcRequest                     = [[GCRequest alloc] init];
    GCResponse *_response        = [[gcRequest getRequestWithPath:_path] retain];
    [gcRequest release];
    [_path release];
    return [_response autorelease];
}

- (void) getMetaDataInBackgroundWithCompletion:(GCResponseBlock) aResponseBlock {
    DO_IN_BACKGROUND([self getMetaData], aResponseBlock);
}

- (GCResponse *) getMetaDataForKey:(NSString *) key {
    if ([self objectID] == 0) {
        return nil;
    }
    NSString *_path     = [[NSString alloc] initWithFormat:@"%@%@/%d/meta/%@", API_URL, [[self class] elementName], [self objectID], key];
    
    GCRequest *gcRequest                      = [[GCRequest alloc] init];
    GCResponse *_response         = [[gcRequest getRequestWithPath:_path] retain];
    [gcRequest release];
    [_path release];
    return [_response autorelease];
}

- (void) getMetaDataForKey:(NSString *) key inBackgroundWithCompletion:(GCResponseBlock) aResponseBlock {
    DO_IN_BACKGROUND([self getMetaDataForKey:key], aResponseBlock);
}

- (BOOL) setMetaData:(NSDictionary *) metaData {
    if ([self objectID] == 0) {
        return NO;
    }
    NSMutableDictionary *_params = [[NSMutableDictionary alloc] init];
    [_params setValue:[[metaData JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding] forKey:@"raw"];

    NSString *_path             = [[NSString alloc] initWithFormat:@"%@%@/%d/meta", API_URL, [[self class] elementName], [self objectID]];
    
    GCRequest *gcRequest              = [[GCRequest alloc] init];
    BOOL _response              = [[gcRequest postRequestWithPath:_path andParams:_params] isSuccessful];
    [gcRequest release];
    [_path release];
    [_params release];
    return _response;
}

- (void) setMetaData:(NSDictionary *) metaData inBackgroundWithCompletion:(GCBoolBlock) aBoolBlock {
    DO_IN_BACKGROUND_BOOL([self setMetaData:metaData], aBoolBlock);
}

- (BOOL) setMetaData:(NSString *) data forKey:(NSString *) key {
    if ([self objectID] == 0) {
        return NO;
    }
    NSMutableDictionary *_params = [[NSMutableDictionary alloc] init];
    [_params setValue:[data dataUsingEncoding:NSUTF8StringEncoding] forKey:@"raw"];
    
    NSString *_path             = [[NSString alloc] initWithFormat:@"%@%@/%d/meta/%@", API_URL, [[self class] elementName], [self objectID], key];
    
    GCRequest *gcRequest              = [[GCRequest alloc] init];
    BOOL _response              = [[gcRequest postRequestWithPath:_path andParams:_params] isSuccessful];
    [gcRequest release];
    [_path release];
    [_params release];
    return _response;
}

- (void) setMetaData:(NSString *) data forKey:(NSString *) key inBackgroundWithCompletion:(GCBoolBlock) aBoolBlock {
    DO_IN_BACKGROUND_BOOL([self setMetaData:data forKey:key], aBoolBlock);
}

- (BOOL) deleteMetaData {
    if ([self objectID] == 0) {
        return NO;
    }
    NSString *_path             = [[NSString alloc] initWithFormat:@"%@%@/%d/meta", API_URL, [[self class] elementName], [self objectID]];
    
    GCRequest *gcRequest              = [[GCRequest alloc] init];
    BOOL _response              = [[gcRequest deleteRequestWithPath:_path andParams:nil] isSuccessful];
    [gcRequest release];
    [_path release];
    return _response;
}

- (void) deleteMetaDataInBackgroundWithCompletion:(GCBoolBlock) aBoolBlock {
    DO_IN_BACKGROUND_BOOL([self deleteMetaData], aBoolBlock);
}

- (BOOL) deleteMetaDataForKey:(NSString *) key {
    if ([self objectID] == 0) {
        return NO;
    }
    NSString *_path             = [[NSString alloc] initWithFormat:@"%@%@/%d/meta/%@", API_URL, [[self class] elementName], [self objectID], key];
    
    GCRequest *gcRequest              = [[GCRequest alloc] init];
    BOOL _response              = [[gcRequest deleteRequestWithPath:_path andParams:nil] isSuccessful];
    [gcRequest release];
    [_path release];
    return _response;
}

- (void) deleteMetaDataForKey:(NSString *) key inBackgroundWithCompletion:(GCBoolBlock) aBoolBlock {
    DO_IN_BACKGROUND_BOOL([self deleteMetaDataForKey:key], aBoolBlock);
}

#pragma mark - Common Data Getters
- (NSUInteger) objectID {
    return [[_content objectForKey:@"id"] intValue];
}

- (NSDate *) updatedAt {
    if (IS_NULL([self objectForKey:@"updated_at"])) {
        return nil;
    }
    NSDateFormatter *_formatter = [[NSDateFormatter alloc] init];
    [_formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    NSDate *_date = [_formatter dateFromString:[self objectForKey:@"updated_at"]];
    [_formatter release];
    return _date;
}

- (NSDate *) createdAt {
    if (IS_NULL([self objectForKey:@"created_at"])) {
        return nil;
    }
    NSDateFormatter *_formatter = [[NSDateFormatter alloc] init];
    [_formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    NSDate *_date = [_formatter dateFromString:[self objectForKey:@"created_at"]];
    [_formatter release];
    return _date;
}

#pragma mark - Instance Method Calls
- (BOOL) save {
    NSString *_data = [[NSString alloc] initWithFormat:@"{ \"data\":%@ }", [self JSONRepresentation]];
    
    NSMutableDictionary *_params = [[NSMutableDictionary alloc] init];
    [_params setValue:[_data dataUsingEncoding:NSUTF8StringEncoding] forKey:@"raw"];
    
    [_data release];
    
    NSString *_path             = [[NSString alloc] initWithFormat:@"%@%@", API_URL, [[self class] elementName]];
    
    GCRequest *gcRequest              = [[GCRequest alloc] init];
    GCResponse *_response = [[gcRequest postRequestWithPath:_path andParams:_params] retain];
    BOOL _result                = [_response isSuccessful];
    
    //Update the current object with the new values
    for (NSString *key in [[_response object] allKeys]) {
        [self setObject:[[_response object] objectForKey:key] forKey:key];
    }
    
    [_response release];
    [gcRequest release];
    [_path release];
    [_params release];
    
    return _result;
}

- (void) saveInBackgroundWithCompletion:(GCBoolBlock) aBoolBlock {
    DO_IN_BACKGROUND_BOOL([self save], aBoolBlock);
}

- (BOOL) update {
    if ([self objectID] == 0) {
        return NO;
    }
    NSString *_data = [[NSString alloc] initWithFormat:@"{ \"data\":%@ }", [self JSONRepresentation]];
    
    NSMutableDictionary *_params = [[NSMutableDictionary alloc] init];
    [_params setValue:[_data dataUsingEncoding:NSUTF8StringEncoding] forKey:@"raw"];
    
    [_data release];
    
    NSString *_path             = [[NSString alloc] initWithFormat:@"%@%@/%d", API_URL, [[self class] elementName], [self objectID]];
    
    GCRequest *gcRequest              = [[GCRequest alloc] init];
    GCResponse *_response = [[gcRequest putRequestWithPath:_path andParams:_params] retain];
    BOOL _result                = [_response isSuccessful];
    
    //Update the current object with the new values
    for (NSString *key in [[_response object] allKeys]) {
        [self setObject:[[_response object] objectForKey:key] forKey:key];
    }
    
    [_response release];
    [gcRequest release];
    [_path release];
    [_params release];
    
    return _result;
}

- (void) updateInBackgroundWithCompletion:(GCBoolBlock) aBoolBlock {
    DO_IN_BACKGROUND_BOOL([self update], aBoolBlock);
}

- (BOOL) destroy {
    if ([self objectID] == 0) {
        return NO;
    }
    NSString *_path     = [[NSString alloc] initWithFormat:@"%@%@/%d", API_URL, [[self class] elementName], [self objectID]];
    
    GCRequest *gcRequest      = [[GCRequest alloc] init];
    BOOL _response      = [[gcRequest deleteRequestWithPath:_path andParams:nil] isSuccessful];
    
    if (_response) {
        [_content release], _content = nil;
        _content = [[NSMutableDictionary alloc] init];
    }
    
    [gcRequest release];
    [_path release];
    return _response;
}

- (void) destroyInBackgroundWithCompletion:(GCBoolBlock) aBoolBlock {
    DO_IN_BACKGROUND_BOOL([self destroy], aBoolBlock);
}

@end
