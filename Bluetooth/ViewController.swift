//
//  ViewController.swift
//  Bluetooth
//
//  Created by JinGu on 2016. 5. 17..
//  Copyright © 2016년 JinGu. All rights reserved.
//

import UIKit
import CoreBluetooth


/*
 
 CoreBluetooth 프레임워크에 포함된 클래스는 모두 CB가 붙는다.
 
 Central -> 블루투스 기기와 통신하는 대상 (예: 컴퓨터, 스마트폰)
 Peripheral -> 블루투스 기기에 해당
 
 CBCentralManager -> 아이폰을 Central(블루투스 기기와 통신하는 대상)으로 만들기 위한 클래스
 CBPeripheral -> 주변 검색되는 블루투스 기기 각각을 나타내는 클래스
 
 
 Peripheral의 데이터 구조
 
 Peripheral
 ㄴ----service
    ㄴ----chracteristic
    ㄴ----chracteristic
 ㄴ----service
    ㄴ----chracteristic
    ㄴ----chracteristic
 
 Peripheral은 수개의 서비스를 가지고 있고 각 서비스는 수개의 캐릭터리스틱을 가지고 있다.
 캐릭터리스틱은 read, write, noti 세가지 속성을 가질 수 있고 중첩될 수도 있다.
 예) 캐릭터리스틱1 - (read, write)
    캐릭터리스틱2 - (read, noti)
 
read: Central에서 원할때 값을 읽을 수 있지만 값이 언제 바뀌는지 알 수가 없다.
write: Central에서 원할때 블루투스 기기에 값을 쓸 수 있다. 블루투스 기기의 설정을 바꿀 때 사용한다.
noti: 블루투스기기의 특정 값이 바뀔때, 혹은 Central측으로 값을 보낼때 사용한다 Central에서 즉각적으로 반응 할 수 있다.
 
 주로 write와 noti를 사용하게 된다. write로 원하는 값을 요청하고 noti로 해당하는 값을 리턴하게 작용
 
 
 현재 프로젝트의 전체적인 구조
 CBCentralManager를 초기화 -> 블루투스 상태 업데이트가 호출된다.(첫 호출을 제외하고 다음부터는 아이폰의 블루투스 설정을 바꿀때마다 호출된다. 블루투스를 끄거나 켰을때)
 블루투스 상태 업데이트를 통해 블루투스가 켜져있다면 -> CBCentralManager에서 주변기기 검색 -> 주변기기가 검색될때마다 "didDiscoverPeripheral 호출"
 검색된 블루투스 기기(CBPeripheral) 중 원하는 것을 선택 후 연결 -> 연결이 성공했다면 didConnectPeripheral 호출
 연결된 CBPeripheral을 내부 변수에 저장하고 어떤 서비스가 있는지 알아본다 -> didDiscoverServices 호출
 발견된 서비스 중 원하는 서비스를 선택하고 어떤 캐릭터리스틱이 있는지 알아본다 -> didDiscoverCharacteristicsForService 호출
 발견된 캐릭터리스틱 중 원하는 캐릭터리스틱에 값을 쓰거나, 캐릭터리스틱에 값이 변경되었을때를 대비하여 노티를 설정할 수 있다.
 값을 쓸때는 리스펀스를 받을수도 있고 안 받을 수도 있다.
 노티를 걸어두면 값이 변경될때마다 didUpdateValueForCharacteristic가 호출된다.
 
 
 */


class ViewController: UIViewController
, CBCentralManagerDelegate, CBPeripheralDelegate
{

    var myPeriphral : CBPeripheral?
    var myCharacteristic : CBCharacteristic?
    var centralManager : CBCentralManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //블루투스 시작
        self.centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
        
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.center = self.view.center
        button.backgroundColor = UIColor.blueColor()
        button.addTarget(self, action: #selector(ViewController.buttonPressed), forControlEvents: .TouchUpInside)
        self.view.addSubview(button)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func buttonPressed() {
        let writeValue = NSString(string: "A").dataUsingEncoding(NSUTF8StringEncoding)
        if self.myCharacteristic != nil {
            self.myPeriphral?.writeValue(writeValue!, forCharacteristic: self.myCharacteristic!, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }

    
    
    
    //CBCentralManagerDelegate
    
    //블루투스 상태가 변경되었을 때
    func centralManagerDidUpdateState(central: CBCentralManager){
        
        if central.state == CBCentralManagerState.PoweredOn {
            print("블루투스가 켜져있음")
            
            //주변기기 검색 시작
            self.centralManager?.scanForPeripheralsWithServices(nil, options: nil)
        }else{
            print("블루투스를 사용할 수 없음")
        }
    }
    
    
    //주변기기가 검색되었을 때
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber){
        print("didDiscoverPeripheral:\(peripheral)")
        
        if peripheral.name == "HMSoft" {
            
            //주변기기와 연결
            self.centralManager?.connectPeripheral(peripheral, options: nil)
            self.myPeriphral = peripheral
            self.myPeriphral?.delegate = self
            
        }
    }

    //주변기기와 연결에 성공하였을때
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral){
        print("didConnectPeripheral")
        
        //주변기기 검색을 멈춘다
        self.centralManager?.stopScan()
        
        //주변기기의 서비스 검색
        self.myPeriphral?.discoverServices(nil)
    }
    
    //주변기기와 연결에 실패하였을 때
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?){
        print("didFailToConnectPeripheral")
    }
    
    //주변기기와 연결이 끊겼을 때
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?){
        print("didDisconnectPeripheral")
    }




    //CBPeripheralDelegate
    
    //주변기기의 서비스가 발견되었을 때
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?){
        print("didDiscoverServices:\(peripheral.services)")
        
        for service in peripheral.services! {
            print("service : \(service)")
            //서비스 중 원하는 서비스를 고른 후
            if service.UUID == CBUUID(string: "FFE0") {
                self.myPeriphral?.discoverCharacteristics(nil, forService: service)
            }
        }
    }

    
    //주변기기의 캐릭터리스틱이 발견되었을 때
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?){
        print("didDiscoverCharacteristicsForService")
        
        for characteristic in service.characteristics! {
            print("characteristic : \(characteristic)")
            //캐릭터리스틱 중 원하는 서비스를 고른 후
            if characteristic.UUID == CBUUID(string: "FFE1"){
                self.myCharacteristic = characteristic
                self.myPeriphral?.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
    }
    
    
    //주변기기의 캐릭터리스틱의 값이 변경되었을 때
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?){
        print("didUpdateValueForCharacteristic::\(characteristic.value!)")
        
        let valueString = NSString(data: characteristic.value!, encoding: NSUTF8StringEncoding)
        print("valueString:\(valueString!)")
        
    }
    
}