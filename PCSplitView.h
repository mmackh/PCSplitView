//
//  PCSplitView.h
//  Ordervisto
//
//  Created by Maximilian Mackh on 30/08/15.
//  Copyright © 2015 Professional Consulting & Trading GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PCSplitViewDirection)
{
    PCSplitViewDirectionHorizontal,
    PCSplitViewDirectionVertical
};

@class PCSplitViewLayoutInstruction;

extern NSInteger const PCSplitViewExcludeLayoutViewTag;
extern NSInteger const PCSplitViewDisableClipOnViewTag;

/// Beta Feature, usually on views that are inbetween the nav- or toolbar in order for it to blur the content
extern NSInteger const PCSplitViewSendToBackAndDisableClipOnViewTag;

@interface PCSplitView : UIView

@property (nonatomic,assign) UIViewController *parentViewController;
@property (nonatomic,assign) BOOL disregardTopLayoutGuide;
@property (nonatomic,assign) BOOL disregardBottomLayoutGuide;

@property (nonatomic) PCSplitViewDirection splitViewDirection;
@property (nonatomic) NSArray *subviewRatios;
@property (nonatomic) NSArray *subviewFixedValues;

/// Markup Explanation: 0.5*-1 => 50% of superview, 0*15 => 15pt exactly, 0*-2 => Automatic UILabel Sizing
+ (instancetype)splitViewWithLayoutHandler:(PCSplitViewLayoutInstruction *(^)(CGRect parentViewBounds))layoutHandler configurationHandler:(void(^)(PCSplitView *splitView))configurationHandler;

+ (instancetype)splitViewWithSubviewLayout:(NSString *)subviewLayout direction:(PCSplitViewDirection)splitDirection configurationHandler:(void(^)(PCSplitView *splitView))configurationHandler;

/// Convenience method for layout. Divide individual layouts with commas (,) and divide ratios and fixed values with a star (*), e.g. @"0.5*-1,0.5*-1" to get an equal split between subviews. For automatic UILabel sizing use 0*-2;
- (void)setSubviewLayout:(NSString *)subviewLayout direction:(PCSplitViewDirection)splitDirection;

/// Retrieve the subview layout in the parsed string format, same as the one it has been set in. You can retrieve this layout also if the layout has been set through the array accessors.
- (NSString *)subviewLayout;

/// Cached Subview Layout that is the same as the one that has been set
@property (nonatomic,readonly) NSString *cachedSubviewLayout;

@property (nonatomic) CGFloat subviewPadding;

@property (nonatomic,assign) BOOL preventAnimations;

- (void)snapToSuperview;
- (void)snapToSuperviewRegardingLayoutGuides:(BOOL)regardLayoutGuides parentViewController:(UIViewController *)parentViewController;
- (void)snapToSuperviewRegardingLayoutGuides:(BOOL)regardLayoutGuides paddingLeft:(CGFloat)paddingLeft paddingRight:(CGFloat)paddingRight paddingBottom:(CGFloat)paddingBottom paddingTop:(CGFloat)paddingTop;

/// Should be called within an animation block to animate subview frame or general subview changes
- (void)invalidateLayout;

/// Add an empty view that doesn't respond to touches and has a clear background
- (UIView *)addEmptySubview;

/// Add a placeholder view, either nil or of a specific background color;
- (void)addSubviewWithColor:(UIColor *)color;

/// Add child split views conveniently
- (instancetype)addSplitViewWithLayoutHandler:(PCSplitViewLayoutInstruction *(^)(CGRect parentViewBounds))layoutHandler configurationHandler:(void(^)(PCSplitView *splitView))configurationHandler;

@property (nonatomic,copy) void(^willLayoutSubviews)(void);
@property (nonatomic,copy) void(^didLayoutSubviews)(void);

@property (nonatomic,copy) PCSplitViewLayoutInstruction *(^layoutHandler)(CGRect parentViewBounds);

/// Suggests an inset value for parent container views to account for the overlap a notch would cause. In case of no notch or portrait layout a default value of 15.0f is returned
+ (CGFloat)suggestedParentHorizontalInset;

/// Get the approx. height of the view from static elements in the subviewLayout
@property (nonatomic,readonly) CGFloat estimatedFixedHeight;

@end

@interface PCSplitViewLayoutInstruction : NSObject

+ (instancetype)instructionWithSubviewLayout:(NSString *)subviewLayout direction:(PCSplitViewDirection)direction;

@property (nonatomic,readonly) NSString *subviewLayout;
@property (nonatomic,readonly) PCSplitViewDirection direction;

@end
