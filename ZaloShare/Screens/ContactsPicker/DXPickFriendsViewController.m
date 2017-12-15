//
//  DXPickFriendsViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/23/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXPickFriendsViewController.h"
#import "DXContactModel.h"
#import "DXShowPickedViewController.h"
#import "DXPickContactsViewController.h"
#import "DXResultSearchViewController.h"
#import "DXImageManager.h"

@interface DXPickFriendsViewController () <UISearchBarDelegate, DXPickContactsViewControllerDelegate, DXShowPickedViewControllerDelegate>

@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UILabel *noResultLabel;

@property (strong, nonatomic) UIBarButtonItem *closeBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *inviteBarButtonItem;
@property (strong, nonatomic) UIImageView *subTitleView;

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) DXShowPickedViewController *showPickedViewController;
@property (strong, nonatomic) DXPickContactsViewController *pickContactsViewController;
@property (strong, nonatomic) DXResultSearchViewController *searchResultViewController;

@property (strong, nonatomic) NSArray *originalData;

@end

@implementation DXPickFriendsViewController

- (id)initWithContactsArray:(NSArray *)contactsArray {
    self = [super init];
    if (self) {
        _originalData = contactsArray.copy;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (self.originalData == nil) {
        self.originalData = [NSArray new];
    }
    
    [self setupTitleView];
    [self setupNavigationBarItems];
    [self setupHeaderView];
    [self setUpContentView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetUp View

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)setupNavigationBarItems {
    self.navigationController.navigationBar.translucent = NO;
    self.closeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(touchUpCloseBarButtonItem)];
    self.navigationItem.leftBarButtonItem = self.closeBarButtonItem;
    
    self.inviteBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Invite" style:UIBarButtonItemStyleDone target:self action:@selector(touchUpInviteButton)];
    self.navigationItem.rightBarButtonItem = self.inviteBarButtonItem;
    [self.inviteBarButtonItem setEnabled:NO];
}

- (void)setupTitleView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 414, 44)];
    UILabel *mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, 414, 18)];
    mainLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    mainLabel.font = [UIFont systemFontOfSize:17];
    mainLabel.textAlignment = NSTextAlignmentCenter;
    mainLabel.text = @"Chọn bạn";
    
    NSString *subTitle = @"0/5";
    UIImage *subImage = [sImageManager titleImageFromString:subTitle];
    CGFloat width = subImage.size.width * 0.6;
    CGFloat height = subImage.size.height * 0.6;
    UIImageView *subTitleView = [[UIImageView alloc] initWithImage:subImage];
    subTitleView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    CGRect subViewFrame = CGRectMake(207 - width/2, 34 - height/2, width, height);
    subTitleView.frame = subViewFrame;
    
    [view addSubview:mainLabel];
    [view addSubview:subTitleView];
    self.navigationItem.titleView = view;
    self.subTitleView = subTitleView;
}

- (void)updateTitleForController {
    NSString *subTitle = [NSString stringWithFormat:@"%zd/5", self.showPickedViewController.pickedModels.count];
    UIImage *subTitleImage =  [sImageManager titleImageFromString:subTitle];
    CGRect rect = self.navigationItem.titleView.bounds;
    CGFloat width = subTitleImage.size.width * 0.6;
    CGFloat height = subTitleImage.size.height * 0.6;
    CGRect subViewFrame = CGRectMake(rect.size.width/2 - width/2, 34 - height/2, width, height);
    CGRect hightLightFrame = CGRectMake(rect.size.width/2 - subTitleImage.size.width/2, 34 - subTitleImage.size.height/2, subTitleImage.size.width, subTitleImage.size.height);
    
    [UIView animateWithDuration:0.1 delay:0.2 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.subTitleView.frame = hightLightFrame;
    } completion:^(BOOL finished) {
        self.subTitleView.frame = hightLightFrame;
        self.subTitleView.image = subTitleImage;
        [UIView animateWithDuration:0.1 delay:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.subTitleView.frame = subViewFrame;
        } completion:^(BOOL finished) {
            self.subTitleView.frame = subViewFrame;
        }];
    }];
}

