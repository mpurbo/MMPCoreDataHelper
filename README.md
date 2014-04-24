MMPCoreDataHelper
=================

A no-nonsense straightforward helper library of wrapper functions for common CoreData tasks. Nothing hidden, no fancy [DAO](http://en.wikipedia.org/wiki/Data_access_object) or [Active Record](http://en.wikipedia.org/wiki/Active_record_pattern), just a practical way to simplify the use of the plain old CoreData. When the library doesn't have the function you need, you can always fallback to the standard CoreData.

Features:
* Thread-safe singleton instance easily accessible from anywhere. No more worrying whether a MOC (NSManagedObjectContext) belongs to the thread or not. The library makes sure that the MOC is local to the whichever thread you're calling the function from.
* Automatic configuration and initialization (by convention over configuration) by default but manual configuration is still possible.
* Provides simple functions for common CoreData usage pattern (query all objects, query by key-value, etc.)
* Get notified on errors and other CoreData events using NSNotificationCenter.


## Installation

The recommended way to install is by using [CocoaPods](http://cocoapods.org/). Once you have CocoaPods installed, add the following line to your project's Podfile:
```
pod 'MMPCoreDataHelper', '~> 0.5.0'
```
Don't forget to link CoreData.framework as well.


## Usage

Use the singleton instance anywhere in any thread in the application and call suitable function:
```objectivec
// get the singleton instance
MMPCoreDataHelper *db = [MMPCoreDataHelper instance];

// create new record (MMPArtist is a NSManagedObject)
artist = (MMPArtist *)[db createObjectOfEntity:[MMPArtist class]];
artist.id = @"2";
artist.name = @"Pink Floyd";

// save it
[db save];

// get all records
NSArray *artists = [db objectsOfEntity:[MMPArtist class]];
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
self.fetchedResultsController = [[MMPCoreDataHelper instance] fetchedResultsControllerForEntity:[MMPAlbum class]
                                                                                        orderBy:@"artist.name"
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
