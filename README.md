# TOSMBClient
`TOSMBClient` is a small library that serves as a simple SMB ([Server Message Block](https://en.wikipedia.org/wiki/Server_Message_Block) ) client for iOS apps.
It is an Objective-C wrapper around [Defective SMb](http://videolabs.github.io/libdsm), or libDSM, a low level SMB client library built in C, by some of VideoLabs' developers.

This project is still heavily under construction, and doesn't do much at present. The end-goal is to encapsulate as much of libDSM's functionality behind an Objective-C wrapper, in order to make SMB integration into an iOS app as easy as possible.
If you yourself are interested in such a thing, I would very much appreciate any contributions.

In the meantime, please feel free to download it now if you would like a copy of Defective SMb precompiled for iOS device architectures.

## Technical Requirements
iOS 7.0 or above.

## License
Depending on which license you are using for libDSM, `TOSMBClient` is available in multiple licenses.

For the LGPL v2.1 licensed version of libDSM, `TOSMBClient` is also available under the same license. 
For the commercially licensed version of Defective SMb, `TOSMBClient` is available under the MIT license.
