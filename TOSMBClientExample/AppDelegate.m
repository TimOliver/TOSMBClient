//
//  AppDelegate.m
//  TOSMBClientExample
//
//  Created by Tim Oliver on 7/27/15.
//  Copyright (c) 2015 TimOliver. All rights reserved.
//

#import "AppDelegate.h"

#import "TOSMBSession.h"
#import "TONetBIOSNameService.h"
#import "TONetBIOSNameServiceEntry.h"

@interface AppDelegate ()

@property (nonatomic, strong) TONetBIOSNameService *nameService;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    /*self.nameService = [[TONetBIOSNameService alloc] init];
    
    id addedEvent = ^(TONetBIOSNameServiceEntry *entry) {
        NSLog(@"Found entry '%@/%@'", entry.group, entry.name);
    };

    id removedEvent = ^(TONetBIOSNameServiceEntry *entry) {
        NSLog(@"Removed entry '%@/%@'", entry.group, entry.name);
    };
    
    [self.nameService startDiscoveryWithTimeOut:4.0f added:addedEvent removed:removedEvent];*/
    
    /*TOSMBSession *session = [TOSMBSession new];
    [session connect];*/
    
    TOSMBSession *session = [[TOSMBSession alloc] initWithHostName:@"TITANNAS" ipAddress:@"192.168.1.3"];
    NSArray *shares = [session requestContentsOfDirectoryAtFilePath:@"/" error:nil];
    NSLog(@"%@", shares);
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self.nameService stopDiscovery];
}

@end
