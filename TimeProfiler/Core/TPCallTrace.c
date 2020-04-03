//
//  TPCallTrace.c
//  VideoIphone
//
//  Created by 吴凯凯 on 2019/6/13.
//  Copyright © 2019 com.baidu. All rights reserved.
//

#include "TPCallTrace.h"

#ifndef __arm64__
// 模拟器 或者 iPhone5及更老iPhone设备，不是使用arm64

void startTrace(char *featureName) {
    printf("====模拟器或者iPhone5及更老iPhone设备,不能hook objc_msgSend====");
};

void stopTrace() {
};

TPMainThreadCallRecord *getMainThreadCallRecord(void)
{
    return NULL;
}
void setMaxDepth(int depth){};
void setCostMinTime(uint64_t time){};

#else
// iPhone5s及更新设备

//#include <stdio.h>
#include <stdlib.h>
#include <dispatch/dispatch.h>
#include <pthread.h>
#include "fishhook.h"
#include <objc/runtime.h>
#include <sys/time.h>


typedef struct {
    Class cls;
    SEL sel;
    uint64_t time;
} MethodRecord;

typedef struct {
    MethodRecord *stack;
    int allocLength;
    int index;
} MainThreadMethodStack;

typedef struct {
    int allocLength;
    int index;
    uintptr_t *lr_stack;
} LRStack;

void (*orgin_objc_msgSend)(void);
void (*orgin_objc_msgSendSuper2)(void);
static pthread_key_t threadKeyLR;
static MainThreadMethodStack *mainThreadStack = NULL;
static TPMainThreadCallRecord *mainThreadCallRecord = NULL;
static bool CallRecordEnable = YES;
static int maxDepth = 3;
static int ignoreCallNum = 0;
static uint64_t costMinTime = 1000;

static inline uint64_t getVirtualCallTime()
{
    struct timeval now;
    gettimeofday(&now, NULL);
    uint64_t time = (now.tv_sec % 1000) * 1000000 + now.tv_usec;
    return time;
}

static inline void pushCallRecord(Class cls, SEL sel)
{
    if (mainThreadStack->index >= maxDepth) {
        ignoreCallNum++;
        return;
    }
    if (mainThreadStack) {
        uint64_t time = getVirtualCallTime();
        if (++mainThreadStack->index >= mainThreadStack->allocLength) {
            mainThreadStack->allocLength += 128;
            mainThreadStack->stack = (MethodRecord *)realloc(mainThreadStack->stack, mainThreadStack->allocLength *  sizeof(MethodRecord));
        }
        MethodRecord *record = &mainThreadStack->stack[mainThreadStack->index];
        record->cls = cls;
        record->sel = sel;
        record->time = time;
    }
}

static inline void popCallRecord(BOOL is_objc_msgSendSuper)
{
    if (ignoreCallNum > 0) {
        ignoreCallNum--;
        return;
    }
    if (mainThreadStack && mainThreadStack->index >= 0) {
        //todo: stack空间缩小算法
        uint64_t time = getVirtualCallTime();
        MethodRecord *record = &mainThreadStack->stack[mainThreadStack->index];
        uint64_t costTime = time - record->time;
        int depth = mainThreadStack->index--;
        if (costTime >= costMinTime) {
            if (++mainThreadCallRecord->index >= mainThreadCallRecord->allocLength) {
                mainThreadCallRecord->allocLength += 128;
                mainThreadCallRecord->record = realloc(mainThreadCallRecord->record, mainThreadCallRecord->allocLength * sizeof(TPCallRecord));
            }
            TPCallRecord* callRecord = &mainThreadCallRecord->record[mainThreadCallRecord->index];
            callRecord->cls = record->cls;
            callRecord->depth = depth;
            callRecord->costTime = costTime;
            callRecord->sel = record->sel;
            callRecord->is_objc_msgSendSuper = is_objc_msgSendSuper;
        }
    }
}

