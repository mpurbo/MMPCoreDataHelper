MMPCoreDataHelper
=================

A lightweight helper library for common CoreData tasks providing data access pattern inspired by [Active Record](http://en.wikipedia.org/wiki/Active_record_pattern), [LINQ](http://en.wikipedia.org/wiki/Language_Integrated_Query), and functional programming. Even if the library doesn't have the function you need, you can always fallback to the standard CoreData, but with thread-safe context bonus.

Features:
* Thread-safe singleton instance easily accessible from anywhere. No more worrying whether a MOC (NSManagedObjectContext) belongs to the thread or not. The library makes sure that the MOC is local to the whichever thread you're calling the function from.
* Functional [Active Record](http://en.wikipedia.org/wiki/Active_record_pattern) + [LINQ](http://en.wikipedia.org/wiki/Language_Integrated_Query)-inspired wrapper for common tasks.
* Import data directly from CSV file.
* Automatic configuration and initialization (by convention over configuration) by default but manual configuration is still possible.
* Get notified on errors and other CoreData events using NSNotificationCenter.

## Installation

The recommended way to install is by using [CocoaPods](http://cocoapods.org/). Once you have CocoaPods installed, add the following line to your project's Podfile:
```
pod "MMPCoreDataHelper"
```

## Usage

Include the header file in your code:
```objc
#import <MMPCoreDataHelper/MMPCoreDataHelper.h>
```
In general, there is no need for database initialization and you can go right ahead directly using your model object to create and query records. See [below](#optional-initialization) for cases that require you to explicitly set names before you start using the library.

### Create, Update, Delete, Save

Start directly with your CoreData model object (extended from NSManagedObject) and simply use `create`, `update`, and  `save` to create records:
```objc
// Create record
MMPArtist *artist = [[[MMPArtist create] 
                       update:@{@"id" : @"1", @"name" : @"Daft Punk"}] 
                       save];

// delete record
[[artist delete] save];

// saving several records once is more efficient, use MMPCoreDataHelper shared instance to do bulk saving.

[[MMPArtist create] update:@{@"id" : @"1", @"name" : @"Daft Punk"}];
[[MMPArtist create] update:@{@"id" : @"2", @"name" : @"Pink Floyd"}];
[[MMPArtist create] update:@{@"id" : @"3", @"name" : @"Porcupine Tree"}];

[MMPCoreDataHelper save];
```

Use `clear` to delete all records in an entity:
```objc
[MMPAlbum clear];
```

### Fetching Data

To fetch data you need to first construct the query (defining constraints) then execute it to produce result. Call `query` to start building, then use `where` function to specify filter, `order` to define sort specification, `limit` to limit the number of result, `offset` to specify starting record number, and `error` to specify code block to be executed when error happens. For constructing `NSFetchedResultsController`, there are two additional functions: `sectionNameKeyPath`, and `cacheName`.

Once a query is constructed, there are several functions to actually produce result. Use `all` to get all records matches the specified constraints as array, `first` to get just the first one, `count` to just count the number of records without actually fetching anything, `each` to traverse each of the records using block, and `fetchedResultsController` to return `NSFetchedResultsController`.

Following code shows how to combine these functions to construct queries and execute it:
```objc
// fetch all artists
NSArray *artists = [[MMPArtist query] all];

// print all artists that starts with 'P' ordered by id using block
[[[[MMPArtist query]
              where:@"name LIKE %@", @"P*"]
              order:@"id"]
              each:^(MMPArtist *artist) {
                  NSLog(@"%@", artist.name);
              }];

// or just get the first record of the query
// note that you can also pass NSDictionary of key = value constraint to where function
MMPArtist *artist = [[[MMPArtist query]
                                 where:@{@"name" : @"Pink Floyd"}]
                                 first];
                                 
// many ways to construct where constraint
artist = [[[MMPArtist query]
                      where:@"name == 'Pink Floyd'"]
                      first];
                      
artists = [[[MMPArtist query]
                       where:@"name == 'Pink Floyd' OR name == 'Led Zeppelin'"]
                       all];
                       
artists = [[[MMPArtist query]
                       where:@"name == %@ OR name == %@", @"Queen", @"Gojira"]
                       all];
                       
// or even use NSPredicate if you feel like it
NSPredicate *predicate = ...
artists = [[[MMPArtist query]
                       where:predicate
                       all];
                                 
// use fetchedResultsController to create NSFetchedResultsController from a query
self.fetchedResultsController = [[[[MMPAlbum query]
                                             order:@"artist.name"]
                                             sectionNameKeyPath:@"artist.name"]
                                             fetchedResultsController];
```
Here's some examples on how to construct more complex ordering:
```objc
artists = [[[MMPArtist query] 
                       order:@"name ASC, members DESC"
                       all];
                       
// same ordering different way
artists = [[[MMPArtist query] 
                       order:@{@"name" : @"ASC", @"members" : @"DESC"}
                       all];
```

### Aggregate Attribute Values

The equivalent of SQL's `count`, `min`, `max`, and `sum` is also available as can be seen in the following example:
```objc
// counting all records
NSLog(@"Database initialized, %lu artists created", [[MMPArtist query] count]);

// getting minimum, maximum, and sum of attribute "members"
NSLog(@"### unfiltered artists' members aggregate: min = %@, max = %@, sum = %@",
          [[MMPArtist query] min:@"members"],
          [[MMPArtist query] max:@"members"],
          [[MMPArtist query] sum:@"members"]);

// getting minimum, maximum, and sum of attribute "members" for artists with name that starts with "D"
MMPCoreDataQueryable *artistsD =[[MMPArtist query] where:@"name LIKE %@", @"D*"];
NSLog(@"### D artists' members aggregate: min = %@, max = %@, sum = %@",
      [artistsD min:@"members"],
      [artistsD max:@"members"],
      [artistsD sum:@"members"]);
```

### Importing Data from CSV File

To import data from CSV file, call `importer` to start building the importer, use `sourceURL` to specify the CSV source URL, `error` to specify code block to be executed on errors, `each` to observe newly imported record, and finally call `import` to start executing.
```objc
// source CSV (with first line header/field names):
// id,name
// 100,Yes
[[[[[[MMPArtist importer]
                sourceType:MMPCoreDataSourceTypeCSV]
                sourceURL:[[NSBundle mainBundle] URLForResource: @"artists" withExtension:@"csv"]]
                error:^(NSError *error) {
                    NSLog(@"[ERROR] error importing from artists CSV: %@", error);
                }]
                each:^(MMPArtist *importedArtist) {
                    NSLog(@"artist %@ imported", importedArtist.name);
                }]
                import];
```

You can also filter unnecessary field values so that it won't be added to the record by using `filter:using:` method:
```objc
// CSV format:
// id,name,genre
// 100,Yes,"Progressive Rock"
// "genre" field will be ignored
[[[[[[[MMPArtist importer]
                 sourceType:MMPCoreDataSourceTypeCSV]
                 sourceURL:[[NSBundle mainBundle] URLForResource: @"artists" withExtension:@"csv"]]
                 error:^(NSError *error) {
                     NSLog(@"[ERROR] error importing from artists CSV: %@", error);
                 }]
                 filter:@"genre" using:^BOOL(id record) {
                     return NO;
                 }]
                 each:^(MMPArtist *importedArtist) {
                     NSLog(@"artist %@ imported", importedArtist.name);
                 }]
                 import];
```

For field-level transformation and custom data conversion (e.g. to populate relationship object) use `map:using:`. For record-level transformation use `map` as shown in the following example:
```objc
// source CSV (with first line header/field names):
// name,artist
// "The Yes Album",Yes
[[[[[[[[MMPAlbum importer]
                 sourceType:MMPCoreDataSourceTypeCSV]
                 sourceURL:[[NSBundle mainBundle] URLForResource: @"albums" withExtension:@"csv"]]
                 error:^(NSError *error) {
                     NSLog(@"[ERROR] error importing from albums CSV: %@", error);
                 }]
                 // map field "artist" from artist's name to NSManagedObject so that it can be set as relationship
                 map:@"artist" using:^MMPArtist *(NSString *value, NSUInteger index) {
                     return [[[MMPArtist query]
                                         where:@{@"name" : value}]
                                         first];
                 }]
                 // map record (populates ID)
                 map:^id(MMPAlbum *importedAlbum, NSUInteger index) {
                     // generate album ID based on artist ID and record index (line on the csv file)
                     importedAlbum.id = [NSString stringWithFormat:@"%@-%lu", importedAlbum.artist.id, (unsigned long)index];
                     return importedAlbum;
                 }]
                 each:^(MMPAlbum *importedAlbum) {
                     NSLog(@"album %@(id = %@) imported for artist %@",
                           importedAlbum.name,
                           importedAlbum.id,
                           importedAlbum.artist.name);
                 }]
                 import];
```

### Optional Initialization

No initialization or configuration necessary assuming the data model (momd) is named exactly the same as the application name. Otherwise, the data model name has to be set before calling any other of singleton's function:
```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Set singleton's data model name
  [MMPCoreDataHelper instance].modelName = @"MyDataModel";

  // Do other application initialization...
  
  return YES;
}
```

### CoreData Fallback

Should you need to use CoreData directly, simply use thread-safe MOC provided by the singleton instance, for example:
```objc
NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyEntity"
                                          inManagedObjectContext:[MMPCoreDataHelper instance].managedObjectContext];
```

## Documentation

Not currently available, but I'll write documentation as I update the library. If you have any questions or requests for features, please feel free to contact me or create issues.

## Contact

MMPCoreDataHelper is maintained by [Mamad Purbo](https://twitter.com/purubo)


## Copyright and License

MMPCoreDataHelper is available under the MIT license. See the LICENSE file for more info.

This library uses code adapted from ObjectiveRecord (https://github.com/supermarin/ObjectiveRecord). Copyright (c) 2014 Marin Usalj <http://supermar.in>
