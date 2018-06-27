//
//  ViewController.m
//  BlueToothPeripheral
//
//  Created by Mac1 on 2018/6/25.
//  Copyright © 2018年 Mac1. All rights reserved.
//

/**
 蓝牙4.0，低功耗蓝牙设备
 外设主要流程：
 1、创建外设管理类
 2、通过管理类判断蓝牙状态
 3、蓝牙状态可用时，创建服务和特征，外设通过服务ID进行广播，告知周围的中心设备它这有数据，他能提供服务和特征值
 4、待中心设备连接上它之后就可以进行数据传递了
 */

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define SERVICE_UUID @"1211"
#define CHARACTERISTIC_UUID @"0551"
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

typedef NS_ENUM(NSInteger, ManagerState) {//蓝牙状态
    ManagerStateUnknown = 0,
    ManagerStateResetting,
    ManagerStateUnsupported,
    ManagerStateUnauthorized,
    ManagerStatePoweredOff,
    ManagerStatePoweredOn,
};

@interface ViewController ()<CBPeripheralManagerDelegate>

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;//外设管理类
@property (nonatomic, strong) CBMutableCharacteristic *characteristic;//特征
@property (nonatomic, strong) UITextField *inputTextField;//输入框
@property (nonatomic, strong) UIButton *postButton;//写入数据按钮

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"蓝牙外设";
    self.inputTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 100, SCREEN_WIDTH - 40, 30)];
    self.inputTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.inputTextField.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.inputTextField];

    self.postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.postButton.frame = CGRectMake(SCREEN_WIDTH * 0.5 - 30, 180, 60, 30);
    [self.postButton setTitle:@"Post" forState:UIControlStateNormal];
    [self.postButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.postButton.backgroundColor = [UIColor redColor];
    self.postButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.postButton addTarget:self action:@selector(writeValue) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.postButton];
    
    //创建外设管理类，会回调peripheralManagerDidUpdateState方法
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
}

/**蓝牙状态
 CBManagerStateUnknown = 0,  未知
 CBManagerStateResetting,    重置中
 CBManagerStateUnsupported,  不支持
 CBManagerStateUnauthorized, 未授权
 CBManagerStatePoweredOff,   未启动
 CBManagerStatePoweredOn,    可用
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (@available(iOS 10.0, *)) {
        if (peripheral.state == CBManagerStatePoweredOn) {
            [self setUpServiceAndCharacteristics];
            //根据服务的UUID开始广播
            [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:SERVICE_UUID]]}];
        }
    }else {
        if (peripheral.state == ManagerStatePoweredOn) {
            [self setUpServiceAndCharacteristics];
            //根据服务的UUID开始广播
            [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:SERVICE_UUID]]}];
        }
    }
}

//创建服务和特征
- (void)setUpServiceAndCharacteristics {
    //创建服务
    CBUUID *serviceID = [CBUUID UUIDWithString:SERVICE_UUID];
    CBMutableService *service = [[CBMutableService alloc] initWithType:serviceID primary:YES];
    //创建服务中的特征
    CBUUID *characteristicID = [CBUUID UUIDWithString:CHARACTERISTIC_UUID];
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:characteristicID properties:CBCharacteristicPropertyRead |
    CBCharacteristicPropertyWrite |
    CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable |
    CBAttributePermissionsWriteable];
    //添加特征到服务
    service.characteristics = @[characteristic];
    //服务加入管理
    [self.peripheralManager addService:service];
    self.characteristic = characteristic;
}

//中心设备读取外设数据时的回调
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    //将输入框中的内容作为请求内容
    request.value = [self.inputTextField.text dataUsingEncoding:NSUTF8StringEncoding];
    //成功响应请求
    [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
}

//中心设备写入数据到外设的回调
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
    //写入数据的请求
    CBATTRequest *request = requests.lastObject;
    //把写入的数据显示在输入框
    self.inputTextField.text = [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding];
}

//订阅成功回调
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"订阅成功：%s",__FUNCTION__);
}

//取消订阅回调
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"取消订阅：%s",__FUNCTION__);
}

//写入数据到中心设备
- (void)writeValue {
    if (self.inputTextField.text.length && self.characteristic) {
        BOOL sendSuccess = [self.peripheralManager updateValue:[self.inputTextField.text dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.characteristic onSubscribedCentrals:nil];
        if (sendSuccess) {
            NSLog(@"发送数据成功");
        }else {
            NSLog(@"发送数据失败");
        }
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
