//
//  AppDelegate.m
//  TOSMBClientExample
//
//  Created by Tim Oliver on 7/27/15.
//  Copyright (c) 2015 TimOliver. All rights reserved.
//

#import "AppDelegate.h"

#import "TONetBIOSNameService.h"
#import "TONetBIOSNameServiceEntry.h"

@interface AppDelegate ()

@property (nonatomic, strong) TONetBIOSNameService *nameService;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.nameService = [[TONetBIOSNameService alloc] init];
    NSString *name = [self.nameService lookupNetworkNameForIPAddress:@"192.168.1.3"];
    NSLog(@"NAME IS %@", name);
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self.nameService stopDiscovery];
}

@end
