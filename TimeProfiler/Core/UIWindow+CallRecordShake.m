//
//  UIWindow+CallRecordShake.m
//  VideoIphone
//
//  Created by 吴凯凯 on 2019/6/18.
//  Copyright © 2019 吴凯凯. All rights reserved.
//

#import "UIWindow+CallRecordShake.h"
#import "TPMainVC.h"

@implementation UIWindow (CallRecordShake)

- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    TPMainVC *vc = [[TPMainVC alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.rootViewController presentViewController:vc animated:YES completion:nil];
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

@end
