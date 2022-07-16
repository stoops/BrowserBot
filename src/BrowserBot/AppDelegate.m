//
//  AppDelegate.m
//  BrowserBot
//
//  Created by jon on 2022-07-15.
//


#import <Cocoa/Cocoa.h>

@interface TextObjc : NSTextField

@end

@implementation TextObjc

- (void)mouseDown:(NSEvent *)event {
    NSAttributedString *at = [self attributedStringValue];
    NSDictionary *di = [at attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, at.length)];
    for (id dkey in di) {
        id dval = [di objectForKey:dkey];
        NSString *urls = [NSString stringWithFormat:@"%@", dval];
        if ([urls containsString:@"http"]) {
            NSLog(@"link [%@][%@] [%@]",dkey,dval,urls);
            NSURL *urlo = [NSURL URLWithString:urls];
            [[NSWorkspace sharedWorkspace] openURL:urlo];
        }
    }
    [super mouseDown:event];
}

@end


#import "AppDelegate.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSTabView *table;
@property (strong) IBOutlet NSStackView *stack;
@property (strong) IBOutlet NSButton *save;
@property (strong) IBOutlet NSButton *repl;
@property (strong) IBOutlet NSButton *rset;
@property (strong) IBOutlet NSTextField *indx;
@property (strong) IBOutlet NSTextField *name;
@property (strong) IBOutlet NSTextField *urls;
@property (strong) IBOutlet NSTextField *comd;
@property (strong) IBOutlet NSPopUpButton *refr;
@property (strong) IBOutlet NSButton *expb;
@property (strong) IBOutlet NSTextView *expt;

@end

@implementation AppDelegate


#define RELAX 0x0
#define QUERY 0x1
#define RETRY 0x3
#define MAGIC 0x31337


long dels, mark;
NSMutableArray *data, *loop, *objs;


/* helper */

- (long)saferSub:(long)a b:(long)c {
    if (a > c) { return (a - c); }
    return 0;
}

- (long)makeTime:(long)off {
    time_t secs = time(NULL);
    return (secs - off);
}

- (NSNumber *)makeInts:(int)num {
    return [NSNumber numberWithInt:num];
}

- (NSNumber *)makeNumb:(long)num {
    return [NSNumber numberWithLong:num];
}

- (NSString *)makeDate:(long)secs adds:(long)numb show:(NSString *)reqs {
    NSDate *edate = [NSDate dateWithTimeIntervalSince1970:secs];
    NSDateFormatter *fdate = [[NSDateFormatter alloc] init];
    [fdate setDateFormat:[NSString stringWithFormat:@"{HH:mm %@ %ld} ", reqs, numb]];
    return [fdate stringFromDate:edate];
}

- (NSArray *)makeLoop {
    return @[[self makeNumb:[self makeTime:86400]], @"", @[@"..."], [self makeNumb:0], [self makeNumb:0]];
}

- (NSTextField *)makeText:(NSString *)string {
    TextObjc *tf = [[TextObjc alloc] init];
    [tf setBezeled:NO];
    [tf setDrawsBackground:NO];
    [tf setEditable:NO];
    [tf setSelectable:NO];
    [tf setAllowsEditingTextAttributes:YES];
    [tf setMaximumNumberOfLines:1];
    [tf setLineBreakMode:NSLineBreakByTruncatingTail];
    [tf setFont:[NSFont fontWithName:@"Menlo" size:13]];
    [tf setStringValue:string];
    return tf;
}

- (NSButton *)makeButton:(NSString *)text tagValue:(long)tagn methType:(int)meth {
    NSButton *bn = [[NSButton alloc] init];
    [bn setButtonType:NSButtonTypeMomentaryLight];
    [bn setBezelStyle:NSBezelStyleRounded];
    [bn setTag:tagn];
    [bn setTitle:text];
    [bn setTarget:self];
    if (meth == 1) {
        [bn setAction:@selector(itemRemo:)];
    } else {
        [bn setAction:@selector(itemCopy:)];
    }
    return bn;
}

