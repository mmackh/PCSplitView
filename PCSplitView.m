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
@property (nonatomic,readwrite) NSString *cachedSubviewLayout;

@property (nonatomic) CGRect boundsCache;
@property (nonatomic) BOOL layoutParsed;

@property (nonatomic) CGFloat onePixelHeight;

@end

@implementation PCSplitView

+ (instancetype)splitViewWithLayoutHandler:(PCSplitViewLayoutInstruction *(^)(CGRect))layoutHandler configurationHandler:(void (^)(PCSplitView *))configurationHandler
{
    PCSplitView *splitView = [self splitViewWithSubviewLayout:@"" direction:PCSplitViewDirectionHorizontal configurationHandler:configurationHandler];
    splitView.layoutHandler = layoutHandler;
    return splitView;
}

+ (instancetype)splitViewWithSubviewLayout:(NSString *)subviewLayout direction:(PCSplitViewDirection)splitDirection configurationHandler:(void(^)(PCSplitView *splitView))configurationHandler
{
    PCSplitView *splitView = [[self class] new];
    [splitView setSubviewLayout:subviewLayout direction:splitDirection];
    __weak typeof(splitView) weakSplitView = splitView;
    if (configurationHandler) configurationHandler(weakSplitView);
    return splitView;
}

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;
    
    self.onePixelHeight = 1/[UIScreen mainScreen].scale;
    
    return self;
}

