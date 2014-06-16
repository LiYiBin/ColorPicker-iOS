//
//  Color.h
//  ColorPickerForSpeakDrawing
//
//  Created by YiBin on 2014/6/16.
//  Copyright (c) 2014年 YB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Group;

@interface Color : NSManagedObject

@property (nonatomic, retain) NSNumber * red;
@property (nonatomic, retain) NSNumber * green;
@property (nonatomic, retain) NSNumber * blue;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) Group *group;

@end
