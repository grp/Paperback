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
#import <Security/Security.h>

#import "Hook.h"


@interface FBKeychainItem : NSObject

@end

@interface FBKeychainStore : NSObject

+ (NSDictionary<NSString *, id> *)defaultDictionaryForItem:(FBKeychainItem *)item;
+ (NSDictionary<NSString *, id> *)searchDictionaryForItem:(FBKeychainItem *)item;

@end


static NSDictionary<NSString *, id> *
RemoveKeychainGroup(NSDictionary<NSString *, id> *dict)
{
    /*
     * By default, the access group is hardcoded to the Facebook app store
     * group. Since this app is re-signed, it can't access the Facebook group,
     * so should fall back to the app's keychain rather than a shared keychain.
     */
    NSMutableDictionary<NSString *, id> *removed = [dict mutableCopy];
    [removed removeObjectForKey:(__bridge NSString *)kSecAttrAccessGroup];
    return removed;
}

__attribute__((constructor))
static void KeychianInitialize(void)
{
    /*
     * Remove the key group from the keychain storage.
     */
    Hook(object_getClass(NSClassFromString(@"FBKeychainStore")), @selector(defaultDictionaryForItem:), ^(Class self, FBKeychainItem *item) {
        NSDictionary<NSString *, id> *original = Original(item);
        return RemoveKeychainGroup(original);
    });

    /*
     * Remove the key group from the keychain search.
     */
    Hook(object_getClass(NSClassFromString(@"FBKeychainStore")), @selector(searchDictionaryForItem:), ^(Class self, FBKeychainItem *item) {
        NSDictionary<NSString *, id> *original = Original(item);
        return RemoveKeychainGroup(original);
    });
}

