#import "FPLTheme.h"

@implementation FPLTheme

+ (UIColor *)colorForDifficulty:(NSInteger)difficulty {
    switch (difficulty) {
        case 1: return [UIColor colorWithRed:0.0 green:0.4 blue:0.1 alpha:1.0]; // Deep Green
        case 2: return [UIColor colorWithRed:0.2 green:0.8 blue:0.3 alpha:1.0]; // Light Green
        case 3: return [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]; // Light Grey
        case 4: return [UIColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0]; // Light Red
        case 5: return [UIColor colorWithRed:0.9 green:0.1 blue:0.1 alpha:1.0]; // Standard Red
        case 6: return [UIColor colorWithRed:0.6 green:0.0 blue:0.1 alpha:1.0]; // Dark Red
        case 7: return [UIColor colorWithRed:0.3 green:0.0 blue:0.0 alpha:1.0]; // Extreme Dark Red
        default: return [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]; // Default Light Grey
    }
}

+ (UIColor *)contrastTextColorForBackgroundColor:(UIColor *)backgroundColor {
    // Simple heuristic
    CGFloat r, g, b, a;
    [backgroundColor getRed:&r green:&g blue:&b alpha:&a];

    // Calculate brightness
    CGFloat brightness = ((r * 299) + (g * 587) + (b * 114)) / 1000;

    if (brightness > 0.5) {
        return [UIColor blackColor];
    } else {
        return [UIColor whiteColor];
    }
}

@end
