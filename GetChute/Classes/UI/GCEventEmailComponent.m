//
//  GCEventEmail.m
//  ChuteSDKDevProject
//
//  Created by Brandon Coston on 9/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GCEventEmailComponent.h"

@implementation GCEventEmailComponent
@synthesize delegate;


+(MFMailComposeViewController*)MailViewControllerForEventNamed:(NSString*)eventName afterEventStartDate:(NSDate*)start beforeEventEndDate:(NSDate*)end withMessage:(NSString*)message andSubject:(NSString*)subject{
    if(!eventName)
        return NULL;
    EKEventStore *store = [[EKEventStore alloc] init];
    if(!start){
        CFGregorianDate gregorianStartDate;
        CFGregorianUnits startUnits = {0, 0, -30, 0, 0, 0};
        CFTimeZoneRef timeZone = CFTimeZoneCopySystem();
        gregorianStartDate = CFAbsoluteTimeGetGregorianDate(
                                                            CFAbsoluteTimeAddGregorianUnits(CFAbsoluteTimeGetCurrent(), timeZone, startUnits),
                                                            timeZone);
        gregorianStartDate.hour = 0;
        gregorianStartDate.minute = 0;
        gregorianStartDate.second = 0;
        start =
        [NSDate dateWithTimeIntervalSinceReferenceDate:CFGregorianDateGetAbsoluteTime(gregorianStartDate, timeZone)];
    }
    if(!end){
        CFGregorianDate gregorianEndDate;
        CFGregorianUnits endUnits = {0, 0, 30, 0, 0, 0};
        CFTimeZoneRef timeZone = CFTimeZoneCopySystem();
        gregorianEndDate = CFAbsoluteTimeGetGregorianDate(
                                                          CFAbsoluteTimeAddGregorianUnits(CFAbsoluteTimeGetCurrent(), timeZone, endUnits),
                                                          timeZone);
        gregorianEndDate.hour = 0;
        gregorianEndDate.minute = 0;
        gregorianEndDate.second = 0;
        end =
        [NSDate dateWithTimeIntervalSinceReferenceDate:CFGregorianDateGetAbsoluteTime(gregorianEndDate, timeZone)];
    }
    NSPredicate *predicate = [store predicateForEventsWithStartDate:start endDate:end calendars:nil];
    NSArray *array = [store eventsMatchingPredicate:predicate];
    EKEvent *foundEvent = NULL;
    for(EKEvent *event in array){
        if([event.title caseInsensitiveCompare:eventName] == NSOrderedSame){
            foundEvent = event;
        }
    }
    if(foundEvent){
        NSArray *attendees = foundEvent.attendees;
        NSMutableArray *emailAddresses = [NSMutableArray array];
        if(attendees){
            for(EKParticipant *attendant in attendees){
                NSString *email = [[attendant URL] absoluteString];
                NSRange range = [email rangeOfString:@"mailto:"];
                if(range.location != NSNotFound){
                    email = [email stringByReplacingOccurrencesOfString:@"mailto:" withString:@""];
                    NSString *emailReg = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
                    
                    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailReg]; 
                    
                    if (!(([emailTest evaluateWithObject:email] != YES) || [email isEqualToString:@""]))
                        [emailAddresses addObject:email];
                }
            }
        }
        MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
        [vc setToRecipients:emailAddresses];
        if(message)
            [vc setMessageBody:message isHTML:YES];
        if(subject)
            [vc setSubject:subject];
        return vc;
    }
    return NULL;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

@end
