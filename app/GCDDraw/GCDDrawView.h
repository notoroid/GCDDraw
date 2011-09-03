//
//  GCDDrawView.h
//  GCDDraw
//
//  Created by 能登 要 on 11/09/02.
//  Copyright 2011 いります電算企画. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GCDDrawView : UIView {
	Boolean	firstTouch_;
    CGContextRef bufferContext_;
    CGColorSpaceRef  imageColorSpace_;
    NSMutableArray* arrayPoints_;
    
    CGFloat drawLength_;
}

@property(nonatomic, readwrite) CGPoint location;
@property(nonatomic, readwrite) CGPoint previousLocation;

-(void)drawInContext:(CGContextRef)context;

-(BOOL)createFramebuffer;
-(void)destroyFramebuffer;
-(void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end;
-(void)renderFlush;

- (IBAction)firedErase:(id)sender;

@end
