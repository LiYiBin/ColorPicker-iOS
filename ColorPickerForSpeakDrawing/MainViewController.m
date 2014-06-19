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
#import "LedEffectDefinition.h"
#import "Group.h"
#import "Color.h"

#import <CoreData/CoreData.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <RSColorPickerView.h>

#define RBL_SERVICE_UUID "713D0000-503E-4C75-BA94-3148F18D941E"
#define RBL_CHAR_TX_UUID "713D0002-503E-4C75-BA94-3148F18D941E"
#define RBL_CHAR_RX_UUID "713D0003-503E-4C75-BA94-3148F18D941E"
#define RBL_BLE_FRAMEWORK_VER 0x0200

#define kRed @"red"
#define kGreen @"green"
#define kBlue @"blue"

@interface MainViewController () <RSColorPickerViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

// for patch view
@property (weak, nonatomic) IBOutlet UICollectionView *patchCollectionView;

// for color picker
@property (weak, nonatomic) IBOutlet RSColorPickerView *colorPickerView;
@property (weak, nonatomic) IBOutlet UIView *patchView;
@property (weak, nonatomic) IBOutlet UILabel *redValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *greenValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *blueValueLabel;
@property (strong, nonatomic) NSMutableDictionary *selectionPatchs;
- (void)selectionPatchChnage:(UISwitch *)sender;

// for saving data
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
- (IBAction)saveThisColor:(id)sender;
- (IBAction)saveAllColor:(id)sender;
- (IBAction)closeAllLeds:(id)sender;

// for saving color
@property (weak, nonatomic) IBOutlet UICollectionView *savedColorCollectionView;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

// for bluetooth
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *activePeripheral;

- (void)changeColor:(UIColor *)color;

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
    
    // setup for core data
    MainAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    // setup for bluetooth
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBConnectPeripheralOptionNotifyOnNotificationKey: @YES}];
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
        patchCell.number = @(indexPath.item);
        [patchCell.controlSwitch addTarget:self action:@selector(selectionPatchChnage:) forControlEvents:UIControlEventValueChanged];
        
        cell = patchCell;
        
    } else if (collectionView == self.savedColorCollectionView) {
        static NSString *SavedColorIdentifier = @"SavedColorCell";
        
        UICollectionViewCell *colorCell = [collectionView dequeueReusableCellWithReuseIdentifier:SavedColorIdentifier forIndexPath:indexPath];
        
        NSManagedObject *patch = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSNumber *red = [patch valueForKey:kPATCH_COLOR_RED];
        NSNumber *green = [patch valueForKey:kPATCH_COLOR_GREEN];
        NSNumber *blue = [patch valueForKey:kPATCH_COLOR_BLUE];
        
        colorCell.backgroundColor = [UIColor colorWithRed:red.intValue/255.0 green:green.intValue/255.0 blue:blue.intValue/255.0 alpha:1.0];
        
        cell = colorCell;
    }
    
    return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.savedColorCollectionView) {
        NSManagedObject *patch = [self.fetchedResultsController objectAtIndexPath:indexPath];
        CGFloat r = [[patch valueForKey:kPATCH_COLOR_RED] floatValue];
        CGFloat g = [[patch valueForKey:kPATCH_COLOR_GREEN] floatValue];
        CGFloat b = [[patch valueForKey:kPATCH_COLOR_BLUE] floatValue];
        
        UIColor *color = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
        
        [self changeColor:color];
    }
}

#pragma mark - Color picker

- (void)selectionPatchChnage:(UISwitch *)sender
{
    PatchCollectionViewCell *cell = (PatchCollectionViewCell *)[[sender superview] superview];

    if (sender.on) {
        [self.selectionPatchs setObject:cell forKey:cell.number];
    } else {
        [self.selectionPatchs removeObjectForKey:cell.number];
    }
}

- (NSDictionary *)parseRGB:(UIColor *)color
{
    // current rgb float value
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    // convert rgb float to int value
    int r = red * 255;
    int g = green * 255;
    int b = blue * 255;
    
    return @{kRed: @(r), kGreen: @(g), kBlue: @(b)};
}

- (void)changeColor:(UIColor *)color
{
    NSDictionary *rgb = [self parseRGB:color];
    int r = [rgb[kRed] intValue];
    int g = [rgb[kGreen] intValue];
    int b = [rgb[kBlue] intValue];
    
    // display rgb value
    self.redValueLabel.text = [NSString stringWithFormat:@"%d", r];
    self.greenValueLabel.text = [NSString stringWithFormat:@"%d", g];
    self.blueValueLabel.text = [NSString stringWithFormat:@"%d", b];
    
    // for display color
    self.patchView.backgroundColor = color;
    PatchCollectionViewCell *cell = nil;
    for (NSNumber *patch in self.selectionPatchs.allKeys) {
        cell = self.selectionPatchs[patch];
        cell.colorView.backgroundColor = color;
        
        // send led color data
        [self sendSingleLedColorByBLE:patch.intValue red:r green:g blue:b];
    }
}

