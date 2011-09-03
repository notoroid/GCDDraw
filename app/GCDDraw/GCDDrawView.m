//
//  GCDDrawView.m
//  GCDDraw
//
//  Created by 能登 要 on 11/09/02.
//  Copyright 2011 いります電算企画. All rights reserved.
//

#import "GCDDrawView.h"

@implementation GCDDrawView

@synthesize location=location_;
@synthesize previousLocation=previousLocation_;

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self != nil)
    {
        arrayPoints_ = [[NSMutableArray alloc] init];
            // 配列を初期かしておく
        
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
        self.clearsContextBeforeDrawing = YES;
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self != nil)
	{
        arrayPoints_ = [[NSMutableArray alloc] init];
            // 配列を初期かしておく
        
		self.backgroundColor = [UIColor blackColor];
		self.opaque = YES;
		self.clearsContextBeforeDrawing = YES;
	}
	return self;
}

-(BOOL)createFramebuffer
    {
    // 描画情報を保持するフレームバッファの確保
    NSAssert(imageColorSpace_ == nil , @"imageColorSpace_ is not nil" );
    NSAssert(bufferContext_ == nil , @"bufferContext_ is not nil" );
    
    imageColorSpace_ = CGColorSpaceCreateDeviceRGB();
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGRect bounds = CGRectMake(0.0f,0.0f, self.frame.size.width * scale , self.frame.size.height * scale );

    bufferContext_ = CGBitmapContextCreate (NULL/*data_*/,bounds.size.width,bounds.size.height,8, bounds.size.width * 4, imageColorSpace_, kCGImageAlphaPremultipliedFirst );
    
    if( bufferContext_ == nil ){
        NSLog(@"Render error.");
        return FALSE;
    }
    
    return YES;
}

-(void)destroyFramebuffer
{
    // フレームバッファの解放
    if( bufferContext_ )
        CGContextRelease(bufferContext_);
    
    if( imageColorSpace_ )
        CGColorSpaceRelease(imageColorSpace_);
    
    bufferContext_ = nil;
    imageColorSpace_ = nil;
}

-(void)drawInContext:(CGContextRef)context
{
    // 描画処理
    // scale に基づいてバッファを書き出すだけ
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bufferContext_);
    CGFloat width = CGImageGetWidth(cgImage);
    CGFloat height = CGImageGetHeight(cgImage);
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGContextScaleCTM(context, 1.0f / scale , 1.0f / scale );
    
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), cgImage );
    CGImageRelease(cgImage);
}

-(void)drawRect:(CGRect)rect
{
	// Since we use the CGContextRef a lot, it is convienient for our demonstration classes to do the real work
	// inside of a method that passes the context as a parameter, rather than having to query the context
	// continuously, or setup that parameter for every subclass.
	[self drawInContext:UIGraphicsGetCurrentContext()];
}

-(void)layoutSubviews
{
    // レイアウト調整毎にフレームバッファの解放と確保
	[self destroyFramebuffer];
	[self createFramebuffer];
}

- (void)dealloc
{
    [arrayPoints_ release];
    [self destroyFramebuffer];
    [super dealloc];
}


// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGRect				bounds = [self bounds];
    UITouch*	touch = [[event touchesForView:self] anyObject];
	firstTouch_ = YES;
	// Convert touch point from UIView referential to OpenGL one (upside-down flip)
	location_ = [touch locationInView:self];
	location_.y = bounds.size.height - location_.y;
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{  
    
	CGRect				bounds = [self bounds];
	UITouch*			touch = [[event touchesForView:self] anyObject];
    
	// Convert touch point from UIView referential to OpenGL one (upside-down flip)
	if (firstTouch_) {
		firstTouch_ = NO;
		previousLocation_ = [touch previousLocationInView:self];
		previousLocation_.y = bounds.size.height - previousLocation_.y;
	} else {
		location_ = [touch locationInView:self];
	    location_.y = bounds.size.height - location_.y;
		previousLocation_ = [touch previousLocationInView:self];
		previousLocation_.y = bounds.size.height - previousLocation_.y;
	}
    
	// Render the stroke
	[self renderLineFromPoint:previousLocation_ toPoint:location_];
}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGRect				bounds = [self bounds];
    UITouch*	touch = [[event touchesForView:self] anyObject];
	if (firstTouch_) {
		firstTouch_ = NO;
		previousLocation_ = [touch previousLocationInView:self];
		previousLocation_.y = bounds.size.height - previousLocation_.y;
        
		[self renderLineFromPoint:previousLocation_ toPoint:location_];
	}
    
    [self renderFlush];
        // 残っていた描画処理を呼び出す
    drawLength_ = .0f;
    [arrayPoints_ release];
    arrayPoints_ = [[NSMutableArray alloc] init];
        // 配列も初期化してしまう
}

// Handles the end of a touch event.
- (void)touchesCancelled:(NSSet *)touches withEvernt:(UIEvent *)event
{
	// If appropriate, add code necessary to save the state of the application.
	// This application is not saving state.
}


- (IBAction)firedErase:(id)sender {
    // 消去処理
    if( bufferContext_ != nil ){
        CGContextSetFillColorWithColor(bufferContext_, [[UIColor blackColor] CGColor] );
        
        CGFloat scale = [UIScreen mainScreen].scale;
        CGContextFillRect(bufferContext_, CGRectMake(.0f,.0f,self.frame.size.width * scale, self.frame.size.height * scale)  );
        
        [self setNeedsDisplay];
    }    
}