static inline void setLRRegisterValue(uintptr_t lr)
{
    LRStack *lrStack = pthread_getspecific(threadKeyLR);
    if (!lrStack) {
        lrStack = (LRStack *)malloc(sizeof(LRStack));
        lrStack->allocLength = 128;
        lrStack->lr_stack = (uintptr_t *)malloc(lrStack->allocLength * sizeof(uintptr_t));
        lrStack->index = -1;
        pthread_setspecific(threadKeyLR, lrStack);
    }
    if (++lrStack->index >= lrStack->allocLength) {
        lrStack->allocLength += 128;
        lrStack->lr_stack = (uintptr_t *)realloc(lrStack->lr_stack, lrStack->allocLength *sizeof(uintptr_t));
    }
    lrStack->lr_stack[lrStack->index] = lr;
}

static inline uintptr_t getLRRegisterValue()
{
    LRStack *lrStack = pthread_getspecific(threadKeyLR);
    uintptr_t lr = lrStack->lr_stack[lrStack->index--];
    return lr;
}

void hook_objc_msgSend_before(id self, SEL sel, uintptr_t lr)
{
    if (CallRecordEnable && pthread_main_np()) {
        pushCallRecord(object_getClass(self), sel);
    }
    
    setLRRegisterValue(lr);
}

uintptr_t hook_objc_msgSend_after(BOOL is_objc_msgSendSuper)
{
    if (CallRecordEnable && pthread_main_np()) {
        popCallRecord(is_objc_msgSendSuper);
    }
    
    return getLRRegisterValue();
}

void threadCleanLRStack(void *ptr)
{
    if (ptr != NULL) {
        LRStack *lrStack = (LRStack *)ptr;
        if (lrStack->lr_stack) {
            free(lrStack->lr_stack);
        }
        free(lrStack);
    }
}

void initData(char *featureName)
{
    if (!mainThreadCallRecord) {
        mainThreadCallRecord = (TPMainThreadCallRecord *)malloc(sizeof(TPMainThreadCallRecord));
        mainThreadCallRecord->allocLength = 128;
        mainThreadCallRecord->record = (TPCallRecord *)malloc(mainThreadCallRecord->allocLength * sizeof(TPCallRecord));
        mainThreadCallRecord->index = -1;
        mainThreadCallRecord->featureName = featureName;
    }
    
    if (!mainThreadStack) {
        mainThreadStack = (MainThreadMethodStack *)malloc(sizeof(MainThreadMethodStack));
        mainThreadStack->allocLength = 128;
        mainThreadStack->stack = (MethodRecord *)malloc(mainThreadStack->allocLength * sizeof(MethodRecord));
        mainThreadStack->index = -1;
    }
}

extern void hook_msgSend(void);
extern void hook_msgSendSuper2(void);

void startTrace(char *featureName) {
    initData(featureName);
    CallRecordEnable = YES;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pthread_key_create(&threadKeyLR, threadCleanLRStack);
        struct rebinding rebindObjc_msgSend;
        rebindObjc_msgSend.name = "objc_msgSend";
        rebindObjc_msgSend.replacement = hook_msgSend;
        rebindObjc_msgSend.replaced = (void *)&orgin_objc_msgSend;
        struct rebinding rebindObjc_msgSendSuper2;
        rebindObjc_msgSendSuper2.name = "objc_msgSendSuper2";
        rebindObjc_msgSendSuper2.replacement = hook_msgSendSuper2;
        rebindObjc_msgSendSuper2.replaced = (void *)&orgin_objc_msgSendSuper2;
        struct rebinding rebs[2] = {rebindObjc_msgSend, rebindObjc_msgSendSuper2};
        rebind_symbols(rebs, 2);
    });
};

void stopTrace() {
    CallRecordEnable = NO;
    if (mainThreadStack) {
        free(mainThreadStack->stack);
        free(mainThreadStack);
        mainThreadStack = NULL;
        ignoreCallNum = 0;
    }
};

TPMainThreadCallRecord *getMainThreadCallRecord(void)
{
    TPMainThreadCallRecord *retValue = mainThreadCallRecord;
    mainThreadCallRecord = NULL;
    return retValue;
}

void setMaxDepth(int depth)
{
    maxDepth = depth;
}

void setCostMinTime(uint64_t time)
{
    costMinTime = time;
}


#endif

