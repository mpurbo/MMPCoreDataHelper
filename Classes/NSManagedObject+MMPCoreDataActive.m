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
#if TARGET_OS_IPHONE
@property (nonatomic, strong) NSString *sectionNameKeyPath;
@property (nonatomic, strong) NSString *cacheName;
#endif
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
#if TARGET_OS_IPHONE
        self.sectionNameKeyPath = nil;
        self.cacheName = nil;
#endif
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

#if TARGET_OS_IPHONE
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
#endif

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

#if TARGET_OS_IPHONE
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
#endif

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

- (id)_aggregate:(NSString *)aggregateFunction of:(NSString *)attributeName
{
    NSError *error = nil;
    id result = [MMPCoreDataHelper runAggregate:aggregateFunction
                                          where:_conditions
                                   forAttribute:attributeName
                                       ofEntity:_entityClass
                                          error:&error];
    if (error) {
        if (_errorBlock) {
            _errorBlock(error);
        } else {
            NSLog(@"[ERROR] Unhandled MMPCoreDataHelper aggregate min error: %@", error);
        }
    }
    
    return result;
}

- (id)min:(NSString *)attributeName
{
    return [self _aggregate:@"min:" of:attributeName];
}

- (id)max:(NSString *)attributeName
{
    return [self _aggregate:@"max:" of:attributeName];
}

- (id)sum:(NSString *)attributeName
{
    return [self _aggregate:@"sum:" of:attributeName];
}

@end

@interface MMPCoreDataImportable()

@property (nonatomic, strong) Class entityClass;
@property (nonatomic, strong) NSURL *sourceURL;
@property (nonatomic, assign) MMPCoreDataSourceType sourceType;
@property (nonatomic, assign) NSDateFormatter *dateFormatter;
@property (nonatomic, copy) MMPCoreDataErrorBlock errorBlock;
@property (nonatomic, copy) MMPCoreDataMapBlock mapBlock;
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

- (MMPCoreDataImportable *)map:(MMPCoreDataMapBlock)mapBlock
{
    self.mapBlock = mapBlock;
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
                each:^(NSDictionary *record, NSUInteger index) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (error) {
                        return;
                    }
                    NSManagedObject *obj = [MMPCoreDataHelper createObjectOfEntity:_entityClass];
                    for (NSString *key in [record allKeys]) {
                        
                        NSString *value = [record objectForKey:key];
                        NSString *lowercaseValue = [value lowercaseString];
                        
                        MMPCoreDataFilterBlock customFilter = [strongSelf.customFilters objectForKey:key];
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
                            [obj setValue:customMapper(value, index) forKey:key];
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
                                        if (value && [value length] > 0) {
                                            [obj setValue:[strongSelf.dateFormatter dateFromString:value]
                                                   forKey:key];
                                        }
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
                        strongSelf.recordBlock(strongSelf.mapBlock ? strongSelf.mapBlock(obj, index) : obj);
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

- (void)setValueFromString:(NSString *)value forKey:(NSString *)key {
    
    NSEntityDescription *entityDescription = [MMPCoreDataHelper entityDescriptionOf:[self class]];
    NSDictionary *attributesByName = [entityDescription attributesByName];
    
    NSString *lowercaseValue = [value lowercaseString];
    NSAttributeDescription *attributeDescription = [attributesByName objectForKey:key];
    
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    
    switch([attributeDescription attributeType]) {
        case NSInteger64AttributeType:
        case NSInteger32AttributeType:
        case NSInteger16AttributeType:
            [self setValue:[nf numberFromString:value]
                    forKey:key];
            break;
        case NSDecimalAttributeType:
            [self setValue:[NSDecimalNumber decimalNumberWithString:value]
                    forKey:key];
            break;
        case NSDoubleAttributeType:
        case NSFloatAttributeType:
            [self setValue:[NSNumber numberWithDouble:[value doubleValue]]
                    forKey:key];
            break;
        case NSBooleanAttributeType:
            [self setValue:[NSNumber numberWithBool:([@"true" isEqualToString:lowercaseValue] ||
                                                     [@"yes" isEqualToString:lowercaseValue])]
                    forKey:key];
            break;
        // TODO: figure out how to specify date formatter
        /*
        case NSDateAttributeType:
            if (strongSelf.dateFormatter) {
                if (value && [value length] > 0) {
                    [obj setValue:[strongSelf.dateFormatter dateFromString:value]
                           forKey:key];
                }
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
            break;*/
        default:
            [self setValue:value forKey:key];
            break;
    }
}

- (void)setValuesForKeysWithDictionaryOfPossibleStringValues:(NSDictionary *)keyedStringValues {
    for (NSString *key in [keyedStringValues allKeys]) {
        id rawValue = [keyedStringValues objectForKey:key];
        if ([rawValue isKindOfClass:[NSString class]]) {
            [self setValueFromString:rawValue forKey:key];
        } else {
            [self setValue:rawValue forKey:key];
        }
    }
}

- (instancetype)update:(NSDictionary *)data
{
    [self setValuesForKeysWithDictionaryOfPossibleStringValues:data];
    return self;
}

- (instancetype)delete
{
    [MMPCoreDataHelper deleteObject:self];
    return self;
}

- (instancetype)save
{
    [MMPCoreDataHelper save];
    return self;
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
