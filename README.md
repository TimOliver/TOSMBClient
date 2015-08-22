# TOSMBClient
`TOSMBClient` is a small library that serves as a simple SMB ([Server Message Block](https://en.wikipedia.org/wiki/Server_Message_Block) ) client for iOS apps.
It is an Objective-C wrapper around [Defective SMb](http://videolabs.github.io/libdsm), or libDSM, a low level SMB client library built in C, by some of VideoLabs' developers.

This project is still heavily under construction, and doesn't do much at present. The end-goal is to encapsulate as much of libDSM's functionality behind an Objective-C wrapper, in order to make SMB integration into an iOS app as easy as possible.
If you yourself are interested in such a thing, I would very much appreciate any contributions.

In the meantime, please feel free to download it now if you would like a copy of Defective SMb precompiled for iOS device architectures.

## Examples
### Create a new Session

```
#import "TOSMBClient.h"

TOSMBSession *session = [[TOSMBSession alloc] initWithHostName:@"Tims-NAS" ipAddress:@"192.168.1.3"];
[session setLoginCredentialsWithUserName:@"wagstaff" password:@"swordfish"];
```
Ideally, it is best to supply both the host name and IP address when creating a new session object. However, if you only initially know one of these values, `TOSMBSession` will perform a lookup via NetBIOS to try and resolve the other value.

### Request a List of Files from the SMB Device
```
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
```
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
For the commercially licensed version of Defective SMb, `TOSMBClient` is available under the MIT license.
