//
//  NSManagedObject+MMPCoreDataActive.m
//  Pods
//
//  Created by Purbo Mohamad on 8/22/14.
//
//

#import "NSManagedObject+MMPCoreDataActive.h"
#import "MMPCoreDataHelper.h"

@implementation NSManagedObject (MMPCoreDataActive)

+ (id)create
{
    return [[MMPCoreDataHelper instance] createObjectOfEntity:[self class]];
}

- (void)delete
{
    [[MMPCoreDataHelper instance] deleteObject:self];
}

- (void)save
{
    [[MMPCoreDataHelper instance] save];
}

+ (NSArray *)all
{
    return [[MMPCoreDataHelper instance] objectsOfEntity:[self class]];
}

+ (NSArray *)allOrderBy:(NSString *)column
{
    return [[MMPCoreDataHelper instance] objectsOfEntity:[self class] orderBy:column];
}

+ (NSArray *)where:(NSString *)column isEqualTo:(id)object
{
    return [[MMPCoreDataHelper instance] objectsOfEntity:[self class] havingValue:object forColumn:column];
}

+ (NSArray *)where:(NSString *)column isEqualTo:(id)object orderBy:(NSString *)orderByColumn
{
    return [[MMPCoreDataHelper instance] objectsOfEntity:[self class] havingValue:object forColumn:column orderBy:orderByColumn];
}

+ (NSArray *)where:(NSString *)column isLike:(id)object orderBy:(NSString *)orderByColumn
{
    return [[MMPCoreDataHelper instance] objectsOfEntity:[self class] havingValueLike:object forColumn:column orderBy:orderByColumn];
}

+ (id)oneWhere:(NSString *)column isEqualTo:(id)object
{
    return [[MMPCoreDataHelper instance] objectOfEntity:[self class] havingValue:object forColumn:column];
}

+ (NSFetchedResultsController *)fetchAllOrderBy:(NSString *)orderByColumn
                             sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    return [[MMPCoreDataHelper instance] fetchedResultsControllerForEntity:[self class] orderBy:orderByColumn sectionNameKeyPath:sectionNameKeyPath];
}

@end
