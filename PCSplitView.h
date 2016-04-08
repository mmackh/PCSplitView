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

extern NSInteger const PCSplitViewExcludeLayoutViewTag;
extern NSInteger const PCSplitViewDisableClipOnViewTag;

/// Beta Feature, usually on views that are inbetween the nav- or toolbar in order for it to blur the content
extern NSInteger const PCSplitViewSendToBackAndDisableClipOnViewTag;

@interface PCSplitView : UIView

@property (nonatomic,assign) UIViewController *parentViewController;

@property (nonatomic) PCSplitViewDirection splitViewDirection;
@property (nonatomic) NSArray *subviewRatios;
@property (nonatomic) NSArray *subviewFixedValues;

/// Convenience method for layout. Divide individual layouts with commas (,) and divide ratios and fixed values with a star (*), e.g. @"0.5*-1,0.5*-1" to get an equal split between subviews
- (void)setSubviewLayout:(NSString *)subviewLayout direction:(PCSplitViewDirection)splitDirection;

/// Retrieve the subview layout in the parsed string format, same as the one it has been set in. You can retrieve this layout also if the layout has been set through the array accessors.
- (NSString *)subviewLayout;

@property (nonatomic) CGFloat subviewPadding;

@property (nonatomic,assign) BOOL preventAnimations;

- (void)snapToSuperview;
- (void)snapToSuperviewRegardingLayoutGuides:(BOOL)regardLayoutGuides parentViewController:(UIViewController *)parentViewController;
- (void)snapToSuperviewRegardingLayoutGuides:(BOOL)regardLayoutGuides paddingLeft:(CGFloat)paddingLeft paddingRight:(CGFloat)paddingRight paddingBottom:(CGFloat)paddingBottom paddingTop:(CGFloat)paddingTop;

/// Should be called within an animation block to animate subview frame or general subview changes
- (void)invalidateLayout;

/// Add an empty view that doesn't respond to touches and has a clear background
- (void)addEmptySubview;

/// Add a placeholder view, either nil or of a specific background color;
- (void)addSubviewWithColor:(UIColor *)color;

@end
