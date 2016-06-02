//
//  ViewController.m
//  HeyDoMac
//
//  Created by lbc on 16/4/14.
//  Copyright © 2016年 lbc. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
static NSString *const ReadServiceUUID=@"蓝牙读服务uuid";
static NSString *const WriteServiceUUID=@"蓝牙写服务uuid";

static NSString *const ReadcharacteristicsUUID=@"蓝牙读characteristicsUUID";
static NSString *const WritecharacteristicsUUID=@"蓝牙写服务characteristicsUUID";

static NSString *const deviceinformationUUID=@"设备信息uuid";//获取系统蓝牙mac通道
static NSString *const readsyscharacteristicsUUID=@"设备信息characteristicsuuid";
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic) BOOL didSuccessGetMac;//是否成功蓝牙地址
@property (nonatomic) BOOL diddevicebluetoothpoweron;//是否设备打开蓝牙
@property (nonatomic) BOOL diddevicesoupportbluetooth;//是否设备支持蓝牙
@property(nonatomic) BOOL didbluetoothconnected;
//设备列表
@property(nonatomic,strong)NSMutableArray*deviceList;
@property(strong,nonatomic)CBCharacteristic *cRead;
@property(strong,nonatomic)CBCharacteristic *cWrite;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property(strong,nonatomic)CBCentralManager* centralManager;
@property(strong,nonatomic) NSTimer *timer;
@end

@implementation ViewController
@synthesize centralManager;
@synthesize diddevicebluetoothpoweron,diddevicesoupportbluetooth,didbluetoothconnected,didSuccessGetMac;

@synthesize deviceList,timer;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //bluetooth
    centralManager=[[CBCentralManager alloc]initWithDelegate:self queue:nil];
    centralManager.delegate=self;
    deviceList=[[NSMutableArray alloc]initWithCapacity:5];
    [self scanBleDevice];
    [NSTimer scheduledTimerWithTimeInterval:10.f target:self selector:@selector(scanBleDevice) userInfo:nil repeats:YES];
    
    UIActivityIndicatorView*activity=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activity.center=self.view.center;
    activity.tag=0x111;
    [self.view addSubview:activity];
    [activity startAnimating];
    
    UILabel*macLab=[[UILabel alloc]initWithFrame:self.view.frame];
    macLab.userInteractionEnabled=YES;
    macLab.backgroundColor=[UIColor whiteColor];
    macLab.tag=0x110;
    //    macLab.text
    macLab.textAlignment=NSTextAlignmentCenter;
    macLab.numberOfLines=2;
    macLab.textColor=[UIColor blackColor];
    macLab.font=[UIFont systemFontOfSize:25];
    macLab.hidden=YES;
    [macLab addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeMacLab:)]];
    [self.view addSubview: macLab];
    didSuccessGetMac=NO;
    
}

-(void)removeMacLab:(id)sender{
    UIView*activity=[self.view viewWithTag:0x111];
    if(activity)
        activity.hidden=YES;
    UIView*view=[self.view viewWithTag:0x110];
    if(view)
        view.hidden=YES;
    _table.hidden=NO;
    
}
/***
 扫描附近ble设备
 */
