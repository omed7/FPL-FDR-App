#import "FPLMainViewController.h"
#import "FPLManager.h"
#import "FPLTeamLogoView.h"
#import "FPLFixtureCell.h"
#import "FPLSettingsViewController.h"
#import "FPLTheme.h"

#pragma mark - Header View

@interface GridHeaderView : UIView
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;
- (void)configureWithStartGW:(NSInteger)start endGW:(NSInteger)end;
@end

@implementation GridHeaderView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor secondarySystemBackgroundColor];

        UILabel *teamLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        teamLabel.text = @"Team";
        teamLabel.font = [UIFont boldSystemFontOfSize:12];
        teamLabel.textAlignment = NSTextAlignmentCenter;
        teamLabel.backgroundColor = [UIColor secondarySystemBackgroundColor];
        teamLabel.layer.borderWidth = 0.5;
        teamLabel.layer.borderColor = [UIColor separatorColor].CGColor;
        [self addSubview:teamLabel];

        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(80, 0, frame.size.width - 80, 40)];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self addSubview:_scrollView];

        _stackView = [[UIStackView alloc] initWithFrame:CGRectZero];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.spacing = 0;
        _stackView.distribution = UIStackViewDistributionFillEqually;
        [_scrollView addSubview:_stackView];
    }
    return self;
}

- (void)configureWithStartGW:(NSInteger)start endGW:(NSInteger)end {
    for (UIView *v in self.stackView.arrangedSubviews) {
        [v removeFromSuperview];
    }

    CGFloat width = 60;
    NSInteger count = end - start + 1;
    self.stackView.frame = CGRectMake(0, 0, count * width, 40);
    self.scrollView.contentSize = CGSizeMake(count * width, 40);

    for (NSInteger i = start; i <= end; i++) {
        UILabel *l = [[UILabel alloc] init];
        l.text = [NSString stringWithFormat:@"GW%ld", (long)i];
        l.font = [UIFont boldSystemFontOfSize:10];
        l.textAlignment = NSTextAlignmentCenter;
        l.layer.borderWidth = 0.5;
        l.layer.borderColor = [UIColor separatorColor].CGColor;
        [self.stackView addArrangedSubview:l];
        [l.widthAnchor constraintEqualToConstant:width].active = YES;
    }
}
@end

#pragma mark - Team Row Cell

@protocol TeamRowCellDelegate <NSObject>
- (void)cellDidScroll:(UIScrollView *)scrollView;
@end

@interface TeamRowCell : UITableViewCell <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) FPLTeam *team;
@property (nonatomic, strong) FPLTeamLogoView *logoView;
@property (nonatomic, strong) UILabel *fdrLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, weak) id<TeamRowCellDelegate> delegate;

- (void)configureWithTeam:(FPLTeam *)team startGW:(NSInteger)start endGW:(NSInteger)end;
@end

@implementation TeamRowCell {
    NSInteger _startGW;
    NSInteger _endGW;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        // Left Column (Fixed 80pt)
        UIView *leftContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, self.contentView.bounds.size.height)];
        leftContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        leftContainer.backgroundColor = [UIColor systemBackgroundColor];
        leftContainer.layer.borderWidth = 0.5;
        leftContainer.layer.borderColor = [UIColor separatorColor].CGColor;
        [self.contentView addSubview:leftContainer];

        _logoView = [[FPLTeamLogoView alloc] initWithFrame:CGRectMake(5, 5, 30, 30)];
        [leftContainer addSubview:_logoView];

        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 5, 35, 15)];
        _nameLabel.font = [UIFont boldSystemFontOfSize:10];
        [leftContainer addSubview:_nameLabel];

        _fdrLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 20, 35, 15)];
        _fdrLabel.font = [UIFont systemFontOfSize:10];
        [leftContainer addSubview:_fdrLabel];

        // Right Grid
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(80, 0, self.contentView.bounds.size.width - 80, self.contentView.bounds.size.height) collectionViewLayout:layout];
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[FPLFixtureCell class] forCellWithReuseIdentifier:@"FixCell"];
        [self.contentView addSubview:_collectionView];
    }
    return self;
}

