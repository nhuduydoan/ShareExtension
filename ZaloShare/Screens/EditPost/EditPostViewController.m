//
//  EditPostViewController.m
//  ZaloShare
//
//  Created by Nhữ Duy Đoàn on 12/18/17.
//  Copyright © 2017 Nhữ Duy Đoàn. All rights reserved.
//

#import "EditPostViewController.h"

@interface UIPlaceHolderTextView : UITextView

@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end
@interface UIPlaceHolderTextView ()

@property (nonatomic, retain) UILabel *placeHolderLabel;

@end

@implementation UIPlaceHolderTextView

CGFloat const UI_PLACEHOLDER_TEXT_CHANGED_ANIMATION_DURATION = 0.25;

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self setPlaceholder:@""];
        [self setPlaceholderColor:[UIColor lightGrayColor]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
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

@interface EditPostViewController ()

@property (strong, nonatomic) UIPlaceHolderTextView *textField;

@end

@implementation EditPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup Views

- (void)setupViews {
    self.view.backgroundColor = [UIColor clearColor];
    self.view.clipsToBounds = YES;
    UIView *thumbnailView = [[UIView alloc] initWithFrame:CGRectMake(16, 10, 80, 80)];
    thumbnailView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.2];
    [self.view addSubview:thumbnailView];
    
    [self setupTextField];
}

- (void)setupTextField {
    
    UIPlaceHolderTextView *textView = [[UIPlaceHolderTextView alloc] initWithFrame:CGRectMake(108, 10, self.view.bounds.size.width - 116, 80)];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:textView];
    
    textView.layer.cornerRadius = 3.0;
    textView.clipsToBounds = YES;
    textView.editable = YES;
    textView.showsHorizontalScrollIndicator = NO;
    textView.textColor = [UIColor blackColor];
    textView.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    
    textView.placeholder = @"Viết cái gì đó...";
    textView.placeholderColor = [UIColor colorWithRed:208/255.5 green:208/255.f blue:208/255.f alpha:1.0];
}

@end