- (void)setupHeaderView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
    self.headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.headerView.backgroundColor = [UIColor colorWithRed:230/255.f green:230/255.f blue:230/255.f alpha:1.0];
    [self.view addSubview:self.headerView];
    
    [self setUpSearchBar];
    [self setupShowPickedViewController];
}

- (void)setUpSearchBar {
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, self.headerView.bounds.size.height - 40, self.view.bounds.size.width, 40)];
    searchBar.delegate = self;
    searchBar.backgroundImage = [UIImage new];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    UITextField *searchField = [searchBar valueForKey:@"searchField"];
    searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search your friends"];
    UILabel *placeholderLabel = [searchField valueForKey:@"placeholderLabel"];
    placeholderLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    
    [self.headerView addSubview:searchBar];
    self.searchBar = searchBar;
}

- (void)setUpContentView {
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 40, self.view.bounds.size.width, self.view.bounds.size.height - 40)];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.contentView];
    
    [self setupPickContactsViewController];
    [self setupSearchResultViewController];
    [self setUpNoResultLabel];
}

- (void)setUpNoResultLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:self.contentView.bounds];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.center = self.contentView.center;
    label.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    label.text = @"No Result";
    label.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:label];
    self.noResultLabel = label;
    if (self.originalData.count > 0) {
        [self displayNoResultlabel:NO];
    } else {
        [self displayNoResultlabel:YES];
    }
}

- (void)setupShowPickedViewController {
    self.showPickedViewController = [DXShowPickedViewController new];
    self.showPickedViewController.delegate = self;
    self.showPickedViewController.view.frame = CGRectMake(0, 0, 0, 0);
    [self.headerView addSubview:self.showPickedViewController.view];
}

- (void)setupPickContactsViewController {
    DXPickContactsViewController *controller = [[DXPickContactsViewController alloc] init];
    controller.delegate = self;
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];
    controller.view.frame = self.contentView.bounds;
    controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView insertSubview:controller.view atIndex:0];
    self.pickContactsViewController = controller;
    [self.pickContactsViewController reloadWithData:self.originalData];
}

- (void)setupSearchResultViewController {
    DXResultSearchViewController *controller = [[DXResultSearchViewController alloc] init];
    controller.delegate = self;
    self.searchResultViewController = controller;
}

- (void)displaySearchResultViewController:(BOOL)isShow {
    if (isShow) {
        [self addChildViewController:self.searchResultViewController];
        [self.searchResultViewController didMoveToParentViewController:self];
        self.searchResultViewController.view.frame = self.contentView.bounds;
        self.searchResultViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.searchResultViewController.view];
        
    } else {
        [self.searchResultViewController removeFromParentViewController];
        [self.searchResultViewController didMoveToParentViewController:nil];
        [self.searchResultViewController.view removeFromSuperview];
    }
}

- (void)displayShowPickedViewController:(BOOL)isShow {
    CGRect headerFrame = self.headerView.frame;
    CGRect contentFrame = self.contentView.frame;
    if (isShow) {
        headerFrame = CGRectMake(0, 0, self.view.bounds.size.width, 94);
    } else {
        headerFrame = CGRectMake(0, 0, self.view.bounds.size.width, 40);
    }
    contentFrame = CGRectMake(0, headerFrame.size.height, self.view.bounds.size.width, self.view.bounds.size.height - headerFrame.size.height);
    
    [UIView animateWithDuration:0.2 animations:^{
        self.headerView.frame = headerFrame;
        self.contentView.frame = contentFrame;
    } completion:^(BOOL finished) {
        self.headerView.frame = headerFrame;
        self.contentView.frame = contentFrame;
        if (isShow) {
            [self addChildViewController:self.showPickedViewController];
            [self.showPickedViewController didMoveToParentViewController:self];
            self.showPickedViewController.view.frame = CGRectMake(0, 10, self.headerView.bounds.size.width, 44);
            self.showPickedViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.headerView insertSubview:self.showPickedViewController.view atIndex:0];
        } else {
            [self.showPickedViewController removeFromParentViewController];
            [self.showPickedViewController didMoveToParentViewController:nil];
            [self.showPickedViewController.view removeFromSuperview];
        }
    }];
}

