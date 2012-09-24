//
//  PontoBaseHandler
//  Ponto
//
//  Created by Grzegorz Nowicki <grzegorz@wikia-inc.com> on 21.09.2012.
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