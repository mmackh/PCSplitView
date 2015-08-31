#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PCSplitViewDirection)
{
    PCSplitViewDirectionHorizontal,
    PCSplitViewDirectionVertical
};

@interface PCSplitView : UIView

@property (nonatomic,assign) UIViewController *parentViewController;

@property (nonatomic) PCSplitViewDirection splitViewDirection;
@property (nonatomic) NSArray *subviewRatios;
@property (nonatomic) NSArray *subviewFixedValues;

- (void)invalidateLayout;

@end
