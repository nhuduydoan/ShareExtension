//
//  DXResultSearchViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/24/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXResultSearchViewController.h"
#import "DXContactModel.h"
#import "DXPickContactTableViewCell.h"

#define PickContactCell @"PickContactCell"

@interface DXResultSearchViewController ()

@property (strong, nonatomic) NSArray<DXContactModel *> *data;

@end

@implementation DXResultSearchViewController

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
    
    self.tableView.separatorColor = [UIColor colorWithRed:223/255.f green:226/255.f blue:227/255.f alpha:1];
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 100, 0, 0)];
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 1/[UIScreen mainScreen].scale)];
    lineView.backgroundColor = self.tableView.separatorColor;
    self.tableView.tableHeaderView = [UIView new];
    self.tableView.tableFooterView = lineView;
}

#pragma mark - Public

- (void)reloadWithData:(NSArray<DXContactModel *> *)data {
    self.data = data.copy;
    [self.tableView reloadData];
    [self checkSelectedFriends];
}

- (void)checkSelectedFriends {
    if ([self.delegate respondsToSelector:@selector(pickContactsViewController:isSelectedModel:)]) {
        for (NSInteger i = 0; i < self.data.count; i++) {
            id model = self.data[i];
            if ([self.delegate pickContactsViewController:self isSelectedModel:model]) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
}

- (void)didSelectModel:(id)model {
    NSInteger index = [self.data indexOfObject:model];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)deSelectModel:(id)model {
    NSInteger index = [self.data indexOfObject:model];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)scrollToContactModel:(id)model {
    NSInteger index = [self.data indexOfObject:model];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - UITableView Datasouce

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DXPickContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PickContactCell];
    if (cell == nil) {
        cell = [[DXPickContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PickContactCell];
    }
    
    id model = [self.data objectAtIndex:indexPath.row];
    [cell displayContactModel:model];
    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id model = [self.data objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(pickContactsViewController:didDeSelectModel:)]) {
        [self.delegate pickContactsViewController:self didSelectModel:model];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    id model = [self.data objectAtIndex:indexPath.row];
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

@end
