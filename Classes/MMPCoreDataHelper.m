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

#import "MMPCoreDataHelper.h"

NSString * const MMPDataAccessSaveErrorNotification = @"MMPDataAccessSaveErrorNotification";
NSString * const MMPDataAccessDidSaveNotification = @"MMPDataAccessDidSaveNotification";

@interface MMPCoreDataHelper () {
}

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContextForBackgroundWriter;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContextForMainThread;

@end

@implementation MMPCoreDataHelper

static NSString * const MP_PERTHREADKEY_MOC = @"MPPerThreadManagedObjectContext";

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - General

+ (instancetype)instance
{
    static dispatch_once_t pred;
    static id shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initSingletonInstance];
    });
    return shared;
}

- (instancetype)initSingletonInstance
{
     return [super init];
}

- (NSString *)appName
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

- (NSString *)databaseName
{
    @synchronized(self) {
        if (!_databaseName)
            _databaseName = [[[self appName] stringByAppendingString:@".sqlite"] copy];
    }
    return _databaseName;
}

- (NSString *)modelName {
    @synchronized(self) {
        if (!_modelName)
            _modelName = [[self appName] copy];
    }
    return _modelName;
}

- (NSManagedObjectModel *)managedObjectModel {
    @synchronized(self) {
        if (!_managedObjectModel) {
            NSURL *modelURL = [[NSBundle mainBundle] URLForResource:[self modelName] withExtension:@"momd"];
            if (!modelURL) {
                // no momd? try mom
                modelURL = [[NSBundle mainBundle] URLForResource:[self modelName] withExtension:@"mom"];
            }
            if (!modelURL) {
                NSLog(@"[ERROR] Unable to find model with name: %@", [self modelName]);
            }
            _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        }
    }
    return _managedObjectModel;
}

- (BOOL)isOSX {
    if (NSClassFromString(@"UIDevice")) return NO;
    return YES;
}

- (void)createApplicationSupportDirIfNeeded:(NSURL *)url {
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.absoluteString]) return;
    
    [[NSFileManager defaultManager] createDirectoryAtURL:url
                             withIntermediateDirectories:YES attributes:nil error:nil];
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)applicationSupportDirectory {
    return [[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                    inDomains:NSUserDomainMask] lastObject]
            URLByAppendingPathComponent:[self appName]];
}

- (NSString *)applicationDocumentsDirectoryAsString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSString *)applicationSupportDirectoryAsString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSURL *)sqliteStoreURL {
    NSURL *directory = [self isOSX] ? self.applicationSupportDirectory : self.applicationDocumentsDirectory;
    NSURL *databaseDir = [directory URLByAppendingPathComponent:[self databaseName]];
    
    [self createApplicationSupportDirIfNeeded:directory];
    return databaseDir;
}

