//
//  PontoBaseHandler
//  Game Guides
//
//  Created by Grzegorz Nowicki on 21.09.2012.
//  Copyright (c) 2012 Wikia Sp. z o.o. All rights reserved.
//

#import "PontoBaseHandler.h"


@implementation PontoBaseHandler {

}

+ (id)instance {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %s in a subclass", __PRETTY_FUNCTION__]
                                 userInfo:nil];
}

@end