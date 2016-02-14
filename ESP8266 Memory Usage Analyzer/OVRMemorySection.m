//
//  OVRMemorySection.m
//  ESP8266 Memory Usage Monitor
//
//  Created by Christopher Armenio on 2/2/16.
//  Copyright © 2016 OvrEngineered. All rights reserved.
//
#import "OVRMemorySection.h"


@interface OVRMemorySection ()
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* textDescription;
@property (nonatomic, assign) OVRMemorySectionType_t type;
@property (nonatomic, assign) NSUInteger startAddress;
@property (nonatomic, assign) NSUInteger maxSize_bytes;
@property (nonatomic, assign) BOOL isUserAccessible;

@property (nonatomic, strong) NSMutableArray* subSections;
@property (nonatomic, strong) NSMutableArray* symbols;
@end


@implementation OVRMemorySection

-(id) initWithName:(NSString*)nameIn
       description:(NSString*)descriptionIn
              type:(OVRMemorySectionType_t)typeIn
      startAddress:(NSUInteger)startAddressIn
     maxSize_bytes:(NSUInteger)maxSize_bytesIn
   isUserAccesible:(BOOL)isUserAccessibleIn
{
    self = [super init];
    if( self != nil )
    {
        self.name = nameIn;
        self.textDescription = descriptionIn;
        self.type = typeIn;
        self.startAddress = startAddressIn;
        self.maxSize_bytes = maxSize_bytesIn;
        self.isUserAccessible = isUserAccessibleIn;
        
        self.symbols = [[NSMutableArray alloc] init];
        self.subSections = [[NSMutableArray alloc] init];
    }
    return self;
}


-(id) initWithName:(NSString*)nameIn
       description:(NSString*)descriptionIn
              type:(OVRMemorySectionType_t)typeIn
      startAddress:(NSUInteger)startAddressIn
   isUserAccesible:(BOOL)isUserAccessibleIn
{
    return [self initWithName:nameIn
                  description:descriptionIn
                         type:typeIn
                 startAddress:startAddressIn
                maxSize_bytes:0
              isUserAccesible:isUserAccessibleIn];
}


-(void) addSubSectionWithName:(NSString*)nameIn
                  description:(NSString*)descriptionIn
           startAddressOffset:(NSUInteger)startAddressOffsetIn
                maxSize_bytes:(NSUInteger)maxSize_bytesIn
              isUserAccesible:(BOOL)isUserAccessibleIn
{
    [self.subSections addObject:[[OVRMemorySection alloc] initWithName:nameIn
                                                           description:descriptionIn
                                                                  type:self.type
                                                          startAddress:self.startAddress+startAddressOffsetIn
                                                         maxSize_bytes:maxSize_bytesIn
                                                       isUserAccesible:isUserAccessibleIn]];
}


-(BOOL) addSymbol:(OVRSymbol*)symbolIn
{
    // make sure the start address falls within our bounds
    if( ([symbolIn getStartAddress] < self.startAddress) || ((self.startAddress + self.maxSize_bytes) < [symbolIn getStartAddress]) ) return NO;

    // find the target memory section
    for( OVRMemorySection* currMemSection in self.subSections )
    {
        if( [currMemSection addSymbol:symbolIn] ) return YES;
    }
    
    // if we made it here, it's being added to us
    
    // make sure the symbol is completely contained within this section
    if( ([symbolIn getStartAddress] + [symbolIn getSize_bytes]) >= (self.startAddress + self.maxSize_bytes) )
    {
        @throw [NSException exceptionWithName:@"Consistency Error"
                                       reason:[NSString stringWithFormat:@"symbol '%@' does not fully fit into memory section '%@'", [symbolIn getName], self.name]
                                     userInfo:nil];
    }
    
    [self.symbols addObject:symbolIn];
    return YES;
}


-(NSString*) getName
{
    return _name;
}


-(NSString*) getDescription
{
    return _textDescription;
}


-(OVRMemorySectionType_t) getType
{
    return _type;
}


