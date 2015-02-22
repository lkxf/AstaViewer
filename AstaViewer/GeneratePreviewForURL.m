#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);


NSString* GetJavaPath() {
    NSTask* whichJavaTask = [NSTask new];
    whichJavaTask.launchPath = @"/usr/bin/which";
    whichJavaTask.arguments = @[@"java"];
    NSPipe* readPipe = [NSPipe pipe];
    NSFileHandle* readHandle = readPipe.fileHandleForReading;
    whichJavaTask.standardOutput = readPipe;
    
    [whichJavaTask launch];
    [whichJavaTask waitUntilExit];
    
    if (whichJavaTask.terminationReason != NSTaskTerminationReasonExit ||
        whichJavaTask.terminationStatus != 0) {
        [readHandle closeFile];
        return nil;
    }
    
    NSData* stdoutData = [readHandle readDataToEndOfFile];
    [readHandle closeFile];
    
    NSString* stdoutStr = [[NSString alloc] initWithData:stdoutData encoding:NSUTF8StringEncoding];
    return [stdoutStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

NSString* CreateTemporaryFolder() {
    NSString* uuid = [[NSUUID UUID] UUIDString];
    NSString* tempFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:uuid];
    
    NSError* error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:tempFolder
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error]) {
        return nil;
    }
    
    return tempFolder;
}



OSStatus GeneratePreviewForURL(void *thisInterface,
                               QLPreviewRequestRef preview,
                               CFURLRef url,
                               CFStringRef contentTypeUTI,
                               CFDictionaryRef options)
{
    @autoreleasepool {
        NSString* javaPath = GetJavaPath();
        if (!javaPath) {
            NSLog(@"ERROR: cannot locate java executable");
            return -1;
        }
        
        NSString* tempFolder = CreateTemporaryFolder();
        if (!tempFolder) {
            NSLog(@"ERROR: cannot create temporary folder");
            return -2;
        }
        
        NSString* filePath = ((__bridge NSURL*)url).path;
        
        CFBundleRef bundleRef = QLPreviewRequestGetGeneratorBundle(preview);
        NSURL* bundleResourcesURL = (__bridge NSURL*)CFBundleCopyResourcesDirectoryURL(bundleRef);
        NSString* jarPath = [[bundleResourcesURL URLByAppendingPathComponent:@"Java"]
                             URLByAppendingPathComponent:@"astah-community.jar"].path;
        
        NSArray* args = @[@"-Djava.awt.headless=true",
                          @"-Dcheck_jvm_version=false",
                          @"-cp", jarPath,
                          @"com.change_vision.jude.cmdline.JudeCommandRunner",
                          @"-image", @"all",
                          @"-dpi", @"72",
                          @"-resized",
                          @"-f", filePath,
                          @"-t", @"jpg",
                          @"-o", tempFolder];
        
        NSTask* exportTask = [NSTask new];
        exportTask.launchPath = javaPath;
        exportTask.arguments = args;
        [exportTask launch];
        [exportTask waitUntilExit];
        
        if (exportTask.terminationReason != NSTaskTerminationReasonExit ||
            exportTask.terminationStatus != 0) {
            NSLog(@"ERROR: failed to generate thumbnails for %@", filePath);
            return -3;
        }

        NSString* firstDiagramPath = nil;
        NSDirectoryEnumerator* etor = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:tempFolder isDirectory:YES]
                                                           includingPropertiesForKeys:nil
                                                                              options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                         errorHandler:nil];
        for (NSURL* diagramURL in etor) {
            if ([diagramURL.pathExtension isEqualToString:@"jpg"]) {
                NSLog(@"DIAGRAM FOUND: %@", diagramURL);
                firstDiagramPath = diagramURL.path;
                break;
            }
        }
        
        NSImage* image = [[NSImage alloc] initWithContentsOfFile:firstDiagramPath];
        CGSize canvasSize = image.size;
        
        if (canvasSize.width > 800) {
            canvasSize.height *= 800.0 / canvasSize.width;
            canvasSize.width = 800;
        }
        if (canvasSize.height > 600) {
            canvasSize.width *= 600.0 / canvasSize.height;
            canvasSize.height = 600;
        }
        
        canvasSize.width = floor(canvasSize.width);
        canvasSize.height = floor(canvasSize.height);
        
        // Preview will be drawn in a vectorized context
        // Here we create a graphics context to draw the Quick Look Preview in
        CGContextRef cgContext = QLPreviewRequestCreateContext(preview, canvasSize, false, NULL);
        NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort:cgContext flipped:NO];
        if (!context) {
            NSLog(@"ERROR: failed to create graphics context");
            return -5;
        }
        
        //These two lines of code are just good safe programming...
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:context];
        
        [image drawInRect:NSMakeRect(0, 0, canvasSize.width, canvasSize.height)];
        
        //This line sets the context back to what it was when we're done
        [NSGraphicsContext restoreGraphicsState];
        
        // When we are done with our drawing code QLPreviewRequestFlushContext() is called to flush the context
        QLPreviewRequestFlushContext(preview, cgContext);
        
        CFRelease(cgContext);
        
        [[NSFileManager defaultManager] removeItemAtPath:tempFolder
                                                   error:NULL];
    }
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
