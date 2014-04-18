//
//  MMPCoreDataHelper.h
//
//  Created by Purbo Mohamad on 11/10/13.
//  Copyright (c) 2013 purbo.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString * const MMPDataAccessSaveErrorNotification;
extern NSString * const MMPDataAccessDidSaveNotification;

@interface MMPCoreDataHelper : NSObject

@property (readonly, strong) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (copy, nonatomic) NSString *databaseName;
@property (copy, nonatomic) NSString *modelName;

// clue for improper use (produces compile time error)
+ (instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
- (instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+ (instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

+ (instancetype)instance;
- (NSString *)sqliteStorePath;

- (void)save;
- (NSManagedObject *)createObjectOfEntity:(Class)entityClass;

- (void)deleteObject:(NSManagedObject *)object;
- (void)deleteObjectsOfEntity:(Class)entityClass;

- (NSArray *)objectsOfEntity:(Class)entityClass;
- (NSArray *)objectsOfEntity:(Class)entityClass orderBy:(NSString *)column;
- (NSArray *)objectsOfEntity:(Class)entityClass havingValue:(id)value forColumn:(NSString *)column;
- (NSArray *)objectsOfEntity:(Class)entityClass havingValue:(id)value forColumn:(NSString *)column orderBy:(NSString *)orderColumn;
- (NSArray *)objectsOfEntity:(Class)entityClass havingValuesForKeys:(NSDictionary *)valuesForKeys;
- (NSArray *)objectsOfEntity:(Class)entityClass havingValueLike:(id)value forColumn:(NSString *)column orderBy:(NSString *)orderColumn;
- (NSArray *)objectsOfEntity:(Class)entityClass havingValuesForPredicates:(NSDictionary *)predicatesForKeys orderBy:(NSString *)orderColumn;
- (NSArray *)objectsOfEntity:(Class)entityClass withPredicate:(NSPredicate *)predicate orderBy:(NSArray *)sortDescriptors;
- (NSManagedObject *)objectOfEntity:(Class)entityClass havingValue:(id)value forColumn:(NSString *)column;
- (NSManagedObject *)objectOfEntity:(Class)entityClass havingValuesForKeys:(NSDictionary *)valuesForKeys;
- (NSUInteger)countObjectsOfEntity:(Class)entityClass;
- (NSUInteger)countObjectsOfEntity:(Class)entityClass havingValue:(id)value forColumn:(NSString *)column;

- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass orderBy:(NSString *)columnName;
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

@end
