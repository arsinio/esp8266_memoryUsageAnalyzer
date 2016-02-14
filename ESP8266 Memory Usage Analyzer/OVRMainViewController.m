//
//  OVRMainViewController.m
//  ESP8266 Memory Usage Monitor
//
//  Created by Christopher Armenio on 2/1/16.
//  Copyright © 2016 OvrEngineered. All rights reserved.
//
#import "OVRMainViewController.h"

#import "OVRNmParser.h"
#import "OVRMemorySection.h"
#import "OVRSymbol.h"


#define COL_ID_ADDRESS          @"col_address"
#define COL_ID_NAME             @"col_name"
#define COL_ID_SIZE             @"col_size"
#define COL_ID_DESCRIPTION      @"col_description"


@interface OVRMainViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (nonatomic, strong) IBOutlet NSButton* btn_nmPath;
@property (nonatomic, strong) IBOutlet NSOutlineView* tbl_memory;

@property (nonatomic, strong) IBOutlet NSComboBox* cmb_flashSize;

@property (nonatomic, strong) IBOutlet NSTextField* lbl_ramUsage;
@property (nonatomic, strong) IBOutlet NSTextField* lbl_flashUsage;
@property (nonatomic, strong) IBOutlet NSTextField* lbl_symbolLocation;

@property (nonatomic, strong) OVRNmParser* nmParser;
@property (nonatomic, strong) NSArray* memorySections;
@end



@implementation OVRMainViewController

#pragma mark - ViewLifeCycle
- (void) viewDidLoad
{
    [super viewDidLoad];
    
    // set some defaults
    self.memorySections = nil;
    self.nmParser = [[OVRNmParser alloc] initUsingNmAtPath:nil];
    
    [self.tbl_memory setDataSource:self];
    [self.tbl_memory setDelegate:self];
}


-(void) viewDidAppear
{
    [super viewDidAppear];
    
    [self.nmParser setNmPath:self.btn_nmPath.title];
}


#pragma mark - IBActions
-(IBAction) onTap_openElf:(NSButton*)sender;
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setTitle:@"Select ELF to parse"];
    [openDlg setPrompt:@"Select"];
    [openDlg setAllowedFileTypes:@[@"elf"]];
    [openDlg beginWithCompletionHandler:^(NSInteger result) {
        if( result == NSFileHandlingPanelCancelButton ) return;
        
        // parse the file in a separate thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @try
            {
                NSUInteger flashSize_bytes;
                if( [self.cmb_flashSize.stringValue hasSuffix:@"MB"] )
                {
                    flashSize_bytes = [[self.cmb_flashSize.stringValue substringToIndex:self.cmb_flashSize.stringValue.length-2] integerValue];
                    flashSize_bytes /= 4;               // word size
                    flashSize_bytes *= 1024 * 1024;
                }
                self.memorySections = [self.nmParser parseSymbolsInMemorySectionsFromFile:openDlg.URL.path
                                                            forModuleWithFlashSizeInBytes:flashSize_bytes];
                
                // calculate our ram and flash usage
                NSUInteger ram_size_bytes = 0;
                NSUInteger flash_size_bytes = 0;
                NSUInteger ram_maxSize_bytes = 0;
                NSUInteger flash_maxSize_bytes = 0;
                for( OVRMemorySection* currMemSection in self.memorySections )
                {
                    if( ([currMemSection getType] == OVR_MEMSECTIONTYPE_RAM) && [currMemSection isUserAccessibleIn] )
                    {
                        ram_size_bytes += [currMemSection getSize_bytes];
                        ram_maxSize_bytes += [currMemSection getMaxSize_bytes];
                    }
                    else if( ([currMemSection getType] == OVR_MEMSECTIONTYPE_ROM) && [currMemSection isUserAccessibleIn] )
                    {
                        flash_size_bytes += [currMemSection getSize_bytes];
                        flash_maxSize_bytes += [currMemSection getMaxSize_bytes];
                    }
                }
                [self.lbl_ramUsage setStringValue:[NSString stringWithFormat:@"%@ / %@ (%.2f%%)",
                                                   [self getSizeString:ram_size_bytes],
                                                   [self getSizeString:ram_maxSize_bytes],
                                                   (((float)ram_size_bytes) / ((float)ram_maxSize_bytes)) * 100.0]];
                [self.lbl_flashUsage setStringValue:[NSString stringWithFormat:@"%@ / %@ (%.2f%%)",
                                                     [self getSizeString:flash_size_bytes],
                                                     [self getSizeString:flash_maxSize_bytes],
                                                     (((float)flash_size_bytes) / ((float)flash_maxSize_bytes)) * 100.0]];
            }
            @catch (NSException *exception)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSAlert* alert = [[NSAlert alloc] init];
                    [alert setAlertStyle:NSWarningAlertStyle];
                    [alert setMessageText:@"Error parsing .elf file"];
                    [alert setInformativeText:exception.description];
                    [alert addButtonWithTitle:@"Continue"];
                    [alert runModal];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tbl_memory reloadData];
            });
        });
    }];
}


