//
//  ZHBLEPeripheral.m
//  BLE_IOS
//
//  Created by aimoke on 15/7/16.
//  Copyright (c) 2015年 zhuo. All rights reserved.
//

#import "ZHBLEPeripheral.h"
@interface ZHBLEPeripheral()<CBPeripheralDelegate>
@property (nonatomic, copy)   ZHObjectChagedBlock didFinishServiceDiscovery;
@property (nonatomic, copy)   ZHObjectChagedBlock rssiUpdated;
@property (nonatomic, strong) NSMutableDictionary * servicesFindingIncludeService;
@property (nonatomic, strong) NSMutableDictionary * characteristicsDiscoveredBlocks;
@property (nonatomic, strong) NSMutableDictionary * descriptorDiscoveredBlocks;
@property (nonatomic, strong) NSMutableDictionary * characteristicsValueUpdatedBlocks;
@property (nonatomic, strong) NSMutableDictionary * descriptorValueUpdatedBlocks;
@property (nonatomic, strong) NSMutableDictionary * characteristicValueWrtieBlocks;
@property (nonatomic, strong) NSMutableDictionary * descriptorValueWrtieBlocks;
@property (nonatomic, strong) NSMutableDictionary * characteristicsNotifyBlocks;
@end

@implementation ZHBLEPeripheral

#pragma mark - Life cycle
-(void)dealloc
{
    _peripheral.delegate = nil;
}
#pragma mark － initialize methods
-(instancetype)initWithPeripheral:(CBPeripheral *)peripheral
{
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _peripheral.delegate = self;
        //#callbacks for finding included services of specified service
        
        self.servicesFindingIncludeService = [NSMutableDictionary dictionary];
        //
        self.characteristicsDiscoveredBlocks = [NSMutableDictionary dictionary];
        self.descriptorDiscoveredBlocks = [NSMutableDictionary dictionary];
        //# read value callbacks
        self.characteristicsValueUpdatedBlocks =[NSMutableDictionary dictionary];
        self.descriptorValueUpdatedBlocks  =[NSMutableDictionary dictionary];
        //# write value callbacks
        self.characteristicValueWrtieBlocks =[NSMutableDictionary dictionary];
        self.descriptorValueWrtieBlocks =[NSMutableDictionary dictionary];
        
        //#for characteristics notification
        self.characteristicsNotifyBlocks = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark propertys

-(NSString *)name
{
    if (!_name) {
        self.name = _peripheral.name;
    }
    return _name;
}

-(NSUUID *)identifier
{
    if (!_identifier) {
        @try {
            self.identifier = _peripheral.identifier;
        }
        @catch (NSException *exception) {
            //ios 6
            NSString *uuidStr = _peripheral.identifier.UUIDString;
            self.identifier = [[NSUUID alloc]initWithUUIDString:uuidStr];
            NSLog(@"ios6 identifier");
        }
        @finally {
            
        }
    }
    return _identifier;
}

-(NSNumber *)RSSI
{
    if (!_RSSI) {
        self.RSSI = self.peripheral.RSSI;
    }
    return _RSSI;
}

-(CBPeripheralState)state
{
    return self.peripheral.state;
}

-(NSArray *)services
{
    return _peripheral.services;
}

#pragma mark discovery services
-(void)discoverServices:(NSArray *)serviceUUIDs onFinish:(ZHObjectChagedBlock)discoverFinished
{
    NSAssert(discoverFinished !=nil, @"block finished must not be nil");
    self.didFinishServiceDiscovery = discoverFinished;
    [_peripheral discoverServices:serviceUUIDs];
}

-(void)discoverIncludedServices:(NSArray *)includedServiceUUIDs forService:(CBService *)service onFinish:(ZHSpecifiedServiceUpdatedBlock)finished
{
     NSAssert(finished!=nil, @"block finished must'not be nil!");
    _servicesFindingIncludeService[service.UUID] = finished;
    [_peripheral discoverIncludedServices:includedServiceUUIDs forService:service];
    
}

#pragma mark Discovering Characteristics and Characteristic Descriptors
-(void)discoverCharacteristics:(NSArray *)characteristicUUIDs forService:(CBService *)service onFinish:(ZHSpecifiedServiceUpdatedBlock)onfinish
{
    NSAssert(onfinish!=nil, @"block onfinish must'not be nil!");
    _characteristicsDiscoveredBlocks[service.UUID] = onfinish;
    [_peripheral discoverCharacteristics:characteristicUUIDs forService:service];
    
}

-(void)discoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic onFinish:(ZHCharacteristicChangeBlock)onfinish
{
    NSAssert(onfinish!=nil, @"block onfinish must'not be nil!");
    _descriptorDiscoveredBlocks[characteristic.UUID] = onfinish;
    [_peripheral discoverDescriptorsForCharacteristic:characteristic];
    
}


#pragma mark Reading Characteristic and Characteristic Descriptor Values
-(void)readValueForCharacteristic:(CBCharacteristic *)characteristic onFinish:(ZHCharacteristicChangeBlock)onUpdate
{
    NSAssert(onUpdate!=nil, @"block onUpdate must'not be nil!");
    _characteristicsValueUpdatedBlocks[characteristic.UUID] = onUpdate;
    [_peripheral readValueForCharacteristic:characteristic];
    
}

-(void)readValueForDescriptor:(CBDescriptor *)descriptor onFinish:(ZHDescriptorChangedBlock)onUpdate
{
    NSAssert(onUpdate!=nil, @"block onUpdate must'not be nil!");
    _descriptorValueUpdatedBlocks[descriptor.UUID] = onUpdate;
    [_peripheral readValueForDescriptor:descriptor];
}

#pragma mark Writing Characteristic and Characteristic Descriptor Values
-(void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type onFinish:(ZHCharacteristicChangeBlock)onfinish
{
    if (type == CBCharacteristicWriteWithResponse) {
        NSAssert(onfinish!=nil, @"block onfinish must'not be nil!");
        _characteristicValueWrtieBlocks[characteristic.UUID] = onfinish;
        
    }
    [_peripheral writeValue:data forCharacteristic:characteristic type:type];
}

-(void)writeValue:(NSData *)data forDescriptor:(CBDescriptor *)descriptor onFinish:(ZHDescriptorChangedBlock)onfinish
{
    if (onfinish) {
        _descriptorValueWrtieBlocks[descriptor.UUID] = onfinish;
        
    }
    [_peripheral writeValue:data forDescriptor:descriptor];
}


#pragma mark Setting Notifications for a Characteristic’s Value
-(void)setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic onUpdated:(ZHCharacteristicChangeBlock)onUpdated
{
    if (enabled) {
        NSAssert(onUpdated!=nil, @"block onUpdated must'not be nil!");
        self.characteristicsNotifyBlocks[characteristic.UUID] =  onUpdated;

    }else{
        [self.characteristicsNotifyBlocks removeObjectForKey:characteristic.UUID];
    }
    [_peripheral setNotifyValue:enabled forCharacteristic:characteristic];
}


#pragma mark ReadRSSI
-(void)readRSSIOnFinish:(ZHObjectChagedBlock)onUpdated
{
    self.rssiUpdated = onUpdated;
    [_peripheral readRSSI];
}

#pragma mark - Delegate
#pragma mark service discovery
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        [self cleanup];
    }
    if (peripheral == _peripheral) {
        self.didFinishServiceDiscovery(error);
        self.didFinishServiceDiscovery = nil;
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        [self cleanup];
    }
    if (peripheral == _peripheral) {
        ZHSpecifiedServiceUpdatedBlock onfound = _servicesFindingIncludeService[service.UUID];
        if (onfound) {
            onfound(service,error);
            [_servicesFindingIncludeService removeObjectForKey:service.UUID];
        }
    }
}

