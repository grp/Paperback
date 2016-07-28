
/*
 * Copyright (c) 2016, Grant Paul
 * All rights reserved.
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

