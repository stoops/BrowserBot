//
//  AppDelegate.m
//  BrowserBot
//
//  Created by jon on 2022-07-15.
//

#import "AppDelegate.h"

#define MAGIC 0x31337

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;

@end

@implementation AppDelegate


long dels;
NSMutableArray *data, *loop;


/* helper */

- (NSNumber *)makeInts:(int)num {
    return [NSNumber numberWithInt:num];
}

- (NSNumber *)makeNumb:(long)num {
    return [NSNumber numberWithLong:num];
}

- (NSString *)makeDate:(long)secs adds:(long)numb show:(NSString *)reqs {
    NSDate *edate = [[NSDate alloc] initWithTimeIntervalSince1970:secs];
    NSDateFormatter *fdate = [[NSDateFormatter alloc] init];
    [fdate setDateFormat:[NSString stringWithFormat:@" [MM-dd/HH:mm %@ %ld]", reqs, numb]];
    return [fdate stringFromDate:edate];
}

- (NSArray *)makeLoop {
    long secs = time(NULL);
    /* last-loop, last-data, data-inp, data-out, new-flag */
    return @[[self makeNumb:0], [self makeNumb:secs], @"", @"...", [self makeNumb:0]];
}

- (NSTextField *)makeText:(NSString *)string {
    NSTextField *tf = [[NSTextField alloc] init];
    [tf setBezeled:NO];
    [tf setDrawsBackground:NO];
    [tf setEditable:NO];
    [tf setSelectable:NO];
    [tf setFont:[NSFont fontWithName:@"Menlo" size:13]];
    [tf setStringValue:string];
    return tf;
}

- (NSButton *)makeButton:(NSString *)text tagValue:(long)tag methType:(int)meth {
    NSButton *butn = [[NSButton alloc] init];
    [butn setButtonType:NSButtonTypeMomentaryLight];
    [butn setBezelStyle:NSBezelStyleRounded];
    [butn setTag:tag];
    [butn setTitle:text];
    [butn setTarget:self];
    if (meth == 0) {
        [butn setAction:@selector(itemRemo:)];
    } else {
        [butn setAction:@selector(itemCopy:)];
    }
    return butn;
}

- (NSStackView *)makeStack:(NSArray *)items tagNum:(long)tag {
    NSStackView *sv = [[NSStackView alloc] init];
    [sv setOrientation:NSUserInterfaceLayoutOrientationHorizontal];
    [sv setAlignment:NSLayoutAttributeCenterY];
    [sv setDistribution:NSStackViewDistributionGravityAreas];
    [sv setSpacing:8];
    [sv addArrangedSubview:[self makeButton:@"x" tagValue:tag methType:0]];
    [sv addArrangedSubview:[self makeButton:@"#" tagValue:tag methType:1]];
    for (int i = 0; i < [items count]; ++i) {
        NSString *is = [items objectAtIndex:i];
        [sv addArrangedSubview:[self makeText:is]];
    }
    return sv;
}

- (int)viewLeng:(int)idx {
    int leng = 0, offs = 0, indx = -1;
    NSArray *viewlist = [self.stack arrangedSubviews];

    for (int i = 0; i < [viewlist count]; ++i) {
        long real = (i - offs);
        NSStackView *subsview = [viewlist objectAtIndex:i];
        if ([[subsview subviews] count] < 1) { offs = (offs + 1); continue; }

        if (idx < 0) {
            NSArray *itemlist = [subsview arrangedSubviews];
            NSButton *buta = [itemlist objectAtIndex:0];
            NSButton *butb = [itemlist objectAtIndex:1];
            [buta setTag:(real+1)]; [butb setTag:(real+1)];
        }

        if ((indx < 0) && (real == idx)) { indx = i; }
        leng = (leng + 1);
    }

    if (idx > -1) { return indx; }
    return leng;
}

- (void)viewRemo:(NSStackView *)subview {
    NSArray *itemviews = [subview arrangedSubviews];
    unsigned long i = [itemviews count];
    while (i > 0) {
        i = (i - 1);
        NSView *itemview = [itemviews objectAtIndex:i];
        [itemview removeFromSuperview];
    }
    if (subview) {
        [subview removeFromSuperview];
    }
}

- (void)procData:(NSData *)data dataIndx:(int)indx {
    if (indx < [loop count]) {
        NSMutableArray *loopitem = [loop objectAtIndex:indx];
        NSNumber *secs = [self makeNumb:time(NULL)];
        [loopitem replaceObjectAtIndex:1 withObject:secs];
        [loopitem replaceObjectAtIndex:2 withObject:data];
    }
}

