//
//  TOFilesViewControllerTableViewController.h
//  TOSMBClientExample
//
//  Created by Tim Oliver on 8/5/15.
//  Copyright (c) 2015 TimOliver. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TOSMBSession;

@interface TOFilesTableViewController : UITableViewController

- (instancetype)initWithSession:(TOSMBSession *)session files:(NSArray *)files;

@end
