//
//  GCDDrawAppDelegate.h
//  GCDDraw
//
//  Created by 能登 要 on 11/09/02.
//  Copyright 2011 いります電算企画. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCDDrawViewController;

@interface GCDDrawAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet GCDDrawViewController *viewController;

@end
