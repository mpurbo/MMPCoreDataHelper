//
//  NSManagedObject+MMPCoreDataActive.h
//  Pods
//
//  Created by Purbo Mohamad on 8/22/14.
//
//

#import <CoreData/CoreData.h>

typedef void(^MMPCoreDataErrorBlock)(NSError *error);

@interface MMPCoreDataQueryable : NSObject

/**---------------------------------------------------------------------------------------
 * @name Constructing query
 *  ---------------------------------------------------------------------------------------
 */

- (MMPCoreDataQueryable *)where:(id)condition, ...;
- (MMPCoreDataQueryable *)order:(id)order;
- (MMPCoreDataQueryable *)limit:(NSUInteger)numberOfRecords;
- (MMPCoreDataQueryable *)offset:(NSUInteger)fromRecordNum;
- (MMPCoreDataQueryable *)error:(MMPCoreDataErrorBlock)errorBlock;

/**---------------------------------------------------------------------------------------
 * @name NSFetchedResultsController specific query construction
 *  ---------------------------------------------------------------------------------------
 */

- (MMPCoreDataQueryable *)sectionNameKeyPath:(NSString *)sectionNameKeyPath;
- (MMPCoreDataQueryable *)cacheName:(NSString *)cacheName;

/**---------------------------------------------------------------------------------------
 * @name Producing result
 *  ---------------------------------------------------------------------------------------
 */

- (id)first;
- (NSArray *)array;
- (NSUInteger)count;
- (NSFetchedResultsController *)fetchedResultsController;

@end;

@interface NSManagedObject (MMPCoreDataActive)

/**---------------------------------------------------------------------------------------
 * @name Create, update, and delete
 *  ---------------------------------------------------------------------------------------
 */

+ (instancetype)create;
- (void)delete;
- (void)save;

/**---------------------------------------------------------------------------------------
 * @name Query
 *  ---------------------------------------------------------------------------------------
 */

+ (MMPCoreDataQueryable *)query;

@end
