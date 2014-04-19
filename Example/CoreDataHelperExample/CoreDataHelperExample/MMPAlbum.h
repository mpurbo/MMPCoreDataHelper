//
//  MMPAlbum.h
//  CoreDataHelperExample
//
//  Created by Purbo Mohamad on 4/18/14.
//  Copyright (c) 2014 Purbo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MMPArtist;

@interface MMPAlbum : NSManagedObject

@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) MMPArtist *artist;

@end
