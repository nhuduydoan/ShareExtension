//
//  DXConversationSearchResultViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXConversationSearchResultViewController.h"
#import "DXConversationModel.h"
#import "DXConversationTableViewCell.h"

NSString* const kShareSearchResultViewCell = @"kShareSearchResultViewCell";

@interface DXConversationSearchResultViewController ()

@property (strong, nonatomic) NSArray *data;

@end

@implementation DXConversationSearchResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupViews {
    self.tableView.rowHeight = 72;
    self.tableView.separatorColor = [UIColor colorWithRed:223/255.f green:226/255.f blue:227/255.f alpha:1];
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 66, 0, 0)];
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 1/[UIScreen mainScreen].scale)];
    lineView.backgroundColor = self.tableView.separatorColor;
    self.tableView.tableHeaderView = [UIView new];
    self.tableView.tableFooterView = lineView;
}

#pragma mark - Public

- (void)reloadWithData:(NSArray *)data {
    self.data = data.copy;
    [self.tableView reloadData];
}

#pragma mark - TableView Datasouce

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DXConversationTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == nil) {
        cell = [[DXConversationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kShareSearchResultViewCell];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    DXConversationModel *model = [self.data objectAtIndex:indexPath.row];
    [cell displayConversation:model];
    return cell;
    
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    id model = [self.data objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(shareSearchResultViewController:didSelectModel:)]) {
        [self.delegate shareSearchResultViewController:self didSelectModel:model];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(shareSearchResultViewControllerWillBeginDragging:)]) {
        [self.delegate shareSearchResultViewControllerWillBeginDragging:self];
    }
}

@end