-(void)scanBleDevice{
    if (deviceList.count>0) {
        UIView*view=[self.view viewWithTag:0x111];
        if(view)
            view.hidden=YES;
    }
    [_table reloadData];
    NSLog(@" 扫描附近ble设备");
    if (![centralManager isScanning]) {
        NSLog(@" 当前未扫描附近ble设备");
        [centralManager scanForPeripheralsWithServices:nil options:nil];
        
    }else{
        NSLog(@" 当前正在扫描附近ble设备");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark UITableView
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return deviceList.count;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 45;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString*cellId=@"cellId";
    
    UITableViewCell*cell=[tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.textLabel.text=((CBPeripheral*)[deviceList objectAtIndex:indexPath.row]).name;
    //    cell.textLabel.text=[NSString stringWithFormat:@"%ld",indexPath.row];
    return cell;
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    didbluetoothconnected=NO;
    [centralManager connectPeripheral:[deviceList objectAtIndex:indexPath.row] options:nil];
    _table.hidden=YES;
    UIView*activity=[self.view viewWithTag:0x111];
    if(activity)
        activity.hidden=NO;
    //    UIView*view=[self.view viewWithTag:0x110];
    //    if(view)
    //        view.hidden=NO;
    
    didSuccessGetMac=NO;
    if (!timer) {
         timer=[NSTimer scheduledTimerWithTimeInterval:10.f target:self selector:@selector(connectTimeout) userInfo:nil repeats:NO];
    }else{
        if ([timer isValid]) {
            [timer invalidate];
             timer=[NSTimer scheduledTimerWithTimeInterval:10.f target:self selector:@selector(connectTimeout) userInfo:nil repeats:NO];
        }
    }
   
}
-(void)connectTimeout{
   
    if (!didSuccessGetMac) {
        UIView*activity=[self.view viewWithTag:0x111];
        if(activity)
            activity.hidden=YES;
        UILabel*mac=[self.view viewWithTag:0x110];
        mac.hidden=NO;
        mac.text=@"获取地址失败";
    }
}
#pragma mark CBCentralManager
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch([central state])
    {
        case CBCentralManagerStateUnsupported:
            diddevicesoupportbluetooth=NO;//不支持
            diddevicebluetoothpoweron=NO;
            NSLog( @"设备蓝牙不支持");
            break;
        case CBCentralManagerStateUnauthorized:
            diddevicesoupportbluetooth=NO;
            diddevicebluetoothpoweron=NO;
            NSLog(@"设备蓝牙应用未授权");
            break;
        case CBCentralManagerStatePoweredOn:
            diddevicesoupportbluetooth=YES;//正常工作
            NSLog(@"设备蓝牙正常工作");
            diddevicebluetoothpoweron=YES;
            
            break;
        case CBCentralManagerStatePoweredOff:
            diddevicesoupportbluetooth=NO;//蓝牙已关闭
            NSLog(@"设备蓝牙已关闭");
            
            diddevicebluetoothpoweron=NO;
            didbluetoothconnected=NO;
            
            break;
        case CBCentralManagerStateUnknown:
            diddevicesoupportbluetooth=NO;//未知状态
            diddevicebluetoothpoweron=NO;
            NSLog(@"设备蓝牙状态未知");
            break;
        default:break;
    }
    
}
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    didbluetoothconnected=YES;
    //停止扫描
    [centralManager stopScan];
    peripheral.delegate=self;
    
    //    [peripheral discoverServices:nil];
    //寻找指定服务
    [peripheral discoverServices:@[[CBUUID UUIDWithString:deviceinformationUUID],[CBUUID UUIDWithString:ReadServiceUUID],[CBUUID UUIDWithString:WriteServiceUUID]]];
}
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    didbluetoothconnected=NO;
}
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    didbluetoothconnected=NO;
}
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if(diddevicesoupportbluetooth)
    {
        NSLog(@"发现蓝牙设备 per=%@",peripheral.name);
        if (![deviceList containsObject:peripheral]) {
            [deviceList addObject:peripheral];
        }
        
    }
    
}

