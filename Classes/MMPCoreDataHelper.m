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

- (void)save
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

- (id)createObjectOfEntity:(Class)entityClass
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                              inManagedObjectContext:managedObjectContext];
    
    NSManagedObject *managedObject = [[NSManagedObject alloc] initWithEntity:entity
                                              insertIntoManagedObjectContext:managedObjectContext];
	return managedObject;
}

- (void)deleteObject:(NSManagedObject *)object
{
    [[self managedObjectContext] deleteObject:object];
}

- (void)deleteObjectsOfEntity:(Class)entityClass
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

- (NSArray *)objectsOfEntity:(Class)entityClass
{
    return [self objectsOfEntity:entityClass
                         orderBy:nil];
}

- (NSArray *)objectsOfEntity:(Class)entityClass orderBy:(NSString *)column
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                   inManagedObjectContext:managedObjectContext]];
    if (column != nil) {
        [request setSortDescriptors:[NSArray arrayWithObjects:
                                     [NSSortDescriptor sortDescriptorWithKey:column ascending:YES],
                                     nil]];
    }
    
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        NSLog(@"Error fetching data: %@", [error localizedDescription]);
    }
    return results;
}

- (NSArray *)objectsOfEntity:(Class)entityClass havingValue:(id)value forColumn:(NSString *)column
{
    return [self objectsOfEntity:entityClass
                     havingValue:value
                       forColumn:column
                         orderBy:nil];
}

- (NSArray *)objectsOfEntity:(Class)entityClass havingValue:(id)value forColumn:(NSString *)column orderBy:(NSString *)orderColumn
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                   inManagedObjectContext:managedObjectContext]];
    NSString *predicateFormat = [NSString stringWithFormat:@"%@ == %%@", column];
    [request setPredicate:[NSPredicate predicateWithFormat:predicateFormat, value]];
    if (orderColumn != nil) {
        [request setSortDescriptors:[NSArray arrayWithObjects:
                                     [NSSortDescriptor sortDescriptorWithKey:orderColumn ascending:YES],
                                     nil]];
    }
    
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        NSLog(@"Error fetching data: %@", [error localizedDescription]);
    }
    
    return results;
}

- (NSArray *)objectsOfEntity:(Class)entityClass havingValueLike:(id)value forColumn:(NSString *)column orderBy:(NSString *)orderColumn
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                   inManagedObjectContext:managedObjectContext]];
    NSString *predicateFormat = [NSString stringWithFormat:@"%@ like %%@", column];
    [request setPredicate:[NSPredicate predicateWithFormat:predicateFormat, value]];
    if (orderColumn != nil) {
        [request setSortDescriptors:[NSArray arrayWithObjects:
                                     [NSSortDescriptor sortDescriptorWithKey:orderColumn ascending:YES],
                                     nil]];
    }
    
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        NSLog(@"Error fetching data: %@", [error localizedDescription]);
    }
    
    return results;
}

- (NSArray *)objectsOfEntity:(Class)entityClass havingValuesForKeys:(NSDictionary *)valuesForKeys
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass) inManagedObjectContext:managedObjectContext]];
    
    NSMutableArray *subpredicates = [NSMutableArray array];
    [valuesForKeys enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *predicateFormat = [NSString stringWithFormat:@"%@ == %%@", key];
        NSPredicate *subpredicate = [NSPredicate predicateWithFormat:predicateFormat, obj];
        [subpredicates addObject:subpredicate];
    }];
    [request setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:subpredicates]];
    
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        NSLog(@"Error fetching data: %@", [error localizedDescription]);
    }
    
    return results;
}

- (NSArray *)objectsOfEntity:(Class)entityClass havingValuesForPredicates:(NSDictionary *)predicatesForKeys orderBy:(NSString *)orderColumn
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                   inManagedObjectContext:managedObjectContext]];
    
    NSMutableArray *subpredicates = [NSMutableArray array];
    [predicatesForKeys enumerateKeysAndObjectsUsingBlock:^(id predicateFormat, id obj, BOOL *stop) {
        NSPredicate *subpredicate = [NSPredicate predicateWithFormat:predicateFormat, obj];
        [subpredicates addObject:subpredicate];
    }];
    [request setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:subpredicates]];
    if (orderColumn != nil) {
        [request setSortDescriptors:[NSArray arrayWithObjects:
                                     [NSSortDescriptor sortDescriptorWithKey:orderColumn ascending:YES],
                                     nil]];
    }
    
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        NSLog(@"Error fetching data: %@", [error localizedDescription]);
    }
    
    return results;
}

