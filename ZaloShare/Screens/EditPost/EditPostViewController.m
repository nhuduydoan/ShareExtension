//
//  EditPostViewController.m
//  ZaloShare
//
//  Created by Nhữ Duy Đoàn on 12/18/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "EditPostViewController.h"
#import "DXImageManager.h"

#pragma mark - UIPlaceHolderTextView ------------------------------------------------

@interface UIPlaceHolderTextView : UITextView

@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end
@interface UIPlaceHolderTextView ()

@property (nonatomic, retain) UILabel *placeHolderLabel;

@end

@implementation UIPlaceHolderTextView

CGFloat const UI_PLACEHOLDER_TEXT_CHANGED_ANIMATION_DURATION = 0.1;

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self setPlaceholder:@""];
        [self setPlaceholderColor:[UIColor lightGrayColor]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:self];
    }
    return self;
}

- (void)textChanged:(NSNotification *)notification {
    if([[self placeholder] length] == 0) {
        return;
    }
    
    [UIView animateWithDuration:UI_PLACEHOLDER_TEXT_CHANGED_ANIMATION_DURATION animations:^{
        if([[self text] length] == 0) {
            [[self viewWithTag:999] setAlpha:1];
        } else {
            [[self viewWithTag:999] setAlpha:0];
        }
    }];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self textChanged:nil];
}

- (void)drawRect:(CGRect)rect {
    if( [[self placeholder] length] > 0 ) {
        if (_placeHolderLabel == nil )  {
            _placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(4,8,self.bounds.size.width - 4,0)];
            _placeHolderLabel.lineBreakMode = NSLineBreakByWordWrapping;
            _placeHolderLabel.numberOfLines = 0;
            _placeHolderLabel.font = self.font;
            _placeHolderLabel.backgroundColor = [UIColor clearColor];
            _placeHolderLabel.textColor = self.placeholderColor;
            _placeHolderLabel.alpha = 0;
            _placeHolderLabel.tag = 999;
            [self addSubview:_placeHolderLabel];
        }
        
        _placeHolderLabel.text = self.placeholder;
        [_placeHolderLabel sizeToFit];
        [self sendSubviewToBack:_placeHolderLabel];
    }
    
    if( [[self text] length] == 0 && [[self placeholder] length] > 0 ) {
        [[self viewWithTag:999] setAlpha:1];
    }
    
    [super drawRect:rect];
}

@end

#pragma mark - EditPostViewController ------------------------------------------------

@interface EditPostViewController ()

@property (strong, nonatomic) UIImageView *thumbnailView;
@property (strong, nonatomic) UIPlaceHolderTextView *textView;
@property (strong, nonatomic) UIImage *thumbnail;

@end

@implementation EditPostViewController

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupViews];
    if (self.shareText.length) {
        self.textView.text = self.shareText;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup Views

- (void)setupViews {
    [self setupThumbnailView];
    [self setupTextView];
}

- (void)setupThumbnailView {
    self.view.backgroundColor = [UIColor clearColor];
    self.view.clipsToBounds = YES;
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 5, 80, 90)];
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    imgView.clipsToBounds = YES;
    imgView.image = self.thumbnail;
    [self.view addSubview:imgView];
    self.thumbnailView = imgView;
}

- (void)setupTextView {
    CGRect rect = CGRectMake(108, 10, self.view.bounds.size.width - 116, 80);
    if (self.thumbnail == nil) {
        rect = CGRectMake(8, 10, self.view.bounds.size.width - 16, 80);
    }
    UIPlaceHolderTextView *textView = [[UIPlaceHolderTextView alloc] initWithFrame:rect];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:textView];
    
    textView.layer.cornerRadius = 3.0;
    textView.clipsToBounds = YES;
    textView.editable = YES;
    textView.showsHorizontalScrollIndicator = NO;
    textView.textColor = [UIColor blackColor];
    textView.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    textView.placeholder = @"Viết cái gì đó...";
    textView.placeholderColor = [UIColor colorWithRed:194/255.5 green:194/255.f blue:194/255.f alpha:1.0];
    self.textView = textView;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:textView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:UITextViewTextDidEndEditingNotification object:textView];
}

#pragma mark - Notification

- (void)textDidBeginEditing:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(editPostViewController:changeEditing:)]) {
        [self.delegate editPostViewController:self changeEditing:YES];
    }
}

- (void)textDidEndEditing:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(editPostViewController:changeEditing:)]) {
        [self.delegate editPostViewController:self changeEditing:NO];
    }
}

#pragma mark - Public

- (void)updateExtensionThumbnail:(UIImage *)thumbnail {
    self.thumbnail = thumbnail;
    if (thumbnail == nil) {
        [self.thumbnailView removeFromSuperview];
        self.thumbnailView = nil;
        return;
    }
    
    if (self.thumbnailView) {
        self.thumbnailView.image = thumbnail;
        CGRect rect = CGRectMake(108, 10, self.view.bounds.size.width - 116, 80);
        [UIView animateWithDuration:0.2 animations:^{
            self.textView.frame = rect;
        } completion:^(BOOL finished) {
            self.textView.frame = rect;
        }];
    }
}

- (void)hideKeyBoard {
    if (self.textView.isFirstResponder) {
        [self.textView resignFirstResponder];
    }
}

- (NSString *)postComment {
    return self.textView.text;
}

- (BOOL)isEditingText {
    return [self.textView isFirstResponder];
}

- (void)setShareText:(NSString *)shareText {
    _shareText = shareText;
    self.textView.text = shareText;
}

@end
