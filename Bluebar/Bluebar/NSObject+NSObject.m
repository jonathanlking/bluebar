//
//  NSObject+NSObject_PWObject_h.m
//  Bluebar
//
//  Created by Jonathan King on 03/09/2013.
//  Copyright (c) 2013 Jonathan King. All rights reserved.
//

#import "NSObject+PWObject.h"

@implementation NSObject (PWObject)

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay
{
    int64_t delta = (int64_t)(1.0e9 * delay);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delta), dispatch_get_main_queue(), block);
}

@end
