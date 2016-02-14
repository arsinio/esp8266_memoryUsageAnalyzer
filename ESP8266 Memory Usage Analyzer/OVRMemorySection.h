//
//  OVRMemorySection.h
//  ESP8266 Memory Usage Monitor
//
//  Created by Christopher Armenio on 2/2/16.
//  Copyright © 2016 OvrEngineered. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "OVRSymbol.h"

typedef enum
{
    OVR_MEMSECTIONTYPE_IO,
    OVR_MEMSECTIONTYPE_RSV,
    OVR_MEMSECTIONTYPE_RAM,
    OVR_MEMSECTIONTYPE_ROM
}OVRMemorySectionType_t;


@interface OVRMemorySection : NSObject

-(id) initWithName:(NSString*)nameIn
       description:(NSString*)descriptionIn
              type:(OVRMemorySectionType_t)typeIn
      startAddress:(NSUInteger)startAddressIn
     maxSize_bytes:(NSUInteger)maxSize_bytesIn
   isUserAccesible:(BOOL)isUserAccessibleIn;

-(id) initWithName:(NSString*)nameIn
       description:(NSString*)descriptionIn
              type:(OVRMemorySectionType_t)typeIn
      startAddress:(NSUInteger)startAddressIn
   isUserAccesible:(BOOL)isUserAccessibleIn;

-(void) addSubSectionWithName:(NSString*)nameIn
                  description:(NSString*)descriptionIn
           startAddressOffset:(NSUInteger)startAddressOffsetIn
                maxSize_bytes:(NSUInteger)maxSize_bytesIn
              isUserAccesible:(BOOL)isUserAccessibleIn;

-(BOOL) addSymbol:(OVRSymbol*)symbolIn;

-(NSString*) getName;
-(NSString*) getDescription;
-(OVRMemorySectionType_t) getType;
-(NSUInteger) getStartAddress;
-(BOOL) isUserAccessibleIn;

-(NSUInteger) getNumSymbols;
-(NSArray*) getSymbols;

-(NSUInteger) getNumSubSections;
-(NSArray*) getSubSections;

-(NSUInteger) getSize_bytes;
-(NSUInteger) getFreeSpace_bytes;
-(NSUInteger) getMaxSize_bytes;

-(void) sortSymbols_byName:(BOOL)ascendingIn;
-(void) sortSymbols_byAddress:(BOOL)ascendingIn;
-(void) sortSymbols_bySize:(BOOL)ascendingIn;

+(NSArray*) getMemorySectionsForModuleWithFlashSize_bytes:(NSUInteger)flashSizeIn;

@end