- (NSString *)procComd:(NSString *)args stdInput:(NSData *)stdi trimStr:(bool)trim {
    char buff[32];
    bzero(buff, 32);
    strncpy(buff, "/tmp/tmpfile-XXXXXX", 21);
    int fd = mkstemp(buff);

    NSFileHandle *fileinpt = [[NSFileHandle alloc] initWithFileDescriptor:fd];
    [fileinpt writeData:stdi];
    [fileinpt closeFile]; close(fd);

    fd = open(buff, 'r');
    fileinpt = [[NSFileHandle alloc] initWithFileDescriptor:fd];

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
    [fileinpt closeFile]; close(fd);
    unlink(buff);

    NSString *outp = [[NSString alloc] initWithBytes:[stdo bytes] length:[stdo length] encoding:NSUTF8StringEncoding];
    if (trim) {
        outp = [outp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    //NSLog (@"stdout: [%@]", outp);
    if ([outp length] < 1) { return @""; }

    return outp;
}

- (void)getWeb:(NSString *)urls dataIndx:(int)indx {
    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urls]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode == 200) {
            dispatch_async(dispatch_get_main_queue(), ^{ [self procData:data dataIndx:indx]; });
        }
    }];
    [task resume];
}

/* main */

- (void)timeLoop:(NSTimer *)timerObj {
    long maxp = 1, secs = time(NULL), offs = 0, newb = 0;

    long vnum = 0, lnum = [loop count], dnum = [data count];
    while (lnum < dnum) { [loop addObject:[[self makeLoop] mutableCopy]]; lnum += 1; }
    while (lnum > dnum) { [loop removeLastObject]; lnum -= 1; }

    vnum = [self viewLeng:-1]; lnum = [loop count];
    while (vnum < lnum) {
        NSStackView *subv = [self makeStack:@[@"", @"", @""] tagNum:(vnum+1)];
        [self.stack addArrangedSubview:subv];
        vnum += 1;
    }
    while (vnum > lnum) {
        NSArray *subs = [self.stack arrangedSubviews];
        [self viewRemo:[subs lastObject]];
        vnum -= 1;
    }

    for (int i = 0; i < [data count]; ++i) {
        NSMutableArray *dataitem = [data objectAtIndex:i];
        long leng = [[dataitem objectAtIndex:0] length];
        if (leng > maxp) { maxp = leng; }
    }

    for (int i = 0; i < [data count]; ++i) {
        NSMutableArray *dataitem = [data objectAtIndex:i];
        NSMutableArray *loopitem = [loop objectAtIndex:i];

        /* process */

        NSData *resp = [loopitem objectAtIndex:2];

        if ([resp length] > 0) {
            NSNumber *nsec = [self makeNumb:secs];
            NSString *args = [dataitem objectAtIndex:2];

            NSLog(@"command: %d [%@]", i, args);
            NSString *outp = [self procComd:args stdInput:resp trimStr:YES];

            if ([outp length] > 0) {
                if (![[loopitem objectAtIndex:3] isEqualToString:outp]) {
                    [loopitem replaceObjectAtIndex:4 withObject:[self makeNumb:1]];
                }
                [loopitem replaceObjectAtIndex:1 withObject:nsec];
                [loopitem replaceObjectAtIndex:2 withObject:@""];
                [loopitem replaceObjectAtIndex:3 withObject:outp];
            }
        }

        /* variables */

        NSString *labl = [dataitem objectAtIndex:0];
        long waittime = [[dataitem objectAtIndex:3] longValue];
        long lasttime = [[loopitem objectAtIndex:0] longValue];
        long datatime = [[loopitem objectAtIndex:1] longValue];
        NSString *outp = [loopitem objectAtIndex:3];

        /* fetch */

        NSString *reqsstat = @"~";

        if ((secs - lasttime) >= (waittime * 60)) {
            NSNumber *gsec = [self makeNumb:(secs+offs)];
            NSString *urls = [dataitem objectAtIndex:1];

            NSLog(@"request: %d [%@]", i, urls);
            [self getWeb:urls dataIndx:i];

            [loopitem replaceObjectAtIndex:0 withObject:gsec];
            offs = (offs + 33);
            reqsstat = @"@";
        }

        /* views */

        NSString *padd = [[NSString string] stringByPaddingToLength:((maxp+1)-[labl length]) withString:@" " startingAtIndex:0];
        NSString *name = [NSString stringWithFormat:@"%@%@", padd, labl];
        NSString *dsec = [self makeDate:datatime adds:waittime show:reqsstat];
        NSStackView *view = [[self.stack arrangedSubviews] objectAtIndex:[self viewLeng:i]];
        NSArray *subs = [view arrangedSubviews];

        /* refresh */

        if ([subs count] > 0) {
            [[subs objectAtIndex:2] setStringValue:dsec];
            [[subs objectAtIndex:3] setStringValue:name];
            [[subs objectAtIndex:4] setStringValue:outp];
        }

        if ([[dataitem objectAtIndex:2] containsString:@"# badge"]) {
            newb += [[loopitem objectAtIndex:4] longValue];
        }
    }

    dels = MAGIC;
    if (newb > 0) { NSApp.dockTile.badgeLabel = [NSString stringWithFormat:@"%ld", newb]; }
    else { NSApp.dockTile.badgeLabel = @""; }
}

