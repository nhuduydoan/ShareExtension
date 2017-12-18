//
//  ZLPickConversationViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 12/13/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "ZLPickConversationViewController.h"
#import "DXConversationModel.h"
#import "DXConversationTableViewCell.h"
#import "DXConversationManager.h"
#import "DXConversationSearchResultViewController.h"
#import "DXImageManager.h"
#import "ZLShareExtensionManager.h"
#import "DXPickFriendsViewController.h"
#import "DXShareNavigationController.h"
#import "EditPostViewController.h"

NSString* const kShareFriendViewCell = @"kShareFriendViewCell";

@interface ZLPickConversationViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, DXConversationSearchResultViewControllerDelegate>

@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIBarButtonItem *closeBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *searchBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *cancelSearchItem;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *sectionTitleView;

@property (strong, nonatomic) DXConversationSearchResultViewController *searchResultViewController;
@property (strong, nonatomic) EditPostViewController *editPostViewController;

@property (strong, nonatomic) NSArray *data;
@property (nonatomic) BOOL isSearching;

@property (strong, nonatomic) UIImage *clearSearchBgImage;
@property (strong, nonatomic) UIImage *blueSearchBgImage;

@end

@implementation ZLPickConversationViewController

+ (instancetype)new {
    [super doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype) init {
    [super doesNotRecognizeSelector:_cmd];
    self = nil;
    return nil;
}

- (instancetype)initWithCompletionHandler:(void (^)(UIViewController *viewController, NSArray<NSString *> *shareURLs))completionHandler {
    self = [super init];
    if (self) {
        _completionHandler = completionHandler;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupNavigationItems];
    [self setupHeaderView];
    [self setupTableView];
    [self setupEditPostViewController];
    [self setupSearchResultViewController];
    [self getAllData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup Views

- (void)setupNavigationItems {
    self.navigationController.navigationBar.translucent = NO;
    self.closeBarButtonItem = [[UIBarButtonItem alloc]
                                     initWithTitle:@"Huỷ"
                                     style:UIBarButtonItemStylePlain
                                     target:self action:@selector(touchUpInsideCloseBarItem)];
    self.searchBarButtonItem = [[UIBarButtonItem alloc]
                                initWithImage:[UIImage imageNamed:@"icon_search"]
                               style:UIBarButtonItemStylePlain
                               target:self action:@selector(touchUpInsideSearchBarItem)];
    self.cancelSearchItem = [[UIBarButtonItem alloc]
                             initWithImage:[UIImage imageNamed:@"icon_back"]
                             style:UIBarButtonItemStylePlain
                             target:self action:@selector(touchUpInsideCancelSearchItem)];
    self.navigationItem.leftBarButtonItem = self.closeBarButtonItem;
    self.navigationItem.rightBarButtonItem = self.searchBarButtonItem;
    
    self.isSearching = NO;
    [self setUpSearchBar];
    self.navigationItem.titleView = self.searchBar;
}

- (void)setupHeaderView {
    self.view.backgroundColor = [UIColor whiteColor];
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    headerView.backgroundColor = [UIColor colorWithRed:230/255.f green:230/255.f blue:230/255.f alpha:1.0];
    headerView.clipsToBounds = YES;
    self.headerView = headerView;
}

- (void)setUpSearchBar {
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:self.headerView.bounds];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    searchBar.delegate = self;
    searchBar.backgroundImage = [UIImage new];
    UIImage *clearImg = [UIImage imageNamed:@"icon_clear"];
    [searchBar setImage:clearImg forSearchBarIcon:UISearchBarIconClear state:UIControlStateNormal];
    
    searchBar.placeholder = @"Tìm cuộc trò chuyện";
    UITextField *searchTextField = [searchBar valueForKey:@"_searchField"];
    searchTextField.layer.cornerRadius = 3.0;
    searchTextField.backgroundColor = [UIColor clearColor];
    searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    searchTextField.clipsToBounds = YES;
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 20)];
    searchTextField.leftView = paddingView;
    searchTextField.leftViewMode = UITextFieldViewModeAlways;
    searchTextField.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    searchTextField.textColor = [UIColor whiteColor];
    
    UILabel *placeholderLabel = [searchTextField valueForKey:@"_placeholderLabel"];
    placeholderLabel.textColor = [UIColor colorWithRed:184/255.5 green:214/255.f blue:240/255.f alpha:1.0];
    
    UIColor *color = [UIColor colorWithRed:16/255.f green:116/255.f blue:204/255.f alpha:1];
    self.blueSearchBgImage = [sImageManager imageWithColor:color size:CGSizeMake(30, 30)];
    self.clearSearchBgImage = [sImageManager imageWithColor:[UIColor clearColor] size:CGSizeMake(30, 30)];
    
     self.searchBar = searchBar;
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.rowHeight = 72;
    self.tableView.separatorColor = [UIColor colorWithRed:223/255.f green:226/255.f blue:227/255.f alpha:1];
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 66, 0, 0)];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)setupEditPostViewController {
    EditPostViewController *controller = [[EditPostViewController alloc] init];
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];
    controller.view.frame = self.headerView.bounds;
    controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.headerView addSubview:controller.view];
    self.editPostViewController = controller;
}

- (void)setupSearchResultViewController {
    DXConversationSearchResultViewController *controller = [[DXConversationSearchResultViewController alloc] init];
    controller.delegate = self;
    self.searchResultViewController = controller;
}

