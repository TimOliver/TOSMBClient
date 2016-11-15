//
//  TORootViewController.h
//  TOSMBClientExample
//
//  Created by Tim Oliver on 8/10/15.
//  Copyright © 2015 TimOliver. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TOSMBSession;

@interface TORootViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel *noticeLabel;

@property (nonatomic, weak) IBOutlet UIView *downloadView;
@property (nonatomic, weak) IBOutlet UILabel *fileNameLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UIButton *suspendButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

@property (nonatomic, strong, null_resettable) TOSMBSession *session;

- (IBAction)suspendButtonTapped:(id)sender;
- (IBAction)cancelButtonTapped:(id)sender;

- (void)downloadFileFromSession:(TOSMBSession *)session atFilePath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