#pragma mark CBPeripheral
//发现服务
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    //在此方法中查找我们需要的服务 然后调用didcverCharacteristics方法查找我们需要的特性
    if(error)
    {
        NSLog(@"Discovered services for %@ with error:%@",peripheral.name,[error localizedDescription]);
        return;
    }
    
    
    BOOL flag=NO;
    
    //往蓝牙写FFE5下的FFE9  从蓝牙读FFE0下得FFE4
    for(CBService *service in peripheral.services)
    {
        //微信版蓝牙测试
        //        if ([service.UUID isEqual:[CBUUID UUIDWithString:weChatServiceUUID]]) {
        //            [self.testperipheral discoverCharacteristics:nil forService:service];
        //        }
        if([service.UUID isEqual:[CBUUID UUIDWithString:deviceinformationUUID]])
        {
            
            [peripheral discoverCharacteristics:nil forService:service];
        }
        if([service.UUID isEqual:[CBUUID UUIDWithString:WriteServiceUUID]])
        {
            flag=YES;
            [peripheral discoverCharacteristics:nil forService:service];
            
        }
        if([service.UUID isEqual:[CBUUID UUIDWithString:ReadServiceUUID]])
        {
            [peripheral discoverCharacteristics:nil forService:service];
            
        }
    }
    
    
    //如果不是heydo的话，断开连接
    if (!flag) {
        NSLog(@"从不是heydo设备中断开连接 from not heydo devices");
        if(self.centralManager && peripheral)
        {
            [self.centralManager cancelPeripheralConnection:peripheral];
        }
    }
}

//发现特征值
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    //在这个方法中我们要找到我们所需的服务特性 然后调用setNotifyValue方法告知我们要监测这个服务的状态变化
    //当setNotifyValue方法调用后用代理CBPeripheralDelegate的-（void）peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
    if(error)
    {
        NSLog(@"DisCovered characteristics for %@ with error:%@",service.UUID,[error localizedDescription]);
        return;
    }
    
    //获取蓝牙设备信息180a
    if([service.UUID isEqual:[CBUUID UUIDWithString:deviceinformationUUID]])
    {
        
        for(CBCharacteristic *ch in service.characteristics)
        {
            //特征值2a23读取设备Mac
            if([ch.UUID isEqual:[CBUUID UUIDWithString:readsyscharacteristicsUUID]])
            {
                //特征值2a23 类型为CBCharacteristicPropertyRead 不需要notify
                [peripheral readValueForCharacteristic:ch];
                
            }
        }
    }
    
    //往蓝牙写FFE5下的FFE9  从蓝牙读FFE0下得FFE4
    if([service.UUID isEqual:[CBUUID UUIDWithString:WriteServiceUUID]])
    {
        for(CBCharacteristic *ch in service.characteristics)
        {
            if([ch.UUID isEqual:[CBUUID UUIDWithString:WritecharacteristicsUUID]])
            {
                self.cWrite=ch;
                
            }
            
        }
    }
    if([service.UUID isEqual:[CBUUID UUIDWithString:ReadServiceUUID]])
    {
        for(CBCharacteristic *ch in service.characteristics)
        {
            if([ch.UUID isEqual:[CBUUID UUIDWithString:ReadcharacteristicsUUID]])
            {
                
                self.cRead=ch;
                //特征值FFE4 类型为CBCharacteristicPropertyNotify 需要notify
                [peripheral setNotifyValue:YES forCharacteristic:self.cRead];
            }
        }
    }
    
    
}

//特征值notify回调
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    if(error==nil)
    {
        //调用下面的方法后 会调用代理的
        //(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
        //        [peripheral readValueForCharacteristic:characteristic];
        
        if (characteristic.isNotifying) {
            [peripheral readValueForCharacteristic:characteristic];
            
        } else { // Notification has stopped
            // so disconnect from the peripheral
            NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
            if(self.centralManager && peripheral)
            {
                [self.centralManager cancelPeripheralConnection:peripheral];
            }
        }
        
        
    }
    else
    {
        NSLog(@"didUpdateNotificationStateForCharacteristic-Error:%@",[error description]);
        NSLog(@"ch:%@",characteristic);
    }
}

