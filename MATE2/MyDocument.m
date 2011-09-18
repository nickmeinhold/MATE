//
//  MyDocument.m
//  MATE2
//
//  Created by Nicholas Meinhold on 16/09/11.
//  Copyright 2011 Cooperative Communities. All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    NSError *error = nil;
    
    [super windowControllerDidLoadNib:aController];
        
    if (!mCaptureSession) {
        BOOL success;
        mCaptureSession = [[QTCaptureSession alloc] init];
        
        QTCaptureDevice *device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
        success = [device open:&error];
        if (!success) {
            [[NSAlert alertWithError:error] runModal];
            return;
        }
        mCaptureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
        success = [mCaptureSession addInput:mCaptureDeviceInput error:&error];
        if (!success) {
            [[NSAlert alertWithError:error] runModal];
            return;
        }
        
        mCaptureDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
        [mCaptureDecompressedVideoOutput setDelegate:self];
        success = [mCaptureSession addOutput:mCaptureDecompressedVideoOutput error:&error];
        if (!success) {
            [[NSAlert alertWithError:error] runModal];
            return;
        }
        
        [mCaptureView setCaptureSession:mCaptureSession];
        
        [mCaptureSession startRunning];
        
        // code for getting the computer's serial number is here: 
        // http://developer.apple.com/library/mac/#technotes/tn1103/_index.html
        
        io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
        if (platformExpert) {
            CFTypeRef serialNumberAsCFString = 
            IORegistryEntryCreateCFProperty(platformExpert,
                                            CFSTR(kIOPlatformSerialNumberKey),
                                            kCFAllocatorDefault, 0);
            if (serialNumberAsCFString) {
                 [serialNumLbl setStringValue:(NSString*)serialNumberAsCFString];
            }
            
            IOObjectRelease(platformExpert);
        }
        
    }
    
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    /*
     Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    */
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    /*
    Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    */
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}

// Handle window closing notifications for the device input and stop the capture session.
- (void)windowWillClose:(NSNotification *)notification
{
    [mCaptureSession stopRunning];
    QTCaptureDevice *device = [mCaptureDeviceInput device];
    if ([device isOpen])
        [device close];
}

// Deallocate memory for the capture objects.
- (void)dealloc
{
    [mCaptureSession release];
    [mCaptureDeviceInput release];
    [mCaptureDecompressedVideoOutput release];
    [super dealloc];
}

// Implement a delegate method that QTCaptureDecompressedVideoOutput calls whenever it receives a frame.
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection {

    // Store the latest frame. Do this in a @synchronized block because the delegate method is not called on the main thread.
    CVImageBufferRef imageBufferToRelease;
    
    CVBufferRetain(videoFrame);
    
    @synchronized (self) {
        imageBufferToRelease = mCurrentImageBuffer;
        mCurrentImageBuffer = videoFrame;
    }
    CVBufferRelease(imageBufferToRelease);
    
}

- (IBAction)captureFrame:(id)sender
{
    
    CVImageBufferRef imageBuffer;
    @synchronized (self) {
        imageBuffer = CVBufferRetain(mCurrentImageBuffer);
    }
    if (imageBuffer) {
        
        // create NSBitmapImageRep to save to file 
        NSBitmapImageRep *bmapImgRep = [[NSBitmapImageRep alloc] initWithCIImage:[CIImage imageWithCVImageBuffer:imageBuffer]];        
        NSData *data;
        data = [bmapImgRep representationUsingType: NSPNGFileType properties: nil];
        [data writeToFile: @"/Users/nick/test.png" atomically: NO];
        
        /* create a reader */
        scanner = zbar_image_scanner_create();
        
        /* configure the reader */
        zbar_image_scanner_set_config(scanner, 0, ZBAR_CFG_ENABLE, 1);
        
        /* obtain image data */
        int width = 0, height = 0;
        void *raw = NULL;
        
        FILE *file = fopen("/Users/nick/test.png", "rb");
        if(!file) exit(2);
        png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
        if(!png) exit(3);
        if(setjmp(png_jmpbuf(png))) exit(4);
        png_infop info = png_create_info_struct(png);
        if(!info) exit(5);
        png_init_io(png, file);
        png_read_info(png, info);
        /* configure for 8bpp grayscale input */
        int color = png_get_color_type(png, info);
        int bits = png_get_bit_depth(png, info);
        if(color & PNG_COLOR_TYPE_PALETTE)
            png_set_palette_to_rgb(png);
        if(color == PNG_COLOR_TYPE_GRAY && bits < 8)
            png_set_expand_gray_1_2_4_to_8(png);
        if(bits == 16)
            png_set_strip_16(png);
        if(color & PNG_COLOR_MASK_ALPHA)
            png_set_strip_alpha(png);
        if(color & PNG_COLOR_MASK_COLOR)
            png_set_rgb_to_gray_fixed(png, 1, -1, -1);
        /* allocate image */
        width = png_get_image_width(png, info);
        height = png_get_image_height(png, info);
        raw = malloc(width * height);
        png_bytep rows[height];
        int i;
        for(i = 0; i < height; i++)
            rows[i] = raw + (width * i);
        png_read_image(png, rows);
        
        /* wrap image data */
        zbar_image_t *zbar_image = zbar_image_create();
        zbar_image_set_format(zbar_image, *(int*)"Y800");
        zbar_image_set_size(zbar_image, width, height);
        zbar_image_set_data(zbar_image, raw, width * height, zbar_image_free_data);
        
        /* scan the image for barcodes */
        int n = zbar_scan_image(scanner, zbar_image);
        
        /* extract results */
        const zbar_symbol_t *symbol = zbar_image_first_symbol(zbar_image);
        for(; symbol; symbol = zbar_symbol_next(symbol)) {
            /* do something useful with results */
            zbar_symbol_type_t typ = zbar_symbol_get_type(symbol);
            const char *data = zbar_symbol_get_data(symbol);
            printf("decoded %s symbol \"%s\"\n", zbar_get_symbol_name(typ), data);
            [qrCodeLbl setStringValue:[NSString stringWithUTF8String:data]];
        }
        
        // send userid and computer serial number to GAE 
        // use OAuth to log them in to the GAE+GWT app and set the venue/computer they are at 
        // http://stackoverflow.com/questions/471898/google-app-engine-with-clientlogin-interface-for-objective-c
        // http://code.google.com/appengine/docs/java/oauth/overview.html
        
        
        /* clean up */
        zbar_image_destroy(zbar_image);
        zbar_image_scanner_destroy(scanner);
        
        NSCIImageRep *imageRep = [NSCIImageRep imageRepWithCIImage:[CIImage imageWithCVImageBuffer:imageBuffer]];
        NSImage *image = [[[NSImage alloc] initWithSize:[imageRep size]] autorelease];
        [image addRepresentation:imageRep];
        CVBufferRelease(imageBuffer);
        
        // convert NSImage to CGImage 
        CGImageSourceRef source;
        source = CGImageSourceCreateWithData((CFDataRef)[image TIFFRepresentation], NULL);
        CGImageRef maskRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
        
        [mImageView setImage: maskRef imageProperties: mImageProperties];
        
    }
    
}



@end
