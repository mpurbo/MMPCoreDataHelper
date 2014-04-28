//
//  MMPTableViewController.m
//  CoreDataHelperExample
//
//  Created by Purbo Mohamad on 4/18/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import "MMPTableViewController.h"
#import "MMPCoreDataHelper.h"
#import "MMPArtist.h"
#import "MMPAlbum.h"

@interface MMPTableViewController ()<NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation MMPTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)initDatabase
{
    // the singleton instance of MMPCoreDataHelper
    MMPCoreDataHelper *db = [MMPCoreDataHelper instance];
    
    MMPArtist *artist = (MMPArtist *)[db createObjectOfEntity:[MMPArtist class]];
    artist.id = @"1";
    artist.name = @"Daft Punk";
    
    MMPAlbum *album = (MMPAlbum *)[db createObjectOfEntity:[MMPAlbum class]];
    album.id = @"1-1";
    album.name = @"Homework";
    album.artist = artist;
    
    album = (MMPAlbum *)[db createObjectOfEntity:[MMPAlbum class]];
    album.id = @"1-2";
    album.name = @"Discovery";
    album.artist = artist;
    
    artist = (MMPArtist *)[db createObjectOfEntity:[MMPArtist class]];
    artist.id = @"2";
    artist.name = @"Pink Floyd";
    
    album = (MMPAlbum *)[db createObjectOfEntity:[MMPAlbum class]];
    album.id = @"2-1";
    album.name = @"Animal";
    album.artist = artist;
    
    album = (MMPAlbum *)[db createObjectOfEntity:[MMPAlbum class]];
    album.id = @"2-2";
    album.name = @"The Wall";
    album.artist = artist;

    [db save];
    
    NSLog(@"Database initialized, %lu artists created", (unsigned long)[db objectsOfEntity:[MMPArtist class]].count);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // the singleton instance of MMPCoreDataHelper
    MMPCoreDataHelper *db = [MMPCoreDataHelper instance];
    
    // check if the data is already created
    NSArray *artists = [db objectsOfEntity:[MMPArtist class]];
    if (!artists || artists.count == 0) {
        [self initDatabase];
    } else {
        NSLog(@"Database ready");
    }
    
    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    // run some dummy DB operation in background for fun
    dispatch_async(dispatch_queue_create("BkgQ", NULL), ^{
        
        MMPArtist *artist = (MMPArtist *)[db objectOfEntity:[MMPArtist class]
                                                havingValue:@"Pink Floyd"
                                                  forColumn:@"name"];
        
        for (int i = 0; i < 5; i++) {
            // add a new album every 2 seconds
            sleep(2);
            MMPAlbum *album = (MMPAlbum *)[db createObjectOfEntity:[MMPAlbum class]];
            album.id = [NSString stringWithFormat:@"dummy-%d", i];
            album.name = [NSString stringWithFormat:@"Dummy %d", i];;
            album.artist = artist;
            [db save];
            // table view should be automatically refreshed by now
            NSLog(@"Dummy album with ID %@ saved", album.id);
        }
        
        NSArray *dummyAlbums = [db objectsOfEntity:[MMPAlbum class]
                                   havingValueLike:@"dummy-*"
                                         forColumn:@"id"
                                           orderBy:@"id"];
        
        NSLog(@"%d dummy albums about to be deleted", [dummyAlbums count]);
        for (MMPAlbum *album in dummyAlbums) {
            // delete album every 2 seconds
            sleep(2);
            [db deleteObject:album];
            [db save];
        }
        
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_fetchedResultsController sections].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [_fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    MMPAlbum *album = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = album.name;
    cell.detailTextLabel.text = album.artist.name;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
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


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    self.fetchedResultsController = [[MMPCoreDataHelper instance] fetchedResultsControllerForEntity:[MMPAlbum class]
                                                                                            orderBy:@"artist.name"
                                                                                 sectionNameKeyPath:@"artist.name"];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
    
}

@end