- (void)displayNoResultlabel:(BOOL)display {
    self.noResultLabel.hidden = !display;
    [self.headerView setHidden:display];
}

#pragma mark - Private

- (void)searchWithKeyWord:(NSString *)keyword {
    if (keyword.length == 0) {
        [self displaySearchResultViewController:NO];
        return;
    }
    
    if (!self.searchResultViewController.view.window) {
        // If SearchResultViewController is not displayed, display it
        [self displaySearchResultViewController:YES];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fullName CONTAINS[c] %@", keyword.lowercaseString];
    NSPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate]];
    NSArray *resArr = [self.originalData filteredArrayUsingPredicate:compoundPredicate];
    [self.searchResultViewController reloadWithData:resArr];
}

- (BOOL)isSelectedModel:(id)model {
    return [self.showPickedViewController isPickedModel:model];
}

- (void)selectModel:(id)model {
    [self.showPickedViewController addPickedModel:model];
    if (self.showPickedViewController.pickedModels.count == 1) {
        [self displayShowPickedViewController:YES];
        [self.inviteBarButtonItem setEnabled:YES];
    }
    [self updateTitleForController];
}

- (void)deSelectModel:(id)model {
    [self.showPickedViewController removePickedModel:model];
    if (self.showPickedViewController.pickedModels.count == 0) {
        [self displayShowPickedViewController:NO];
        [self.inviteBarButtonItem setEnabled:NO];
    }
    [self updateTitleForController];
}

- (void)hideKeyBoard {
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark - Action

- (void)touchUpCloseBarButtonItem {
    [self hideKeyBoard];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)touchUpInviteButton {
    [self hideKeyBoard];
    
    NSArray *selectedFriends = [self.showPickedViewController pickedModels];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Your selected friends" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];

    for (DXContactModel *contact in selectedFriends) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:contact.fullName style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:action];
    }

    UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDestructive handler:nil];
    [alertController addAction:closeAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UISearchBar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self searchWithKeyWord:searchText];
}

#pragma mark - DXPickContactsViewControllerDelegate

- (BOOL)pickContactsViewController:(UIViewController *)controller isSelectedModel:(id)model {
    return [self isSelectedModel:model];
}

- (BOOL)pickContactsViewController:(UIViewController *)controller didSelectModel:(id)model {
    if (self.showPickedViewController.pickedModels.count >= 5) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Thông báo" message:@"Bạn không được chọn quá 5 người" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return NO;
    }
    
    [self selectModel:model];
    if (controller == self.pickContactsViewController) {
        [self.searchResultViewController didSelectModel:model];
    } else {
        [self.pickContactsViewController didSelectModel:model];
    }
    [self hideKeyBoard];
    return YES;
}

- (void)pickContactsViewController:(UIViewController *)controller didDeSelectModel:(id)model {
    [self deSelectModel:model];
    if (controller == self.pickContactsViewController) {
        [self.searchResultViewController deSelectModel:model];
    } else {
        [self.pickContactsViewController deSelectModel:model];
    }
    [self hideKeyBoard];
}

- (void)didTapOnPickContactsViewController:(DXPickContactsViewController *)controller {
    [self hideKeyBoard];
}

#pragma mark - DXShowPickedViewControllerDelegate

- (void)showPickedViewController:(DXShowPickedViewController *)controller didSelectModel:(id)model {
    if (self.searchResultViewController.view.window) {
        [self.searchResultViewController scrollToContactModel:model];
    } else {
        [self.pickContactsViewController scrollToContactModel:model];
    }
    [self hideKeyBoard];
}

@end
