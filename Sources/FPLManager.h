#import <Foundation/Foundation.h>
#import "FPLModels.h"

@interface FPLFixtureDisplay : NSObject
@property (nonatomic, assign) NSInteger fixtureID;
@property (nonatomic, assign) NSInteger opponentID;
@property (nonatomic, copy) NSString *opponentShortName;
@property (nonatomic, assign) NSInteger difficulty;
@property (nonatomic, assign) BOOL isHome;
@property (nonatomic, strong) NSDate *date;
@end

@interface FPLManager : NSObject

@property (nonatomic, strong, readonly) NSArray<FPLTeam *> *teams;
@property (nonatomic, strong, readonly) NSArray<FPLEvent *> *events;
@property (nonatomic, strong, readonly) NSArray<FPLFixture *> *fixtures;

// Settings
@property (nonatomic, assign) NSInteger startGameweek;
@property (nonatomic, assign) NSInteger endGameweek;
@property (nonatomic, assign) BOOL sortByEase;

+ (instancetype)sharedManager;

- (void)fetchDataWithCompletion:(void (^)(NSError *error))completion;

- (NSArray<FPLTeam *> *)getSortedTeams;
- (NSArray<FPLFixtureDisplay *> *)getFixturesForTeam:(NSInteger)teamID gameweek:(NSInteger)gameweek;
- (double)calculateAverageFDRForTeam:(NSInteger)teamID;

- (NSInteger)getStrengthForTeam:(NSInteger)teamID location:(NSString *)location;
- (void)updateStrengthForTeam:(NSInteger)teamID location:(NSString *)location value:(NSInteger)value;
- (void)toggleVisibilityForTeam:(NSInteger)teamID;
- (BOOL)isTeamVisible:(NSInteger)teamID;

@end