-(IBAction) onTap_selectNm:(NSButton*)sender
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setTitle:@"Select 'xtensa-lx106-elf-nm' executable"];
    [openDlg setPrompt:@"Select"];
    [openDlg setAllowedFileTypes:@[@""]];
    [openDlg setDirectoryURL:[NSURL fileURLWithPath:self.btn_nmPath.title]];
    [openDlg beginWithCompletionHandler:^(NSInteger result) {
        if( result == NSFileHandlingPanelCancelButton ) return;
        [self.btn_nmPath setTitle:openDlg.URL.path];
        [self.nmParser setNmPath:self.btn_nmPath.title];
    }];
}


#pragma mark - NSOutlineView
-(BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [item isKindOfClass:[OVRMemorySection class]];
}


-(NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    NSInteger retVal = 0;
    
    if( item == nil)
    {
        // item is nil when the outline view wants to inquire for root level items
        retVal = (self.memorySections != nil) ? self.memorySections.count : 0;
    }
    else if( [item isKindOfClass:[OVRMemorySection class]] )
    {
        OVRMemorySection* currMemSect = ((OVRMemorySection*)item);
        retVal = [currMemSect getSubSections].count + [currMemSect getSymbols].count;
    }
    
    return retVal;
}


-(id) outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    id retVal = nil;
    
    if( item == nil )
    {
        // item is nil when the outline view wants to inquire for root level items
        retVal = (self.memorySections != nil) ? [self.memorySections objectAtIndex:index] : nil;
    }
    else if( [item isKindOfClass:[OVRMemorySection class]] )
    {
        OVRMemorySection* currMemSect = ((OVRMemorySection*)item);
        if( index < [currMemSect getNumSubSections] ) retVal = [[currMemSect getSubSections] objectAtIndex:index];
        else retVal = [[currMemSect getSymbols] objectAtIndex:index - [currMemSect getNumSubSections]];
    }
    
    return retVal;
}


-(id) outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)theColumn byItem:(id)item
{
    NSString* retVal = nil;
    

    if( [[theColumn identifier] isEqualToString:COL_ID_ADDRESS] )
    {
        retVal = [NSString stringWithFormat:@"0x%08lX", [((OVRSymbol*)item) getStartAddress]];
    }
    else if( [[theColumn identifier] isEqualToString:COL_ID_SIZE] )
    {
        if( [item isKindOfClass:[OVRMemorySection class]] )
        {
            retVal = [self getSizeString:[((OVRMemorySection*)item) getSize_bytes]];
        }
        else
        {
            retVal = [self getSizeString:[((OVRSymbol*)item) getSize_bytes]];
        }
    }
    else if( [[theColumn identifier] isEqualToString:COL_ID_NAME] )
    {
        retVal = [item isKindOfClass:[OVRMemorySection class]] ? [((OVRMemorySection*)item) getName] : [((OVRSymbol*)item) getName];
    }
    else if( [[theColumn identifier] isEqualToString:COL_ID_DESCRIPTION] )
    {
        retVal = [item isKindOfClass:[OVRMemorySection class]] ? [((OVRMemorySection*)item) getDescription] : nil;
    }
    
    return retVal;
}


-(BOOL) outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if( [item isKindOfClass:[OVRSymbol class]] )
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString* sourceFile_str = [self.nmParser findSourceFileForSymbol:((OVRSymbol*)item)];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.lbl_symbolLocation setStringValue:(sourceFile_str != nil) ?
                    [sourceFile_str substringFromIndex:[self.nmParser getLastParsedFileDirectory].length] :
                    @"<unknown>"];
            });
        });
    }
    return YES;
}


-(void) outlineView:(NSOutlineView *)outlineView didClickTableColumn:(NSTableColumn *)tableColumn
{
    if( self.memorySections == nil ) return;
    
    static BOOL ascending = YES;
    
    for( OVRMemorySection* currMemSection in self.memorySections )
    {
        if( [[tableColumn identifier] isEqualToString:COL_ID_ADDRESS] )
        {
            [currMemSection sortSymbols_byAddress:ascending];
        }
        else if( [[tableColumn identifier] isEqualToString:COL_ID_NAME] )
        {
            [currMemSection sortSymbols_byName:ascending];
        }
        else if( [[tableColumn identifier] isEqualToString:COL_ID_SIZE] )
        {
            [currMemSection sortSymbols_bySize:ascending];
        }
    }
    
    ascending = !ascending;
    
    [self.tbl_memory reloadData];
}


#pragma mark - helper functions

-(NSString*) getSizeString:(NSUInteger)size_bytesIn
{
    NSString* retVal = nil;
    
    if( size_bytesIn < 1024 )                                           retVal = [NSString stringWithFormat:@"%lu", (unsigned long)size_bytesIn];
    else if( (1024 <= size_bytesIn) && (size_bytesIn) < (1024*1024) )   retVal = [NSString stringWithFormat:@"%.2fk", ((float)size_bytesIn)/1024];
    else if( (1024*1024 <= size_bytesIn) )                              retVal = [NSString stringWithFormat:@"%.2fM", ((float)size_bytesIn)/(1024*1024)];
    
    return retVal;
}

@end
