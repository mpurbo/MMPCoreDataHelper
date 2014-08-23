MMPCoreDataHelper
=================

A no-nonsense straightforward helper library of wrapper functions for common CoreData tasks. When the library doesn't have the function you need, you can always fallback to the standard CoreData.

Features:
* [Active Record](http://en.wikipedia.org/wiki/Active_record_pattern)-like wrapper for common tasks.
* Thread-safe singleton instance easily accessible from anywhere. No more worrying whether a MOC (NSManagedObjectContext) belongs to the thread or not. The library makes sure that the MOC is local to the whichever thread you're calling the function from.
* Automatic configuration and initialization (by convention over configuration) by default but manual configuration is still possible.
* Provides simple functions for common CoreData usage pattern (query all objects, query by key-value, etc.)
* Get notified on errors and other CoreData events using NSNotificationCenter.


## Installation

The recommended way to install is by using [CocoaPods](http://cocoapods.org/). Once you have CocoaPods installed, add the following line to your project's Podfile:
```
pod "MMPCoreDataHelper"
```


## Usage

Use the singleton instance anywhere in any thread in the application and call suitable function:
```objectivec
// create new record (MMPArtist is a NSManagedObject)
artist = [MMPArtist create];
artist.id = @"2";
artist.name = @"Pink Floyd";

// save it
[artist save];

// get all records
NSArray *artists = [MMPArtist all];
```

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

Functions producing NSFetchedResultsController are also available, for example:
```objectivec
self.fetchedResultsController = [MMPAlbum fetchAllOrderBy:@"artist.name"
                                       sectionNameKeyPath:@"artist.name"];
```

Should you need to use CoreData directly, simply use thread-safe MOC provided by the singleton instance, for example:
```objectivec
NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyEntity"
                                          inManagedObjectContext:[MMPCoreDataHelper instance].managedObjectContext];
```

## Documentation

Not currently available, but I'll write documentation as I update the library.

## Contact

MMPCoreDataHelper is maintained by [Mamad Purbo](https://twitter.com/purubo)


## License

MMPCoreDataHelper is available under the MIT license. See the LICENSE file for more info.
