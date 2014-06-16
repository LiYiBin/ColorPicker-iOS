//
//  Group.h
//  ColorPickerForSpeakDrawing
//
//  Created by YiBin on 2014/6/16.
//  Copyright (c) 2014年 YB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Color;

@interface Group : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *colors;
@end

@interface Group (CoreDataGeneratedAccessors)

- (void)addColorsObject:(Color *)value;
- (void)removeColorsObject:(Color *)value;
- (void)addColors:(NSSet *)values;
- (void)removeColors:(NSSet *)values;

@end
