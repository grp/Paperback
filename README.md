# Paperback 

A version of Paper modified to pretend to be the Facebook app.

## Explanation

Paper was an alternative to the Facebook app released in February 2014 and discontinued in July 2016. While the app was disabled remotely, the client is still functional. This project brings Paper back to life by making it indistinguishable from the standard Facebook for iOS app.

## Installation

### Prequisites

 - Recent macOS and Xcode.
 - [Ninja](https://ninja-build.org) to build:

        brew install ninja

 - [ios-deploy](https://github.com/phonegap/ios-deploy) to install:

        brew install node
        npm install -g ios-deploy

 - An unmodified, decrypted copy of `Paper.app`, version 1.2.6.
 - An iOS Developer program membership, to re-sign the app.
 
### Instructions

 1. Put the decrypted `Paper.app` into the same directory as the code.
 2. Modify `Entitlements.xml` to reference the appropriate App ID prefix for your provisioning profile.
 3. Set the `CODE_SIGN_IDENTITY` environment variable to reference the appropriate code signing identity (often `iPhone Developer`).
 
        export CODE_SIGN_IDENTITY="iPhone Developer"

 4. Build:

        ninja build

 5. Install onto attached device:

        ninja install

    Alternatively, package `build/Paper.app` and install with iTunes or OTA.

## License

See the `LICENSE` file for details.

---

![Sloth](https://github.com/grp/Paperback/blob/master/sloth.png?raw=true) 

Thanks to everyone who made Paper possible.

