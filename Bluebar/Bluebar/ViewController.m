//
//  ViewController.m
//  Bluebar
//
//  Created by Jonathan King on 03/09/2013.
//  Copyright (c) 2013 Jonathan King. All rights reserved.
//

#import "ViewController.h"
#import "BLE.h"

@interface ViewController () <BLEDelegate>
@property (strong, nonatomic) BLE *manager;
- (void)scanForPeripherals;
- (void)setDigitalOutput:(BOOL)output forPin:(int)pin;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Class Methods

- (void)scanForPeripherals {
    
    if (self.manager.activePeripheral && self.manager.activePeripheral.isConnected) {
        
        // Already connected - so disconnect
        [[self.manager CM] cancelPeripheralConnection:[self.manager activePeripheral]];
    }
    
    self.manager.peripherals = nil;
    
    // Search for peripherals with a timeout of 2 seconds
    int timeout = 2;
    [self.manager findBLEPeripherals:timeout];
}

- (void)setDigitalOutput:(BOOL)output forPin:(int)pin {
    
    // Add support for sperate pins
    
    UInt8 buffer[3] = {0x01, 0x00, 0x00};
    buffer[1] = output ? 0x01 : 0x00;
    
    NSData *data = [[NSData alloc] initWithBytes:buffer length:3];
    [self.manager write:data];
}

#pragma mark - BLE delegate

- (void)bleDidDisconnect
{
    NSLog(@"->Disconnected");
}

// When RSSI is changed, this will be called
- (void)bleDidUpdateRSSI:(NSNumber *)rssi
{
    NSLog(@"Signal strength: %@", rssi.stringValue);
}

// When disconnected, this will be called
- (void)bleDidConnect
{
    NSLog(@"->Connected");
}

// When data is comming, this will be called
- (void)bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSLog(@"Length: %d", length);
    
    // parse data, all commands are in 3-byte
    for (int i = 0; i < length; i+=3)
    {
        NSLog(@"0x%02X, 0x%02X, 0x%02X", data[i], data[i+1], data[i+2]);
        
        if (data[i] == 0x0A)
        {
//            if (data[i+1] == 0x01)
//                swDigitalIn.on = true;
//            else
//                swDigitalIn.on = false;
        }
        else if (data[i] == 0x0B)
        {
            UInt16 Value;
            
            Value = data[i+2] | data[i+1] << 8;
//            lblAnalogIn.text = [NSString stringWithFormat:@"%d", Value];
        }
    }
}


@end
