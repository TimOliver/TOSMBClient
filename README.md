# TOSMBClient

[![Beerpay](https://beerpay.io/TimOliver/TOSMBClient/badge.svg?style=flat)](https://beerpay.io/TimOliver/TOSMBClient)
[![PayPal](https://img.shields.io/badge/paypal-donate-blue.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M4RKULAVKV7K8)

`TOSMBClient` is a small library that serves as a simple SMB ([Server Message Block](https://en.wikipedia.org/wiki/Server_Message_Block) ) client for iOS apps. The library allows connecting to SMB devices, downloading file metadata, and subsequently allows asynchronous downloading of files from an SMB device straight to an iOS device.

It is an Objective-C wrapper around [Defective SMb](http://videolabs.github.io/libdsm), or libDSM, a low level SMB client library built in C built by some of VideoLabs' developers. A copy of libDSM has been specially cross-compiled for iOS device architectures and embedded in this library, so this project has no external dependencies.


## Features
* Connects to (**MOST**) SMB devices over local network.
* Concurrently download files from SMB devices to your iOS device.
* Allows basic user authentication, with automatic deferral to 'guest' where possible.
* Simplified, asynchronous API for accessing file metadata on devices.
* Uses iOS multitasking to ensure downloads continue even if the app is suspended.

## Examples
### Create a new Session

```objc
#import "TOSMBClient.h"

TOSMBSession *session = [[TOSMBSession alloc] initWithHostName:@"Tims-NAS" ipAddress:@"192.168.1.3"];
[session setLoginCredentialsWithUserName:@"wagstaff" password:@"swordfish"];
```
Ideally, it is best to supply both the host name and IP address when creating a new session object. However, if you only initially know one of these values, `TOSMBSession` will perform a lookup via NetBIOS to try and resolve the other value.

### Request a List of Files from the SMB Device
```objc
// Asynchronous Request
[session requestContentsOfDirectoryAtFilePath:@"/"
    success:^(NSArray *files){ 
      NSLog(@"SMB Client Files: %@", error.localizedDescription);
    }
    error:^(NSError *error) {
        NSLog(@"SMB Client Error: %@", error.localizedDescription);
    }];
    
// Synchronous Request
NSArray *files = [session requestContentsOfDirectoryAtFilePath:@"/" error:nil];
```
All request methods have a synchronous and an asynchronous implementation. Both return an `NSArray` of `TOSMBSessionFile` objects that provide metadata on each file entry discovered.

### Downloading a File from an SMB Device
```objc
TOSMBSessionDownloadTask *downloadTask = [session downloadTaskForFileAtPath:@"/Comics/Issue-1.cbz"
      destinationPath:nil //Default is 'Documents' directory
      progressHandler:^(uint64_t totalBytesWritten, uint64_t totalBytesExpected) { NSLog(@"%f", (CGFloat)totalBytesWritten / (CGFloat) totalBytesExpected);
      completionHandler:^(NSString *filePath) { NSLog(@"File was downloaded to %@!", filePath); }
      failHandler:^(NSError *error) { NSLog(@"Error: %@", error.localizedDescription); }];

[downloadTask resume];
```
Download tasks are handled similarily to their counterparts in `NSURLSession`. They may paused or canceled at anytime (Both however reset the connection to ensure nothing hangs), and they additionally implement the `UIApplication` backgrounding system to ensure downloads can continue, even if the user clicks the Home button.

## Technical Requirements
iOS 7.0 or above.

## License
Depending on which license you are using for libDSM, `TOSMBClient` is available in multiple licenses.

For the LGPL v2.1 licensed version of libDSM, `TOSMBClient` is also available under the same license. 
For the commercially licensed version of Defective SMb, `TOSMBClient` is available under the MIT license. ![analytics](https://ga-beacon.appspot.com/UA-5643664-16/TOSMBClient/README.md?pixel)
