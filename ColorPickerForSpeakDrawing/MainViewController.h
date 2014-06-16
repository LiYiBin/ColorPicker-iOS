//
//  MainViewController.h
//  ColorPickerForSpeakDrawing
//
//  Created by YiBin on 2014/6/13.
//  Copyright (c) 2014年 YB. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController


// for led effect by bluetooth
- (void)sendSingleLedColorByBLE:(int)led red:(int)red green:(int)green blue:(int)blue;

@end
