//
//  OVRSymbol.m
//  ESP8266 Memory Usage Monitor
//
//  Created by Christopher Armenio on 2/2/16.
//  Copyright © 2016 OvrEngineered. All rights reserved.
//

#import "OVRSymbol.h"


@interface OVRSymbol ()
@property (nonatomic, strong) NSString* name;
@property (nonatomic, assign) OVRSymbolType type;

@property (nonatomic, assign) NSUInteger startAddress;
@property (nonatomic, assign) NSUInteger size_bytes;

@property (nonatomic, assign) BOOL isGlobal;
@end


@implementation OVRSymbol

-(id) initWithName:(NSString*)nameIn andType:(OVRSymbolType)typeIn andStartAddress:(NSUInteger)startAddressIn andSize:(NSUInteger)size_bytesIn isGlobal:(BOOL)isGlobalIn
{
    self = [super init];
    if( self != nil )
    {
        self.name = nameIn;
        self.type = typeIn;
        self.startAddress = startAddressIn;
        self.size_bytes = size_bytesIn;
        self.isGlobal = isGlobalIn;
    }
    return self;
}


-(id) initUndefinedSymbolNamed:(NSString*)nameIn
{
    self = [super init];
    if( self != nil )
    {
        self.name = nameIn;
        self.type = OVR_SYMBOLTYPE_UNDEFINED;
        self.startAddress = 0;
        self.size_bytes = 0;
        self.isGlobal = NO;
    }
    return self;
}


-(NSString*) getName
{
    return _name;
}


-(OVRSymbolType) getType
{
    return _type;
}


-(NSUInteger) getStartAddress
{
    return _startAddress;
}


-(NSUInteger) getSize_bytes
{
    return _size_bytes;
}


-(BOOL) isEqualToSymbol:(OVRSymbol*)symbolIn
{
    return [self.name isEqualToString:symbolIn.name] && (self.type == symbolIn.type);
}


+(OVRSymbolType) getSymbolTypeFromString:(NSString*)stringIn
{
    OVRSymbolType retVal = OVR_SYMBOLTYPE_UNKNOWN;
    NSString* lowerCase = [stringIn lowercaseString];
    
    if( [lowerCase isEqualToString:@"a"] ) retVal = OVR_SYMBOLTYPE_ABSOLUTE;
    else if( [lowerCase isEqualToString:@"b"] ) retVal = OVR_SYMBOLTYPE_UNINITIALIZED;
    else if( [lowerCase isEqualToString:@"c"] ) retVal = OVR_SYMBOLTYPE_UNINITIALIZED;
    else if( [lowerCase isEqualToString:@"d"] ) retVal = OVR_SYMBOLTYPE_INITIALIZED;
    else if( [lowerCase isEqualToString:@"r"] ) retVal = OVR_SYMBOLTYPE_READONLY;
    else if( [lowerCase isEqualToString:@"t"] ) retVal = OVR_SYMBOLTYPE_TEXT;
    else if( [lowerCase isEqualToString:@"w"] ) retVal = OVR_SYMBOLTYPE_WEAK;
    else if( [lowerCase isEqualToString:@"u"] ) retVal = OVR_SYMBOLTYPE_UNDEFINED;

    return retVal;
}

@end
