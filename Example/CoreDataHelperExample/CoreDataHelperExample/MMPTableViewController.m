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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    MMPAlbum *album = [_fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = album.name;
    cell.detailTextLabel.text = album.artist.name;
    
    return cell;
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
