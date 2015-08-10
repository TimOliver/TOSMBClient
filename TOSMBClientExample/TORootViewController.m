//
//  TORootViewController.m
//  TOSMBClientExample
//
//  Created by Tim Oliver on 8/10/15.
//  Copyright © 2015 TimOliver. All rights reserved.
//

#import "TORootViewController.h"
#import "TORootTableViewController.h"

@interface TORootViewController ()

- (void)cancelButtonTapped:(id)sender;

@end

@implementation TORootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addButtonTapped:(id)sender
{
    TORootTableViewController *tableController = [[TORootTableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:tableController];
    controller.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:controller animated:YES completion:nil];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonTapped:)];
    tableController.navigationItem.rightBarButtonItem = item;
}

- (void)cancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)actionButtonTapped:(id)sender
{
    
}


@end
