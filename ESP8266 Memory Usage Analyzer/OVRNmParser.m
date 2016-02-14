//
//  OVRNmParser.m
//  ESP8266 Memory Usage Monitor
//
//  Created by Christopher Armenio on 2/2/16.
//  Copyright © 2016 OvrEngineered. All rights reserved.
//
#import "OVRNmParser.h"

#import "OVRSymbol.h"
#import "OVRMemorySection.h"


#define MULTIPART_SUFFIX_START              @"_start"
#define MULTIPART_SUFFIX_END                @"_end"

#define EMPTY_LINKERSECTION_NAMES           @[@"_heap"]


@interface OVRNmParser ()
@property (nonatomic, strong) NSString* nmPath;
@property (nonatomic, strong) NSString* lastParsedFileDir;
@end


@implementation OVRNmParser

#pragma mark - public  methods
-(instancetype) initUsingNmAtPath:(NSString*)pathToNmIn
{
    self = [super init];
    if( self != nil )
    {
        self.nmPath = pathToNmIn;
        self.lastParsedFileDir = nil;
    }
    return self;
}


-(void) setNmPath:(NSString*)pathToNmIn
{
    _nmPath = pathToNmIn;
}


-(NSString*) getLastParsedFileDirectory
{
    return self.lastParsedFileDir;
}


-(NSArray*) parseSymbolsInMemorySectionsFromFile:(NSString*)filePathIn
                   forModuleWithFlashSizeInBytes:(NSUInteger)flashSizeIn
{
    NSArray* symbols = [self parseSymbolsFromFileAtPath:filePathIn];
    
    // get our memory sections
    NSArray* memorySections = [OVRMemorySection getMemorySectionsForModuleWithFlashSize_bytes:flashSizeIn];
    
    // organize our symbols into our memory sections
    [OVRNmParser distributeSymbols:symbols intoMemorySections:memorySections];
    
    // save our last parsed file dir
    self.lastParsedFileDir = [filePathIn stringByDeletingLastPathComponent];
    
    return memorySections;
}


-(NSString*) findSourceFileForSymbol:(OVRSymbol*)symbolIn
{
    if( self.lastParsedFileDir == nil ) return nil;
    
    NSPipe* pipe = [NSPipe pipe];
    NSFileHandle* file = pipe.fileHandleForReading;
    
    // execute nm
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = @"/usr/local/bin/grep";
    task.currentDirectoryPath = self.lastParsedFileDir;
    task.arguments = @[@"-r", @"-l", @"--include=*.o", [symbolIn getName], self.lastParsedFileDir];
    task.standardOutput = pipe;
    [task launch];
    
    // get the output data (in string format)
    NSData* data = [file readDataToEndOfFile];
    [file closeFile];
    NSString* output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    // this now contains an array of files that contain this symbol...we need to find
    // the file where this is actually declared...
    NSArray* potentialSourceFiles = [output componentsSeparatedByString:@"\n"];
    for( NSString* currPotentialSource in potentialSourceFiles )
    {
        NSArray* symbolsInCurrFile = [self parseSymbolsFromFileAtPath:currPotentialSource];
        
        // now look through the symbols for the same symbol
        for( OVRSymbol* currSymbol in symbolsInCurrFile )
        {
            if( [currSymbol isEqualToSymbol:symbolIn] ) return currPotentialSource;
        }
    }
    
    // if we made it here, we couldn't find the symbol in our potential sources
    return nil;
}


#pragma mark - private methods

