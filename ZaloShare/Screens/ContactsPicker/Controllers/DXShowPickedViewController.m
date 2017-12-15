//
//  DXShowPickedViewController.m
//  DemoXcode
//
//  Created by Nhữ Duy Đoàn on 11/23/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "DXShowPickedViewController.h"
#import "DXShowPickedCollectionViewCell.h"
#import "DXContactModel.h"

#define ShowPickedCell @"ShowPickedCell"

@interface DXShowPickedViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) UICollectionView *collectionView;

@property (strong, nonatomic) NSMutableArray *data;

@end

@implementation DXShowPickedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.data = [NSMutableArray new];
    [self setupCollectionView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SetUp View

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(40, 40);
    layout.minimumInteritemSpacing = 8;
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.scrollEnabled = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 8, 0, 8);
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([DXShowPickedCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:ShowPickedCell];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self.view addSubview:self.collectionView];
    [self.collectionView reloadData];
}

#pragma mark - Public

- (NSArray *)pickedModels {
    return self.data.copy;
}

- (BOOL)isPickedModel:(id)model {
    return [self.data containsObject:model];
}

- (void)addPickedModel:(id)model {
    if ([self.data containsObject:model]) {
        return;
    }
    
    [self.data addObject:model];
    NSInteger index = self.data.count - 1;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
}

- (void)removePickedModel:(id)model {
    if (self.data.count == 0) {
        return;
    }
    
    NSInteger index = [self.data indexOfObject:model];
    if (index != NSNotFound) {
        [self.data removeObject:model];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    }
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.data.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    DXShowPickedCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ShowPickedCell forIndexPath:indexPath];
    id model = [self.data objectAtIndex:indexPath.row];
    [cell displayContactModel:model];
    return cell;
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id model = [self.data objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(showPickedViewController:didSelectModel:)]) {
        [self.delegate showPickedViewController:self didSelectModel:model];
    }
}

@end
