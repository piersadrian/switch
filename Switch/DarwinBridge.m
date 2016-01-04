//
//  DarwinBridge.m
//  Switch
//
//  Created by Piers Mainwaring on 12/22/15.
//  Copyright © 2015 piersadrian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DarwinBridge.h"

int fcntl_setnonblock(int fd)
{
    return fcntl(fd, F_SETFL, O_NONBLOCK);
}