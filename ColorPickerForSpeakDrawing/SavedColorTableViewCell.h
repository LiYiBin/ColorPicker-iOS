//
//  SavedColorTableViewCell.h
//  ColorPickerForSpeakDrawing
//
//  Created by YiBin on 2014/6/16.
//  Copyright (c) 2014年 YB. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SavedColorTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *colorView;
@property (weak, nonatomic) IBOutlet UILabel *redLabel;
@property (weak, nonatomic) IBOutlet UILabel *greenLabel;
@property (weak, nonatomic) IBOutlet UILabel *blueLabel;

@end
