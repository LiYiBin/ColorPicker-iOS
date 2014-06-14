//
//  Patch.h
//  ColorPickerForSpeakDrawing
//
//  Created by YiBin on 2014/6/14.
//  Copyright (c) 2014年 YB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Patch : NSManagedObject

@property (nonatomic, retain) NSNumber * colorRed;
@property (nonatomic, retain) NSNumber * colorGreen;
@property (nonatomic, retain) NSNumber * colorBlue;

@end
