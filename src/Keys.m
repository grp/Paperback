/*
 * Copyright (c) 2016, Grant Paul
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "Hook.h"


@interface FBCajmereKeySource : NSObject

@property(readonly, copy, nonatomic) NSString *appSecret;
@property(readonly, copy, nonatomic) NSString *publicAppName;

@end

@interface FBApplication : NSObject

+ (NSString *)applicationFBID;

@end


__attribute__((constructor))
static void KeysInitialize(void)
{
    /*
     * Replace Paper's app ID with the Facebook app ID.
     */
    Hook(object_getClass(NSClassFromString(@"FBApplication")), @selector(applicationFBID), ^(Class self) {
        /*
         * By default, this is read from the `FacebookAppID` key in the app's
         * Info.plist. However, it's cleaner to modify that at runtime rather
         * than on disk at build time, so hook the code here that loads it.
         */
        return @"6628568379";
    });

    /*
     * Replace Paper app secret with Facebook app secret.
     */
    Hook(NSClassFromString(@"FBCajmereKeySource"), @selector(appSecret), ^(FBCajmereKeySource *self) {
        return @"c1e620fa708a1d5696fb991c1bde5662";
    });

    /*
     * Replace Paper's user-agent name, with the Facebook app's user-agent name.
     */
    Hook(NSClassFromString(@"FBCajmereKeySource"), @selector(publicAppName), ^(FBCajmereKeySource *self) {
        /*
         * The history behind this one is interesting. The Facebook backend uses the
         * user-agent to identify the client app requesting the page. Originally, Paper
         * used its own codename for its user-agent, but since it's also sent to web
         * links viewed in Paper, this was seen as a potential for leaks. To hide Paper
         * before launch, the user-agent name was changed to `FBiOS`, distinguishable
         * on the server (in case) from the main app's `FBIOS` but inconspicuous to humans.
         */
        return @"FBIOS";
    });
}

