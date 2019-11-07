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

void startTrace() {
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
#include "fishhook/fishhook.h"
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

static id (*orgin_objc_msgSend)(id, SEL, ...);
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

static inline void popCallRecord()
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

uintptr_t hook_objc_msgSend_after()
{
    if (CallRecordEnable && pthread_main_np()) {
        popCallRecord();
    }
    
    return getLRRegisterValue();
}

#define call(b, value) \
__asm volatile ("stp x8, x9, [sp, #-16]!\n"); \
__asm volatile ("mov x10, %0\n" :: "r"(value)); \
__asm volatile ("ldp x8, x9, [sp], #16\n"); \
__asm volatile (#b " x10\n");

__attribute__((__naked__))
static void fake_objc_msgSend_safe()
{
    //维护CFI(call frame information)，这样就可以看到调用堆栈
//    __asm__ volatile(
//                     ".cfi_def_cfa w29, 16\n"
//                     ".cfi_offset w30, -8\n"
//                     ".cfi_offset w29, -16\n"
//                     "stp    x29, x30, [sp, #-16]!\n"
//                     "mov    x29, sp\n"
//    );
    // backup registers
    __asm__ volatile(
                     "str x8,  [sp, #-16]!\n"  //arm64标准：sp % 16 必须等于0
                     "stp x6, x7, [sp, #-16]!\n"
                     "stp x4, x5, [sp, #-16]!\n"
                     "stp x2, x3, [sp, #-16]!\n"
                     "stp x0, x1, [sp, #-16]!\n"
                     );
    // prepare args and call func
    __asm volatile (
                    /*
                     hook_objc_msgSend_before(id self, SEL sel, uintptr_t lr)
                     x0=self  x1=sel x2=lr
                     */
                    "mov x2, lr\n"
                    "bl _hook_objc_msgSend_before"
                    );
    
    // restore registers
    __asm volatile (
                    "ldp x0, x1, [sp], #16\n"
                    "ldp x2, x3, [sp], #16\n"
                    "ldp x4, x5, [sp], #16\n"
                    "ldp x6, x7, [sp], #16\n"
                    "ldr x8,  [sp], #16\n"
                    );
    
    call(blr, orgin_objc_msgSend)

    // backup registers
    __asm__ volatile(
                     "str x8,  [sp, #-16]!\n"  //arm64标准：sp % 16 必须等于0
                     "stp x6, x7, [sp, #-16]!\n"
                     "stp x4, x5, [sp, #-16]!\n"
                     "stp x2, x3, [sp, #-16]!\n"
                     "stp x0, x1, [sp, #-16]!\n"
                     );
    
    __asm volatile (
                    "bl _hook_objc_msgSend_after"
                    );
    
    __asm volatile (
                    "mov lr, x0\n"
                    );
    
    // restore registers
    __asm volatile (
                    "ldp x0, x1, [sp], #16\n"
                    "ldp x2, x3, [sp], #16\n"
                    "ldp x4, x5, [sp], #16\n"
                    "ldp x6, x7, [sp], #16\n"
                    "ldr x8,  [sp], #16\n"
                    );
    
    __asm volatile (
//                    "ldp x29, x30, [sp], #16\n"
                    "ret");
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

void initData()
{
    if (!mainThreadCallRecord) {
        mainThreadCallRecord = (TPMainThreadCallRecord *)malloc(sizeof(TPMainThreadCallRecord));
        mainThreadCallRecord->allocLength = 128;
        mainThreadCallRecord->record = (TPCallRecord *)malloc(mainThreadCallRecord->allocLength * sizeof(TPCallRecord));
        mainThreadCallRecord->index = -1;
    }
    
    if (!mainThreadStack) {
        mainThreadStack = (MainThreadMethodStack *)malloc(sizeof(MainThreadMethodStack));
        mainThreadStack->allocLength = 128;
        mainThreadStack->stack = (MethodRecord *)malloc(mainThreadStack->allocLength * sizeof(MethodRecord));
        mainThreadStack->index = -1;
    }
}

void startTrace() {
    initData();
    CallRecordEnable = YES;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pthread_key_create(&threadKeyLR, threadCleanLRStack);
        struct rebinding rebindObjc_msgSend;
        rebindObjc_msgSend.name = "objc_msgSend";
        rebindObjc_msgSend.replacement = fake_objc_msgSend_safe;
        rebindObjc_msgSend.replaced = (void *)&orgin_objc_msgSend;
        struct rebinding rebs[1] = {rebindObjc_msgSend};
        rebind_symbols(rebs, 1);
    });
};

void stopTrace() {
    CallRecordEnable = NO;
};

TPMainThreadCallRecord *getMainThreadCallRecord(void)
{
    return mainThreadCallRecord;
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

