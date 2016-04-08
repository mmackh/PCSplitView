//
//  PCSplitView.m
//  Ordervisto
//
//  Created by Maximilian Mackh on 30/08/15.
//  Copyright © 2015 Professional Consulting & Trading GmbH. All rights reserved.
//

#import "PCSplitView.h"

NSInteger const PCSplitViewExcludeLayoutViewTag = 260890;
NSInteger const PCSplitViewDisableClipOnViewTag = 110292;
NSInteger const PCSplitViewSendToBackAndDisableClipOnViewTag = 160894;

@interface PCSplitView ()

@property (nonatomic) NSArray *originalSubviews;

@end

@implementation PCSplitView

- (void)setSubviewLayout:(NSString *)subviewLayout direction:(PCSplitViewDirection)splitDirection
{
    self.splitViewDirection = splitDirection;
    
    NSMutableArray *subviewRatiosMutable = [NSMutableArray new];
    NSMutableArray *subviewFixedValuesMutable = [NSMutableArray new];
    for (NSString *layout in [subviewLayout componentsSeparatedByString:@","])
    {
        NSArray *layoutSplit = [layout componentsSeparatedByString:@"*"];
        [subviewRatiosMutable addObject:[layoutSplit firstObject]];
        [subviewFixedValuesMutable addObject:(![layout containsString:@"*"])?@"-1":[layoutSplit lastObject]];
    }
    
    self.subviewFixedValues = subviewFixedValuesMutable.copy;
    self.subviewRatios = subviewRatiosMutable.copy;
}

- (NSString *)subviewLayout
{
    NSMutableArray *subviewLayoutMutable = [NSMutableArray new];
    NSInteger idx = 0;
    
    BOOL usesFixedValues = self.subviewFixedValues.count;
    
    for (id value in self.subviewRatios)
    {
        id fixedValue = (!usesFixedValues) ? @"-1" : self.subviewFixedValues[idx];
        [subviewLayoutMutable addObject:[NSString stringWithFormat:@"%@*%@",value,fixedValue]];
        idx += 1;
    }
    return [subviewLayoutMutable componentsJoinedByString:@","].copy;
}

- (void)layoutIfNeeded
{
    if (self.preventAnimations)
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [super layoutIfNeeded];
        [CATransaction commit];
    }
    else
    {
        [super layoutIfNeeded];
    }
}

- (void)layoutSubviews
{
    if (self.preventAnimations)
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    
    [super layoutSubviews];
    
    if (!self.originalSubviews || self.originalSubviews.count != self.subviews.count) self.originalSubviews = self.subviews;
    
    NSMutableArray *subviewsMutable = [NSMutableArray new];
    for (UIView *subview in self.originalSubviews)
    {
        if (subview.tag == PCSplitViewExcludeLayoutViewTag) continue;
        [subviewsMutable addObject:subview];
    }
    
    if (!self.subviewRatios.count) return;
    
    BOOL hz = (self.splitViewDirection == PCSplitViewDirectionHorizontal);
    
    CGFloat topLayoutGuideLength = (self.parentViewController) ? self.parentViewController.topLayoutGuide.length : 0.0;
    CGFloat bottomLayoutGuideLength = (self.parentViewController) ? self.parentViewController.bottomLayoutGuide.length : 0.0;
    
    NSArray *fixedValues = self.subviewFixedValues;
    NSArray *ratios = self.subviewRatios;
    CGFloat padding = self.subviewPadding;
    
    NSInteger counter = 0;
    CGFloat offsetTracker = (hz)?0.0:topLayoutGuideLength;
    
    NSInteger ratioTargetCount = 0;
    NSInteger ratioLossIndex = 0;
    CGFloat ratioLossValue = 0.0;
    
    CGFloat fixedValuesSum = 0.0;
    for (NSNumber *fixedValue in fixedValues)
    {
        CGFloat fixedValueFloat = [fixedValue floatValue];
        CGFloat ratio = [ratios[ratioLossIndex] floatValue];
        ratioLossIndex++;
        
        ratioTargetCount++;
        if (fixedValueFloat == -1) continue;
        ratioTargetCount--;
        
        fixedValuesSum += fixedValueFloat;
        ratioLossValue += ratio;
    }
    
    NSInteger subviewPadding = (int)padding;
    
    CGFloat width = self.bounds.size.width - ((hz)?fixedValuesSum : 0.0);
    CGFloat height = self.bounds.size.height - (topLayoutGuideLength + bottomLayoutGuideLength) - ((hz)?0.0 : fixedValuesSum);
    
    for (UIView *childView in subviewsMutable)
    {
        CGFloat ratio = [ratios[counter] floatValue] + ((ratioLossValue>0)?(ratioLossValue / ratioTargetCount):0.0);
        
        CGFloat fixedValue = -1;
        if (fixedValues.count)
        {
            fixedValue = [fixedValues[counter] floatValue];
        }
        
        CGRect childFrame = CGRectMake((hz)?offsetTracker:0, (hz)?topLayoutGuideLength:offsetTracker, (hz)?(width * ratio) : width, (hz)?height : (height * ratio));
        
        if (fixedValue > -1 && hz)
        {
            childFrame.size.width = fixedValue;
        }
        if (fixedValue > -1 && !hz)
        {
            childFrame.size.height = fixedValue;
        }
        
        childFrame = CGRectIntegral(childFrame);
        
        offsetTracker += (hz)?childFrame.size.width : childFrame.size.height;
        
        childView.frame = CGRectInset(childFrame, subviewPadding, subviewPadding);;
        childView.clipsToBounds = (childView.tag != PCSplitViewDisableClipOnViewTag);
    
        if (childView.tag == PCSplitViewSendToBackAndDisableClipOnViewTag)
        {
            [self sendSubviewToBack:childView];
            childView.clipsToBounds = NO;
        }
        
        counter++;
    }
    
    if (self.preventAnimations) [CATransaction commit];
}