- (CGSize)sizeStack:(float)kind {
    float wide = self.window.frame.size.width;
    float high = self.window.frame.size.height;
    float offw = (48.0 - (kind * 8.0));
    float offh = (96.0 - (kind * 8.0));
    return CGSizeMake(wide-offw, high-offh);
}

- (NSStackView *)makeStack:(NSArray *)items tagNum:(long)tag {
    NSStackView *sv = [[NSStackView alloc] init];
    [sv setOrientation:NSUserInterfaceLayoutOrientationHorizontal];
    [sv setAlignment:NSLayoutAttributeCenterY];
    [sv setDistribution:NSStackViewDistributionGravityAreas];
    [sv setSpacing:8];
    [sv setFrameSize:[self sizeStack:1.0]];
    if (items) {
        [sv addArrangedSubview:[self makeButton:@"x" tagValue:tag methType:1]];
        [sv addArrangedSubview:[self makeButton:@"#" tagValue:tag methType:2]];
        for (int i = 0; i < [items count]; ++i) {
            NSString *is = [items objectAtIndex:i];
            NSTextField *tf = [self makeText:is];
            [sv addArrangedSubview:tf];
        }
    }
    return sv;
}

- (void)viewRemo:(NSStackView *)subsview {
    while ([[subsview arrangedSubviews] count] > 0) {
        NSArray *viewlist = [subsview arrangedSubviews];
        NSView *viewitem = [viewlist lastObject];
        [viewitem removeFromSuperview];
    }
    [subsview removeFromSuperview];
}

- (void)procView:(int)indx viewData:(NSArray *)info {
    long onum = [objs count], lnum = [loop count], dnum = [data count];

    while (onum < lnum) {
        NSStackView *subv = [self makeStack:@[@"", @"", @""] tagNum:MAGIC];
        [objs addObject:subv];
        [self.stack addView:subv inGravity:NSStackViewGravityBottom];
        onum += 1;
    }

    while (onum > lnum) {
        NSStackView *subv = [objs lastObject];
        [self viewRemo:subv];
        [objs removeLastObject];
        onum -= 1;
    }

    if ((-1 < indx) && (indx < onum)) {
        NSStackView *view = [objs objectAtIndex:indx];
        NSArray *subs = [view arrangedSubviews];

        if ([subs count] > 0) {
            [[subs objectAtIndex:0] setTag:(indx+1)];
            [[subs objectAtIndex:1] setTag:(indx+1)];
            [[subs objectAtIndex:2] setStringValue:[info objectAtIndex:0]];
            [[subs objectAtIndex:3] setStringValue:[info objectAtIndex:1]];
            [[subs objectAtIndex:4] setStringValue:[info objectAtIndex:2]];
            if ((-1 < indx) && (indx < dnum)) {
                NSMutableArray *di = [data objectAtIndex:indx];
                NSString *us = [di objectAtIndex:1];
                NSString *is = [info objectAtIndex:1];
                TextObjc *tf = [subs objectAtIndex:3];
                NSURL *uo = [NSURL URLWithString:us];
                NSMutableAttributedString *at = [[NSMutableAttributedString alloc] initWithString:is];
                [at addAttribute:NSLinkAttributeName value:uo range:NSMakeRange(0, is.length)];
                [tf setAttributedStringValue:at];
            }
        }
    }
}

- (void)procDock:(long)numb {
    NSString *nums = @"";
    if (numb > 0) { nums = [NSString stringWithFormat:@"%ld", numb]; }
    [[NSApp dockTile] setBadgeLabel:nums];
}

- (void)procData:(NSData *)data dataIndx:(int)indx {
    if (indx < [loop count]) {
        NSMutableArray *loopitem = [loop objectAtIndex:indx];
        [loopitem replaceObjectAtIndex:1 withObject:data];
        [self timeLoop:nil];
    }
}

