#import "PCSplitView.h"

@implementation PCSplitView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.subviewRatios.count) return;
    
    [self clipViewToEdge:self];
    
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
        [self clipViewToEdge:childView];
        
        counter++;
    }
}

- (void)clipViewToEdge:(UIView *)view
{
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    view.translatesAutoresizingMaskIntoConstraints = YES;
}

- (void)invalidateLayout
{
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
