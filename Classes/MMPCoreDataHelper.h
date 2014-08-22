//
//  MMPCoreDataHelper.h
//
//  The MIT License (MIT)
//  Copyright (c) 2014 Mamad Purbo, purbo.org
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
 *  Commits all changes asynchronously regardless of which thread this method is called from. 
 *  If this method is called on a background thread, the changes will be propagated to main thread 
 *  context as well.
 */
- (void)save;

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
- (id)createObjectOfEntity:(Class)entityClass;

/**
 *  Deletes a single object.
 *
 *  @param object Object to be deleted
 */
- (void)deleteObject:(NSManagedObject *)object;

/**
 *  Deletes all objects of an entity type (clear table).
 *
 *  @param entityClass Class extended from NSManagedObject
 */
- (void)deleteObjectsOfEntity:(Class)entityClass;

/**---------------------------------------------------------------------------------------
 * @name Query producing multiple objects
 *  ---------------------------------------------------------------------------------------
 */

- (NSArray *)objectsOfEntity:(Class)entityClass;
- (NSArray *)objectsOfEntity:(Class)entityClass
                     orderBy:(NSString *)column;
- (NSArray *)objectsOfEntity:(Class)entityClass
                 havingValue:(id)value
                   forColumn:(NSString *)column;
- (NSArray *)objectsOfEntity:(Class)entityClass
                 havingValue:(id)value
                   forColumn:(NSString *)column
                     orderBy:(NSString *)orderColumn;
- (NSArray *)objectsOfEntity:(Class)entityClass
             havingValueLike:(id)value forColumn:(NSString *)column
                     orderBy:(NSString *)orderColumn;
- (NSArray *)objectsOfEntity:(Class)entityClass
         havingValuesForKeys:(NSDictionary *)valuesForKeys;

- (NSArray *)objectsOfEntity:(Class)entityClass
   havingValuesForPredicates:(NSDictionary *)predicatesForKeys
                     orderBy:(NSString *)orderColumn;
- (NSArray *)objectsOfEntity:(Class)entityClass
               withPredicate:(NSPredicate *)predicate
                     orderBy:(NSArray *)sortDescriptors;

/**---------------------------------------------------------------------------------------
 * @name Query producing single object
 *  ---------------------------------------------------------------------------------------
 */

- (id)objectOfEntity:(Class)entityClass
         havingValue:(id)value
           forColumn:(NSString *)column;
- (id)objectOfEntity:(Class)entityClass
 havingValuesForKeys:(NSDictionary *)valuesForKeys;

/**---------------------------------------------------------------------------------------
 * @name Counting object
 *  ---------------------------------------------------------------------------------------
 */

- (NSUInteger)countObjectsOfEntity:(Class)entityClass;
- (NSUInteger)countObjectsOfEntity:(Class)entityClass
                       havingValue:(id)value
                         forColumn:(NSString *)column;

/**---------------------------------------------------------------------------------------
 * @name Query producing NSFetchedResultsController
 *  ---------------------------------------------------------------------------------------
 */

- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                          orderBy:(NSString *)columnName;
- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                          orderBy:(NSString *)columnName
                                               sectionNameKeyPath:(NSString *)sectionNameKeyPath;
- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                      havingValue:(id)value
                                                        forColumn:(NSString *)column
                                                          orderBy:(NSString *)columnName;
- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                    withPredicate:(NSPredicate *)predicate
                                                          orderBy:(NSArray *)sortDescriptors;
- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                    withPredicate:(NSPredicate *)predicate
                                                          orderBy:(NSArray *)sortDescriptors
                                               sectionNameKeyPath:(NSString *)sectionNameKeyPath;
- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                    withPredicate:(NSPredicate *)predicate
                                                          orderBy:(NSArray *)sortDescriptors
                                               sectionNameKeyPath:(NSString *)sectionNameKeyPath
                                                        cacheName:(NSString *)cacheName;

@end