- (NSString *)sqliteStorePath {
    return [[self applicationDocumentsDirectoryAsString] stringByAppendingPathComponent:[self databaseName]];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinatorWithStoreType:(NSString *const)storeType
                                                                 storeURL:(NSURL *)storeURL {
    
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @YES,
                               NSInferMappingModelAutomaticallyOption: @YES };
    
    NSError *error = nil;
    if (![coordinator addPersistentStoreWithType:storeType configuration:nil URL:storeURL options:options error:&error])
        NSLog(@"ERROR WHILE CREATING PERSISTENT STORE COORDINATOR! %@, %@", error, [error userInfo]);
    
    return coordinator;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    @synchronized(self) {
        if (!_persistentStoreCoordinator)
            _persistentStoreCoordinator = [self persistentStoreCoordinatorWithStoreType:NSSQLiteStoreType
                                                                               storeURL:[self sqliteStoreURL]];
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContextForBackgroundWriter
{
    @synchronized(self) {
        if (!_managedObjectContextForBackgroundWriter) {
            _managedObjectContextForBackgroundWriter = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [_managedObjectContextForBackgroundWriter setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
        }
    }
    return _managedObjectContextForBackgroundWriter;
}

- (NSManagedObjectContext *)managedObjectContextForMainThread
{
    @synchronized(self) {
        if (!_managedObjectContextForMainThread) {
            _managedObjectContextForMainThread = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            _managedObjectContextForMainThread.parentContext = [self managedObjectContextForBackgroundWriter];
        }
    }
    return _managedObjectContextForMainThread;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if ([NSThread isMainThread]) {
        return [self managedObjectContextForMainThread];
    } else {
        
        NSThread *currentThread = [NSThread currentThread];
        NSMutableDictionary *threadDictionary = [currentThread threadDictionary];
        
        NSManagedObjectContext *managedObjectContextForCurrentThread = [threadDictionary objectForKey:MP_PERTHREADKEY_MOC];
        
        if (managedObjectContextForCurrentThread == nil) {
            managedObjectContextForCurrentThread = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            managedObjectContextForCurrentThread.parentContext = [self managedObjectContextForMainThread];
            [threadDictionary setObject:managedObjectContextForCurrentThread forKey:MP_PERTHREADKEY_MOC];
        }
        
        return managedObjectContextForCurrentThread;        
    }
}

- (void)saveContextForMainThread
{
    NSError *error;
    if ([[self managedObjectContextForMainThread] save:&error]) {
        // save to background writer
        [[self managedObjectContextForBackgroundWriter] performBlock:^{
            NSError *error;
            if (![[self managedObjectContextForBackgroundWriter] save:&error]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:MMPDataAccessSaveErrorNotification
                                                                    object:nil
                                                                  userInfo:@{@"error" : error}];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:MMPDataAccessDidSaveNotification
                                                                    object:nil
                                                                  userInfo:nil];
            }
        }];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:MMPDataAccessSaveErrorNotification
                                                            object:nil
                                                          userInfo:@{@"error" : error}];
    }
}

- (void)_save
{
    if ([NSThread isMainThread]) {
        [self saveContextForMainThread];
    } else {
        NSError *error;
        if ([[self managedObjectContext] save:&error]) {
            // save to main thread
            [[self managedObjectContextForMainThread] performBlock:^{
                [self saveContextForMainThread];
            }];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:MMPDataAccessSaveErrorNotification
                                                                object:nil
                                                              userInfo:@{@"error" : error}];
        }
    }
}

+ (void)save
{
    [[MMPCoreDataHelper instance] _save];
}

#pragma mark - Create, update, and delete

- (id)_createObjectOfEntity:(Class)entityClass
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                              inManagedObjectContext:managedObjectContext];
    
    NSManagedObject *managedObject = [[NSManagedObject alloc] initWithEntity:entity
                                              insertIntoManagedObjectContext:managedObjectContext];
	return managedObject;
}

+ (id)createObjectOfEntity:(Class)entityClass
{
    return [[MMPCoreDataHelper instance] _createObjectOfEntity:entityClass];
}

- (void)_deleteObject:(NSManagedObject *)object
{
    [[self managedObjectContext] deleteObject:object];
}

+ (void)deleteObject:(NSManagedObject *)object
{
    [[MMPCoreDataHelper instance] _deleteObject:object];
}

- (void)_deleteObjectsOfEntity:(Class)entityClass
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                              inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *items = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    
    for (NSManagedObject *managedObject in items) {
    	[managedObjectContext deleteObject:managedObject];
    }
    
    if (![managedObjectContext save:&error]) {
    	NSLog(@"[ERROR] Error deleting %@ - error:%@", NSStringFromClass(entityClass), error);
    }
}

+ (void)deleteObjectsOfEntity:(Class)entityClass
{
    [[MMPCoreDataHelper instance] _deleteObjectsOfEntity:entityClass];
}

#pragma mark - Utilities
// Utilities adapted from https://github.com/supermarin/ObjectiveRecord

+ (NSPredicate *)predicateFromDictionary:(NSDictionary *)dict
{
    NSMutableArray *subpredicates = [NSMutableArray array];
    for (NSString* key in dict) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"%K = %@", key, [dict objectForKey:key]]];
    }
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
}

+ (NSPredicate *)predicateFromObject:(id)condition {
    return [self predicateFromObject:condition arguments:NULL];
}