-(NSUInteger) getStartAddress
{
    return _startAddress;
}


-(BOOL) isUserAccessibleIn
{
    return _isUserAccessible;
}


-(NSUInteger) getNumSymbols
{
    return self.symbols.count;
}


-(NSArray*) getSymbols
{
    return _symbols;
}


-(NSUInteger) getNumSubSections
{
    return self.subSections.count;
}


-(NSArray*) getSubSections
{
    return _subSections;
}


-(NSUInteger) getSize_bytes
{
    NSUInteger retVal = 0;

    for( OVRMemorySection* currSection in self.subSections )
    {
        retVal += [currSection getSize_bytes];
    }
    for( OVRSymbol* currSymbol in self.symbols )
    {
        retVal += [currSymbol getSize_bytes];
    }
    
    return retVal;
}


-(NSUInteger) getFreeSpace_bytes
{
    return self.maxSize_bytes - [self getSize_bytes];
}


-(NSUInteger) getMaxSize_bytes
{
    return self.maxSize_bytes;
}


-(void) sortSymbols_byName:(BOOL)ascendingIn
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:ascendingIn];
    self.symbols = [[self.symbols sortedArrayUsingDescriptors:@[sort]] mutableCopy];
}


-(void) sortSymbols_byAddress:(BOOL)ascendingIn
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"startAddress" ascending:ascendingIn];
    self.symbols = [[self.symbols sortedArrayUsingDescriptors:@[sort]] mutableCopy];
}


-(void) sortSymbols_bySize:(BOOL)ascendingIn
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"size_bytes" ascending:ascendingIn];
    self.symbols = [[self.symbols sortedArrayUsingDescriptors:@[sort]] mutableCopy];
}


+(NSArray*) getMemorySectionsForModuleWithFlashSize_bytes:(NSUInteger)flashSizeIn
{
    // our main array
    NSArray* retVal = @[

                        [[OVRMemorySection alloc] initWithName:@"dport0"
                                                   description:@"Memory-mapped I/O, repeated every 100h."
                                                          type:OVR_MEMSECTIONTYPE_IO
                                                  startAddress:0x3FF00000
                                                 maxSize_bytes:0x1000
                                               isUserAccesible:NO],
                        [[OVRMemorySection alloc] initWithName:@"dram0"
                                                   description:@"User data RAM. This is where your variables live."
                                                          type:OVR_MEMSECTIONTYPE_RAM
                                                  startAddress:0x3FFE8000
                                                 maxSize_bytes:0x14000
                                               isUserAccesible:YES],
                        [[OVRMemorySection alloc] initWithName:@"etsRAM"
                                                   description:@"ETS system data RAM"
                                                          type:OVR_MEMSECTIONTYPE_RAM
                                                  startAddress:0x3FFFC000
                                                 maxSize_bytes:0x4000
                                               isUserAccesible:NO],
                        [[OVRMemorySection alloc] initWithName:@"brom"
                                                   description:@"Internal ROM. May be writable somehow, but details unknown."
                                                          type:OVR_MEMSECTIONTYPE_ROM
                                                  startAddress:0x40000000
                                                 maxSize_bytes:0x10000
                                               isUserAccesible:NO],
                        [[OVRMemorySection alloc] initWithName:@"iram1"
                                                   description:@"Instruction RAM. Used by bootloader to load SPI Flash <40000h."
                                                          type:OVR_MEMSECTIONTYPE_RAM
                                                  startAddress:0x40100000
                                                 maxSize_bytes:0x8000
                                               isUserAccesible:NO],
                        [[OVRMemorySection alloc] initWithName:@"spiFlash"
                                                   description:@"External SPI Flash is mapped here. This is where your code lives."
                                                          type:OVR_MEMSECTIONTYPE_ROM
                                                  startAddress:0x40200000
                                                 maxSize_bytes:flashSizeIn
                                               isUserAccesible:YES]
                        ];
    return retVal;
}

@end
