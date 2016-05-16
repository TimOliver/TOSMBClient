//
// TONetBIOSNameService.m
// Copyright 2015-2016 Timothy Oliver
//
// This file is dual-licensed under both the MIT License, and the LGPL v2.1 License.
//
// -------------------------------------------------------------------------------
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
// -------------------------------------------------------------------------------

#import <arpa/inet.h>

#import "TOSMBConstants.h"
#import "TONetBIOSNameService.h"
#import "TONetBIOSNameServiceEntry.h"

#import "netbios_ns.h"
#import "netbios_defs.h"

const NSTimeInterval kTONetBIOSNameServiceDiscoveryTimeOut = 4.0f;

#pragma mark - Class Private Interface -
@interface TONetBIOSNameService ()

@property (nonatomic, assign) netbios_ns *nameService;
@property (nonatomic, assign, readwrite) BOOL discovering;

/* Internal copies of the blocks that are executed during name discovery */
@property (nonatomic, copy) TONetBIOSNameServiceDiscoveryEvent discoveryAddedEvent;
@property (nonatomic, copy) TONetBIOSNameServiceDiscoveryEvent discoveryRemovedEvent;

/* Operation queue for asynchronously resolving hosts */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

/* Lazy load the operation queue when and if we need it. */
- (void)setupOperationQueue;

@end

// -------------------------------------------------------------------------------

#pragma mark - NetBIOS Name Service Discovery Callback Functions -
static void on_entry_added(void *p_opaque, netbios_ns_entry *entry)
{
    @autoreleasepool {
        __weak TONetBIOSNameService *funcSelf = (__bridge TONetBIOSNameService *)(p_opaque);
        if (funcSelf.discoveryAddedEvent == nil) {
            return;
        }
        
        TONetBIOSNameServiceEntry *entryObject = [TONetBIOSNameServiceEntry entryWithCEntry:entry];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([funcSelf respondsToSelector:@selector(discoveryAddedEvent)] && funcSelf.discoveryAddedEvent) {
                funcSelf.discoveryAddedEvent(entryObject);
            }
        });
    }
}

static void on_entry_removed(void *p_opaque, netbios_ns_entry *entry)
{
    @autoreleasepool {
        __weak TONetBIOSNameService *funcSelf = (__bridge TONetBIOSNameService *)(p_opaque);
        if (funcSelf.discoveryRemovedEvent == nil) {
            return;
        }
        
        TONetBIOSNameServiceEntry *entryObject = [TONetBIOSNameServiceEntry entryWithCEntry:entry];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([funcSelf respondsToSelector:@selector(discoveryRemovedEvent)] && funcSelf.discoveryRemovedEvent) {
                funcSelf.discoveryRemovedEvent(entryObject);
            }
        });
    }
}

// -------------------------------------------------------------------------------

#pragma mark - Class Implementation -
@implementation TONetBIOSNameService

- (instancetype)init
{
    if (self = [super init]) {
        _nameService = netbios_ns_new();
        if (_nameService == NULL) {
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [self.operationQueue cancelAllOperations];
    netbios_ns_destroy(self.nameService);
}

#pragma mark - Device Name / IP Resolution -
- (NSString *)resolveIPAddressWithName:(NSString *)name type:(TONetBIOSNameServiceType)type
{
    if (name == nil)
        return nil;
    
    struct in_addr addr;
    int result = netbios_ns_resolve(self.nameService, [name cStringUsingEncoding:NSUTF8StringEncoding], TONetBIOSNameServiceCTypeForType(type), &addr.s_addr);
    if (result < 0)
        return nil;
    
    char *ipAddress = inet_ntoa(addr);
    if (ipAddress == NULL) {
        return nil;
    }
    
    return [NSString stringWithCString:ipAddress encoding:NSUTF8StringEncoding];
}

- (void)resolveIPAddressWithName:(NSString *)name type:(TONetBIOSNameServiceType)type
                         success:(void (^)(NSString *ipAddress))success
                         failure:(void (^)(void))failure
{
    if (name == nil) {
        if (failure)
            failure();
        
        return;
    }
    
    NSBlockOperation *blockOperation = [[NSBlockOperation alloc] init];
    
    __weak typeof (self) weakSelf = self;
    __weak NSBlockOperation *weakOperation = blockOperation;
    id executionBlock = ^{
        //Make sure the queue wasn't cancelled before it even started
        if (weakOperation.isCancelled)
            return;
        
        NSString *ipAddress = [weakSelf resolveIPAddressWithName:name type:type];
        
        //Ensure the queue wasn't cancelled while the lookup was occurring
        if (weakOperation.isCancelled)
            return;
        
        if (ipAddress == nil) {
            if (failure) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{ failure(); }];
            }
            
            return;
        }
        
        if (success) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{ success(ipAddress); }];
        }
    };
    
    [blockOperation addExecutionBlock:executionBlock];
    
    [self setupOperationQueue];
    [self.operationQueue addOperation:blockOperation];
}