/* delegate */

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //[self.window orderOut:self];
    [self windowDidResize:NULL];

    [self.table selectTabViewItemAtIndex:0];
    [self.stack addArrangedSubview:[[NSView alloc] init]];
    [self.stack setDistribution:NSStackViewDistributionFill];
    //[self.stack setDistribution:NSStackViewDistributionGravityAreas];

    NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
    NSArray *cmds = [pref arrayForKey:@"data"];
    if (!cmds) {
        cmds = @[];
        [pref setObject:cmds forKey:@"data"];
    }

    dels = MAGIC;
    data = [cmds mutableCopy];
    loop = [NSMutableArray arrayWithArray:@[]];

    [self resClick:nil];
    [self timeLoop:nil];
    [NSTimer scheduledTimerWithTimeInterval:13 target:self selector:@selector(timeLoop:) userInfo:nil repeats:YES];

    [self.save setAction:@selector(addClick:)];
    [self.repl setAction:@selector(repClick:)];
    [self.rset setAction:@selector(resClick:)];

    [self.indx setAlignment:NSTextAlignmentRight];
    [self.expr.documentView insertText:[NSString stringWithFormat:@"%@", data]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)app hasVisibleWindows:(BOOL)flag {
    [self.window makeKeyAndOrderFront:self];
    for (int i = 0; i < [loop count]; ++i) {
        NSMutableArray *loopitem = [loop objectAtIndex:i];
        [loopitem replaceObjectAtIndex:4 withObject:[self makeNumb:0]];
    }
    NSApp.dockTile.badgeLabel = @"";
    return NO;
}

- (void)windowDidResize:(NSNotification *)aNotification {
    float wide = self.window.frame.size.width;
    float high = self.window.frame.size.height;
    /* views */
    [self.table setFrameOrigin:CGPointMake(-8, -8)];
    [self.table setFrameSize:CGSizeMake(wide+16, high-30)];
    [self.stack setFrameOrigin:CGPointMake(16, 8)];
    [self.stack setFrameSize:CGSizeMake(wide-8, high-110)];
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

        if ((indx <= -1) || (indx >= [data count])) {
            [data addObject:[item mutableCopy]];
            [loop addObject:[info mutableCopy]];
        } else {
            if (act == 0) {
                [data insertObject:[item mutableCopy] atIndex:indx];
                [loop insertObject:[info mutableCopy] atIndex:indx];
            } else {
                [data replaceObjectAtIndex:indx withObject:[item mutableCopy]];
                [loop replaceObjectAtIndex:indx withObject:[info mutableCopy]];
            }
        }

        [pref setObject:[data copy] forKey:@"data"];
        [self.table selectTabViewItemAtIndex:0];
    }

    [self resClick:nil];
    [self timeLoop:nil];
}

- (void)addClick:(NSNotification *)aNotification {
    [self actClick:aNotification mode:0];
}

- (void)repClick:(NSNotification *)aNotification {
    [self actClick:aNotification mode:1];
}

- (int)itemRemo:(NSNotification *)aNotification {
    NSButton *butn = (NSButton *)aNotification;

    long indx = ([butn tag] - 1);
    if ((dels == indx) && (-1 < indx) && (indx < [data count])) {
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
        [loop removeObjectAtIndex:indx];
        [data removeObjectAtIndex:indx];
        [pref setObject:[data copy] forKey:@"data"];
        [self timeLoop:nil];
        dels = MAGIC;
        return 1;
    }

    dels = indx;
    [self itemCopy:aNotification];
    return 0;
}

- (void)itemCopy:(NSNotification *)aNotification {
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
}


@end