- (void)setSubviewLayout:(NSString *)subviewLayout direction:(PCSplitViewDirection)splitDirection
{
    if (self.splitViewDirection != splitDirection || ![self.cachedSubviewLayout isEqualToString:subviewLayout])
    {
        self.layoutParsed = NO;
    }
    
    self.splitViewDirection = splitDirection;
    self.cachedSubviewLayout = subviewLayout;
    
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
    if (self.willLayoutSubviews) self.willLayoutSubviews();
    
    if (self.preventAnimations)
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    
    [super layoutSubviews];
    
    if (self.layoutHandler)
    {
        PCSplitViewLayoutInstruction *instruction = self.layoutHandler(self.superview.bounds);
        [self setSubviewLayout:instruction.subviewLayout direction:instruction.direction];
    }
    
    if (CGRectEqualToRect(self.boundsCache, self.bounds) && self.layoutParsed)
    {
        // Disable Prevent Animations
        if (self.preventAnimations) [CATransaction commit];
        return;
    }
    self.boundsCache = self.bounds;
    self.layoutParsed = YES;
        
    if (!self.originalSubviews || self.originalSubviews.count != self.subviews.count) self.originalSubviews = self.subviews;
    
    NSMutableArray *subviewsMutable = [NSMutableArray new];
    for (UIView *subview in self.originalSubviews)
    {
        if (subview.tag == PCSplitViewExcludeLayoutViewTag) continue;
        [subviewsMutable addObject:subview];
    }
    
    if (!self.subviewRatios.count) return;
    
    BOOL hz = (self.splitViewDirection == PCSplitViewDirectionHorizontal);
    
    CGFloat topLayoutGuideLength = (self.parentViewController && !self.disregardTopLayoutGuide) ? self.parentViewController.topLayoutGuide.length : 0.0;
    CGFloat bottomLayoutGuideLength = (self.parentViewController && !self.disregardBottomLayoutGuide) ? self.parentViewController.bottomLayoutGuide.length : 0.0;
    
    NSMutableArray *fixedValuesMutable = self.subviewFixedValues.mutableCopy;
    NSArray *ratios = self.subviewRatios;
    CGFloat padding = self.subviewPadding;
    
    NSInteger counter = 0;
    CGFloat offsetTracker = (hz)?0.0:topLayoutGuideLength;
    
    NSInteger ratioTargetCount = 0;
    NSInteger ratioLossIndex = 0;
    CGFloat ratioLossValue = 0.0;
    
    CGFloat fixedValuesSum = 0.0;
    
    for (NSNumber *fixedValue in fixedValuesMutable.copy)
    {
        CGFloat fixedValueFloat = [fixedValue floatValue];
        CGFloat ratio = [ratios[ratioLossIndex] floatValue];
        ratioLossIndex++;
        
        ratioTargetCount++;
        if (fixedValueFloat == -1) continue;
        ratioTargetCount--;
        
        // Automatic label loss calculation
        if (fixedValueFloat < -1)
        {
            NSInteger idx = ratioLossIndex - 1;
            id label = (id)[subviewsMutable objectAtIndex:idx];
            
            CGFloat additionalPadding = 0.0;
            if ([label isKindOfClass:[UIButton class]])
            {
                UIButton *button = label;
                additionalPadding += (hz) ? (button.titleEdgeInsets.left + button.titleEdgeInsets.right) : (button.titleEdgeInsets.bottom + button.titleEdgeInsets.top);
            }
            CGSize labelDimensions = [label sizeThatFits:CGSizeMake(hz?CGFLOAT_MAX:self.bounds.size.width, hz?self.bounds.size.height:CGFLOAT_MAX)];
            fixedValueFloat = (hz) ? labelDimensions.width : labelDimensions.height;
            fixedValueFloat += additionalPadding;
            fixedValuesMutable[idx] = @(fixedValueFloat);
        }
        
        if (fixedValueFloat < 1.0 && fixedValueFloat > 0.0)
        {
            fixedValueFloat = self.onePixelHeight;
        }
        
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
        if (fixedValuesMutable.count)
        {
            fixedValue = [fixedValuesMutable[counter] floatValue];
        }
        
        if (fixedValue < 1.0 && fixedValue > 0.0)
        {
            fixedValue = self.onePixelHeight;
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
        
        offsetTracker += (hz)?childFrame.size.width : childFrame.size.height;
        
        childView.frame = CGRectInset(childFrame, subviewPadding, subviewPadding);
        
#if !TARGET_OS_MACCATALYST
        childView.clipsToBounds = (childView.tag != PCSplitViewDisableClipOnViewTag);
#endif
    
        if (childView.tag == PCSplitViewSendToBackAndDisableClipOnViewTag)
        {
            [self sendSubviewToBack:childView];
            childView.clipsToBounds = NO;
        }
        
        counter++;
    }
    
    if (self.preventAnimations) [CATransaction commit];
    
    if (self.didLayoutSubviews) self.didLayoutSubviews();
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
    self.frame = self.superview.bounds;
    self.translatesAutoresizingMaskIntoConstraints = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
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
                                     attribute:(regardLayoutGuides) ? NSLayoutAttributeBottom : NSLayoutAttributeTop
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
                                     attribute:(regardLayoutGuides) ? NSLayoutAttributeTop : NSLayoutAttributeBottom
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
    self.layoutParsed = NO;
    
    self.originalSubviews = nil;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (UIView *)addEmptySubview
{
    UIView *subview = [[UIView alloc] initWithFrame:CGRectZero];
    [self addSubview:subview];
    return subview;
}

- (void)addSubviewWithColor:(UIColor *)color
{
    UIView *view = [[UIView alloc] init];
    if (color) view.backgroundColor = color;
    [self addSubview:view];
}

- (instancetype)addSplitViewWithLayoutHandler:(PCSplitViewLayoutInstruction *(^)(CGRect parentViewBounds))layoutHandler configurationHandler:(void(^)(PCSplitView *splitView))configurationHandler
{
    PCSplitView *splitView = [PCSplitView splitViewWithLayoutHandler:layoutHandler configurationHandler:configurationHandler];
    [self addSubview:splitView];
    return splitView;
}

+ (CGFloat)suggestedParentHorizontalInset
{
    CGFloat horizontalInset = 15;
    if (@available(iOS 11.0, *))
    {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        horizontalInset = (window.safeAreaInsets.left > 0) ? window.safeAreaInsets.left : horizontalInset;
    }
    return horizontalInset;
}

- (CGFloat)estimatedFixedHeight
{
    CGFloat estimatedFixedHeight = 0.0;
    
    for (NSNumber *fixedValue in self.subviewFixedValues)
    {
        estimatedFixedHeight += [fixedValue floatValue];
    }
    
    if (self.subviewPadding)
    {
        estimatedFixedHeight += 2*self.subviewPadding;
    }
        
    return estimatedFixedHeight;
}

@end

@interface PCSplitViewLayoutInstruction ()

@property (nonatomic,readwrite) NSString *subviewLayout;
@property (nonatomic,readwrite) PCSplitViewDirection direction;

@end

@implementation PCSplitViewLayoutInstruction

+ (instancetype)instructionWithSubviewLayout:(NSString *)subviewLayout direction:(PCSplitViewDirection)direction
{
    PCSplitViewLayoutInstruction *instruction = [PCSplitViewLayoutInstruction new];
    instruction.subviewLayout = subviewLayout;
    instruction.direction = direction;
    return instruction;
}

@end
