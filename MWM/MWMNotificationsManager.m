/*****************************************************************************
 *  Copyright (c) 2011 Meta Watch Ltd.                                       *
 *  www.MetaWatch.org                                                        *
 *                                                                           *
 =============================================================================
 *                                                                           *
 *  Licensed under the Apache License, Version 2.0 (the "License");          *
 *  you may not use this file except in compliance with the License.         *
 *  You may obtain a copy of the License at                                  *
 *                                                                           *
 *    http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                           *
 *  Unless required by applicable law or agreed to in writing, software      *
 *  distributed under the License is distributed on an "AS IS" BASIS,        *
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
 *  See the License for the specific language governing permissions and      *
 *  limitations under the License.                                           *
 *                                                                           *
 *****************************************************************************/

//
//  MWMNotificationsManager.m
//  MWM
//
//  Created by Siqi Hao on 6/6/12.
//  Copyright (c) 2012 Meta Watch. All rights reserved.
//

#import "MWMNotificationsManager.h"

#import "MWManager.h"
#import "AppDelegate.h"

@implementation MWMNotificationsManager

static MWMNotificationsManager *sharedManager;

#pragma mark - Notifications Enalbers

- (void) setNotificationsEnabled:(BOOL)enable {
    if (enable) {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [self setCalendarAlertEnabled:[[prefs objectForKey:@"notifCalendar"] boolValue]];
    } else {
        [self setCalendarAlertEnabled:NO];
    }
    
}

- (void) setCalendarAlertEnabled:(BOOL)enable {
    if (enable) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storeChanged:)
                                                     name:EKEventStoreChangedNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:EKEventStoreChangedNotification object:nil];
    }
}

- (void) storeChanged:(id)sender {
    NSLog(@"NotificationManager detected calendar changes.");
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    NSDate *startDate = [NSDate date];
    NSDate *endDate   = [NSDate distantFuture];
    NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:startDate
                                                                 endDate:endDate
                                                               calendars:nil];
    
    NSArray *newEventsArray = [[eventStore eventsMatchingPredicate:predicate] sortedArrayUsingSelector:@selector(compareStartDateWithEvent:)];
    if (newEventsArray.count > 0) {
        EKEvent *nextEvent = [newEventsArray objectAtIndex:0];
        NSString *textToDisplay = [NSString stringWithFormat:@"%@", nextEvent.title];
        [NSTimer scheduledTimerWithTimeInterval:[nextEvent.startDate timeIntervalSinceDate:[NSDate date]] target:self selector:@selector(internalUpdate:) userInfo:textToDisplay repeats:NO];
    }
}

- (void) internalUpdate:(NSTimer*)timer {
    UIImage *imageToSend = [AppDelegate imageForText:timer.userInfo];
    
    [[MWManager sharedManager] writeImage:[AppDelegate imageDataForCGImage:imageToSend.CGImage] forMode:kMODE_NOTIFICATION inRect:CGRectMake(0, (96 - imageToSend.size.height)*0.5, imageToSend.size.width, imageToSend.size.height) linesPerMessage:LINESPERMESSAGE shouldLoadTemplate:YES buzzWhenDone:YES];
}

#pragma mark - Singleton

+ (MWMNotificationsManager *) sharedManager {
    if (sharedManager == nil) {
        sharedManager = [[super allocWithZone:NULL] init];
    }
    return sharedManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if ([prefs objectForKey:@"notifCalendar"] == nil) {
            [prefs setValue:[NSNumber numberWithBool:YES] forKeyPath:@"notifCalendar"];
            [prefs synchronize];
        }

    }
    
    return self;
}

@end
