#import <Foundation/Foundation.h>

@interface FPLTeam : NSObject
@property (nonatomic, assign) NSInteger teamID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *shortName;
@property (nonatomic, assign) NSInteger code;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface FPLEvent : NSObject
@property (nonatomic, assign) NSInteger eventID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL dataChecked;
@property (nonatomic, assign) BOOL isCurrent;
@property (nonatomic, assign) BOOL isNext;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end

@interface FPLFixture : NSObject
@property (nonatomic, assign) NSInteger fixtureID;
@property (nonatomic, assign) NSInteger eventID;
@property (nonatomic, assign) NSInteger teamH;
@property (nonatomic, assign) NSInteger teamA;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, copy) NSString *kickoffTime;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
@end
