#import <UIKit/UIKit.h>

@interface FPLTheme : NSObject

+ (UIColor *)colorForDifficulty:(NSInteger)difficulty;
+ (UIColor *)contrastTextColorForBackgroundColor:(UIColor *)backgroundColor;

@end
