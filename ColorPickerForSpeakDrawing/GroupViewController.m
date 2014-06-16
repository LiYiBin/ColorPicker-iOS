//
//  GroupViewController.m
//  ColorPickerForSpeakDrawing
//
//  Created by YiBin on 2014/6/16.
//  Copyright (c) 2014年 YB. All rights reserved.
//

#import "GroupViewController.h"
#import "MainAppDelegate.h"
#import "ModelsName.h"
#import "GroupTableViewCell.h"
#import "Group.h"
#import "Color.h"
#import "MainViewController.h"

#import <CoreData/CoreData.h>

@interface GroupViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation GroupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    MainAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITableView
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Identifier = @"GroupColorCell";
    
    GroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier forIndexPath:indexPath];
    
    NSManagedObject *group = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSSet *colors = [group valueForKey:kGroupColors];

    for (Color *color in colors) {
        
        CGFloat r = [color.red floatValue];
        CGFloat g = [color.green floatValue];
        CGFloat b = [color.blue floatValue];
        
        UIColor *currentColor = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
        NSString *currentColorRGB = [NSString stringWithFormat:@"RGB: %.0f, %.0f, %.0f", r, g, b];
        switch ([color.index intValue]) {
            case 0:
                cell.color1View.backgroundColor = currentColor;
                cell.color1Label.text = currentColorRGB;
                break;
            case 1:
                cell.color2View.backgroundColor = currentColor;
                cell.color2Label.text = currentColorRGB;
                break;
            case 2:
                cell.color3View.backgroundColor = currentColor;
                cell.color3Label.text = currentColorRGB;
                break;
            case 3:
                cell.color4View.backgroundColor = currentColor;
                cell.color4Label.text = currentColorRGB;
                break;
            case 4:
                cell.color5View.backgroundColor = currentColor;
                cell.color5Label.text = currentColorRGB;
                break;
            case 5:
                cell.color6View.backgroundColor = currentColor;
                cell.color6Label.text = currentColorRGB;
                break;
            case 6:
                cell.color7View.backgroundColor = currentColor;
                cell.color7Label.text = currentColorRGB;
                break;
            case 7:
                cell.color8View.backgroundColor = currentColor;
                cell.color8Label.text = currentColorRGB;
                break;
            case 8:
                cell.color9View.backgroundColor = currentColor;
                cell.color9Label.text = currentColorRGB;
                break;
            case 9:
                cell.color10View.backgroundColor = currentColor;
                cell.color10Label.text = currentColorRGB;
                break;
            case 10:
                cell.color11View.backgroundColor = currentColor;
                cell.color11Label.text = currentColorRGB;
                break;
            case 11:
                cell.color12View.backgroundColor = currentColor;
                cell.color12Label.text = currentColorRGB;
                break;
            default:
                break;
        }
    }
    
    return cell;
}


#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainViewController *viewController = [self.tabBarController viewControllers][0];
    Group *group = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    for (Color *color in group.colors) {
        [viewController sendSingleLedColorByBLE:color.index.intValue red:color.red.intValue green:color.green.intValue blue:color.blue.intValue];
    }
}

#pragma mark - core data

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:kGroup inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kGroupName ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Group"];
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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
