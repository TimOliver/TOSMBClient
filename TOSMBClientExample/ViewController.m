//
//  ViewController.m
//  TOSMBClientExample
//
//  Created by Tim Oliver on 7/27/15.
//  Copyright (c) 2015 TimOliver. All rights reserved.
//

#include <arpa/inet.h>

#import "ViewController.h"
#import "TOSMBSession.h"

@interface ViewController () <NSNetServiceBrowserDelegate>

@property (nonatomic, strong) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, strong) NSMutableArray *nameServiceEntries;

- (void)beginServiceBrowser;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.nameServiceEntries == nil) {
        self.nameServiceEntries = [NSMutableArray array];
    }
    
    [self beginServiceBrowser];
}

- (void)beginServiceBrowser
{
    if (self.serviceBrowser)
        return;
    
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    self.serviceBrowser.includesPeerToPeer = YES;
    self.serviceBrowser.delegate = self;
    
    [self.serviceBrowser searchForServicesOfType:@"_smb._tcp." inDomain:@"local"];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    [self.nameServiceEntries addObject:service];
    [service resolveWithTimeout:5.0f]; //Just start resolving now. But normally, you should be a bit more careful with this
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.nameServiceEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellName = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellName];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = [self.nameServiceEntries[indexPath.row] name];
    
    return cell;
}

- (void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSNetService *service = self.nameServiceEntries[indexPath.row];
    NSLog(@"Name: %@ Hostname: %@ Address: %@", service.name, service.hostName, service.addresses);
    if (service.addresses.count == 0)
        return;
    
    //resolve the ip address
    struct sockaddr_in  *socketAddress = nil;
    NSString            *ipString = nil;
    
    socketAddress = (struct sockaddr_in *)[service.addresses[0] bytes];
    ipString = [NSString stringWithFormat: @"%s", inet_ntoa(socketAddress->sin_addr)];  ///problem here

    TOSMBSession *session = [[TOSMBSession alloc] initWithHostName:service.hostName ipAddress:ipString];
    NSArray *directories = [session requestContentsOfDirectoryAtFilePath:@"/" error:nil];
    
    NSLog(@"%@", directories);
}

@end
