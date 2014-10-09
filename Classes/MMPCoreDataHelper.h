//
//  MMPCoreDataHelper.h
//
//  The MIT License (MIT)
//  Copyright (c) 2014 Mamad Purbo, <http://mamad.purbo.org>
//
//  This library includes ideas and implementations adapted from ObjectiveRecord
//  (https://github.com/supermarin/ObjectiveRecord)
//  Copyright (c) 2014 Marin Usalj <http://supermar.in>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSManagedObject+MMPCoreDataActive.h"

/**
 *  Library's error domain
 */
extern NSString * const MMPCoreDataErrorDomain;

/**
 *  Notification sent on error commiting changes. Observe this notification on NSNotificationManager to 
 *  be notified on errors. The actual NSError object can be accessed from userInfo (with key "error") 
 *  passed along with NSNotification.
 */
extern NSString * const MMPDataAccessSaveErrorNotification;

/**
 *  Notification sent after all changes are commited.
 */
extern NSString * const MMPDataAccessDidSaveNotification;

/**
 *  Thread-safe CoreData wrapper with helper functions for common tasks.
 */
@interface MMPCoreDataHelper : NSObject

/**
 *  Context local to the accessing thread. When used in a background thread, the context
 *  returned will be a child of main thread's context and all changes made on the context
 *  will be propragated to main thread's context when saved.
 */
@property (readonly, strong) NSManagedObjectContext *managedObjectContext;

/**
 *  Object model used by this class.
 */
@property (readonly, strong) NSManagedObjectModel *managedObjectModel;

/**
 *  Store coordinator used by this class.
 */
@property (readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/**
 *  Database (.sqlite) file name used by this class. Set this value before calling any function to
 *  customize sqlite file name. Otherwise it will default to application name (value of CFBundleName).
 */
@property (copy, nonatomic) NSString *databaseName;

/**
 *  Model (.momd) file name used by this class. Set this value before calling any function to
 *  customize momd file name. Otherwise it will default to application name (value of CFBundleName).
 */
@property (copy, nonatomic) NSString *modelName;

/**---------------------------------------------------------------------------------------
 * @name General
 *  ---------------------------------------------------------------------------------------
 */

// clue for improper use (produces compile time error)
+ (instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
- (instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+ (instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

/**
 *  Gets the singleton object of this class.
 *
 *  @return Singleton object of this class.
 */
+ (instancetype)instance;

/**
 *  Gets the path to physical sqlite file.
 *
 *  @return Path to physical sqlite file.
 */
- (NSString *)sqliteStorePath;

/**
 *  Gets description of an entity class.
 *
 *  @return Description of the entity class specified.
 */
+ (NSEntityDescription *)entityDescriptionOf:(Class)entityClass;

/**
 *  Commits all changes asynchronously regardless of which thread this method is called from. 
 *  If this method is called on a background thread, the changes will be propagated to main thread 
 *  context as well.
 */
+ (void)save;

/**---------------------------------------------------------------------------------------
 * @name Create, update, and delete
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Create a new object of entity type as specified.
 *
 *  @param entityClass Class extended from NSManagedObject
 *
 *  @return A new object of entity type as specified.
 */
+ (id)createObjectOfEntity:(Class)entityClass;

/**
 *  Deletes a single object.
 *
 *  @param object Object to be deleted
 */
+ (void)deleteObject:(NSManagedObject *)object;

/**
 *  Deletes all objects of an entity type (clear table).
 *
 *  @param entityClass Class extended from NSManagedObject
 */
+ (void)deleteObjectsOfEntity:(Class)entityClass;

/**---------------------------------------------------------------------------------------
 * @name Utilities
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  A wrapper for NSManagedObjectContext's objectWithID:
 *
 *  @param objectID An object ID.
 *
 *  @return The object for the specified ID.
 */
+ (id)objectWithID:(NSManagedObjectID *)objectID;

+ (NSPredicate *)predicateFromObject:(id)condition arguments:(va_list)arguments;

/**---------------------------------------------------------------------------------------
 * @name Query producing multiple objects
 *  ---------------------------------------------------------------------------------------
 */

+ (NSArray *)objectsOfEntity:(Class)entityClass
                       where:(id)condition
                       order:(id)order
                       limit:(NSNumber *)numberOfRecords
                      offset:(NSNumber *)fromRecordNum
                       error:(NSError **)error;

+ (NSArray *)objectsOfEntity:(Class)entityClass
               withPredicate:(NSPredicate *)predicate
             sortDescriptors:(NSArray *)sortDescriptors
                  fetchLimit:(NSNumber *)fetchLimit
                 fetchOffset:(NSNumber *)fetchOffset
                       error:(NSError **)error;

/**---------------------------------------------------------------------------------------
 * @name Aggregate query
 *  ---------------------------------------------------------------------------------------
 */

+ (NSUInteger)countObjectsOfEntity:(Class)entityClass
                             where:(id)condition
                             error:(NSError **)error;

+ (NSUInteger)countObjectsOfEntity:(Class)entityClass
                     withPredicate:(NSPredicate *)predicate
                             error:(NSError **)error;

#if TARGET_OS_IPHONE
/**---------------------------------------------------------------------------------------
 * @name Query producing NSFetchedResultsController
 *  ---------------------------------------------------------------------------------------
 */

+ (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                            where:(id)condition
                                                            order:(id)order
                                                            limit:(NSNumber *)numberOfRecords
                                                           offset:(NSNumber *)fromRecordNum
                                               sectionNameKeyPath:(NSString *)sectionNameKeyPath
                                                        cacheName:(NSString *)cacheName;

+ (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                    withPredicate:(NSPredicate *)predicate
                                                  sortDescriptors:(NSArray *)sortDescriptors
                                                       fetchLimit:(NSNumber *)fetchLimit
                                                      fetchOffset:(NSNumber *)fetchOffset
                                               sectionNameKeyPath:(NSString *)sectionNameKeyPath
                                                        cacheName:(NSString *)cacheName;
#endif
@end
