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


@interface FBGraphQLQuery : NSObject

- (NSString *)queryString;
- (void)setQueryString:(NSString *)queryString;

@end

@interface FBNetworkerRequest : NSObject

@end

@interface FBSessionNetworkerRequest : FBNetworkerRequest

@end

@interface FBGraphQLDownloadRequest : FBSessionNetworkerRequest

@end

@interface FBGraphQLPagedDownloadRequest : FBGraphQLDownloadRequest

@end

@interface FBNewsFeedSectionStoryDownloadRequest : FBGraphQLPagedDownloadRequest

- (FBGraphQLQuery *)newQueryWithCursor:(id)cursor;

@end

@interface FBNewsFeedSectionStreamConfiguration : NSObject

- (NSString *)storySectionNameForSequenceType:(unsigned int)type;

@end

__attribute__((constructor))
static void FeedInitialize(void)
{
    Hook(NSClassFromString(@"FBNewsFeedSectionStoryDownloadRequest"), @selector(newQueryWithCursor:), ^(FBNewsFeedSectionStoryDownloadRequest *self, id cursor) {
        FBGraphQLQuery *query = Original(cursor);

        NSString *queryString = query.queryString;

        /*
         * Rather than loading a Paper section feed, load the standard News Feed
         * used by other Facebook apps.
         */
        NSRange sectionFeedRange = [queryString rangeOfString:@"section_feed"];
        queryString = [queryString stringByReplacingCharactersInRange:sectionFeedRange withString:@"news_feed"];

        /* `news_feed` is a field on `Viewer`, not a Paper section. */
        NSRange nodeRange = [queryString rangeOfString:@"node(<targetID>)"];
        queryString = [queryString stringByReplacingCharactersInRange:nodeRange withString:@"viewer()"];

        /* `Viewer` does not have an ID. */
        NSRange idRange = [queryString rangeOfString:@"cache_id,id,"];
        queryString = [queryString stringByReplacingCharactersInRange:idRange withString:@""];

        /*
         * Use the Facebook app environment, rather than Paper.
         */
        NSRange immersiveRange = [queryString rangeOfString:@"iphone_immersive"];
        queryString = [queryString stringByReplacingCharactersInRange:immersiveRange withString:@"iphone"];

        query.queryString = queryString;

        /*
         * Swap out the root call and ID to match the modified query.
         */
        [query setValue:@"viewer" forKey:@"callName"];
        [query setValue:nil forKey:@"rootIDVariable"];

        /*
         * Remove the persisted query ID so the request uses the query string,
         * rather than sending just the ID and assuming the query is cached.
         */
        [query setValue:nil forKey:@"persistID"];

        return query;
    });

    Hook(NSClassFromString(@"FBNewsFeedSectionStreamConfiguration"), @selector(storySectionNameForSequenceType:), ^(FBNewsFeedSectionStreamConfiguration *self, unsigned int type) {
        /*
         * The stories are loaded from the `news_feed` field on `Viewer`. This tells
         * Paper to find the stories in that field, rather than the `section_feed`.
         */
        return @"newsFeed";
    });
}

