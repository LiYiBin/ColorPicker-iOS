//
//  MainViewController.m
//  ColorPickerForSpeakDrawing
//
//  Created by YiBin on 2014/6/13.
//  Copyright (c) 2014年 YB. All rights reserved.
//

#import "MainViewController.h"
#import "PatchCollectionViewCell.h"

#import <RSColorPickerView.h>

@interface MainViewController () <RSColorPickerViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *patchCollectionView;

@property (weak, nonatomic) IBOutlet RSColorPickerView *colorPickerView;
@property (weak, nonatomic) IBOutlet UIView *patchView;

@property (strong, nonatomic) NSMutableDictionary *selectionPatchs;
- (void)selectionPatchChnage:(UISwitch *)sender;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.colorPickerView.CropToCircle = YES;
    self.colorPickerView.delegate = self;
    
    self.selectionPatchs = [[NSMutableDictionary alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 12;
}

#pragma mark - UICollectionView
#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Identifier = @"PatchView";
    PatchCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:Identifier forIndexPath:indexPath];
    
    cell.number = @(indexPath.item + 1);
    [cell.controlSwitch addTarget:self action:@selector(selectionPatchChnage:) forControlEvents:UIControlEventValueChanged];
    
    return cell;
}

- (void)selectionPatchChnage:(UISwitch *)sender
{
    PatchCollectionViewCell *cell = (PatchCollectionViewCell *)[[sender superview] superview];

    if (sender.on) {
        [self.selectionPatchs setObject:cell forKey:cell.number];
    } else {
        [self.selectionPatchs removeObjectForKey:cell.number];
    }
}

#pragma mark UICollectionViewDelegate



#pragma mark - RSColorPickerViewDelegate

- (void)colorPickerDidChangeSelection:(RSColorPickerView *)cp
{
    PatchCollectionViewCell *cell = nil;
    
    UIColor *currentColor = [cp selectionColor];
    self.patchView.backgroundColor = currentColor;
    for (NSNumber *patch in self.selectionPatchs.allKeys) {
        cell = self.selectionPatchs[patch];
        cell.colorView.backgroundColor = currentColor;
    }
}

@end
