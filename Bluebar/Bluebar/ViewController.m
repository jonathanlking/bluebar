//
//  ViewController.m
//  Bluebar
//
//  Created by Jonathan King on 03/09/2013.
//  Copyright (c) 2013 Jonathan King. All rights reserved.
//

#import "ViewController.h"
#import "BLE.h"
#import "NSObject+PWObject.h"

#define LEFT_VIBRATOR_PIN 4
#define RIGHT_VIBRATOR_PIN 5

#define HIGH 1
#define LOW 0

typedef enum {
    LeftVibrator,
    RightVibrator
} vibrator;

@interface ViewController () <BLEDelegate>
@property (strong, nonatomic) BLE *manager;
- (void)scanForPeripherals;
- (void)setDigitalOutput:(BOOL)output forPin:(int)pin;
- (UInt8)addressForPin:(int)pin;
- (int)pinForVibrator:(vibrator)vibrator;
- (BOOL)pinSupportsAnalogOutput:(int)pin;
- (void)disconnectCurrentDevice;
- (void)controlSwitchValueChanged:(id)sender;
// Test methods
- (void)blink:(NSNumber *)value;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Setup the BLE Manager
    self.manager = [[BLE alloc] init];
    [self.manager controlSetup:1];
    self.manager.delegate = self;
    
    [_controlSwitch addTarget:self action:@selector(controlSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Class Methods

- (void)scanForPeripherals {
    
    if (self.manager.CM.state != CBCentralManagerStatePoweredOn) {
        
        NSLog(@"Bluetooth not yet powered on - so scanning is pointless");
        return;
    }
    
    self.manager.peripherals = nil;
    
    // Stop the user changing the switch
    _controlSwitch.enabled = NO;
    
    // Search for peripherals with a timeout of 2 seconds
    int timeout = 2;
    [self.manager findBLEPeripherals:timeout];
    
    // This will fetch the results after the timeout
    [self performBlock:^{
        
        if (self.manager.peripherals.count > 0) [self.manager connectPeripheral:self.manager.peripherals[0]];
        else {
            
            [_controlSwitch setOn:NO animated:YES];
            _signalStrength.text = @"Device not found       ";
        }
        _controlSwitch.enabled = YES;
        
    } afterDelay:timeout];

}

- (void)disconnectCurrentDevice {
    
    if (self.manager.activePeripheral && self.manager.activePeripheral.isConnected) {
        
        // Already connected - so disconnect
        [[self.manager CM] cancelPeripheralConnection:[self.manager activePeripheral]];
    }
}

- (int)pinForVibrator:(vibrator)vibrator {
    
    switch (vibrator) {
        case LeftVibrator:
            return LEFT_VIBRATOR_PIN;
            break;
        case RightVibrator:
            return RIGHT_VIBRATOR_PIN;
            break;
        default:
            break;
    }
}

- (UInt8)addressForPin:(int)pin {
    
    switch (pin) {
        case LEFT_VIBRATOR_PIN:
            return 0x01;
            break;
        case RIGHT_VIBRATOR_PIN:
            return 0x02;
            break;
        default:
            return 0x00;
            break;
    }
}

- (BOOL)pinSupportsAnalogOutput:(int)pin {
    
    switch (pin) {
        default:
            return NO;
            break;
    }
}

- (void)setDigitalOutput:(BOOL)output forPin:(int)pin {
    
    UInt8 buffer[3] = {0x00, 0x00, 0x00};
    buffer[0] = [self addressForPin:pin];
    buffer[1] = output ? 0x01 : 0x00;
    
    NSData *data = [[NSData alloc] initWithBytes:buffer length:3];
    [self.manager write:data];
}

- (void)setAnalogOutput:(UInt8)output forPin:(int)pin {
    
    if (![self pinSupportsAnalogOutput:pin]) {
        
        NSLog(@"This pin does not support analog output!");
        [self setDigitalOutput:(BOOL)output forPin:pin];
        return;
    }
    
    UInt8 buffer[3] = {0x00, 0x00, 0x00};
    buffer[0] = [self addressForPin:pin];
    buffer[1] = output;
    buffer[2] = (int)output >> 8;
    
    NSData *data = [[NSData alloc] initWithBytes:buffer length:3];
    [self.manager write:data];
}

- (void)controlSwitchValueChanged:(id)sender {
    
    if (_controlSwitch.on) {

        // The switch has been turned on, therefore start scanning.
        [self scanForPeripherals];
        _signalStrength.text = @"Connecting";
    }
    
    else {
        
        [self disconnectCurrentDevice];
    }
}

#pragma mark - Tests

- (void)blink:(NSNumber *)value {
    
    [self setDigitalOutput:value.integerValue forPin:LEFT_VIBRATOR_PIN];
    BOOL inverse = !(BOOL)value.integerValue;
    [self performSelector:@selector(blink:) withObject:[NSNumber numberWithBool:inverse] afterDelay:1];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (self.manager.activePeripheral && self.manager.activePeripheral.isConnected) {
        
        for (UITouch *touch in [touches allObjects]) {
            
            float x = [touch locationInView:self.view].x;
            float screenWidth = self.view.bounds.size.width;
            
            float middleMax = screenWidth/2 + screenWidth/8;
            float middleMin = screenWidth/2 - screenWidth/8;
            
            if (x < middleMax && x > middleMin) {
                
                [self setDigitalOutput:LOW forPin:LEFT_VIBRATOR_PIN];
                [self setDigitalOutput:LOW forPin:RIGHT_VIBRATOR_PIN];
            }
            
            else if (x<middleMin) {
                
                // It is a left press
                [self setDigitalOutput:LOW forPin:LEFT_VIBRATOR_PIN];
            }
            
            else if (x>middleMax) {
                
                // It is a right press
                [self setDigitalOutput:LOW forPin:RIGHT_VIBRATOR_PIN];
            }
            
        }
        
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (self.manager.activePeripheral && self.manager.activePeripheral.isConnected) {
        
        // Already connected - so disconnect
        [self setDigitalOutput:HIGH forPin:LEFT_VIBRATOR_PIN];
        [self setDigitalOutput:HIGH forPin:RIGHT_VIBRATOR_PIN];
    }
}

#pragma mark - BLE delegate

- (void)bleDidDisconnect
{
    NSLog(@"->Disconnected");
    [_controlSwitch setOn:NO animated:YES];
    _signalStrength.text = @"Disconnected";
}

// When RSSI is changed, this will be called
- (void)bleDidUpdateRSSI:(NSNumber *)rssi
{
    _signalStrength.text = [NSString stringWithFormat:@"Signal strength: %@", rssi.stringValue];
}

// When disconnected, this will be called
- (void)bleDidConnect
{
    NSLog(@"->Connected");
    [_controlSwitch setOn:YES animated:YES];
    _signalStrength.text = @"Connected";
//    [self setDigitalOutput:HIGH forPin:DIGITAL_OUTPUT_PIN];
//    [self blink:[NSNumber numberWithBool:HIGH]];
}

// When data is comming, this will be called
- (void)bleDidReceiveData:(unsigned char *)data length:(int)length
{

}


@end
