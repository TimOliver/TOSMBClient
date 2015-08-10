//
//  ViewController.m
//  TOSMBClientExample
//
//  Created by Tim Oliver on 7/27/15.
//  Copyright (c) 2015 TimOliver. All rights reserved.
//

#include <arpa/inet.h>

#import "TORootTableViewController.h"
#import "TOFilesTableViewController.h"
#import "TOSMBClient.h"

@interface TORootTableViewController () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic, assign) NSIndexPath *resolvingIndexPath;

@property (nonatomic, strong) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, strong) NSMutableArray *nameServiceEntries;

- (void)beginServiceBrowser;

@end

@implementation TORootTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"SMB Devices";
    
    if (self.nameServiceEntries == nil) {
        self.nameServiceEntries = [NSMutableArray array];
    }
    
    [self beginServiceBrowser];
}

#pragma mark - Bonjour Service -
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
    [self.tableView reloadData];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [self.nameServiceEntries removeObject:aNetService];
    [self.tableView reloadData];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSNetService *service = sender;
    NSLog(@"Name: %@ Hostname: %@ Address: %@", service.name, service.hostName, service.addresses);
    if (service.addresses.count == 0)
        return;
    
    //resolve the ip address
    struct sockaddr_in  *socketAddress = nil;
    NSString            *ipString = nil;
    
    socketAddress = (struct sockaddr_in *)[service.addresses[0] bytes];
    ipString = [NSString stringWithFormat: @"%s", inet_ntoa(socketAddress->sin_addr)];
    
    TOSMBSession *session = [[TOSMBSession alloc] initWithHostName:service.hostName ipAddress:ipString];
    TOFilesTableViewController *controller = [[TOFilesTableViewController alloc] initWithSession:session title:@"Shares"];
    controller.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
    [self.navigationController pushViewController:controller animated:YES];
    
    [session requestContentsOfDirectoryAtFilePath:@"/"
                                          success:^(NSArray *files){ controller.files = files; }
                                            error:^(NSError *error) {
                                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SMB Client Error" message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                                [alert show];
                                            }];
    
    
    self.resolvingIndexPath = nil;
    [self.tableView reloadData];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    self.resolvingIndexPath = nil;
    [self.tableView reloadData];
}

#pragma mark - Table View -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.nameServiceEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellName = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellName];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = [self.nameServiceEntries[indexPath.row] name];
    
    if (self.resolvingIndexPath && self.resolvingIndexPath.row == indexPath.row) {
        cell.detailTextLabel.text = @"Resolving";
    }
    else
        cell.detailTextLabel.text = nil;
    
    return cell;
}

- (void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.resolvingIndexPath)
        return;
    
    self.resolvingIndexPath = indexPath;
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    NSNetService *service = self.nameServiceEntries[indexPath.row];
    service.delegate = self;
    [service resolveWithTimeout:5.0f];
}

@end