+ (NSPredicate *)predicateFromObject:(id)condition arguments:(va_list)arguments
{
    if ([condition isKindOfClass:[NSPredicate class]])
        return condition;
    
    if ([condition isKindOfClass:[NSString class]])
        return [NSPredicate predicateWithFormat:condition arguments:arguments];
    
    if ([condition isKindOfClass:[NSDictionary class]])
        return [self predicateFromDictionary:condition];
    
    return nil;
}

+ (NSSortDescriptor *)sortDescriptorFromDictionary:(NSDictionary *)dict
{
    BOOL isAscending = ![[[dict.allValues objectAtIndex:0] uppercaseString] isEqualToString:@"DESC"];
    return [NSSortDescriptor sortDescriptorWithKey:[dict.allKeys objectAtIndex:0]
                                         ascending:isAscending];
}

+ (NSSortDescriptor *)sortDescriptorFromString:(NSString *)order
{
    NSArray *result = [order componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray *components = [NSMutableArray array];
    for (NSString *string in result) {
        if (string.length > 0) {
            [components addObject:string];
        }
    }
    
    NSString *key = [components firstObject];
    NSString *value = [components count] > 1 ? components[1] : @"ASC";
    
    return [self sortDescriptorFromDictionary:@{key: value}];
    
}

+ (NSSortDescriptor *)sortDescriptorFromObject:(id)order
{
    if ([order isKindOfClass:[NSSortDescriptor class]])
        return order;
    
    if ([order isKindOfClass:[NSString class]])
        return [self sortDescriptorFromString:order];
    
    if ([order isKindOfClass:[NSDictionary class]])
        return [self sortDescriptorFromDictionary:order];
    
    return nil;
}

+ (NSArray *)sortDescriptorsFromObject:(id)order
{
    if (!order) {
        return nil;
    }
    
    if ([order isKindOfClass:[NSString class]])
        order = [order componentsSeparatedByString:@","];
    
    if ([order isKindOfClass:[NSArray class]]) {
        NSMutableArray *ret = [NSMutableArray array];
        for (id object in order) {
            [ret addObject:[self sortDescriptorFromObject:object]];
        }
        return ret;
    }
    
    return @[[self sortDescriptorFromObject:order]];
}

+ (id)objectWithID:(NSManagedObjectID *)objectID
{
    return [[[MMPCoreDataHelper instance] managedObjectContext] objectWithID:objectID];
}

#pragma mark - Query producing multiple objects

+ (NSArray *)objectsOfEntity:(Class)entityClass
                       where:(id)condition
                       order:(id)order
                       limit:(NSNumber *)numberOfRecords
                      offset:(NSNumber *)fromRecordNum
                       error:(NSError **)error
{
    return [MMPCoreDataHelper objectsOfEntity:entityClass
                                withPredicate:[MMPCoreDataHelper predicateFromObject:condition]
                              sortDescriptors:[MMPCoreDataHelper sortDescriptorsFromObject:order]
                                   fetchLimit:numberOfRecords
                                  fetchOffset:fromRecordNum
                                        error:error];
}

- (NSArray *)_objectsOfEntity:(Class)entityClass
                withPredicate:(NSPredicate *)predicate
              sortDescriptors:(NSArray *)sortDescriptors
                   fetchLimit:(NSNumber *)fetchLimit
                  fetchOffset:(NSNumber *)fetchOffset
                        error:(NSError **)error
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                   inManagedObjectContext:managedObjectContext]];
    if (predicate) {
        [request setPredicate:predicate];
    }
    if (sortDescriptors) {
        [request setSortDescriptors:sortDescriptors];
    }
    if (fetchLimit) {
        [request setFetchLimit:[fetchLimit unsignedIntegerValue]];
    }
    if (fetchOffset) {
        [request setFetchOffset:[fetchOffset unsignedIntegerValue]];
    }
    
    return [managedObjectContext executeFetchRequest:request error:error];
}