- (NSString *)procComd:(NSString *)args stdInput:(NSData *)stdi trimStr:(bool)trim {
    char buff[32];
    bzero(buff, 32); strncpy(buff, "/tmp/tmpfile-XXXXXX", 21);
    int fd = mkstemp(buff);
    NSString *filepath = [NSString stringWithCString:buff encoding:NSASCIIStringEncoding];

    if (fd == -1) { return @""; }

    NSFileHandle *fileinpt = [NSFileHandle fileHandleForWritingAtPath:filepath];
    [fileinpt writeData:stdi];
    [fileinpt closeFile]; close(fd);
    fileinpt = [NSFileHandle fileHandleForReadingAtPath:filepath];

    NSPipe *pipeoutp = [NSPipe pipe];
    NSFileHandle *fileoutp = pipeoutp.fileHandleForReading;
    NSFileHandle *outpxxxx = pipeoutp.fileHandleForWriting;

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-c", args];
    task.standardInput = fileinpt;
    task.standardOutput = pipeoutp;

    [task launch];

    NSData *stdo = [fileoutp readDataToEndOfFile];
    [fileoutp closeFile]; [outpxxxx closeFile];
    [fileinpt closeFile]; unlink(buff);

    NSString *outp = [[NSString alloc] initWithBytes:[stdo bytes] length:[stdo length] encoding:NSASCIIStringEncoding];
    if (trim) {
        outp = [outp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    return outp;
}

- (void)getWeb:(NSString *)urls dataIndx:(int)indx {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urls] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:11];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if ((http.statusCode == 200) && data && ([data length] > 0)) {
            [self procData:data dataIndx:indx];
        }
    }];
    [task resume];
}

/* main */

- (void)timeLoop:(NSTimer *)timerObj {
    long maxp = 1, reqs = 0, newb = 0;
    long lnum = [loop count], dnum = [data count], secs = [self makeTime:0];

    while (lnum < dnum) {
        [loop addObject:[[self makeLoop] mutableCopy]];
        lnum += 1;
    }

    while (lnum > dnum) {
        [loop removeLastObject];
        lnum -= 1;
    }

    for (int i = 0; i < dnum; ++i) {
        NSMutableArray *dataitem = [data objectAtIndex:i];
        long leng = [[dataitem objectAtIndex:0] length];
        if (leng > maxp) { maxp = leng; }
    }

    for (int i = 0; i < dnum; ++i) {
        NSMutableArray *dataitem = [data objectAtIndex:i];
        NSMutableArray *loopitem = [loop objectAtIndex:i];

        /* variables */

        NSString *labl =  [dataitem objectAtIndex:0];
        NSString *urls =  [dataitem objectAtIndex:1];
        NSString *args =  [dataitem objectAtIndex:2];
        long  waittime = [[dataitem objectAtIndex:3] longValue];

        long  lasttime = [[loopitem objectAtIndex:0] longValue];
        NSData   *resp =  [loopitem objectAtIndex:1];
        NSArray  *outp =  [loopitem objectAtIndex:2];
        long  listindx = [[loopitem objectAtIndex:3] longValue];
        long  statnumb = [[loopitem objectAtIndex:4] longValue];

        /* process */

        if ([resp length] > 0) {
            NSLog(@"command: %d [%@]", i, args);
            NSString *stdo = [self procComd:args stdInput:resp trimStr:YES];
            NSArray *stdl = [stdo componentsSeparatedByString:@"\n"];

            if (statnumb != MAGIC) { statnumb = RELAX; }
            if ([stdo length] > 0) {
                if (([args containsString:@"# badge"]) && (![stdl isEqualToArray:outp])) {
                    statnumb = MAGIC;
                }
                outp = stdl;
            }
            listindx = 0;

            [loopitem replaceObjectAtIndex:1 withObject:@""];
            [loopitem replaceObjectAtIndex:2 withObject:outp];
            [loopitem replaceObjectAtIndex:3 withObject:[self makeNumb:listindx]];
            [loopitem replaceObjectAtIndex:4 withObject:[self makeNumb:statnumb]];
        }

        /* fetch */

        NSString *statstrs = @"*";

        if (reqs < 1) {
            if (timerObj && (statnumb == QUERY)) {
                lasttime = 0; statnumb = RETRY;
            }

            if ((secs - lasttime) >= (waittime * 60)) {
                NSLog(@"request: %d [%@]", i, urls);
                [self getWeb:urls dataIndx:i];

                lasttime = (secs + 5);
                [loopitem replaceObjectAtIndex:0 withObject:[self makeNumb:lasttime]];

                if (statnumb == RELAX) { statnumb = QUERY; }
                [loopitem replaceObjectAtIndex:4 withObject:[self makeNumb:statnumb]];

                reqs += 1;
            }
        }

        if (statnumb == RELAX) { statstrs = @"~"; }
        else if (statnumb == QUERY) { statstrs = @"@"; }
        else if (statnumb == MAGIC) { statstrs = @"!"; }

        /* views */

        long outpleng = [outp count];
        long padl = [self saferSub:(maxp+1) b:[labl length]];

        if (outpleng > 0) {
            NSString *padd = [[NSString string] stringByPaddingToLength:padl withString:@" " startingAtIndex:0];
            NSString *nums = [NSString stringWithFormat:@"%ld/%ld", listindx+1, outpleng];
            NSString *name = [NSString stringWithFormat:@"%@%@", padd, labl];
            NSString *dsec = [self makeDate:lasttime adds:waittime show:statstrs];
            NSString *dstr = [outp objectAtIndex:listindx];

            if (outpleng > 1) {
                padl = [self saferSub:5 b:[nums length]];
                padd = [[NSString string] stringByPaddingToLength:padl withString:@" " startingAtIndex:0];
                dstr = [NSString stringWithFormat:@"(%@%@) %@", padd, nums, dstr];

                if (timerObj) {
                    listindx = ((listindx + 1) % outpleng);
                    [loopitem replaceObjectAtIndex:3 withObject:[self makeNumb:listindx]];
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [self procView:i viewData:@[dsec, name, dstr]];
            });
        }

        if (statnumb == MAGIC) { newb += 1; }
    }

    if (timerObj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self procDock:newb];
        });
    }

    dels = MAGIC;
}