- (void)displaySearchResultViewController:(BOOL)isShow {
    if (isShow) {
        [self addChildViewController:self.searchResultViewController];
        [self.searchResultViewController didMoveToParentViewController:self];
        self.searchResultViewController.view.frame = self.view.bounds;
        self.searchResultViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:self.searchResultViewController.view];
        
    } else {
        [self.searchResultViewController removeFromParentViewController];
        [self.searchResultViewController didMoveToParentViewController:nil];
        [self.searchResultViewController.view removeFromSuperview];
    }
}

- (void)displaySelectMultiFriendsViewController {
    NSArray *contacts = [[DXConversationManager shareInstance] getContactsArray];
    DXPickFriendsViewController *controller = [[DXPickFriendsViewController alloc] initWithContactsArray:contacts];
    controller.completionHandler = self.completionHandler;
    DXShareNavigationController *navController = [[DXShareNavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)updateSeachBar {
    if (self.isSearching) {
        self.navigationItem.rightBarButtonItem = self.cancelSearchItem;
        [self.searchBar setSearchFieldBackgroundImage:self.blueSearchBgImage forState:UIControlStateNormal];
        
    } else {
        self.navigationItem.rightBarButtonItem = self.searchBarButtonItem;
        [self.searchBar setSearchFieldBackgroundImage:self.clearSearchBgImage forState:UIControlStateNormal];
    }
}

- (void)hideKeyBoardScreen {
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark - Private

- (void)touchUpInsideCloseBarItem {
    [self hideKeyBoardScreen];
    self.completionHandler(self.navigationController, nil);
}

- (void)touchUpInsideSearchBarItem {
    [self.searchBar becomeFirstResponder];
}

- (void)touchUpInsideCancelSearchItem {
    self.isSearching = NO;
    [self.searchBar setText:@""];
    [self searchWithKeyWord:@""];
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    } else {
        [self updateSeachBar];
    }
}

- (void)getAllData {
    __weak typeof(self) selfWeak = self;
    [[DXConversationManager shareInstance] getAllConversationsWithCompletionHandler:^(NSArray *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            selfWeak.data = result.copy;
            [selfWeak.tableView reloadData];
        });
    }];
}

- (void)searchWithKeyWord:(NSString *)keyword {
    if (keyword.length == 0) {
        [self displaySearchResultViewController:NO];
        return;
    }
    
    if (!self.searchResultViewController.view.window) {
        // If SearchResultViewController is not displayed, display it
        [self displaySearchResultViewController:YES];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"displayName CONTAINS[c] %@", keyword.lowercaseString];
    NSPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate]];
    NSArray<DXConversationModel *> *resArr = [self.data filteredArrayUsingPredicate:compoundPredicate];
    [self.searchResultViewController reloadWithData:resArr];
}

- (void)didSelectConversation:(DXConversationModel *)model {
    NSLog(@"====Start Sharing : %@====", model.conversationId);
    NSString *shareId = model.conversationId.copy;
    self.completionHandler(self.navigationController, @[shareId]);
}

#pragma mark - TableView Datasouce

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DXConversationTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == nil) {
        cell = [[DXConversationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kShareFriendViewCell];
    }
    
    if (indexPath.section == 0) {
        UIImage *friendImage = [UIImage imageNamed:@"icon_friend"];
        [cell displayString:@"Chia sẻ cho nhiều bạn" image:friendImage];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    } else {
        DXConversationModel *model = [self.data objectAtIndex:indexPath.row];
        [cell displayConversation:model];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    return cell;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hideKeyBoardScreen];
    
    if (indexPath.section == 0) { // Touch in cell : "Chia sẻ cho nhiều bạn"
        [self displaySelectMultiFriendsViewController];
        return;
    }
    
    id model = [self.data objectAtIndex:indexPath.row];
    [self didSelectConversation:model];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self hideKeyBoardScreen];
}

#pragma mark - TableView Header + Footer

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return 22;
    }
    return 1/[UIScreen mainScreen].scale;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 1) {
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 1/[UIScreen mainScreen].scale)];
        lineView.backgroundColor = self.tableView.separatorColor;
        return lineView;
    }
    
    if (self.sectionTitleView == nil) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 22)];
        view.backgroundColor = [UIColor whiteColor];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 2, view.bounds.size.width, 20)];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.textColor = [UIColor colorWithRed:103/255.f green:116/255.f blue:129/255.f alpha:1];
        label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        label.text = @"Trò chuyện gần đây";
        [view addSubview:label];
        
        // Add top footer view line
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, view.bounds.size.width, 1/[UIScreen mainScreen].scale)];
        lineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        lineView.backgroundColor = self.tableView.separatorColor;
        [view addSubview:lineView];
        
        self.sectionTitleView = view;
    }
    
    return self.sectionTitleView;
}

#pragma mark - UISearchBar Delegates

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSString *keyword = searchBar.text;
    [self searchWithKeyWord:keyword];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.isSearching = YES;
    [self updateSeachBar];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (self.searchBar.text.length == 0) {
        self.isSearching = NO;
        [self updateSeachBar];
    }
}

#pragma mark - DXConversationSearchResultViewController Delegate

- (void)shareSearchResultViewController:(UIViewController *)viewController didSelectModel:(id)model {
    [self didSelectConversation:model];
}

- (void)shareSearchResultViewControllerWillBeginDragging:(UIViewController *)viewController {
    [self hideKeyBoardScreen];
}

@end