- (NSArray *)objectsOfEntity:(Class)entityClass withPredicate:(NSPredicate *)predicate orderBy:(NSArray *)sortDescriptors
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                   inManagedObjectContext:managedObjectContext]];
    [request setPredicate:predicate];
    [request setSortDescriptors:sortDescriptors];
    
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        NSLog(@"Error fetching data: %@", [error localizedDescription]);
    }
    
    return results;
}

- (NSManagedObject *)objectOfEntity:(Class)entityClass havingValue:(id)value forColumn:(NSString *)column
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                   inManagedObjectContext:managedObjectContext]];
    NSString *predicateFormat = [NSString stringWithFormat:@"%@ == %%@", column];
    [request setPredicate:[NSPredicate predicateWithFormat:predicateFormat, value]];
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        NSLog(@"Error fetching data: %@", [error localizedDescription]);
    }
    
    if ([results count] > 0) {
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
}

- (NSManagedObject *)objectOfEntity:(Class)entityClass havingValuesForKeys:(NSDictionary *)valuesForKeys
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                   inManagedObjectContext:managedObjectContext]];
    
    NSMutableArray *subpredicates = [NSMutableArray array];
    [valuesForKeys enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *predicateFormat = [NSString stringWithFormat:@"%@ == %%@", key];
        NSPredicate *subpredicate = [NSPredicate predicateWithFormat:predicateFormat, obj];
        [subpredicates addObject:subpredicate];
    }];
    [request setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:subpredicates]];
    
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    
    if (error != nil) {
        NSLog(@"Error fetching data: %@", [error localizedDescription]);
    }
    
    if ([results count] > 0) {
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
}

- (NSUInteger)countObjectsOfEntity:(Class)entityClass
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                   inManagedObjectContext:managedObjectContext]];
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [managedObjectContext countForFetchRequest:request error:&err];
    if (count == NSNotFound) {
        count = 0;
    }
    
    return count;
}

- (NSUInteger)countObjectsOfEntity:(Class)entityClass havingValue:(id)value forColumn:(NSString *)column
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:NSStringFromClass(entityClass)
                                   inManagedObjectContext:managedObjectContext]];
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    NSString *predicateFormat = [NSString stringWithFormat:@"%@ == %%@", column];
    [request setPredicate:[NSPredicate predicateWithFormat:predicateFormat, value]];
    
    NSError *err;
    NSUInteger count = [managedObjectContext countForFetchRequest:request error:&err];
    if (count == NSNotFound) {
        count = 0;
    }
    
    return count;
}

- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass orderBy:(NSString *)columnName
{
    return [self fetchedResultsControllerForEntity:entityClass
                                     withPredicate:nil
                                           orderBy:columnName ? @[[NSSortDescriptor sortDescriptorWithKey:columnName ascending:YES]] : nil
                                sectionNameKeyPath:nil
                                         cacheName:nil];
}

- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass orderBy:(NSString *)columnName sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    return [self fetchedResultsControllerForEntity:entityClass
                                     withPredicate:nil
                                           orderBy:columnName ? @[[NSSortDescriptor sortDescriptorWithKey:columnName ascending:YES]] : nil
                                sectionNameKeyPath:sectionNameKeyPath
                                         cacheName:nil];
}

- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                      havingValue:(id)value
                                                        forColumn:(NSString *)column
                                                          orderBy:(NSString *)columnName
{
    return [self fetchedResultsControllerForEntity:entityClass
                                     withPredicate:(column && value) ? [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ == %%@", column], value] : nil
                                           orderBy:columnName ? @[[NSSortDescriptor sortDescriptorWithKey:columnName ascending:YES]] : nil
                                sectionNameKeyPath:nil
                                         cacheName:nil];
}

- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                    withPredicate:(NSPredicate *)predicate
                                                          orderBy:(NSArray *)sortDescriptors
{
    return [self fetchedResultsControllerForEntity:entityClass
                                     withPredicate:predicate
                                           orderBy:sortDescriptors
                                sectionNameKeyPath:nil
                                         cacheName:nil];
}

- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                    withPredicate:(NSPredicate *)predicate
                                                          orderBy:(NSArray *)sortDescriptors
                                               sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    return [self fetchedResultsControllerForEntity:entityClass
                                     withPredicate:predicate
                                           orderBy:sortDescriptors
                                sectionNameKeyPath:sectionNameKeyPath
                                         cacheName:nil];
}

- (NSFetchedResultsController *)fetchedResultsControllerForEntity:(Class)entityClass
                                                    withPredicate:(NSPredicate *)predicate
                                                          orderBy:(NSArray *)sortDescriptors
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
    return [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                               managedObjectContext:managedObjectContext
                                                 sectionNameKeyPath:sectionNameKeyPath
                                                          cacheName:cacheName];
}

@end
