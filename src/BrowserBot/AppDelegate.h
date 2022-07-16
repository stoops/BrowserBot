//
//  AppDelegate.h
//  BrowserBot
//
//  Created by jon on 2022-07-15.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, weak) IBOutlet NSTabView *table;
@property (nonatomic, weak) IBOutlet NSStackView *stack;
@property (nonatomic, weak) IBOutlet NSButton *save;
@property (nonatomic, weak) IBOutlet NSButton *repl;
@property (nonatomic, weak) IBOutlet NSButton *rset;
@property (nonatomic, weak) IBOutlet NSTextField *indx;
@property (nonatomic, weak) IBOutlet NSTextField *name;
@property (nonatomic, weak) IBOutlet NSTextField *urls;
@property (nonatomic, weak) IBOutlet NSTextField *comd;
@property (nonatomic, weak) IBOutlet NSPopUpButton *refr;
@property (nonatomic, weak) IBOutlet NSScrollView *expr;

@end