//收到水杯发送数据
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        NSLog(@"Read Error:%@",[error description]);
        return;
    }
    //设备信息
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:readsyscharacteristicsUUID]])
    {
        
        NSData *data=characteristic.value;
        if(data&&data.length==8)
        {
            //获取水杯Mac地址
            NSString*lastmac=[self getMacFromBytes:data];
            NSLog(@"获取水杯Mac地址=%@",lastmac);
            
            UILabel*mac=[self.view viewWithTag:0x110];
            mac.hidden=NO;
            mac.text=[NSString stringWithFormat:@"获取水杯Mac地址\n%@",lastmac];
            didSuccessGetMac=YES;
            [centralManager cancelPeripheralConnection:peripheral];
            //            [allconnectedinform setObject:lastmac forKey:[[NSString alloc]initWithFormat:@"%@_mac",[peripheral.identifier UUIDString]]];
            
            
        }
        
        
    }
    else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:ReadcharacteristicsUUID]]){//收到消息
        
        
    }
}
/*
 将二进制Mac地址转换为字符串
 */
-(NSString*)getMacFromBytes:(NSData*)data{
    
    NSMutableData *macdata=[[NSMutableData alloc]init];
    Byte *databyte=(Byte *)[data bytes];
    unsigned char fflag=(unsigned char)databyte[7];
    [macdata appendBytes:&fflag length:1];
    fflag=(unsigned char)databyte[6];
    [macdata appendBytes:&fflag length:1];
    fflag=(unsigned char)databyte[5];
    [macdata appendBytes:&fflag length:1];
    fflag=(unsigned char)databyte[2];
    [macdata appendBytes:&fflag length:1];
    fflag=(unsigned char)databyte[1];
    [macdata appendBytes:&fflag length:1];
    fflag=(unsigned char)databyte[0];
    [macdata appendBytes:&fflag length:1];
    
    Byte*byts=(Byte*)[macdata bytes];
    
    NSString*lastmac=[NSString stringWithFormat:@"%@%@%@%@%@%@",
                      [self  ssBluetoothMacGetChara:(unsigned char)byts[0]],
                      [self  ssBluetoothMacGetChara:(unsigned char)byts[1]],
                      [self  ssBluetoothMacGetChara:(unsigned char)byts[2]],
                      [self  ssBluetoothMacGetChara:(unsigned char)byts[3]],
                      [self  ssBluetoothMacGetChara:(unsigned char)byts[4]],
                      [self  ssBluetoothMacGetChara:(unsigned char)byts[5]] ];//
    
    //转换成大写
    lastmac=[lastmac uppercaseString];
    
    return lastmac;
}
/*
 获取mac地址的十六进制字符
 */
-(NSString *)ssBluetoothMacGetChara:(unsigned char)_id
{
    unsigned char left=_id/16;
    unsigned char right=_id%16;
    
    NSString *rtv;
    NSString *leftstr;
    NSString *rightstr;
    
    if(left==0xf)
    {
        leftstr=@"f";
    }
    else if(left==0xe)
    {
        leftstr=@"e";
    }
    else if(left==0xd)
    {
        leftstr=@"d";
    }
    else if(left==0xc)
    {
        leftstr=@"c";
    }
    else if(left==0xb)
    {
        leftstr=@"b";
    }
    else if(left==0xa)
    {
        leftstr=@"a";
    }
    else
    {
        leftstr=[[NSString alloc]initWithFormat:@"%d",left ];
    }
    
    
    if(right==0xf)
    {
        rightstr=@"f";
    }
    else if(right==0xe)
    {
        rightstr=@"e";
    }
    else if(right==0xd)
    {
        rightstr=@"d";
    }
    else if(right==0xc)
    {
        rightstr=@"c";
    }
    else if(right==0xb)
    {
        rightstr=@"b";
    }
    else if(right==0xa)
    {
        rightstr=@"a";
    }
    else
    {
        rightstr=[[NSString alloc]initWithFormat:@"%d",right ];
    }
    
    rtv=[[NSString alloc]initWithFormat:@"%@%@",leftstr,rightstr];
    
    return rtv;
}

@end
