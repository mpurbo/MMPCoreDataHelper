//
//  NSManagedObject+MMPCoreDataActive.m
//  Pods
//
//  Created by Purbo Mohamad on 8/22/14.
//
//

#import "NSManagedObject+MMPCoreDataActive.h"
#import "MMPCoreDataHelper.h"

@interface MMPCoreDataQueryable()

@property (nonatomic, strong) Class entityClass;

@property (nonatomic, strong) id conditions;
@property (nonatomic, strong) id order;
@property (nonatomic, strong) NSNumber *numberOfRecords;
@property (nonatomic, strong) NSNumber *fromRecordNum;
@property (nonatomic, strong) NSString *sectionNameKeyPath;
@property (nonatomic, strong) NSString *cacheName;
@property (nonatomic, copy) MMPCoreDataErrorBlock errorBlock;

- (id)initWithClass:(Class)entityClass;

@end

@implementation MMPCoreDataQueryable

- (id)initWithClass:(Class)entityClass;
{
    if (self = [super init]) {
        self.entityClass = entityClass;
        self.conditions = nil;
        self.order = nil;
        self.numberOfRecords = nil;
        self.fromRecordNum = nil;
        self.sectionNameKeyPath = nil;
        self.cacheName = nil;
        self.errorBlock = nil;
    }
    return self;
}

- (MMPCoreDataQueryable *)where:(id)condition, ...
{
    va_list va_arguments;
    va_start(va_arguments, condition);
    _conditions =  [MMPCoreDataHelper predicateFromObject:condition arguments:va_arguments];
    va_end(va_arguments);
    return self;
}

- (MMPCoreDataQueryable *)order:(id)order
{
    _order = order;
    return self;
}

- (MMPCoreDataQueryable *)limit:(NSUInteger)numberOfRecords
{
    _numberOfRecords = @(numberOfRecords);
    return self;
}

- (MMPCoreDataQueryable *)offset:(NSUInteger)fromRecordNum
{
    _fromRecordNum = @(fromRecordNum);
    return self;
}

- (MMPCoreDataQueryable *)error:(MMPCoreDataErrorBlock)errorBlock
{
    _errorBlock = errorBlock;
    return self;
}

- (MMPCoreDataQueryable *)sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    _sectionNameKeyPath = sectionNameKeyPath;
    return self;
}

- (MMPCoreDataQueryable *)cacheName:(NSString *)cacheName
{
    _cacheName = cacheName;
    return self;
}

- (id)first
{
    NSArray *result = [self all];
    return ([result count] > 0) ? [result objectAtIndex:0] : nil;
}

- (NSArray *)all
{
    NSError *error = nil;
    NSArray *ret = [[MMPCoreDataHelper instance] objectsOfEntity:_entityClass
                                                           where:_conditions
                                                           order:_order
                                                           limit:_numberOfRecords
                                                          offset:_fromRecordNum
                                                           error:&error];
    if (error) {
        if (_errorBlock) {
            _errorBlock(error);
        } else {
            NSLog(@"[ERROR] Unhandled MMPCoreDataHelper query error: %@", error);
        }
    }
    
    return ret;
}

- (void)each:(MMPCoreDataRecordBlock)recordBlock
{
    NSArray *result = [self all];
    if (result && [result count] > 0) {
        for (id record in result) {
            recordBlock(record);
        }
    }
}

- (NSFetchedResultsController *)fetchedResultsController
{
    return [[MMPCoreDataHelper instance] fetchedResultsControllerForEntity:_entityClass
                                                                     where:_conditions
                                                                     order:_order
                                                                     limit:_numberOfRecords
                                                                    offset:_fromRecordNum
                                                        sectionNameKeyPath:_sectionNameKeyPath
                                                                 cacheName:_cacheName];
}

- (NSUInteger)count
{
    NSError *error = nil;
    NSUInteger ret = [[MMPCoreDataHelper instance] countObjectsOfEntity:_entityClass
                                                                  where:_conditions
                                                                  error:&error];
    
    if (error) {
        if (_errorBlock) {
            _errorBlock(error);
        } else {
            NSLog(@"[ERROR] Unhandled MMPCoreDataHelper count error: %@", error);
        }
    }
    
    return ret;
}

@end;

@implementation NSManagedObject (MMPCoreDataActive)

+ (instancetype)create
{
    return [[MMPCoreDataHelper instance] createObjectOfEntity:[self class]];
}

- (instancetype)update:(NSDictionary *)data
{
    [self setValuesForKeysWithDictionary:data];
    return self;
}

- (instancetype)delete
{
    [[MMPCoreDataHelper instance] deleteObject:self];
    return self;
}

- (void)save
{
    [[MMPCoreDataHelper instance] save];
}

+ (MMPCoreDataQueryable *)query
{
    return [[MMPCoreDataQueryable alloc] initWithClass:[self class]];
}

@end
