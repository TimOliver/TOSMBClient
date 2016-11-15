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

#pragma mark - Object Lifecycle

- (void)dealloc
{
    if (self.netbiosService)
        [self.netbiosService stopDiscovery];
}

#pragma mark - Properties

- (TOSMBSession *)session {
    if (!_session) {
        _session = [[TOSMBSession alloc] init];
        self.rootController.session = _session;
    }
    return _session;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"SMB Devices";
    
    if (self.nameServiceEntries == nil) {
        self.nameServiceEntries = [NSMutableArray array];
    }
    
    [self beginServiceBrowser];
    
    if (self.session.connected) {
        [self pushContentOfRootDirectory];
    }
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
    
    if (self.session.hostName.length && ![self.session.hostName isEqualToString:entry.name]) {
        self.session = nil;
    }

    self.session.hostName = entry.name;
    self.session.ipAddress = entry.ipAddressString;
    
    [self pushContentOfRootDirectory];
}

- (void)pushContentOfRootDirectory {
    TOFilesTableViewController *controller = [[TOFilesTableViewController alloc] initWithSession:self.session title:@"Shares"];
    controller.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem];
    controller.rootController = self.rootController;
    [self.navigationController pushViewController:controller animated:YES];
    
    __weak typeof(self) weakSelf = self;
    [self.session requestContentsOfDirectoryAtFilePath:@"/"
                                               success:^(NSArray *files) { controller.files = files; }
                                                 error:^(NSError *error) {
                                                     [weakSelf.navigationController popViewControllerAnimated:YES];
                                                     if ([error.domain isEqualToString:TOSMBClientErrorDomain] && error.code == TOSMBSessionErrorCodeAuthenticationFailed) {
                                                         [weakSelf presentLogin];
                                                     } else {
                                                         [weakSelf presentError:error];
                                                     }
                                                 }];
}

#pragma mark - Error Handling

- (void)presentError:(NSError *)error {
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"SMB Client Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:okAction];
    
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

- (void)presentLogin {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"SMB Client Login" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Username";
    }];
    
    [controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Password";
        textField.secureTextEntry = YES;
    }];
    
    __weak typeof(self) weakSelf = self;
    UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"Login" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *usernameTextField = controller.textFields.firstObject;
        UITextField *passwordTextField = controller.textFields.lastObject;
        [weakSelf.session setLoginCredentialsWithUserName:usernameTextField.text password:passwordTextField.text];
        [weakSelf pushContentOfRootDirectory];
    }];
    [controller addAction:loginAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        weakSelf.session = nil;
    }];
    [controller addAction:cancelAction];
    
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

@end
