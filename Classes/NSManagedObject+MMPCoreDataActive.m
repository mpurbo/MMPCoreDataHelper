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
    NSArray *ret = [MMPCoreDataHelper objectsOfEntity:_entityClass
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
    return [MMPCoreDataHelper fetchedResultsControllerForEntity:_entityClass
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
    NSUInteger ret = [MMPCoreDataHelper countObjectsOfEntity:_entityClass
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

@end

@interface MMPCoreDataImportable()

@property (nonatomic, strong) Class entityClass;
@property (nonatomic, strong) NSURL *sourceURL;
@property (nonatomic, assign) MMPCoreDataSourceType sourceType;
@property (nonatomic, assign) NSDateFormatter *dateFormatter;
@property (nonatomic, copy) MMPCoreDataErrorBlock errorBlock;
@property (nonatomic, copy) MMPCoreDataRecordBlock recordBlock;
@property (nonatomic, strong) NSMutableDictionary *customFilters;
@property (nonatomic, strong) NSMutableDictionary *customMappers;

- (id)initWithClass:(Class)entityClass;

@end

@implementation MMPCoreDataImportable

- (id)initWithClass:(Class)entityClass;
{
    if (self = [super init]) {
        self.entityClass = entityClass;
        self.sourceURL = nil;
        self.sourceType = MMPCoreDataSourceTypeUnknown;
        self.dateFormatter = nil;
        self.errorBlock = nil;
        self.customFilters = [NSMutableDictionary new];
        self.customMappers = [NSMutableDictionary new];
    }
    return self;
}

- (MMPCoreDataImportable *)dateFormatter:(NSDateFormatter *)dateFormatter
{
    self.dateFormatter = dateFormatter;
    return self;
}

- (MMPCoreDataImportable *)sourceType:(MMPCoreDataSourceType)sourceType
{
    self.sourceType = sourceType;
    return self;
}

- (MMPCoreDataImportable *)sourceURL:(NSURL *)sourceURL
{
    self.sourceURL = sourceURL;
    return self;
}

- (MMPCoreDataImportable *)error:(MMPCoreDataErrorBlock)errorBlock
{
    self.errorBlock = errorBlock;
    return self;
}

- (MMPCoreDataImportable *)filter:(NSString *)fieldName using:(MMPCoreDataFilterBlock)filterBlock
{
    [self.customFilters setObject:[filterBlock copy] forKey:fieldName];
    return self;
}

- (MMPCoreDataImportable *)map:(NSString *)fieldName using:(MMPCoreDataMapBlock)mapBlock
{
    [self.customMappers setObject:[mapBlock copy] forKey:fieldName];
    return self;
}

- (MMPCoreDataImportable *)each:(MMPCoreDataRecordBlock)recordBlock
{
    self.recordBlock = recordBlock;
    return self;
}

- (void)import
{
    if (_sourceType == MMPCoreDataSourceTypeCSV) {
        [self importCSV];
    } else {
        NSError *error = [[NSError alloc] initWithDomain:MMPCoreDataErrorDomain code:MMPCoreDataErrorCodeInvalidDataSourceType userInfo:nil];
        if (_errorBlock) {
            _errorBlock(error);
        } else {
            NSLog(@"[ERROR] %@", error);
        }
    }
}

- (void)importCSV
{
    if (!_sourceURL) {
        NSError *error = [[NSError alloc] initWithDomain:MMPCoreDataErrorDomain code:MMPCoreDataErrorCodeInvalidDataSourceURL userInfo:nil];
        if (_errorBlock) {
            _errorBlock(error);
        } else {
            NSLog(@"[ERROR] %@", error);
        }
        return;
    }
    
    NSEntityDescription *entityDescription = [MMPCoreDataHelper entityDescriptionOf:_entityClass];
    NSDictionary *attributesByName = [entityDescription attributesByName];
    NSDictionary *relationshipsByName = [entityDescription relationshipsByName];
    
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];

    __weak typeof(self) weakSelf = self;
    __block NSError *error = nil;
    
    [[[[[MMPCSV readURL:_sourceURL]
                format:[[[MMPCSVFormat defaultFormat]
                                       useFirstLineAsKeys]
                                       sanitizeFields]]
                error:^(NSError *error) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf.errorBlock) {
                        strongSelf.errorBlock(error);
                    } else {
                        NSLog(@"[ERROR] %@", error);
                    }
                }]
                end:^{
                    [MMPCoreDataHelper save];
                }]
                each:^(NSDictionary *record) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (error) {
                        return;
                    }
                    NSManagedObject *obj = [MMPCoreDataHelper createObjectOfEntity:_entityClass];
                    for (NSString *key in [record allKeys]) {
                        
                        NSString *value = [record objectForKey:key];
                        NSString *lowercaseValue = [value lowercaseString];
                        
                        MMPCoreDataMapBlock customFilter = [strongSelf.customFilters objectForKey:key];
                        if (customFilter && !customFilter(value)) {
                            continue;
                        }
                        
                        NSAttributeDescription *attributeDescription = [attributesByName objectForKey:key];
                        NSRelationshipDescription *relationshipDescription = [relationshipsByName objectForKey:key];
                        if (!attributeDescription && !relationshipDescription) {
                            error = [[NSError alloc] initWithDomain:MMPCoreDataErrorDomain
                                                               code:MMPCoreDataErrorCodeInvalidFieldName
                                                           userInfo:@{@"invalidFieldName" : key}];
                            if (strongSelf.errorBlock) {
                                strongSelf.errorBlock(error);
                            } else {
                                NSLog(@"[ERROR] %@", error);
                            }
                            return;
                        }
                        
                        MMPCoreDataMapBlock customMapper = [strongSelf.customMappers objectForKey:key];
                        if (customMapper) {
                            [obj setValue:customMapper(value) forKey:key];
                        } else {
                            switch([attributeDescription attributeType]) {
                                case NSInteger64AttributeType:
                                case NSInteger32AttributeType:
                                case NSInteger16AttributeType:
                                    [obj setValue:[nf numberFromString:value]
                                           forKey:key];
                                    break;
                                case NSDecimalAttributeType:
                                    [obj setValue:[NSDecimalNumber decimalNumberWithString:value]
                                           forKey:key];
                                    break;
                                case NSDoubleAttributeType:
                                case NSFloatAttributeType:
                                    [obj setValue:[NSNumber numberWithDouble:[value doubleValue]]
                                           forKey:key];
                                    break;
                                case NSBooleanAttributeType:
                                    [obj setValue:[NSNumber numberWithBool:([@"true" isEqualToString:lowercaseValue] ||
                                                                            [@"yes" isEqualToString:lowercaseValue])]
                                           forKey:key];
                                    break;
                                case NSDateAttributeType:
                                    if (strongSelf.dateFormatter) {
                                        [obj setValue:[strongSelf.dateFormatter dateFromString:value]
                                               forKey:key];
                                    } else {
                                        error = [[NSError alloc] initWithDomain:MMPCoreDataErrorDomain
                                                                           code:MMPCoreDataErrorCodeDateFormatterUnspecified
                                                                       userInfo:@{@"invalidFieldName" : key}];
                                        if (strongSelf.errorBlock) {
                                            strongSelf.errorBlock(error);
                                        } else {
                                            NSLog(@"[ERROR] %@", error);
                                        }
                                        return;
                                    }
                                    break;
                                default:
                                    [obj setValue:value forKey:key];
                                    break;
                            }
                        }
                    }
                    
                    if (strongSelf.recordBlock) {
                        strongSelf.recordBlock(obj);
                    }
                }];
}

@end

@implementation NSManagedObject (MMPCoreDataActive)

+ (instancetype)create
{
    return [MMPCoreDataHelper createObjectOfEntity:[self class]];
}

+ (void)clear
{
    [MMPCoreDataHelper deleteObjectsOfEntity:[self class]];
}

- (instancetype)update:(NSDictionary *)data
{
    [self setValuesForKeysWithDictionary:data];
    return self;
}

- (instancetype)delete
{
    [MMPCoreDataHelper deleteObject:self];
    return self;
}

- (void)save
{
    [MMPCoreDataHelper save];
}

+ (MMPCoreDataImportable *)importer
{
    return [[MMPCoreDataImportable alloc] initWithClass:[self class]];
}

+ (MMPCoreDataQueryable *)query
{
    return [[MMPCoreDataQueryable alloc] initWithClass:[self class]];
}

@end
