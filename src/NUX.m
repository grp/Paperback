/*
 * Copyright (c) 2016, Grant Paul
 * All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Hook.h"


@interface FBCoverChooserView : UIView

@property(readonly, nonatomic, getter=isInteracting) BOOL interacting;

@end

@interface FBFeedStoreView : FBCoverChooserView

- (void)_doneButtonTapped:(id)sender;
- (void)animateOut;

@end


__attribute__((constructor))
static void NUXInitialize(void)
{
    /*
     * Remove requirement to select a section before existing the feed store NUX,
     * since sections are no longer available.
     */
    Hook(NSClassFromString(@"FBFeedStoreView"), @selector(_doneButtonTapped:), ^(FBFeedStoreView *self, id sender) {
        /* Avoid checking if no covers are selected. */
        if (!self.interacting) {
            [self animateOut];
        }
    });
}