/* delegate */

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self windowDidResize:NULL];

    [self.table selectTabViewItemAtIndex:0];
    [self.stack addArrangedSubview:[self makeStack:nil tagNum:MAGIC]];
    [self.stack setDistribution:NSStackViewDistributionGravityAreas];

    NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
    NSArray *cmds = [pref arrayForKey:@"data"];

    if (!cmds) {
        cmds = @[];
        [pref setObject:cmds forKey:@"data"];
        [pref synchronize];
    }

    mark = 0;
    dels = MAGIC;
    data = [cmds mutableCopy];
    loop = [NSMutableArray arrayWithArray:@[]];
    objs = [NSMutableArray arrayWithArray:@[]];

    [self resClick:nil]; [self timeLoop:nil];
    [NSTimer scheduledTimerWithTimeInterval:13 target:self selector:@selector(timeLoop:) userInfo:nil repeats:YES];

    [self.save setAction:@selector(addClick:)];
    [self.repl setAction:@selector(repClick:)];
    [self.rset setAction:@selector(resClick:)];
    [self.expb setAction:@selector(expClick:)];
    [self.indx setAlignment:NSTextAlignmentRight];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    /* no-op */
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (void)markNews:(NSTimer *)timerObj {
    for (int i = 0; i < [loop count]; ++i) {
        NSMutableArray *loopitem = [loop objectAtIndex:i];
        [loopitem replaceObjectAtIndex:4 withObject:[self makeNumb:0]];
    }
    mark = 0;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)app hasVisibleWindows:(BOOL)flag {
    [self.window makeKeyAndOrderFront:self];

    if (mark == 0) {
        mark = 1;
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(markNews:) userInfo:nil repeats:NO];
    }

    return NO;
}

- (void)windowDidResize:(NSNotification *)aNotification {
    float wide = self.window.frame.size.width;
    float high = self.window.frame.size.height;
    /* views */
    [self.table setFrameOrigin:CGPointMake(-8, -8)];
    [self.table setFrameSize:CGSizeMake(wide+16, high-28)];
    [self.stack setFrameOrigin:CGPointMake(12, 8)];
    [self.stack setFrameSize:[self sizeStack:0.0]];
    //[self.stack setEdgeInsets:NSEdgeInsetsMake(8.0, 8.0, 8.0, 8.0)];
    /* points */
    [self.save setFrameOrigin:NSMakePoint(wide-112, self.save.frame.origin.y)];
    [self.repl setFrameOrigin:NSMakePoint(wide-192, self.repl.frame.origin.y)];
    [self.rset setFrameOrigin:NSMakePoint(wide-112, self.rset.frame.origin.y)];
    [self.indx setFrameOrigin:NSMakePoint(wide-90, self.indx.frame.origin.y)];
    /* sizes */
    [self.name setFrameSize:NSMakeSize((wide/4)*1, self.name.frame.size.height)];
    [self.urls setFrameSize:NSMakeSize((wide*67)/100, self.urls.frame.size.height)];
    [self.comd setFrameSize:NSMakeSize(wide-120, self.comd.frame.size.height)];
}

