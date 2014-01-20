//
//  IDNViewController.m
//  IDNScanSpeak
//
//  Created by Ricardo on 1/18/14.
//  Copyright (c) 2014 Idean. All rights reserved.
//

#import "IDNViewController.h"
@import AVFoundation;

@interface IDNViewController () <AVCaptureMetadataOutputObjectsDelegate, AVSpeechSynthesizerDelegate>

// Scan
@property (strong, nonatomic, readwrite) AVCaptureSession* session;
@property (strong, nonatomic, readwrite) AVCaptureDevice* device;
@property (strong, nonatomic, readwrite) AVCaptureDeviceInput* input;
@property (strong, nonatomic, readwrite) AVCaptureMetadataOutput* output;
@property (strong, nonatomic, readwrite) AVCaptureVideoPreviewLayer* preview;

// Speak
@property (strong, nonatomic, readwrite) AVSpeechSynthesizer* synthesizer;
@property (strong, nonatomic, readwrite) AVSpeechUtterance* utterance;

@end

@implementation IDNViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self scanSetup];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.session startRunning];
}

#pragma mark - Scan
- (void)scanSetup
{
    // Device
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Input
    NSError* inputError;
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&inputError];
    if(inputError)
        NSLog(@"Input Error: %@", inputError);
    
    // Output
    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // Session
    self.session = [[AVCaptureSession alloc] init];
    [self.session addInput:self.input];
    [self.session addOutput:self.output];
    [self.output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    
    // Preview
    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height);
    [self.view.layer addSublayer:self.preview];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString* QRCode = nil;
    for(AVMetadataObject* metadata in metadataObjects)
    {
        if([metadata.type isEqualToString:AVMetadataObjectTypeQRCode])
        {
            QRCode = [(AVMetadataMachineReadableCodeObject*)metadata stringValue];
            break;
        }
    }
    
    if(QRCode)
    {
        NSLog(@"QR Code: %@", QRCode);
        [self.session stopRunning];
        
        [self speak:QRCode];
    }
}

#pragma mark - Speak
- (void)speak:(NSString*)string
{
    if(!self.synthesizer)
    {
        self.synthesizer = [[AVSpeechSynthesizer alloc] init];
        self.synthesizer.delegate = self;
    }
    
    self.utterance = [AVSpeechUtterance speechUtteranceWithString:string];
    self.utterance.rate = 0.25;
    
    [self.synthesizer speakUtterance:self.utterance];
}

#pragma mark - AVSpeechSynthesizerDelegate
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    [self.session startRunning];
}

@end
