//
//  LayeredActionBar.m
//  NetHack-iOS
//
//  Created by Dirk Zimmermann on 7/8/10.
//  Copyright 2010 Dirk Zimmermann. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "LayeredActionBar.h"
#import "Action.h"

static const CGSize s_actionItemSize  = { 72, 40 };

#define kTextColor UIColor.whiteColor.CGColor
#define kBackgroundColor UIColor.blackColor.CGColor
#define kHighlightColor UIColor.lightGrayColor.CGColor
#define kBackgroundColorAnimation @"backgroundColor"

@interface ActionLayer : CALayer {
	
	Action *action;
	BOOL isHighlighted;

}

@property (nonatomic, retain) Action *action;
@property (nonatomic, assign) BOOL isHighlighted;

@end

@implementation ActionLayer

@synthesize action;
@synthesize isHighlighted;

- (id)init {
	if (self = [super init]) {
		self.opaque = YES;
		self.opacity = 1.0f;
		self.isHighlighted = NO;
		self.borderColor = UIColor.whiteColor.CGColor;
		self.borderWidth = 0.5;
		self.cornerRadius = 5;
		self.bounds = (CGRect){CGPointZero, s_actionItemSize};
		self.anchorPoint = CGPointZero;
		[[self animationForKey:kBackgroundColorAnimation] setDuration:0.4];
	}
	return self;
}

- (void)setIsHighlighted:(BOOL)flag {
	isHighlighted = flag;
	self.backgroundColor = self.isHighlighted ? kHighlightColor : kBackgroundColor;
}

- (void)drawInContext:(CGContextRef)context {
	if (self.action) {
		UIFont* const font = [UIFont boldSystemFontOfSize:12];
		UIGraphicsPushContext(context);
		CGContextSetFillColorWithColor(context, kTextColor);
		CGSize stringSize = [self.action.title sizeWithFont:font];
		CGPoint p;
		p.x = (self.bounds.size.width - stringSize.width) / 2;
		p.y = (self.bounds.size.height - stringSize.height) / 2;
		[self.action.title drawAtPoint:p withFont:font];
		UIGraphicsPopContext();
	}
}
@end

@implementation LayeredActionBar

@synthesize actions;

- (void)setup {
	actionLayers = [[NSMutableArray alloc] init];
	self.pagingEnabled  = YES;
	self.indicatorStyle = UIScrollViewIndicatorStyleWhite;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		[self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
		[self setup];
	}
	return self;
}

- (void)updateLayers {
	for(CALayer *layer in actionLayers) {
		[layer removeFromSuperlayer];
	}
	[actionLayers removeAllObjects];
	for(NSUInteger index = 0; index < self.actions.count; ++index) {
		ActionLayer *layer = [[ActionLayer alloc] init];
		layer.position = CGPointMake(0.0f, layer.bounds.size.height * index);
		layer.action = [self.actions objectAtIndex:index];
		layer.isHighlighted = index == highlightedIndex;
		[self.layer addSublayer:layer];
		[layer release];
		[layer setNeedsDisplay];
		[actionLayers addObject:layer];
	}
}

- (void)setActions:(NSArray *)as {
	if (actions != as) {
		[actions release];
	}
	actions = [as retain];
	highlightedIndex = -1;
	[self updateLayers];
}

// given size is ignored!
- (CGSize)sizeThatFits:(CGSize)size {
	CGSize s = s_actionItemSize;
	s.height = actions.count * s_actionItemSize.height;
	return s;
}

#pragma mark touch handling

- (CALayer *)layerForTouch:(UITouch *)touch {
	CGPoint point = [touch locationInView:touch.view];
	point = [touch.view convertPoint:point toView:self.superview];
	return [self.layer hitTest:point];
}

- (NSUInteger)actionIndexForTouch:(UITouch *)touch {
	CALayer *layer = [self layerForTouch:touch];
	return [actionLayers indexOfObject:layer];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSUInteger touchedIndex = [self actionIndexForTouch:touches.anyObject];
	if (touchedIndex != NSNotFound) {
		highlightedIndex = touchedIndex;
	} else {
		highlightedIndex = -1;
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	highlightedIndex = -1;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (highlightedIndex == -1) {
		return;
	}
	CALayer *layer = [self layerForTouch:touches.anyObject];
	NSUInteger touchedIndex = [actionLayers indexOfObject:layer];
	if (touchedIndex != NSNotFound) {
		CGRect frame = layer.frame;
		NSValue *v = [NSValue valueWithCGRect:frame];
		[[actions objectAtIndex:touchedIndex] invoke:v];
		
		highlightedIndex = -1;
		
		CALayer* layer = [actionLayers objectAtIndex:touchedIndex];
		
		CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:kBackgroundColorAnimation];
		[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
		[animation setToValue:(id)kHighlightColor];
		[animation setAutoreverses:YES];
		[animation setDuration:0.1];
		[layer addAnimation:animation forKey:kBackgroundColorAnimation];
	}
	
	highlightedIndex = -1;
}

#pragma mark memory

- (void)dealloc {
    [super dealloc];
}

@end
