/*
 * Copyright (c) 2016, Grant Paul
 * All rights reserved.
 */

#import <objc/runtime.h>

#define Hook(_class, _selector, ...) do { \
    SEL __selector = _selector; \
    Class __class = _class; \
    Method __method = class_getInstanceMethod(__class, __selector); \
    \
    /* Store implementations to swap. */ \
    __block IMP __original = NULL; \
    IMP __replaced = NULL; \
    { \
        /* Expose _cmd, lost by `imp_implementationWithBlock()`. */ \
        SEL _cmd = __selector; \
        __replaced = imp_implementationWithBlock(__VA_ARGS__); \
    } \
    \
    /* Perform the swap. */ \
    __original = method_setImplementation(__method, __replaced); \
} while (0)

#define Original(...) __original(self, _cmd, ##__VA_ARGS__)