- (void)configureWithTeam:(FPLTeam *)team startGW:(NSInteger)start endGW:(NSInteger)end {
    _team = team;
    _startGW = start;
    _endGW = end;

    _logoView.teamShortName = team.shortName;
    _nameLabel.text = team.shortName;

    double avg = [[FPLManager sharedManager] calculateAverageFDRForTeam:team.teamID];
    _fdrLabel.text = [NSString stringWithFormat:@"%.1f", avg];
    _fdrLabel.textColor = [FPLTheme colorForDifficulty:(int)round(avg)];

    [self.collectionView reloadData];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _endGW - _startGW + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FPLFixtureCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FixCell" forIndexPath:indexPath];

    NSInteger gw = _startGW + indexPath.item;
    NSArray *fixtures = [[FPLManager sharedManager] getFixturesForTeam:_team.teamID gameweek:gw];
    [cell configureWithFixtures:fixtures];

    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(60, collectionView.bounds.size.height);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.isDragging || scrollView.isDecelerating || scrollView.isTracking) {
        [self.delegate cellDidScroll:scrollView];
    }
}

@end

#pragma mark - Main VC

@interface FPLMainViewController () <UITableViewDataSource, UITableViewDelegate, TeamRowCellDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) GridHeaderView *headerView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, assign) CGPoint sharedContentOffset;
@property (nonatomic, assign) BOOL isSyncing;
@end

@implementation FPLMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"FPL FDR";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"slider.horizontal.3"] style:UIBarButtonItemStylePlain target:self action:@selector(openSettings)];

    // Header
    _headerView = [[GridHeaderView alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 40)];
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerView.scrollView.delegate = self; // Handle header scroll
    [self.view addSubview:_headerView];

    // Table
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerClass:[TeamRowCell class] forCellReuseIdentifier:@"RowCell"];
    [self.view addSubview:_tableView];

    [NSLayoutConstraint activateConstraints:@[
        [_headerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_headerView.heightAnchor constraintEqualToConstant:40],

        [_tableView.topAnchor constraintEqualToAnchor:_headerView.bottomAnchor],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _spinner.center = self.view.center;
    [self.view addSubview:_spinner];

    [_spinner startAnimating];
    [[FPLManager sharedManager] fetchDataWithCompletion:^(NSError *error) {
        [_spinner stopAnimating];
        if (error) {
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:ac animated:YES completion:nil];
        } else {
            [self reloadData];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)reloadData {
    FPLManager *m = [FPLManager sharedManager];
    [self.headerView configureWithStartGW:m.startGameweek endGW:m.endGameweek];
    [self.tableView reloadData];
}

- (void)openSettings {
    FPLSettingsViewController *vc = [[FPLSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[FPLManager sharedManager] getSortedTeams].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    FPLManager *m = [FPLManager sharedManager];
    FPLTeam *team = [m getSortedTeams][indexPath.row];

    NSInteger maxFixtures = 1;
    for (NSInteger gw = m.startGameweek; gw <= m.endGameweek; gw++) {
        NSInteger count = [m getFixturesForTeam:team.teamID gameweek:gw].count;
        if (count > maxFixtures) maxFixtures = count;
    }

    // Height = maxFixtures * 40 + padding
    return maxFixtures * 40 + (maxFixtures - 1) * 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TeamRowCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RowCell" forIndexPath:indexPath];
    FPLManager *m = [FPLManager sharedManager];
    FPLTeam *team = [m getSortedTeams][indexPath.row];

    cell.delegate = self;
    [cell configureWithTeam:team startGW:m.startGameweek endGW:m.endGameweek];

    // Sync offset
    [cell.collectionView setContentOffset:self.sharedContentOffset animated:NO];

    return cell;
}

#pragma mark - Scrolling

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Check if it's the header scroll view
    if (scrollView == self.headerView.scrollView) {
        if (self.isSyncing) return;
        self.isSyncing = YES;
        self.sharedContentOffset = scrollView.contentOffset;

        for (TeamRowCell *cell in self.tableView.visibleCells) {
            [cell.collectionView setContentOffset:self.sharedContentOffset animated:NO];
        }
        self.isSyncing = NO;
    }
}

- (void)cellDidScroll:(UIScrollView *)scrollView {
    if (self.isSyncing) return;
    self.isSyncing = YES;

    self.sharedContentOffset = scrollView.contentOffset;

    // Sync Header
    [self.headerView.scrollView setContentOffset:self.sharedContentOffset animated:NO];

    // Sync other cells
    for (TeamRowCell *cell in self.tableView.visibleCells) {
        if (cell.collectionView != scrollView) {
            [cell.collectionView setContentOffset:self.sharedContentOffset animated:NO];
        }
    }

    self.isSyncing = NO;
}

@end
