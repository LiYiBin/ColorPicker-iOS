//
//  PatchCollectionViewCell.h
//  ColorPickerForSpeakDrawing
//
//  Created by YiBin on 2014/6/13.
//  Copyright (c) 2014年 YB. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PatchCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) NSNumber *number;
@property (weak, nonatomic) IBOutlet UIView *colorView;
@property (weak, nonatomic) IBOutlet UISwitch *controlSwitch;

@end
