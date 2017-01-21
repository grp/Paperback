/*
 * Copyright (c) 2016, Grant Paul
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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

