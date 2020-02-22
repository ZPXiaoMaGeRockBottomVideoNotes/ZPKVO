//
//  ViewController.m
//  KVO
//
//  Created by 赵鹏 on 2019/5/5.
//  Copyright © 2019 赵鹏. All rights reserved.
//

/**
 KVO的概念：KVO的全称是Key-Value Observing，俗称“键值监听”，可以用于监听某个对象属性值的改变。

 KVO的实现原理：
 1、在给这个person实例对象添加KVO监听之后，系统会利用Runtime机制动态地创建一个ZPPerson类的子类，名字就叫做"NSKVONotifying_ZPPerson"。然后系统会把这个person实例对象里面的isa指针由原来的指向ZPPerson类的class对象变为现在的指向NSKVONotifying_ZPPerson类的class对象；
 2、新创建的子类"NSKVONotifying_ZPPerson"的class对象里面存储着isa指针、superclass指针、"setAge:"实例方法、"class"实例方法、"dealloc"实例方法以及"_isKVOA"实例方法等。其中系统会重写"setAge:"实例方法，重写后的该方法与它父类中的该方法实现是不一样的，只不过方法的名称是一样的而已；
 3、添加完KVO监听之后，当开发者调用"setAge:"实例方法来修改person对象的age属性的时候，根据上面所述，这个instance对象里面的isa指针已经由原来的指向ZPPerson类的class对象变为了现在的指向NSKVONotifying_ZPPerson类的class对象了，所以系统根据这个instance对象里面的isa指针找到的是NSKVONotifying_ZPPerson类的class对象，然后在这个class对象里面找到重写后的"setAge:"实例方法，最后再进行调用。这个重写的"setAge:"实例方法里面会调用Foundation框架里面的C语言函数"_NSSetIntValueAndNotify();"，这个函数的实现里面首先会执行"[self willChangeValueForKey:@"age"];"代码，然后再执行"[super setAge:age];"代码，在执行这句代码的时候就会执行它的父类，也就是ZPPerson类里面的"setAge:"方法，从而真正更改这个属性的值，最后再执行"[self didChangeValueForKey:@"age"];"代码。"didChangeValueForKey:"这个方法里面会通知监听器"age"属性的值被改变了，即调用"- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context"监听方法，从而实现了对对象的某个属性进行监听的目的。
*/
#import "ViewController.h"
#import "ZPPerson.h"
#import <objc/runtime.h>

@interface ViewController ()

@property (strong, nonatomic) ZPPerson *person;
@property (strong, nonatomic) ZPPerson *person1;

@end

@implementation ViewController

#pragma mark ————— 生命周期 —————
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.person = [[ZPPerson alloc] init];
    self.person.age = 1;
    
    self.person1 = [[ZPPerson alloc] init];
    self.person1.age = 2;
    
    //查看添加KVO监听之前ZPPerson类的class对象的名称
    NSLog(@"person对象添加KVO监听之前class对象的名称：%@ %@", object_getClass(self.person), object_getClass(self.person1));
    
    //查看添加KVO监听之前ZPPerson类的class对象里面的"setAge:"实例方法存放的地址
    NSLog(@"person对象添加KVO监听之前，class对象里面存储的setAge:实例方法的地址: - %p %p", [self.person methodForSelector:@selector(setAge:)], [self.person1 methodForSelector:@selector(setAge:)]);
    
    /**
     给person对象添加KVO监听，用来监测person对象age的属性值的变化：
     添加监听方法中的addObserver:参数表示的是让谁来监听，一般用当前的VC来监听，所以一般写self；forKeyPath:参数一般写要监听对象的哪个属性；options:参数一般写所要监听的对象的属性变化前后的值；context:参数一般是当监听的对象的属性值有变化时，然后系统自动调用相应的监听方法的时候，给那个监听方法传过去的值，如果不传入任何值的话则写nil即可。
     */
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    [self.person addObserver:self forKeyPath:@"age" options:options context:nil];
    
    //查看添加KVO监听之后ZPPerson类的class对象的名称
    NSLog(@"person对象添加KVO监听class对象的名称：%@ %@", object_getClass(self.person), object_getClass(self.person1));
    
    /**
     查看添加KVO监听之后ZPPerson类的class对象里面的"setAge:"实例方法存放的地址：
     因为在给person实例对象添加完KVO监听之后，系统会把instance对象里面的isa指针指向新创建的那个子类的calss对象，在这个新创建的子类的calss对象中会重新撰写"setAge:"实例方法，所以在添加监听的前后"setAge:"实例方法其实是存储在父子两个类的class对象中，故而他们的地址是不一样的。
     */
    NSLog(@"person对象添加KVO监听之后，setAge:实例方法存放的地址：%p %p", [self.person methodForSelector:@selector(setAge:)], [self.person1 methodForSelector:@selector(setAge:)]);
    
    //查看添加KVO监听之后的class对象的存放地址
    NSLog(@"person对象添加KVO监听之后的class对象的存放地址：%p %p", object_getClass(self.person), object_getClass(self.person1));
    
    /**
     查看添加KVO监听之后的meta-class对象的存放地址：
     可以看到添加了KVO监听的person的元类对象和未添加监听的person1的元类对象是不一样的。
     */
    NSLog(@"person对象添加KVO监听之后的meta-class对象的存放地址：%p %p", object_getClass(object_getClass(self.person)), object_getClass(object_getClass(self.person1)));
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
//    self.person.age = 10;
    self.person1.age = 20;
    
    /**
     ·手动触发KVO：如果想让监听对象的属性值在不发生改变的时候也触发"- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context"监听方法的话，就需要进行手动触发KVO了。
     ·想要测试手动触发KVO的话就要把上面的"self.person.age = 10;"代码行注释掉。同样，想要测试自动触发KVO的话就要把下面的代码行注释掉。
     */
    [self manualTriggerKVO];
}

/**
 当监听对象的属性值发生改变的时候，系统就会自动调用这个监听方法；
 下面方法中的object参数表示的是所要监听的对象，keyPath参数表示的是要监听对象的哪个属性，change参数表示的是那个属性值的改变，context参数表示的是注册KVO的时候传递过来的参数。
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSLog(@"监听到%@的%@属性值改变了 - %@", object, keyPath, change);
}

#pragma mark ————— 手动触发KVO —————
- (void)manualTriggerKVO
{
    [self.person willChangeValueForKey:@"age"];
    [self.person didChangeValueForKey:@"age"];
}

//在VC将要销毁之前，要把之前添加的KVO监听移除掉。
- (void)dealloc
{
    [self.person removeObserver:self forKeyPath:@"age"];
}

@end