- (void)addSubview:(UIView *)view
{
    [super addSubview:view];
}

- (void)clipViewToEdge:(UIView *)view removeConstraints:(BOOL)removeConstraints
{
    if (removeConstraints)
    {
        for (NSLayoutConstraint *constraint in view.constraints.copy)
        {
            [view removeConstraint:constraint];
        }
    }
}

- (void)snapToSuperview
{
    [self snapToSuperviewRegardingLayoutGuides:NO parentViewController:nil];
}

- (void)snapToSuperviewRegardingLayoutGuides:(BOOL)regardLayoutGuides parentViewController:(UIViewController *)parentViewController;
{
    self.parentViewController = parentViewController;
    
    [self snapToSuperviewRegardingLayoutGuides:regardLayoutGuides paddingLeft:0 paddingRight:0 paddingBottom:0 paddingTop:0];
}

- (void)snapToSuperviewRegardingLayoutGuides:(BOOL)regardLayoutGuides paddingLeft:(CGFloat)paddingLeft paddingRight:(CGFloat)paddingRight paddingBottom:(CGFloat)paddingBottom paddingTop:(CGFloat)paddingTop
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *superview = self.superview;
    
    [superview addConstraints:@[
                                
        [NSLayoutConstraint constraintWithItem:self
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:(regardLayoutGuides) ? (id)self.parentViewController.topLayoutGuide : superview
                                     attribute:(regardLayoutGuides) ?NSLayoutAttributeBottom : NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:paddingTop],
        
        [NSLayoutConstraint constraintWithItem:self
                                     attribute:NSLayoutAttributeLeft
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:superview
                                     attribute:NSLayoutAttributeLeft
                                    multiplier:1.0
                                      constant:paddingLeft],
        
        [NSLayoutConstraint constraintWithItem:self
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:(regardLayoutGuides) ? (id)self.parentViewController.bottomLayoutGuide : superview
                                     attribute:(regardLayoutGuides)?NSLayoutAttributeTop : NSLayoutAttributeBottom
                                    multiplier:1.0
                                      constant:-paddingBottom],
        
        [NSLayoutConstraint constraintWithItem:self
                                     attribute:NSLayoutAttributeRight
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:superview
                                     attribute:NSLayoutAttributeRight
                                    multiplier:1
                                      constant:-paddingRight],
        
    ]];
    
}

- (void)invalidateLayout
{
    self.originalSubviews = nil;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)addEmptySubview
{
    UIView *subview = [[UIView alloc] initWithFrame:CGRectZero];
    subview.tag = PCSplitViewExcludeLayoutViewTag;
    [self addSubview:subview];
}

- (void)addSubviewWithColor:(UIColor *)color
{
    UIView *view = [[UIView alloc] init];
    if (color) view.backgroundColor = color;
    [self addSubview:view];
}

@end
