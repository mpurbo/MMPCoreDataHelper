//
//  NSManagedObject+MMPCoreDataActive.h
//  Pods
//
//  Created by Purbo Mohamad on 8/22/14.
//
//

#import <CoreData/CoreData.h>
#import <MMPCSVUtil/MMPCSVUtil.h>

typedef void(^MMPCoreDataErrorBlock)(NSError *error);
typedef void(^MMPCoreDataRecordBlock)(id record);
typedef BOOL(^MMPCoreDataFilterBlock)(id record);
typedef id(^MMPCoreDataMapBlock)(id value);

typedef NS_ENUM(NSInteger, MMPCoreDataSourceType) {
    MMPCoreDataSourceTypeUnknown = 0,
    MMPCoreDataSourceTypeCSV = 1
};

typedef NS_ENUM(NSInteger, MMPCoreDataErrorCode) {
    MMPCoreDataErrorCodeInvalidDataSourceType = 101,
    MMPCoreDataErrorCodeInvalidDataSourceURL = 102,
    MMPCoreDataErrorCodeInvalidFieldName = 201,
    MMPCoreDataErrorCodeDateFormatterUnspecified = 202
};

@interface MMPCoreDataQueryable : NSObject

/**---------------------------------------------------------------------------------------
 * @name Constructing query
 * ---------------------------------------------------------------------------------------
 */

- (MMPCoreDataQueryable *)where:(id)condition, ...;
- (MMPCoreDataQueryable *)order:(id)order;
- (MMPCoreDataQueryable *)limit:(NSUInteger)numberOfRecords;
- (MMPCoreDataQueryable *)offset:(NSUInteger)fromRecordNum;
- (MMPCoreDataQueryable *)error:(MMPCoreDataErrorBlock)errorBlock;

/**---------------------------------------------------------------------------------------
 * @name NSFetchedResultsController specific query construction
 * ---------------------------------------------------------------------------------------
 */

- (MMPCoreDataQueryable *)sectionNameKeyPath:(NSString *)sectionNameKeyPath;
- (MMPCoreDataQueryable *)cacheName:(NSString *)cacheName;

/**---------------------------------------------------------------------------------------
 * @name Producing result
 * ---------------------------------------------------------------------------------------
 */

- (id)first;
- (NSArray *)all;
- (void)each:(MMPCoreDataRecordBlock)recordBlock;
- (NSFetchedResultsController *)fetchedResultsController;
- (NSUInteger)count;

@end

@interface MMPCoreDataImportable : NSObject

/**---------------------------------------------------------------------------------------
 * @name Importer construction
 * ---------------------------------------------------------------------------------------
 */

- (MMPCoreDataImportable *)dateFormatter:(NSDateFormatter *)dateFormatter;
- (MMPCoreDataImportable *)sourceType:(MMPCoreDataSourceType)sourceType;
- (MMPCoreDataImportable *)sourceURL:(NSURL *)sourceURL;
- (MMPCoreDataImportable *)error:(MMPCoreDataErrorBlock)errorBlock;
- (MMPCoreDataImportable *)filter:(NSString *)fieldName using:(MMPCoreDataFilterBlock)filterBlock;
- (MMPCoreDataImportable *)map:(NSString *)fieldName using:(MMPCoreDataMapBlock)mapBlock;
- (MMPCoreDataImportable *)each:(MMPCoreDataRecordBlock)recordBlock;

/**---------------------------------------------------------------------------------------
 * @name Execution
 * ---------------------------------------------------------------------------------------
 */

- (void)import;

@end

@interface NSManagedObject (MMPCoreDataActive)

/**---------------------------------------------------------------------------------------
 * @name Create, update, and delete
 * ---------------------------------------------------------------------------------------
 */

/**
*  Create new empty record.
*
*  @return Newly created record.
*/
+ (instancetype)create;

/**
 *  Delete all records.
 */
+ (void)clear;

- (instancetype)update:(NSDictionary *)data;
- (instancetype)delete;
- (void)save;

/**---------------------------------------------------------------------------------------
 * @name Data import
 * ---------------------------------------------------------------------------------------
 */

+ (MMPCoreDataImportable *)importer;

/**---------------------------------------------------------------------------------------
 * @name Query
 * ---------------------------------------------------------------------------------------
 */

+ (MMPCoreDataQueryable *)query;

@end
