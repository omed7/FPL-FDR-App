#import "FPLModels.h"

@implementation FPLTeam

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _teamID = [dict[@"id"] integerValue];
        _name = [dict[@"name"] copy];
        _shortName = [dict[@"short_name"] copy];
        _code = [dict[@"code"] integerValue];
    }
    return self;
}

@end

@implementation FPLEvent

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _eventID = [dict[@"id"] integerValue];
        _name = [dict[@"name"] copy];
        _finished = [dict[@"finished"] boolValue];
        _dataChecked = [dict[@"data_checked"] boolValue];
        _isCurrent = [dict[@"is_current"] boolValue];
        _isNext = [dict[@"is_next"] boolValue];
    }
    return self;
}

@end

@implementation FPLFixture

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _fixtureID = [dict[@"id"] integerValue];
        if (dict[@"event"] && ![dict[@"event"] isEqual:[NSNull null]]) {
            _eventID = [dict[@"event"] integerValue];
        } else {
            _eventID = 0;
        }
        _teamH = [dict[@"team_h"] integerValue];
        _teamA = [dict[@"team_a"] integerValue];
        _finished = [dict[@"finished"] boolValue];
        if (dict[@"kickoff_time"] && ![dict[@"kickoff_time"] isEqual:[NSNull null]]) {
            _kickoffTime = [dict[@"kickoff_time"] copy];
        }
    }
    return self;
}

@end
