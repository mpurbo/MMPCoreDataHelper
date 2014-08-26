MMPCoreDataHelper
=================

A lightweight helper library for common CoreData tasks providing data access pattern inspired by [Active Record](http://en.wikipedia.org/wiki/Active_record_pattern), [LINQ](http://en.wikipedia.org/wiki/Language_Integrated_Query), and functional programming. Even if the library doesn't have the function you need, you can always fallback to the standard CoreData, but with thread-safe context bonus.

Features:
* Thread-safe singleton instance easily accessible from anywhere. No more worrying whether a MOC (NSManagedObjectContext) belongs to the thread or not. The library makes sure that the MOC is local to the whichever thread you're calling the function from.
* Functional [Active Record](http://en.wikipedia.org/wiki/Active_record_pattern) + [LINQ](http://en.wikipedia.org/wiki/Language_Integrated_Query)-inspired wrapper for common tasks.
* Automatic configuration and initialization (by convention over configuration) by default but manual configuration is still possible.
* Get notified on errors and other CoreData events using NSNotificationCenter.

## Installation

The recommended way to install is by using [CocoaPods](http://cocoapods.org/). Once you have CocoaPods installed, add the following line to your project's Podfile:
```
pod "MMPCoreDataHelper"
```

## Usage

Include the header file in your code:
```objectivec
#import <MMPCoreDataHelper/MMPCoreDataHelper.h>
```
In general, there is no need for database initialization and you can go right ahead directly using your model object to create and query records. See below for cases that requires you to explicitly set names before you start using the library.

### Create, Update, Delete, Save

Start directly with your CoreData model object (extended from NSManagedObject) and simply use `create`, `update`, and  `save` to create records:
```objectivec
// Create record
MMPArtist *artist = [[[MMPArtist create] 
                       update:@{@"id" : @"1", @"name" : @"Daft Punk"}] 
                       save];

// delete record
[[artist delete] save];

// saving several records once is more efficient, use MMPCoreDataHelper instance to do bulk saving.

[[MMPArtist create] update:@{@"id" : @"1", @"name" : @"Daft Punk"}];
[[MMPArtist create] update:@{@"id" : @"2", @"name" : @"Pink Floyd"}];
[[MMPArtist create] update:@{@"id" : @"3", @"name" : @"Porcupine Tree"}];

[[MMPCoreDataHelper instance] save];

```

### Fetching Data

To fetch data you need to first construct the query (defining constraints) then execute it to produce result. Call `query` to start building, then use `where` function to specify filter, `order` to define sort specification, `limit` to limit the number of result, `limit` to specify starting record number, and `error` to specify code block to be executed when error happens. For constructing `NSFetchedResultsController`, there are two additional functions: `sectionNameKeyPath`, and `cacheName`.

Once a query is constructed, there are several functions to actually produce result. Use `all` to get all records matches the specified constraints as array, `first` to get just the first one, `count` to just count the number of records without actually fetching anything, `each` to traverse each of the records using block, and `fetchedResultsController` to return `NSFetchedResultsController`.

Following code shows how to combine these functions to construct queries and execute it:
```objectivec

// fetch all artists
NSArray *artists = [[MMPArtist query] all];

// print all artists that starts with 'P' ordered by id using block
[[[[MMPArtist query]
              where:@"name LIKE %@", @"P*"]
              order:@"id"]
              each:^(MMPArtist *artist) {
                  NSLog(@"%@", artist.name);
              }];

// or just get the first one
MMPArtist *firstP = [[[[MMPArtist query]
                        where:@"name LIKE %@", @"P*"]
                        order:@"id"] 
                        first];
```

### Optional Initialization

No initialization or configuration necessary assuming the data model (momd) is named exactly the same as the application name. Otherwise, the data model name has to be set before calling any other of singleton's function:
```objectivec
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
```objectivec
NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyEntity"
                                          inManagedObjectContext:[MMPCoreDataHelper instance].managedObjectContext];
```

## Documentation

Not currently available, but I'll write documentation as I update the library.

## Contact

MMPCoreDataHelper is maintained by [Mamad Purbo](https://twitter.com/purubo)


## Copyright and License

MMPCoreDataHelper is available under the MIT license. See the LICENSE file for more info.
This library contains ideas and implementations adapted from ObjectiveRecord (https://github.com/supermarin/ObjectiveRecord). Copyright (c) 2014 Marin Usalj <http://supermar.in>
