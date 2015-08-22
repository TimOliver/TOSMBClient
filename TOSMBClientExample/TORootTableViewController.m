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

@property (nonatomic, strong) NSNetServiceBrowser *serviceBrowser;
@property (nonatomic, strong) NSMutableArray *nameServiceEntries;
@property (nonatomic, strong) TONetBIOSNameService *netbiosService;

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

- (void)dealloc
{
    if (self.netbiosService)
        [self.netbiosService stopDiscovery];
}

#pragma mark - NetBios Service -
- (void)beginServiceBrowser
{
    if (self.netbiosService)
        return;
    
    self.netbiosService = [[TONetBIOSNameService alloc] init];
    [self.netbiosService startDiscoveryWithTimeOut:4.0f added:^(TONetBIOSNameServiceEntry *entry) {
        [self.nameServiceEntries addObject:entry];
        [self.tableView reloadData];
    } removed:^(TONetBIOSNameServiceEntry *entry) {
        [self.nameServiceEntries removeObject:entry];
        [self.tableView reloadData];
    }];
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
    cell.detailTextLabel.text = nil;
    
    return cell;
}

- (void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TONetBIOSNameServiceEntry *entry = self.nameServiceEntries[indexPath.row];

    TOSMBSession *session = [[TOSMBSession alloc] initWithHostName:entry.name ipAddress:entry.ipAddressString];
    TOFilesTableViewController *controller = [[TOFilesTableViewController alloc] initWithSession:session title:@"Shares"];
    controller.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
    controller.rootController = self.rootController;
    [self.navigationController pushViewController:controller animated:YES];
    
    [session requestContentsOfDirectoryAtFilePath:@"/"
                                          success:^(NSArray *files){ controller.files = files; }
                                            error:^(NSError *error) {
                                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SMB Client Error" message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                                                [alert show];
                                            }];
}

@end
