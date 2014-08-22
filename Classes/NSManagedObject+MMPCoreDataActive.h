//
//  NSManagedObject+MMPCoreDataActive.h
//  Pods
//
//  Created by Purbo Mohamad on 8/22/14.
//
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (MMPCoreDataActive)

/**---------------------------------------------------------------------------------------
 * @name Create, update, and delete
 *  ---------------------------------------------------------------------------------------
 */

+ (id)create;
- (void)delete;
- (void)save;

/**---------------------------------------------------------------------------------------
 * @name Create, update, and delete
 *  ---------------------------------------------------------------------------------------
 */

+ (NSArray *)all;
+ (NSArray *)allOrderBy:(NSString *)column;
+ (NSArray *)where:(NSString *)column isEqualTo:(id)object;
+ (NSArray *)where:(NSString *)column isEqualTo:(id)object orderBy:(NSString *)orderByColumn;
+ (NSArray *)where:(NSString *)column isLike:(id)object orderBy:(NSString *)orderByColumn;

+ (id)oneWhere:(NSString *)column isEqualTo:(id)object;

+ (NSFetchedResultsController *)fetchAllOrderBy:(NSString *)orderByColumn
                             sectionNameKeyPath:(NSString *)sectionNameKeyPath;

@end
