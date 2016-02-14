//
//  OVRNmParser.h
//  ESP8266 Memory Usage Monitor
//
//  Created by Christopher Armenio on 2/2/16.
//  Copyright © 2016 OvrEngineered. All rights reserved.
//
#import <Foundation/Foundation.h>

#import "OVRSymbol.h"


@interface OVRNmParser : NSObject

-(instancetype) initUsingNmAtPath:(NSString*)pathToNmIn;

-(void) setNmPath:(NSString*)pathToNmIn;

-(NSString*) getLastParsedFileDirectory;

-(NSArray*) parseSymbolsInMemorySectionsFromFile:(NSString*)filePathIn
                   forModuleWithFlashSizeInBytes:(NSUInteger)flashSizeIn;

-(NSString*) findSourceFileForSymbol:(OVRSymbol*)symbolIn;

@end