- (NSString *)lookupNetworkNameForIPAddress:(NSString *)address
{
    if (address == nil)
        return nil;
    
    struct in_addr  addr;
    inet_aton([address cStringUsingEncoding:NSASCIIStringEncoding], &addr);
    char *addressString = (char *)netbios_ns_inverse(self.nameService, addr.s_addr);
    if (addressString == NULL) {
        return nil;
    }
    
    return [NSString stringWithCString:addressString encoding:NSUTF8StringEncoding];
}

- (void)lookupNetworkNameForIPAddress:(NSString *)address success:(void (^)(NSString *))success failure:(void (^)(void))failure
{
    if (address == nil) {
        if (failure)
            failure();
        
        return;
    }
    
    NSBlockOperation *blockOperation = [[NSBlockOperation alloc] init];
    
    __weak typeof (self) weakSelf = self;
    __weak NSBlockOperation *weakOperation = blockOperation;
    id executionBlock = ^{
        //Make sure the queue wasn't cancelled before it even started
        if (weakOperation.isCancelled)
            return;
        
        NSString *name = [weakSelf lookupNetworkNameForIPAddress:address];
        
        //Ensure the queue wasn't cancelled while the lookup was occurring
        if (weakOperation.isCancelled)
            return;
        
        //Followup if the lookup failed and a failure block was supplied
        if (name == nil) {
            if (failure) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{ failure(); }];
            }
            
            return;
        }
        
        if (success) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{ success(name); }];
        }
    };
    [blockOperation addExecutionBlock:executionBlock];
    
    [self setupOperationQueue];
    [self.operationQueue addOperation:blockOperation];
}

#pragma mark - Operation Queue Management -
- (void)setupOperationQueue
{
    if (self.operationQueue)
        return;
    
    self.operationQueue = [[NSOperationQueue alloc] init];
}

#pragma mark - Network Device Name Discovery -
- (BOOL)startDiscoveryWithTimeOut:(NSTimeInterval)timeout
                            added:(TONetBIOSNameServiceDiscoveryEvent)addedHandler
                          removed:(TONetBIOSNameServiceDiscoveryEvent)removedHandler
{
    if (self.discovering) {
        [self stopDiscovery];
    }
    
    if (timeout <= FLT_EPSILON) {
        timeout = kTONetBIOSNameServiceDiscoveryTimeOut;
    }
    
    netbios_ns_discover_callbacks callbacks;
    callbacks.p_opaque = (__bridge void *)(self);
    callbacks.pf_on_entry_added = on_entry_added;
    callbacks.pf_on_entry_removed = on_entry_removed;
    
    self.discovering = YES;
    self.discoveryAddedEvent = addedHandler;
    self.discoveryRemovedEvent = removedHandler;
    
    return netbios_ns_discover_start(self.nameService, (unsigned int)timeout, &callbacks);
}

- (BOOL)stopDiscovery
{
    self.discovering = NO;
    self.discoveryAddedEvent = nil;
    self.discoveryRemovedEvent = nil;
    
    return netbios_ns_discover_stop(self.nameService);
}

@end
