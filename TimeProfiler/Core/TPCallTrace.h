//
//  TPCallTrace.h
//  VideoIphone
//
//  Created by 吴凯凯 on 2019/6/13.
//  Copyright © 2019 吴凯凯. All rights reserved.
//

#ifndef TPCallTrace_h
#define TPCallTrace_h

#include <stdio.h>
#include <objc/objc.h>


typedef struct {
    Class cls;
    SEL sel;
    uint64_t costTime; //单位：纳秒（百万分之一秒）
    int depth;
    BOOL is_objc_msgSendSuper;
} TPCallRecord;

typedef struct {
    TPCallRecord *record;
    int allocLength;
    int index;
    char *featureName;
} TPMainThreadCallRecord;

void startTrace(char *featureName);
void stopTrace(void);
TPMainThreadCallRecord *getMainThreadCallRecord(void);
void setMaxDepth(int depth);
void setCostMinTime(uint64_t time);

#endif /* TPCallTrace_h */
