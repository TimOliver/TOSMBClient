//
//  TOFilesViewControllerTableViewController.h
//  TOSMBClientExample
//
//  Created by Tim Oliver on 8/5/15.
//  Copyright (c) 2015 TimOliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TORootViewController.h"

@class TOSMBSession;
@class TOSMBSessionFile;

@interface TOFilesTableViewController : UITableViewController

@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSArray <TOSMBSessionFile *> *files;
@property (nonatomic, weak) TORootViewController *rootController;

- (instancetype)initWithSession:(TOSMBSession *)session title:(NSString *)title;

@end