+ (NSArray *)objectsOfEntity:(Class)entityClass
               withPredicate:(NSPredicate *)predicate
             sortDescriptors:(NSArray *)sortDescriptors
                  fetchLimit:(NSNumber *)fetchLimit
                 fetchOffset:(NSNumber *)fetchOffset
                       error:(NSError **)error
{
    return [[MMPCoreDataHelper instance] _objectsOfEntity:entityClass
                                            withPredicate:predicate
                                          sortDescriptors:sortDescriptors
                                               fetchLimit:fetchLimit
                                              fetchOffset:fetchOffset
                                                    error:error];
}

#pragma mark - Aggregate query

+ (NSUInteger)countObjectsOfEntity:(Class)entityClass
                             where:(id)condition
                             error:(NSError **)error
{
    return [MMPCoreDataHelper countObjectsOfEntity:entityClass
                                     withPredicate:[MMPCoreDataHelper predicateFromObject:condition]
                                             error:error];
}

- (NSUInteger)_countObjectsOfEntity:(Class)entityClass
                     withPredicate:(NSPredicate *)predicate
                             error:(NSError **)error
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                   inManagedObjectContext:managedObjectContext]];
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    if (predicate) {
        [request setPredicate:predicate];
    }
    
    NSUInteger count = [managedObjectContext countForFetchRequest:request error:error];
    if (count == NSNotFound) {
        count = 0;
    }
    
    return count;
}

+ (NSUInteger)countObjectsOfEntity:(Class)entityClass
                     withPredicate:(NSPredicate *)predicate
                             error:(NSError **)error
{
    return [[MMPCoreDataHelper instance] _countObjectsOfEntity:entityClass
                                                 withPredicate:predicate
                                                         error:error];
}

#pragma mark - Query producing NSFetchedResultsController

+ (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                            where:(id)condition
                                                            order:(id)order
                                                            limit:(NSNumber *)numberOfRecords
                                                           offset:(NSNumber *)fromRecordNum
                                               sectionNameKeyPath:(NSString *)sectionNameKeyPath
                                                        cacheName:(NSString *)cacheName
{
    return [MMPCoreDataHelper fetchedResultsControllerForEntity:entityClass
                                                  withPredicate:[MMPCoreDataHelper predicateFromObject:condition]
                                                sortDescriptors:[MMPCoreDataHelper sortDescriptorsFromObject:order]
                                                     fetchLimit:numberOfRecords
                                                    fetchOffset:fromRecordNum
                                             sectionNameKeyPath:sectionNameKeyPath
                                                      cacheName:cacheName];
}

- (NSFetchedResultsController *)_fetchedResultsControllerForEntity:(Class)entityClass
                                                    withPredicate:(NSPredicate *)predicate
                                                  sortDescriptors:(NSArray *)sortDescriptors
                                                       fetchLimit:(NSNumber *)fetchLimit
                                                      fetchOffset:(NSNumber *)fetchOffset
                                               sectionNameKeyPath:(NSString *)sectionNameKeyPath
                                                        cacheName:(NSString *)cacheName
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                              inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    if (sortDescriptors) {
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    if (fetchLimit) {
        [fetchRequest setFetchLimit:[fetchLimit unsignedIntegerValue]];
    }
    if (fetchOffset) {
        [fetchRequest setFetchOffset:[fetchOffset unsignedIntegerValue]];
    }
    return [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                               managedObjectContext:managedObjectContext
                                                 sectionNameKeyPath:sectionNameKeyPath
                                                          cacheName:cacheName];
}

+ (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                    withPredicate:(NSPredicate *)predicate
                                                  sortDescriptors:(NSArray *)sortDescriptors
                                                       fetchLimit:(NSNumber *)fetchLimit
                                                      fetchOffset:(NSNumber *)fetchOffset
                                               sectionNameKeyPath:(NSString *)sectionNameKeyPath
                                                        cacheName:(NSString *)cacheName
{
    return [[MMPCoreDataHelper instance] _fetchedResultsControllerForEntity:entityClass
                                                              withPredicate:predicate
                                                            sortDescriptors:sortDescriptors
                                                                 fetchLimit:fetchLimit
                                                                fetchOffset:fetchOffset
                                                         sectionNameKeyPath:sectionNameKeyPath
                                                                  cacheName:cacheName];
}

@end