-(NSArray*) parseSymbolsFromFileAtPath:(NSString*)filePathIn
{
    if( [filePathIn isEqualToString:@""] ) return nil;
    
    NSPipe* pipe = [NSPipe pipe];
    NSFileHandle* file = pipe.fileHandleForReading;
    
    // execute nm
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = self.nmPath;
    task.arguments = @[@"-n", @"-S", filePathIn];
    task.standardOutput = pipe;
    [task launch];
    
    // get the output data (in string format)
    NSData* data = [file readDataToEndOfFile];
    [file closeFile];
    NSString* output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // parse the string, line by line, and get all of the symbols
    NSArray* lines = [output componentsSeparatedByString:@"\n"];
    
    NSMutableArray* retVal = [[NSMutableArray alloc] init];
    for( NSString* currLine in lines )
    {
        NSString* trimmedLine = [currLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray* lineFields = [trimmedLine componentsSeparatedByString:@" "];
    
        // parsing depends on the number of fields
        if( lineFields.count == 2 )
        {
            OVRSymbolType type = [OVRSymbol getSymbolTypeFromString:lineFields[0]];
            if( type != OVR_SYMBOLTYPE_UNDEFINED )
            {
                @throw [NSException exceptionWithName:@"Parse Error"
                                               reason:[NSString stringWithFormat:@"unknown symbol type for line '%@'", currLine]
                                             userInfo:nil];
            }
            [retVal addObject:[[OVRSymbol alloc] initUndefinedSymbolNamed:lineFields[1]]];
        }
        else if( (lineFields.count == 3) || (lineFields.count == 4) )
        {
            // get all of our strings (format can change based upon how many fields we have)
            NSString* str_address = lineFields[0];
            NSString* str_length = (lineFields.count == 4) ? lineFields[1] : @"0";
            NSString* str_type = (lineFields.count == 4) ? lineFields[2] : lineFields[1];
            NSString* str_name = (lineFields.count == 4) ? lineFields[3] : lineFields[2];
            
            // figure out our type
            OVRSymbolType type = [OVRSymbol getSymbolTypeFromString:str_type];
            if( type == OVR_SYMBOLTYPE_UNKNOWN )
            {
                @throw [NSException exceptionWithName:@"Parse Error"
                                               reason:[NSString stringWithFormat:@"unknown symbol type for line '%@'", currLine]
                                             userInfo:nil];
            }
            
            // figure out whether we are global
            BOOL isGlobal = ([str_type rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]].location == NSNotFound);
            
            // figure out our address
            NSUInteger address;
            if( ![OVRNmParser parseNumberFromHexString:str_address saveTo:&address] )
            {
                @throw [NSException exceptionWithName:@"Parse Error"
                                               reason:[NSString stringWithFormat:@"unable to parse address for line '%@'", currLine]
                                             userInfo:nil];
            }
            
            // figure out our size
            NSUInteger length;
            if( ![OVRNmParser parseNumberFromHexString:str_length saveTo:&length] )
            {
                @throw [NSException exceptionWithName:@"Parse Error"
                                               reason:[NSString stringWithFormat:@"unable to parse length for line '%@'", currLine]
                                             userInfo:nil];
            }
        
            // add our new symbol
            [retVal addObject:[[OVRSymbol alloc] initWithName:str_name andType:type andStartAddress:address andSize:length isGlobal:isGlobal]];
        }
        else
        {
            NSLog(@"invalid number of fields for line '%@'", currLine);
            continue;
        }
    }
    
    return retVal;
}


+(void) distributeSymbols:(NSArray*)symbolsIn intoMemorySections:(NSArray*)memorySectionsIn
{
    for( OVRSymbol* currSymbol in symbolsIn )
    {
        // find the target memory section
        BOOL wasAddedToSection = NO;
        for( OVRMemorySection* currMemSection in memorySectionsIn )
        {
            if( [currMemSection addSymbol:currSymbol] )
            {
                wasAddedToSection = YES;
                break;
            }
        }
        
        // check to see if we found a target section
        if( !wasAddedToSection && ([currSymbol getType] != OVR_SYMBOLTYPE_ABSOLUTE) && ([currSymbol getType] != OVR_SYMBOLTYPE_UNDEFINED) )
        {
            // we didn't find a match for this symbol
            @throw [NSException exceptionWithName:@"Consistency Error"
                                           reason:[NSString stringWithFormat:@"symbol '%@' @ 0x%lX does not belong in any known memory section",
                                                   [currSymbol getName], (unsigned long)[currSymbol getStartAddress]]
                                         userInfo:nil];
        }
    }
}


+(BOOL) parseNumberFromHexString:(NSString*) hexStringIn saveTo:(NSUInteger*)uintOut
{
    NSScanner* scanner = [NSScanner scannerWithString:hexStringIn];
    unsigned int rawVal;
    if( ![scanner scanHexInt:&rawVal] ) return false;
    
    if( uintOut != NULL ) *uintOut = rawVal;
    return true;
}


@end
