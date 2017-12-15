//
//  DXPickContactsViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/22/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXPickContactsViewController.h"
#import "DXContactModel.h"
#import "DXPickContactTableViewCell.h"

#define PickContactCell @"PickContactCell"

@interface DXSectionObject : NSObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSArray<DXContactModel *> *data;

@end

@implementation DXSectionObject

- (instancetype)initWithTitle:(NSString *)title data:(NSArray<DXContactModel *> *)data {
    self = [super init];
    if (self) {
        _title = title;
        _data = data.copy;
    }
    return self;
}

@end

@interface DXPickContactsViewController ()

@property (strong, nonatomic) NSArray<DXSectionObject *> *sections;
@property (strong, nonatomic) NSArray<NSString *> *sectionTitles;

@end

@implementation DXPickContactsViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStylePlain];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetUp View

- (void)setupTableView {
    [self.tableView registerClass:[DXPickContactTableViewCell class] forCellReuseIdentifier:PickContactCell];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.editing = YES;
    self.tableView.rowHeight = 64;
    self.tableView.tableFooterView = [UIView new];
    
    self.tableView.separatorColor = [UIColor colorWithRed:223/255.f green:226/255.f blue:227/255.f alpha:1];
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 100, 0, 0)];
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
}

#pragma mark - Public

- (void)reloadWithData:(NSArray<DXContactModel *> *)data {
    self.sections = [self sectionsArrayWithData:data];
    self.sectionTitles = [self getSectionTitlesForData:self.sections];
    [self.tableView reloadData];
    [self checkSelectedFriends];
}

- (void)checkSelectedFriends {
    if ([self.delegate respondsToSelector:@selector(pickContactsViewController:isSelectedModel:)]) {
        for (NSInteger i = 0; i < self.sections.count; i++) {
            DXSectionObject *sectionObject = [self.sections objectAtIndex:i];
            NSArray *sectionData = sectionObject.data;
            for (NSInteger index = 0; index < sectionData.count; index++) {
                id model = sectionData[index];
                if ([self.delegate pickContactsViewController:self isSelectedModel:model]) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:i];
                    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                }
            }
        }
    }
}

- (void)didSelectModel:(id)model {
    NSIndexPath *indexPath = [self indexPathForModel:model];
    if (indexPath) {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)deSelectModel:(id)model {
    NSIndexPath *indexPath = [self indexPathForModel:model];
    if (indexPath) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)scrollToContactModel:(id)model {
    NSIndexPath *indexPath = [self indexPathForModel:model];
    if (indexPath) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - Private

- (NSArray<NSString *> *)getSectionTitlesForData:(NSArray<DXSectionObject *> *)data {
    NSMutableArray<NSString *> *sectionTitles = [NSMutableArray new];
    for (DXSectionObject *obj in data) {
        [sectionTitles addObject:obj.title];
    }
    return sectionTitles;
}

- (NSIndexPath *)indexPathForModel:(id)model {
    for (NSInteger i = 0; i < self.sections.count; i++) {
        DXSectionObject *sectionObject = [self.sections objectAtIndex:i];
        NSInteger index = [sectionObject.data indexOfObject:model];
        if (index != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:i];
            return indexPath;
        }
    }
    
    return nil;
}

- (NSArray<DXSectionObject *> *)sectionsArrayWithData:(NSArray<DXContactModel *> *)data {
    if (data.count == 0) {
        return [NSArray new];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"fullName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedArray = [data sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    NSMutableArray *sectionsArr = [NSMutableArray new];
    NSMutableArray *section = [NSMutableArray new];
    DXContactModel *firstModel = sortedArray.firstObject;
    NSString *groupKey = [self groupKeyForString:firstModel.fullName];
    
    for (DXContactModel *contact in sortedArray) {
        NSString *checkKey = [self groupKeyForString:contact.fullName];
        if (![checkKey isEqualToString:groupKey]) {
            DXSectionObject *sectionObject = [[DXSectionObject alloc] initWithTitle:groupKey data:section];
            [sectionsArr addObject:sectionObject];
            section = [NSMutableArray new];
            groupKey = checkKey;
        }
        [section addObject:contact];
    }
    DXSectionObject *sectionObject = [[DXSectionObject alloc] initWithTitle:groupKey data:section];
    [sectionsArr addObject:sectionObject];
    
    return sectionsArr;
}

- (NSString *)groupKeyForString:(NSString *)string {
    NSString *checkString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (checkString.length == 0) {
        return @"#";
    }
    unichar firstChar = [checkString characterAtIndex:0];
    if (![[NSCharacterSet letterCharacterSet] characterIsMember:firstChar]) {
        return @"#";
    }
    NSString *groupKey = [string substringToIndex:1].uppercaseString;
    return groupKey;
}

#pragma mark - UITableView Datasouce

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    DXSectionObject *sectionObject = [self.sections objectAtIndex:section];
    return sectionObject.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DXPickContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PickContactCell];
    if (cell == nil) {
        cell = [[DXPickContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PickContactCell];
    }
    
    DXSectionObject *sectionObject = [self.sections objectAtIndex:indexPath.section];
    id model = [sectionObject.data objectAtIndex:indexPath.row];
    [cell displayContactModel:model];
    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DXSectionObject *sectionObject = [self.sections objectAtIndex:indexPath.section];
    id model = [sectionObject.data objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(pickContactsViewController:didDeSelectModel:)]) {
        [self.delegate pickContactsViewController:self didSelectModel:model];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    DXSectionObject *sectionObject = [self.sections objectAtIndex:indexPath.section];
    id model = [sectionObject.data objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(pickContactsViewController:didDeSelectModel:)]) {
        [self.delegate pickContactsViewController:self didDeSelectModel:model];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(didTapOnPickContactsViewController:)]) {
        [self.delegate didTapOnPickContactsViewController:self];
    }
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    // highlight cell
    [self setCellColor:[UIColor colorWithRed:235/255.f green:235/255.f blue:235/255.f alpha:1.0] forCell:cell];
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self setCellColor:[UIColor clearColor] forCell:cell]; //normal color
}

- (void)setCellColor:(UIColor *)color forCell:(UITableViewCell *)cell {
    cell.contentView.backgroundColor = color;
    cell.backgroundColor = color;
}

#pragma mark - UITableView Header + Footer

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.sectionTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    NSInteger i = [self.sectionTitles indexOfObject:title];
    return i;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    DXSectionObject *sectionObject = [self.sections objectAtIndex:section];
    return sectionObject.title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 20)];
    view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, view.bounds.size.width - 30, view.bounds.size.height)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    DXSectionObject *sectionObject = [self.sections objectAtIndex:section];
    NSString *sectionTitle = sectionObject.title;
    titleLabel.text = sectionTitle;
    
    [view addSubview:titleLabel];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1/[UIScreen mainScreen].scale;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 1/[UIScreen mainScreen].scale)];
    lineView.backgroundColor = self.tableView.separatorColor;
    return lineView;
}


@end
