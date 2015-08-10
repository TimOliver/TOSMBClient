//
//  TOFilesViewControllerTableViewController.m
//  TOSMBClientExample
//
//  Created by Tim Oliver on 8/5/15.
//  Copyright (c) 2015 TimOliver. All rights reserved.
//

#import "TOFilesTableViewController.h"
#import "TOSMBClient.h"

@interface TOFilesTableViewController ()

@property (nonatomic, copy) NSString *directoryTitle;
@property (nonatomic, strong) TOSMBSession *session;

@end

@implementation TOFilesTableViewController

- (instancetype)initWithSession:(TOSMBSession *)session title:(NSString *)title
{
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _directoryTitle = title;
        _session = session;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Loading...";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.files.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    TOSMBSessionFile *file = self.files[indexPath.row];
    cell.textLabel.text = file.name;
    cell.detailTextLabel.text = file.directory ? @"Directory" : [NSString stringWithFormat:@"File | Size: %ld", (long)file.fileSize];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TOSMBSessionFile *file = self.files[indexPath.row];
    TOFilesTableViewController *controller = [[TOFilesTableViewController alloc] initWithSession:self.session title:file.name];
    controller.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
    [self.navigationController pushViewController:controller animated:YES];
    
    [self.session requestContentsOfDirectoryAtFilePath:file.filePath success:^(NSArray *files) {
        controller.files = files;
    } error:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SMB Client Error" message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }];
}

- (void)setFiles:(NSArray *)files
{
    _files = files;
    self.navigationItem.title = self.directoryTitle;
    [self.tableView reloadData];
}

@end
