//
//  OVRSymbol.h
//  ESP8266 Memory Usage Monitor
//
//  Created by Christopher Armenio on 2/2/16.
//  Copyright © 2016 OvrEngineered. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    OVR_SYMBOLTYPE_ABSOLUTE,
    OVR_SYMBOLTYPE_UNINITIALIZED,
    OVR_SYMBOLTYPE_INITIALIZED,
    OVR_SYMBOLTYPE_READONLY,
    OVR_SYMBOLTYPE_TEXT,
    OVR_SYMBOLTYPE_WEAK,
    OVR_SYMBOLTYPE_UNDEFINED,
    OVR_SYMBOLTYPE_UNKNOWN
}OVRSymbolType;


@interface OVRSymbol : NSObject

-(id) initWithName:(NSString*)nameIn andType:(OVRSymbolType)typeIn andStartAddress:(NSUInteger)startAddressIn andSize:(NSUInteger)size_bytesIn isGlobal:(BOOL)isGlobalIn;
-(id) initUndefinedSymbolNamed:(NSString*)nameIn;

-(NSString*) getName;
-(OVRSymbolType) getType;
-(NSUInteger) getStartAddress;
-(NSUInteger) getSize_bytes;

-(BOOL) isEqualToSymbol:(OVRSymbol*)symbolIn;

+(OVRSymbolType) getSymbolTypeFromString:(NSString*)stringIn;

@end
