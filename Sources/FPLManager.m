#import "FPLManager.h"

@implementation FPLFixtureDisplay
@end

@interface FPLManager ()

@property (nonatomic, strong) NSArray<FPLTeam *> *teams;
@property (nonatomic, strong) NSArray<FPLEvent *> *events;
@property (nonatomic, strong) NSArray<FPLFixture *> *fixtures;

@property (nonatomic, strong) NSMutableDictionary *teamDifficultyRatings; // TeamID -> @{@"home": @(int), @"away": @(int)}
@property (nonatomic, strong) NSMutableDictionary *teamVisibility; // TeamID -> @(BOOL)
@property (nonatomic, strong) NSDictionary *teamMap;
@property (nonatomic, strong) NSDictionary *fixturesByTeamAndEvent; // TeamID -> EventID -> [Fixture]
@property (nonatomic, strong) NSISO8601DateFormatter *dateFormatter;

@end

@implementation FPLManager

+ (instancetype)sharedManager {
    static FPLManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FPLManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _startGameweek = 1;
        _endGameweek = 38;
        _sortByEase = NO;
        _teamDifficultyRatings = [NSMutableDictionary dictionary];
        _teamVisibility = [NSMutableDictionary dictionary];

        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
        _dateFormatter.formatOptions = NSISO8601DateFormatWithInternetDateTime;

        [self loadPreferences];
    }
    return self;
}

#pragma mark - Data Fetching

- (void)fetchDataWithCompletion:(void (^)(NSError *error))completion {
    NSURL *teamsUrl = [NSURL URLWithString:@"https://fantasy.premierleague.com/api/bootstrap-static/"];
    NSURL *fixturesUrl = [NSURL URLWithString:@"https://fantasy.premierleague.com/api/fixtures/"];

    dispatch_group_t group = dispatch_group_create();

    __block NSError *fetchError = nil;
    __block NSDictionary *bootstrapData = nil;
    __block NSArray *fixturesData = nil;

    dispatch_group_enter(group);
    [[NSURLSession.sharedSession dataTaskWithURL:teamsUrl completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            fetchError = error;
        } else {
            bootstrapData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) fetchError = error;
        }
        dispatch_group_leave(group);
    }] resume];

    dispatch_group_enter(group);
    [[NSURLSession.sharedSession dataTaskWithURL:fixturesUrl completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            fetchError = error;
        } else {
            fixturesData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) fetchError = error;
        }
        dispatch_group_leave(group);
    }] resume];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (fetchError) {
            completion(fetchError);
        } else {
            [self processBootstrap:bootstrapData fixtures:fixturesData];
            completion(nil);
        }
    });
}

- (void)processBootstrap:(NSDictionary *)bootstrap fixtures:(NSArray *)fixturesList {
    NSMutableArray *teams = [NSMutableArray array];
    for (NSDictionary *d in bootstrap[@"teams"]) {
        [teams addObject:[[FPLTeam alloc] initWithDictionary:d]];
    }
    self.teams = teams;

    NSMutableArray *events = [NSMutableArray array];
    for (NSDictionary *d in bootstrap[@"events"]) {
        FPLEvent *e = [[FPLEvent alloc] initWithDictionary:d];
        if (!e.finished) {
            [events addObject:e];
        }
    }
    self.events = events;

    NSMutableArray *fixtures = [NSMutableArray array];
    for (NSDictionary *d in fixturesList) {
        [fixtures addObject:[[FPLFixture alloc] initWithDictionary:d]];
    }
    self.fixtures = fixtures;

    // Map Teams
    NSMutableDictionary *tm = [NSMutableDictionary dictionary];
    for (FPLTeam *t in self.teams) {
        tm[@(t.teamID)] = t;

        // Init Defaults
        if (!self.teamDifficultyRatings[@(t.teamID)]) {
            self.teamDifficultyRatings[@(t.teamID)] = [NSMutableDictionary dictionaryWithDictionary:@{@"home": @3, @"away": @3}];
        }
        if (!self.teamVisibility[@(t.teamID)]) {
            self.teamVisibility[@(t.teamID)] = @YES;
        }
    }
    self.teamMap = tm;

    // Process Fixtures Lookup
    NSMutableDictionary *lookup = [NSMutableDictionary dictionary];

    for (FPLFixture *f in self.fixtures) {
        if (f.eventID == 0) continue;

        // Home
        if (!lookup[@(f.teamH)]) lookup[@(f.teamH)] = [NSMutableDictionary dictionary];
        if (!lookup[@(f.teamH)][@(f.eventID)]) lookup[@(f.teamH)][@(f.eventID)] = [NSMutableArray array];
        [lookup[@(f.teamH)][@(f.eventID)] addObject:f];

        // Away
        if (!lookup[@(f.teamA)]) lookup[@(f.teamA)] = [NSMutableDictionary dictionary];
        if (!lookup[@(f.teamA)][@(f.eventID)]) lookup[@(f.teamA)][@(f.eventID)] = [NSMutableArray array];
        [lookup[@(f.teamA)][@(f.eventID)] addObject:f];
    }
    self.fixturesByTeamAndEvent = lookup;

    // Set Start/End
    if (self.events.count > 0) {
        NSInteger firstActive = [self.events.firstObject eventID];
        if (self.startGameweek < firstActive) {
            self.startGameweek = firstActive;
        }
    }
    if (self.endGameweek > 38) self.endGameweek = 38;
    if (self.startGameweek > self.endGameweek) self.startGameweek = self.endGameweek;
}

#pragma mark - Logic