#pragma mark RSColorPickerViewDelegate

- (void)colorPickerDidChangeSelection:(RSColorPickerView *)cp
{
    [self changeColor:cp.selectionColor];
}

- (IBAction)saveThisColor:(id)sender
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    NSDictionary *rgb = [self parseRGB:self.patchView.backgroundColor];
    
    NSManagedObject *patch = [NSEntityDescription insertNewObjectForEntityForName:kPATCH inManagedObjectContext:context];
    [patch setValue:rgb[kRed] forKey:kPATCH_COLOR_RED];
    [patch setValue:rgb[kGreen] forKey:kPATCH_COLOR_GREEN];
    [patch setValue:rgb[kBlue] forKey:kPATCH_COLOR_BLUE];
    
    NSError *error;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (IBAction)saveAllColor:(id)sender
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    Group *group = [NSEntityDescription insertNewObjectForEntityForName:kGroup inManagedObjectContext:context];
   
    for (int i = 0; i < 12; i++) {
        PatchCollectionViewCell *cell = (PatchCollectionViewCell *)[self.patchCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        NSDictionary *rgb = [self parseRGB:cell.colorView.backgroundColor];
        
        Color *color = [NSEntityDescription insertNewObjectForEntityForName:kColor inManagedObjectContext:context];
        color.red = rgb[kRed];
        color.green = rgb[kGreen];
        color.blue = rgb[kBlue];
        color.index = @(i);
        
        [group addColorsObject:color];
    }

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
    NSEntityDescription *entity = [NSEntityDescription entityForName:kPATCH inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kPATCH_COLOR_RED ascending:NO];
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

#pragma mark - Core Bluetooth
#pragma mark CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"Central Manager did update state: %@", [central description]);
    if (central.state != CBCentralManagerStatePoweredOn) {
        return;
    }
    
    [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@RBL_SERVICE_UUID]] options:nil];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Dicovered peripheral: %@", peripheral.identifier);
    if (self.activePeripheral != peripheral) {
        self.activePeripheral = peripheral;
        self.activePeripheral.delegate = self;
        
        [central connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnNotificationKey: @YES}];
        [central stopScan];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connect peripheral: %@, %@", peripheral.name, [peripheral.identifier UUIDString]);

    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Fail to connect peripheral: %@, %@", [peripheral.identifier UUIDString], error);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"BLE" message:@"Connection failed" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Disconnect peripheral: %@, %@", peripheral.name, [peripheral.identifier UUIDString]);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"BLE" message:@"Disconnect" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    
    self.activePeripheral = nil;
    [central scanForPeripheralsWithServices:nil options:nil];
    [central retrievePeripheralsWithIdentifiers:@[peripheral.identifier]];
}

#pragma mark CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Service discovery was unsuccessful!");
        return;
    }
    
    NSLog(@"Services of peripheral with UUID : %@ found", [peripheral.identifier UUIDString]);
    
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service %@", service);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Characteristic discorvery unsuccessful!");
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Discovered characteristic %@", characteristic);
        
//        UInt8 buf[] = {0x00};
//        NSData *data = [NSData dataWithBytes:buf length:1];
//        [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Characteristic update unsuccessful!");
        return;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", [error localizedDescription]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error writing characteristic value: %@", [error localizedDescription]);
    }
}

#pragma mark - Control led effect

- (CBCharacteristic *)findCharacteristicOfLedEffect
{
    CBService *service = [self findServiceOfLedEffect];

    if (!service) {
        NSLog(@"Find service unsuccessful!");
        return nil;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([[characteristic.UUID UUIDString] isEqualToString:@RBL_CHAR_RX_UUID]) {
            return characteristic;
        }
    }
    
    return nil;
}

- (CBService *)findServiceOfLedEffect
{
    for (CBService *service in self.activePeripheral.services) {
        if ([[service.UUID UUIDString] isEqualToString:@RBL_SERVICE_UUID]) {
            return service;
        }
    }
    
    return nil;
}

- (IBAction)closeAllLeds:(id)sender
{
    UInt8 buf[] = {kInit, 0x00, 0x00, 0x00, 0x00};
    NSData *data = [NSData dataWithBytes:buf length:5];
    
    [self sendLedDataByBLE:data];
}

- (void)sendSingleLedColorByBLE:(int)led red:(int)red green:(int)green blue:(int)blue
{
    UInt8 buf[] = {kChangeSingleLedColor, 0x00, 0x00, 0x00, 0x00};
    buf[1] = led;
    buf[2] = red;
    buf[3] = green;
    buf[4] = blue;

    NSData *data = [NSData dataWithBytes:buf length:5];
    
    [self sendLedDataByBLE:data];
}

- (void)sendLedDataByBLE:(NSData *)data
{
    CBCharacteristic *characteristic = [self findCharacteristicOfLedEffect];
    
    if (!characteristic) {
        NSLog(@"Find characteristic unsuccessful!");
        return;
    }
    
    [self.activePeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}

@end
