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

- (void)snapToSuperviewRegardingLayoutGuides:(BOOL)regardLayoutGuides parentViewController:(UIViewController *)parentViewController;
- (void)invalidateLayout;

@end