/* callback */

- (void)resClick:(NSNotification *)aNotification {
    [self.indx setStringValue:@"-1"];
    [self.name setStringValue:@""];
    [self.urls setStringValue:@""];
    [self.comd setStringValue:@""];
    [self.refr selectItemAtIndex:0];
}

- (void)actClick:(NSNotification *)aNotification mode:(int)act {
    int indx = [[self.indx stringValue] intValue];
    long refr = [self.refr selectedTag];

    if ([data count] < 15) {
        NSArray *item = @[[self.name stringValue], [self.urls stringValue], [self.comd stringValue], [self makeNumb:refr]];
        NSArray *info = [self makeLoop];
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];

        if ((indx <= -1) || ([data count] <= indx)) {
            [data addObject:[item mutableCopy]];
            [loop addObject:[info mutableCopy]];
        } else {
            if (act == 1) {
                [data insertObject:[item mutableCopy] atIndex:indx];
                [loop insertObject:[info mutableCopy] atIndex:indx];
            } else {
                [data replaceObjectAtIndex:indx withObject:[item mutableCopy]];
                [loop replaceObjectAtIndex:indx withObject:[info mutableCopy]];
            }
        }

        [pref setObject:[data copy] forKey:@"data"];
        [pref synchronize];

        [self.table selectTabViewItemAtIndex:0];
    }

    [self resClick:nil];
    [self timeLoop:nil];
}

- (void)addClick:(NSNotification *)aNotification {
    [self actClick:aNotification mode:1];
}

- (void)repClick:(NSNotification *)aNotification {
    [self actClick:aNotification mode:2];
}

- (void)expClick:(NSNotification *)aNotification {
    NSString *o = @"";
    for (int i = 0; i < [data count]; ++i) {
        NSArray *z = [data objectAtIndex:i];
        o = [NSString stringWithFormat:@"%@%@\n%@\n%@\n\n", o, [z objectAtIndex:0], [z objectAtIndex:1], [z objectAtIndex:2]];
    }
    [self.expt setString:o];
}

- (int)itemCopy:(NSNotification *)aNotification {
    NSButton *butn = (NSButton *)aNotification;

    long indx = ([butn tag] - 1);
    if ((-1 < indx) && (indx < [data count])) {
        NSArray *dataitem = [data objectAtIndex:indx];
        NSNumber *timerefr = [dataitem objectAtIndex:3];

        [self.indx setStringValue:[NSString stringWithFormat:@"%ld", indx]];
        [self.name setStringValue:[dataitem objectAtIndex:0]];
        [self.urls setStringValue:[dataitem objectAtIndex:1]];
        [self.comd setStringValue:[dataitem objectAtIndex:2]];
        [self.refr selectItemWithTag:[timerefr longValue]];

        if (dels == MAGIC) {
            [self.table selectTabViewItemAtIndex:1];
        }
    }

    return 0;
}

- (int)itemRemo:(NSNotification *)aNotification {
    NSButton *butn = (NSButton *)aNotification;

    long indx = ([butn tag] - 1);
    if ((dels == indx) && (-1 < indx) && (indx < [data count])) {
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];

        [data removeObjectAtIndex:indx];
        [loop removeObjectAtIndex:indx];

        [pref setObject:[data copy] forKey:@"data"];
        [pref synchronize];

        [self procView:-1 viewData:@[]];
        [self timeLoop:nil];

        return 1;
    }

    dels = indx;
    [self itemCopy:aNotification];

    return 0;
}


@end
