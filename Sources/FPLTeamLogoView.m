#import "FPLTeamLogoView.h"

@interface FPLTeamLogoView ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *fallbackLabel;
@property (nonatomic, strong) UIView *fallbackCircle;
@end

@implementation FPLTeamLogoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    _fallbackCircle = [[UIView alloc] initWithFrame:self.bounds];
    _fallbackCircle.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.3];
    _fallbackCircle.layer.cornerRadius = self.bounds.size.width / 2;
    _fallbackCircle.clipsToBounds = YES;
    _fallbackCircle.hidden = YES;
    _fallbackCircle.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_fallbackCircle];

    _fallbackLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _fallbackLabel.textAlignment = NSTextAlignmentCenter;
    _fallbackLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    _fallbackLabel.textColor = [UIColor labelColor];
    _fallbackLabel.hidden = YES;
    _fallbackLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_fallbackLabel];

    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_imageView];
}

- (void)setTeamShortName:(NSString *)teamShortName {
    _teamShortName = [teamShortName copy];

    UIImage *image = [UIImage imageNamed:teamShortName.lowercaseString];
    if (image) {
        self.imageView.image = image;
        self.imageView.hidden = NO;
        self.fallbackCircle.hidden = YES;
        self.fallbackLabel.hidden = YES;
    } else {
        self.imageView.hidden = YES;
        self.fallbackCircle.hidden = NO;
        self.fallbackLabel.hidden = NO;
        self.fallbackLabel.text = teamShortName;
        self.fallbackCircle.layer.cornerRadius = self.bounds.size.width / 2;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.fallbackCircle.layer.cornerRadius = self.bounds.size.width / 2;
}

@end
