//
//  MainViewController.m
//  ColorPickerForSpeakDrawing
//
//  Created by YiBin on 2014/6/13.
//  Copyright (c) 2014年 YB. All rights reserved.
//

#import "MainViewController.h"
#import "PatchCollectionViewCell.h"
#import "Patch.h"
#import "MainAppDelegate.h"
#import "ModelsName.h"

#import <CoreData/CoreData.h>
#import <RSColorPickerView.h>

#define kRed @"Red"
#define kGreen @"Green"
#define kBlue @"Blue"

@interface MainViewController () <RSColorPickerViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *patchCollectionView;

@property (weak, nonatomic) IBOutlet RSColorPickerView *colorPickerView;
@property (weak, nonatomic) IBOutlet UIView *patchView;
@property (weak, nonatomic) IBOutlet UILabel *redValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *greenValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *blueValueLabel;
@property (strong, nonatomic) NSMutableDictionary *currentColor;
- (IBAction)saveThisColor:(id)sender;

@property (strong, nonatomic) NSMutableDictionary *selectionPatchs;
- (void)selectionPatchChnage:(UISwitch *)sender;

// Core data
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

// For saving color
@property (weak, nonatomic) IBOutlet UICollectionView *savedColorCollectionView;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // setup color picker view
    self.colorPickerView.CropToCircle = YES;
    self.colorPickerView.delegate = self;
    
    // setup for saving selection patches
    self.selectionPatchs = [[NSMutableDictionary alloc] init];
    self.currentColor = [NSMutableDictionary dictionaryWithObjects:@[@255, @255, @255] forKeys:@[kRed, kGreen, kBlue]];
    
    // setup for core data
    MainAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionView
#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == self.patchCollectionView) {
        return 12;
    } else if (collectionView == self.savedColorCollectionView) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
        return [sectionInfo numberOfObjects];
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = nil;
    
    if (collectionView == self.patchCollectionView) {
        static NSString *PatchIdentifier = @"PatchView";
        
        PatchCollectionViewCell *patchCell = [collectionView dequeueReusableCellWithReuseIdentifier:PatchIdentifier forIndexPath:indexPath];
        patchCell.number = @(indexPath.item + 1);
        [patchCell.controlSwitch addTarget:self action:@selector(selectionPatchChnage:) forControlEvents:UIControlEventValueChanged];
        
        cell = patchCell;
        
    } else if (collectionView == self.savedColorCollectionView) {
        static NSString *SavedColorIdentifier = @"SavedColorCell";
        
        UICollectionViewCell *colorCell = [collectionView dequeueReusableCellWithReuseIdentifier:SavedColorIdentifier forIndexPath:indexPath];
        
        NSManagedObject *patch = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSNumber *red = [patch valueForKey:PATCH_COLOR_RED];
        NSNumber *green = [patch valueForKey:PATCH_COLOR_GREEN];
        NSNumber *blue = [patch valueForKey:PATCH_COLOR_BLUE];
        
        colorCell.backgroundColor = [UIColor colorWithRed:red.intValue/255.0 green:green.intValue/255.0 blue:blue.intValue/255.0 alpha:1.0];
        
        cell = colorCell;
    }
    
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

#pragma mark - RSColorPickerViewDelegate

- (void)colorPickerDidChangeSelection:(RSColorPickerView *)cp
{
    PatchCollectionViewCell *cell = nil;

    // for display color
    UIColor *currentColor = [cp selectionColor];
    self.patchView.backgroundColor = currentColor;
    for (NSNumber *patch in self.selectionPatchs.allKeys) {
        cell = self.selectionPatchs[patch];
        cell.colorView.backgroundColor = currentColor;
    }
    
    // for template current rgb value
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0;
    [currentColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    int r = (int)(red * 255.0);
    int g = (int)(green * 255.0);
    int b = (int)(blue * 255.0);
    
    // temporal cuurent color
    self.currentColor[kRed] = @(r);
    self.currentColor[kGreen] = @(g);
    self.currentColor[kBlue] = @(b);
    
    // display rgb value
    self.redValueLabel.text = [NSString stringWithFormat:@"%d", r];
    self.greenValueLabel.text = [NSString stringWithFormat:@"%d", g];
    self.blueValueLabel.text = [NSString stringWithFormat:@"%d", b];
}

- (IBAction)saveThisColor:(id)sender
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    NSManagedObject *patch = [NSEntityDescription insertNewObjectForEntityForName:PATCH inManagedObjectContext:context];
    [patch setValue:self.currentColor[kRed] forKey:PATCH_COLOR_RED];
    [patch setValue:self.currentColor[kGreen] forKey:PATCH_COLOR_GREEN];
    [patch setValue:self.currentColor[kBlue] forKey:PATCH_COLOR_BLUE];
    
    NSError *error;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - Saved Colors

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:PATCH inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:PATCH_COLOR_RED ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"SAVED_COLOR"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.savedColorCollectionView insertItemsAtIndexPaths:@[[NSIndexSet indexSetWithIndex:sectionIndex]]];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.savedColorCollectionView deleteItemsAtIndexPaths:@[[NSIndexSet indexSetWithIndex:sectionIndex]]];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UICollectionView *collectionView = self.savedColorCollectionView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            break;
            
        case NSFetchedResultsChangeDelete:
            [collectionView deleteItemsAtIndexPaths:@[indexPath]];
            break;
            
        case NSFetchedResultsChangeUpdate:
            break;
            
        case NSFetchedResultsChangeMove:
            [collectionView deleteItemsAtIndexPaths:@[indexPath]];
            [collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            break;
    }
}

@end