// Drawings a line onscreen based on where the user touches
- (void) renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end
{

#define RENDER_INTERVAL 4
    static NSInteger drawStep = 0;
    
    if( drawStep % RENDER_INTERVAL == 0 ){

        
        CGContextRef context = bufferContext_;
        if( context != nil ){
            CGFloat scale = [UIScreen mainScreen].scale;
            CGFloat height = self.frame.size.height;
                // スケールと高さを用意しておく

            // 描画位置を正規化
            CGPoint normalizeStartPoint = CGPointMake( start.x * scale , (height-start.y) * scale );
            CGPoint normalizeEndPoint = CGPointMake( end.x * scale , (height-end.y) * scale );

            // 位置を格納
            [arrayPoints_ addObject:[NSValue valueWithCGPoint:normalizeStartPoint]];
            [arrayPoints_ addObject:[NSValue valueWithCGPoint:normalizeEndPoint]];
            
            // バッファから定期的に描画ここでは距離で換算
            drawLength_ += sqrt( fabs(normalizeStartPoint.x - normalizeEndPoint.x) * fabs(normalizeStartPoint.y - normalizeEndPoint.y)  );
            
            // 一定以上描画した時点でバッファを書き出し
            if(  drawLength_ > 5.0f ){
                [self renderFlush];
                    // ためた描画バッファを書き出し
                drawLength_ = .0f;
            }
        }

    }
    drawStep++;
}

// バッファリングされた描画を書き出す
-(void)renderFlush
{
    CGContextRef context = bufferContext_;
    
#define PATH_ITEM_COUNT 3    
    if( context != nil && [arrayPoints_ count] > PATH_ITEM_COUNT + 1){
        
        NSMutableArray* drawPoints = arrayPoints_;
        
        arrayPoints_ = [[NSMutableArray alloc] init];
        
        NSInteger count = [drawPoints count];
        NSInteger modValue = (count -1 ) % PATH_ITEM_COUNT;
        // 描画のセットからあふれる要素数を取得
        
        // 線の描画に満たない要素はバッファに戻す
        for( NSInteger i = 0; i < modValue;i++ ){
            NSValue* lastObj = [drawPoints lastObject];
            [arrayPoints_ insertObject:lastObj atIndex:0];
            [drawPoints removeObject:lastObj ];
        }
        
        // バッファの先頭に描画の開始位置として位置をコピーしておく
        [arrayPoints_ insertObject:[drawPoints objectAtIndex:[drawPoints count]-1] atIndex:0];        
        
        CGFloat scale = [UIScreen mainScreen].scale;
        
        // ここからGCD 開始
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        // 
        dispatch_async(queue, ^{
            if( context == bufferContext_ ){
                CGContextRetain(context);
                    // コンテキストを確保
                
                NSValue* value = [drawPoints objectAtIndex:0];
                
                CGPoint movePoint = [value CGPointValue];
                [drawPoints removeObjectAtIndex:0];
                
                NSInteger count = [drawPoints count];
                // 要素数を取得
#if 0
                // コメントアウトしているがカーブのコントロールの描画
                CGContextMoveToPoint( context,movePoint.x,movePoint.y );
                CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
                for( NSInteger i = 0; i < count; i+= PATH_ITEM_COUNT ){
                    CGPoint point = [[drawPoints objectAtIndex:i] CGPointValue];
                    CGPoint point2 = [[drawPoints objectAtIndex:i+1] CGPointValue];
                    CGContextMoveToPoint( context,point.x,point.y );
                    CGContextAddLineToPoint(context, point2.x, point2.y);
                }                CGContextClosePath(context);

                CGContextSetLineWidth(context, 2.0f * scale );
                CGContextStrokePath(context);        
#endif          
                
#if 0
                // コメントアウトしているがカーブポイントが無い場合の描画
                CGContextMoveToPoint( context,movePoint.x,movePoint.y );
                CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 1.0);
                for( NSInteger i = 0; i < count; i+= PATH_ITEM_COUNT ){
                    CGPoint point = [[drawPoints objectAtIndex:i] CGPointValue];
                    CGPoint point2 = [[drawPoints objectAtIndex:i+1] CGPointValue];
                    CGPoint point3 = [[drawPoints objectAtIndex:i+2] CGPointValue];
                    CGContextAddLineToPoint(context, point.x, point.y);
                    CGContextAddLineToPoint(context, point2.x, point2.y);
                    CGContextAddLineToPoint(context, point3.x, point3.y);
                }
                CGContextSetLineWidth(context, 2.0f * scale );
                CGContextStrokePath(context);        
#endif            
                
                // 開始位置まで移動
                CGContextMoveToPoint( context,movePoint.x,movePoint.y );
                for( NSInteger i = 0; i < count; i+= PATH_ITEM_COUNT ){
                    CGPoint point = [[drawPoints objectAtIndex:i] CGPointValue];
                    CGPoint point2 = [[drawPoints objectAtIndex:i+1] CGPointValue];
                    CGPoint point3 = [[drawPoints objectAtIndex:i+2] CGPointValue];
                    CGContextAddCurveToPoint(context, point.x, point.y, point2.x, point2.y, point3.x, point3.y);
                        // point,point2 を制御点としてカーブを描画
                }
                
                // Drawing lines with a white stroke color
                CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
                    // 線の色を指定
                CGContextSetLineCap(context, kCGLineCapRound );
                    // 縁を丸に変更
                CGContextSetLineWidth(context,  2.0f * scale );
                    // 幅を設定
                CGContextStrokePath(context);
                    // 線を描画
                
                // 描画後に再描画を送信
                dispatch_async( dispatch_get_main_queue() , ^{
                    [self setNeedsDisplay];
                });
                
                CGContextRelease(context);
                    // コンテキストを解放
            }
        });
        [drawPoints release];
        
    }
    
}

@end
