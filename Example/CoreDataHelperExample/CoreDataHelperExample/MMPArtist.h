//
//  MMPArtist.h
//  CoreDataHelperExample
//
//  Created by Purbo Mohamad on 4/18/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MMPArtist : NSManagedObject

@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * members;
@property (nonatomic, retain) NSSet *albums;
@end

@interface MMPArtist (CoreDataGeneratedAccessors)

- (void)addAlbumsObject:(NSManagedObject *)value;
- (void)removeAlbumsObject:(NSManagedObject *)value;
- (void)addAlbums:(NSSet *)values;
- (void)removeAlbums:(NSSet *)values;

@end