- (NSArray<FPLTeam *> *)getSortedTeams {
    NSMutableArray *visibleTeams = [NSMutableArray array];
    for (FPLTeam *t in self.teams) {
        if ([self isTeamVisible:t.teamID]) {
            [visibleTeams addObject:t];
        }
    }

    if (self.sortByEase) {
        [visibleTeams sortUsingComparator:^NSComparisonResult(FPLTeam *obj1, FPLTeam *obj2) {
            double avg1 = [self calculateAverageFDRForTeam:obj1.teamID];
            double avg2 = [self calculateAverageFDRForTeam:obj2.teamID];
            if (avg1 < avg2) return NSOrderedAscending;
            if (avg1 > avg2) return NSOrderedDescending;
            return NSOrderedSame;
        }];
    } else {
        [visibleTeams sortUsingComparator:^NSComparisonResult(FPLTeam *obj1, FPLTeam *obj2) {
            if (obj1.teamID < obj2.teamID) return NSOrderedAscending;
            return NSOrderedDescending;
        }];
    }
    return visibleTeams;
}

- (double)calculateAverageFDRForTeam:(NSInteger)teamID {
    double total = 0;
    int count = 0;

    for (NSInteger gw = self.startGameweek; gw <= self.endGameweek; gw++) {
        NSArray *fixtures = [self getFixturesForTeam:teamID gameweek:gw];
        for (FPLFixtureDisplay *fd in fixtures) {
            total += fd.difficulty;
            count++;
        }
    }

    if (count == 0) return 0.0;
    return total / count;
}

- (NSArray<FPLFixtureDisplay *> *)getFixturesForTeam:(NSInteger)teamID gameweek:(NSInteger)gameweek {
    NSDictionary *gwFixtures = self.fixturesByTeamAndEvent[@(teamID)];
    if (!gwFixtures) return @[];
    NSArray *fixtures = gwFixtures[@(gameweek)];
    if (!fixtures) return @[];

    NSMutableArray *result = [NSMutableArray array];

    for (FPLFixture *f in fixtures) {
        BOOL isHome = (f.teamH == teamID);
        NSInteger opponentID = isHome ? f.teamA : f.teamH;
        FPLTeam *opponent = self.teamMap[@(opponentID)];

        BOOL opponentIsHome = !isHome;
        NSInteger strength = [self getStrengthForTeam:opponentID location:opponentIsHome ? @"home" : @"away"];

        FPLFixtureDisplay *fd = [[FPLFixtureDisplay alloc] init];
        fd.fixtureID = f.fixtureID;
        fd.opponentID = opponentID;
        fd.opponentShortName = opponent ? opponent.shortName : @"UNK";
        fd.difficulty = strength;
        fd.isHome = isHome;
        fd.date = [self.dateFormatter dateFromString:f.kickoffTime ?: @""];

        [result addObject:fd];
    }

    [result sortUsingComparator:^NSComparisonResult(FPLFixtureDisplay *obj1, FPLFixtureDisplay *obj2) {
        return [obj1.date compare:obj2.date];
    }];

    return result;
}

- (NSInteger)getStrengthForTeam:(NSInteger)teamID location:(NSString *)location {
    NSDictionary *ratings = self.teamDifficultyRatings[@(teamID)];
    if (ratings) {
        return [ratings[location] integerValue];
    }
    return 3;
}

- (void)updateStrengthForTeam:(NSInteger)teamID location:(NSString *)location value:(NSInteger)value {
    if (!self.teamDifficultyRatings[@(teamID)]) {
        self.teamDifficultyRatings[@(teamID)] = [NSMutableDictionary dictionaryWithDictionary:@{@"home": @3, @"away": @3}];
    }
    self.teamDifficultyRatings[@(teamID)][location] = @(value);
    [self savePreferences];
}

- (void)toggleVisibilityForTeam:(NSInteger)teamID {
    BOOL current = [self isTeamVisible:teamID];
    self.teamVisibility[@(teamID)] = @(!current);
    [self savePreferences];
}

- (BOOL)isTeamVisible:(NSInteger)teamID {
    NSNumber *val = self.teamVisibility[@(teamID)];
    return val ? [val boolValue] : YES;
}

#pragma mark - Persistence

- (void)savePreferences {
    [[NSUserDefaults standardUserDefaults] setObject:self.teamDifficultyRatings forKey:@"FPL_TeamRatings"];
    [[NSUserDefaults standardUserDefaults] setObject:self.teamVisibility forKey:@"FPL_TeamVisibility"];
    [[NSUserDefaults standardUserDefaults] setBool:self.sortByEase forKey:@"FPL_SortByEase"];
    [[NSUserDefaults standardUserDefaults] setInteger:self.startGameweek forKey:@"FPL_StartGW"];
    [[NSUserDefaults standardUserDefaults] setInteger:self.endGameweek forKey:@"FPL_EndGW"];
}

- (void)loadPreferences {
    NSDictionary *ratings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"FPL_TeamRatings"];
    if (ratings) {
        // Deep mutable copy needed
        NSMutableDictionary *mutableRatings = [NSMutableDictionary dictionary];
        for (NSNumber *key in ratings) {
            mutableRatings[key] = [ratings[key] mutableCopy];
        }
        self.teamDifficultyRatings = mutableRatings;
    }

    NSDictionary *vis = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"FPL_TeamVisibility"];
    if (vis) {
        self.teamVisibility = [vis mutableCopy];
    }

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"FPL_SortByEase"]) {
        self.sortByEase = [[NSUserDefaults standardUserDefaults] boolForKey:@"FPL_SortByEase"];
    }

    NSInteger start = [[NSUserDefaults standardUserDefaults] integerForKey:@"FPL_StartGW"];
    if (start > 0) self.startGameweek = start;

    NSInteger end = [[NSUserDefaults standardUserDefaults] integerForKey:@"FPL_EndGW"];
    if (end > 0) self.endGameweek = end;
}

@end
