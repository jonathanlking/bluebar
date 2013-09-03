//
//  NSObject+NSObject_PWObject_h.h
//  Bluebar
//
//  Created by Jonathan King on 03/09/2013.
//  Copyright (c) 2013 Jonathan King. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (PWObject)

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

@end
