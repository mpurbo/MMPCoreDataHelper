MMPCoreDataHelper
=================

A no-nonsense straightforward helper library providing wrapper functions for common CoreData tasks. Nothing hidden, no fancy DAO or active record, just a way to simplify plain old CoreData uses. 

Features:
* Thread-safe singleton instance easily accessible from anywhere. No more worrying whether a MOC belongs to the thread or not.
* Automatic configuration and initialization (by convention over configuration), although manual configuration is still possible.
* Simple functions for common CoreData usage pattern (query all objects, query by key-value, etc.), although direct CoreData access is still possible.
* Get notified on errors and other CoreData events using NSNotificationCenter.

## Usage

Use the singleton instance anywhere in any thread in the application and call suitable function:
```objectivec
NSArray *artists = [[MMPCoreDataHelper instance] objectsOfEntity:[MMPArtist class]];
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
