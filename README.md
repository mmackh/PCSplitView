# PCSplitView
Super powerful layout for iOS, simplified. Express your complicated layout in a few lines without the hassle of Auto Layout.
Ratio changes can easily be animated, and SplitViews can be stacked within one another.

*Notes:*
- Ratios must always equal 1
- Initial PCSplitView must have a frame
- FixedValues must either equal the number of ratios and subviews, or be omitted completely

```
- (void)setup
{
    PCSplitView *containerSplitView = [[PCSplitView alloc] initWithFrame:self.view.bounds];
    containerSplitView.splitViewDirection = PCSplitViewDirectionHorizontal;
    containerSplitView.subviewRatios = @[@(0.1),@(0.9)];
    containerSplitView.subviewFixedValues = @[@(1),@(-1)];
    
    UIView *hairline = [[UIView alloc] init];
    hairline.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    [containerSplitView addSubview:hairline];
    
    PCSplitView *subContainerSplit = [[PCSplitView alloc] init];
    subContainerSplit.subviewRatios = @[@(.5),@(.5)];
    UIView *c1 = [[UIView alloc] init];
    c1.backgroundColor = [UIColor redColor];
    [subContainerSplit addSubview:c1];
    UIView *c2 = [[UIView alloc] init];
    c2.backgroundColor = [UIColor greenColor];
    [subContainerSplit addSubview:c2];
    [containerSplitView addSubview:subContainerSplit];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moveSplit)];
    [subContainerSplit addGestureRecognizer:tap];
    
    [self.view addSubview:containerSplitView];
    
    _containerSplitView = containerSplitView;
}

- (void)moveSplit
{
    _containerSplitView.subviewFixedValues = @[@(-1),@(-1)];
    _containerSplitView.subviewRatios = @[@(0.5),@(0.5)];
    
    [UIView animateWithDuration:.4 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:1.0 options:0 animations:^
     {
         [_containerSplitView invalidateLayout];
    } completion:nil];
}
