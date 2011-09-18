//
//  MyDocument.h
//  MATE2
//
//  Created by Nicholas Meinhold on 16/09/11.
//  Copyright 2011 Cooperative Communities. All rights reserved.
//

#import <QTKit/QTKit.h>
#import <Quartz/Quartz.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include "zbar.h"
#include "png.h"

@interface MyDocument : NSDocument {
    
    IBOutlet IKImageView                *mImageView;
    NSDictionary                        *mImageProperties;
    
    IBOutlet QTCaptureView              *mCaptureView;
    QTCaptureSession                    *mCaptureSession;
    QTCaptureDeviceInput                *mCaptureDeviceInput;
    QTCaptureDecompressedVideoOutput    *mCaptureDecompressedVideoOutput;
    CVImageBufferRef                    mCurrentImageBuffer;
    zbar_image_scanner_t                *scanner;
    
    IBOutlet NSTextField                *qrCodeLbl;
    IBOutlet NSTextField                *serialNumLbl;
    
}

- (IBAction)captureFrame:(id)sender;

@end
