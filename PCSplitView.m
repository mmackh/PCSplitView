#import "PCSplitView.h"

@implementation PCSplitView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.subviewRatios.count) return;
    
    BOOL hz = (self.splitViewDirection == PCSplitViewDirectionHorizontal);
    
    CGFloat topLayoutGuideLength = (self.parentViewController) ? self.parentViewController.topLayoutGuide.length : 0.0;
    CGFloat bottomLayoutGuideLength = (self.parentViewController) ? self.parentViewController.bottomLayoutGuide.length : 0.0;
    
    NSInteger counter = 0;
    CGFloat offsetTracker = (hz)?0.0:topLayoutGuideLength;
    
    NSInteger ratioTargetCount = 0;
    NSInteger ratioLossIndex = 0;
    CGFloat ratioLossValue = 0.0;
    
    CGFloat fixedValuesSum = 0.0;
    for (NSNumber *fixedValue in self.subviewFixedValues)
    {
        CGFloat fixedValueFloat = [fixedValue floatValue];
        CGFloat ratio = [self.subviewRatios[ratioLossIndex] floatValue];
        ratioLossIndex++;
        
        ratioTargetCount++;
        if (fixedValueFloat == -1) continue;
        ratioTargetCount--;
        
        fixedValuesSum += fixedValueFloat;
        ratioLossValue += ratio;
    }
    
    CGFloat width = self.bounds.size.width - ((hz)?fixedValuesSum : 0.0);
    CGFloat height = self.bounds.size.height - (topLayoutGuideLength + bottomLayoutGuideLength) - ((hz)?0.0 : fixedValuesSum);
    
    for (UIView *childView in self.subviews)
    {
        CGFloat ratio = [self.subviewRatios[counter] floatValue] + ((ratioLossValue>0)?(ratioLossValue / ratioTargetCount):0.0);
        
        CGFloat fixedValue = -1;
        if (self.subviewFixedValues.count)
        {
            fixedValue = [self.subviewFixedValues[counter] floatValue];
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
        
        childView.frame = childFrame;
        childView.clipsToBounds = YES;
        [self clipViewToEdge:childView removeConstraints:NO];
        
        counter++;
    }
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
    
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    view.translatesAutoresizingMaskIntoConstraints = YES;
}

- (void)snapToSuperviewRegardingLayoutGuides:(BOOL)regardLayoutGuides parentViewController:(UIViewController *)parentViewController;
{
    self.parentViewController = parentViewController;
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.superview attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f]];
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.superview attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f]];
    
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:(regardLayoutGuides)?(id)self.parentViewController.topLayoutGuide : self.superview attribute:(regardLayoutGuides)?NSLayoutAttributeBottom:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:(regardLayoutGuides)?(id)self.parentViewController.bottomLayoutGuide : self.superview attribute:(regardLayoutGuides)?NSLayoutAttributeTop:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f]];
}

- (void)invalidateLayout
{
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
