//
//  Header.h
//  Test_Nimbus
//
//  Created by CPU12068 on 11/24/17.
//  Copyright © 2017 CPU12068. All rights reserved.
//

#ifndef Header_h
#define Header_h

//Queue constaint
#define globalDefaultQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define globalBackgroundQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
#define globalHighQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
#define mainQueue dispatch_get_main_queue()

//Contact constaint
#define AvatarSize CGSizeMake(50, 50)
#define AvatarSmallSize CGSizeMake(40, 40)

#define GetValidQueue(queue)                queue ? queue : mainQueue

#define weakify(_var_) typeof(_var_) __weak _var_##Weak = _var_

#endif /* Header_h */
