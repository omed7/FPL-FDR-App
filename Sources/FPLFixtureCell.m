#import "FPLFixtureCell.h"
#import "FPLTheme.h"

@implementation FPLFixtureCell {
    UIStackView *_stackView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.contentView.layer.borderWidth = 0.5;
    self.contentView.layer.borderColor = [UIColor separatorColor].CGColor;

    _stackView = [[UIStackView alloc] init];
    _stackView.axis = UILayoutConstraintAxisVertical;
    _stackView.distribution = UIStackViewDistributionFillEqually;
    _stackView.spacing = 2;
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_stackView];

    [NSLayoutConstraint activateConstraints:@[
        [_stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [_stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [_stackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [_stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
    ]];
}

- (void)configureWithFixtures:(NSArray<FPLFixtureDisplay *> *)fixtures {
    // Clear old
    for (UIView *v in _stackView.arrangedSubviews) {
        [v removeFromSuperview];
    }

    if (fixtures.count == 0) {
        // BLANK
        UILabel *label = [[UILabel alloc] init];
        label.text = @"-";
        label.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
        label.textColor = [UIColor systemGrayColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2];
        [_stackView addArrangedSubview:label];
    } else {
        for (FPLFixtureDisplay *fd in fixtures) {
            UIView *container = [[UIView alloc] init];
            UIColor *bgColor = [FPLTheme colorForDifficulty:fd.difficulty];
            UIColor *textColor = [FPLTheme contrastTextColorForBackgroundColor:bgColor];
            container.backgroundColor = bgColor;
            container.layer.cornerRadius = 4;
            container.clipsToBounds = YES;

            UILabel *oppLabel = [[UILabel alloc] init];
            oppLabel.text = fd.opponentShortName;
            oppLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
            oppLabel.textColor = textColor;
            oppLabel.textAlignment = NSTextAlignmentCenter;

            UILabel *locLabel = [[UILabel alloc] init];
            locLabel.text = fd.isHome ? @"(H)" : @"(A)";
            locLabel.font = [UIFont systemFontOfSize:10];
            locLabel.textColor = [textColor colorWithAlphaComponent:0.8];
            locLabel.textAlignment = NSTextAlignmentCenter;

            UIStackView *vStack = [[UIStackView alloc] initWithArrangedSubviews:@[oppLabel, locLabel]];
            vStack.axis = UILayoutConstraintAxisVertical;
            vStack.alignment = UIStackViewAlignmentCenter;
            vStack.spacing = 0;
            vStack.translatesAutoresizingMaskIntoConstraints = NO;
            [container addSubview:vStack];

            [NSLayoutConstraint activateConstraints:@[
                [vStack.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
                [vStack.centerYAnchor constraintEqualToAnchor:container.centerYAnchor]
            ]];

            [_stackView addArrangedSubview:container];
        }
    }
}

@end
