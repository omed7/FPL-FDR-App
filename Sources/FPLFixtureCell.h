#import <UIKit/UIKit.h>
#import "FPLManager.h"

@interface FPLFixtureCell : UICollectionViewCell

- (void)configureWithFixtures:(NSArray<FPLFixtureDisplay *> *)fixtures;

@end
