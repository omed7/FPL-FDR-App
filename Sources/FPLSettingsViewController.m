#import "FPLSettingsViewController.h"
#import "FPLManager.h"
#import "FPLTheme.h"

@implementation FPLSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3; // Display, Visibility, Difficulty
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Display Options";
    if (section == 1) return @"Team Visibility";
    return @"Difficulty Overrides";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 3; // Sort, Start, End
    if (section == 1) return [FPLManager sharedManager].teams.count;
    if (section == 2) return [FPLManager sharedManager].teams.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    FPLManager *manager = [FPLManager sharedManager];

    if (indexPath.section == 0) {
        // Display Options
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Sort by Easiest Fixtures";
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = manager.sortByEase;
            [sw addTarget:self action:@selector(toggleSort:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
        } else if (indexPath.row == 1) {
            cell.textLabel.text = [NSString stringWithFormat:@"Start GW: %ld", (long)manager.startGameweek];
            UIStepper *step = [[UIStepper alloc] init];
            step.minimumValue = 1;
            step.maximumValue = manager.endGameweek;
            step.value = manager.startGameweek;
            step.tag = 1;
            [step addTarget:self action:@selector(stepChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = step;
        } else {
            cell.textLabel.text = [NSString stringWithFormat:@"End GW: %ld", (long)manager.endGameweek];
            UIStepper *step = [[UIStepper alloc] init];
            step.minimumValue = manager.startGameweek;
            step.maximumValue = 38;
            step.value = manager.endGameweek;
            step.tag = 2;
            [step addTarget:self action:@selector(stepChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = step;
        }
    } else if (indexPath.section == 1) {
        // Visibility
        FPLTeam *team = manager.teams[indexPath.row];
        cell.textLabel.text = team.name;
        BOOL visible = [manager isTeamVisible:team.teamID];
        cell.accessoryType = visible ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        cell.textLabel.textColor = visible ? [UIColor labelColor] : [UIColor secondaryLabelColor];
        cell.accessoryView = nil;
    } else {
        // Difficulty
        FPLTeam *team = manager.teams[indexPath.row];
        cell.textLabel.text = team.name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryView = nil;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 1) {
        FPLTeam *team = [FPLManager sharedManager].teams[indexPath.row];
        [[FPLManager sharedManager] toggleVisibilityForTeam:team.teamID];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (indexPath.section == 2) {
        FPLTeam *team = [FPLManager sharedManager].teams[indexPath.row];
        [self showDifficultyEditorForTeam:team];
    }
}

#pragma mark - Actions

- (void)toggleSort:(UISwitch *)sender {
    [FPLManager sharedManager].sortByEase = sender.on;
    [[FPLManager sharedManager] savePreferences];
}

- (void)stepChanged:(UIStepper *)sender {
    FPLManager *manager = [FPLManager sharedManager];
    if (sender.tag == 1) {
        manager.startGameweek = (NSInteger)sender.value;
    } else {
        manager.endGameweek = (NSInteger)sender.value;
    }
    [manager savePreferences];
    [self.tableView reloadData];
}

- (void)showDifficultyEditorForTeam:(FPLTeam *)team {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:team.name message:@"Set Difficulty" preferredStyle:UIAlertControllerStyleActionSheet];

    [ac addAction:[UIAlertAction actionWithTitle:@"Set Home Strength" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showStrengthPickerForTeam:team location:@"home"];
    }]];

    [ac addAction:[UIAlertAction actionWithTitle:@"Set Away Strength" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showStrengthPickerForTeam:team location:@"away"];
    }]];

    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:ac animated:YES completion:nil];
}

- (void)showStrengthPickerForTeam:(FPLTeam *)team location:(NSString *)location {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ Strength", location.capitalizedString] message:nil preferredStyle:UIAlertControllerStyleAlert];

    for (int i = 1; i <= 7; i++) {
        [ac addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%d", i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[FPLManager sharedManager] updateStrengthForTeam:team.teamID location:location value:i];
        }]];
    }

    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

@end