#pragma mark Characteristic
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (peripheral ==_peripheral) {
        ZHSpecifiedServiceUpdatedBlock onfound = _characteristicsDiscoveredBlocks[service.UUID];
        if (onfound) {
            onfound(service,error);
            [_characteristicsDiscoveredBlocks removeObjectForKey:service.UUID];
            
        }
    }
}


-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (peripheral == _peripheral) {
        ZHCharacteristicChangeBlock onfound = _descriptorDiscoveredBlocks[characteristic.UUID];
        if (onfound) {
            onfound(characteristic,error);
            [_descriptorDiscoveredBlocks removeObjectForKey:characteristic.UUID];
        }
    }
    
}

#pragma mark Retrieving Characteristic and Characteristic Descriptor Values
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (peripheral == _peripheral) {
        ZHCharacteristicChangeBlock onupdate = _characteristicsValueUpdatedBlocks[characteristic.UUID];
        if (onupdate) {
            onupdate(characteristic,error);
            [_characteristicsValueUpdatedBlocks removeObjectForKey:characteristic.UUID];
        }else{
            
            //notification
            onupdate = self.characteristicsNotifyBlocks[characteristic.UUID];
            if (onupdate) {
                onupdate(characteristic,error);
            }
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    if (peripheral == _peripheral) {
        ZHDescriptorChangedBlock onupdate = _descriptorValueUpdatedBlocks[descriptor.UUID];
        if (onupdate) {
            onupdate(descriptor,error);
            [_descriptorValueUpdatedBlocks removeObjectForKey:descriptor.UUID];
        }
    }
}

#pragma mark Writing Characteristic and Characteristic Descriptor Values
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (peripheral == _peripheral) {
        ZHCharacteristicChangeBlock onwrite = _characteristicValueWrtieBlocks[characteristic.UUID];
        if (onwrite) {
            onwrite(characteristic,error);
            [_characteristicValueWrtieBlocks removeObjectForKey:characteristic.UUID];
        }
    }
}

#pragma mark Managing Notifications for a Characteristic’s Value
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (peripheral ==_peripheral && self.notificationStateChanged) {
        self.notificationStateChanged(characteristic,error);
    }
}

-(void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (peripheral == _peripheral) {
        self.RSSI = self.peripheral.RSSI;
        self.rssiUpdated(error);
        self.rssiUpdated = nil;
    }
}


#pragma mark Monitoring Changes to a Peripheral’s Name or Services

-(void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices
{
    if (peripheral ==_peripheral && self.onServiceModified) {
        self.onServiceModified(invalidatedServices);
    }
}

-(void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    if (peripheral == _peripheral && self.onNameUpdated) {
        self.onNameUpdated(nil);
    }
}

#pragma mark clearup
-(void)cleanup
{
    if (self.peripheral.state == CBPeripheralStateConnected) {
        return;
    }
    if (self.peripheral.services != nil) {
        for (CBService *service in self.peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if (characteristic.isNotifying) {
                        [self.peripheral setNotifyValue:NO forCharacteristic:characteristic];
                    }
                }
            }
        }
        
    }
}



@end
