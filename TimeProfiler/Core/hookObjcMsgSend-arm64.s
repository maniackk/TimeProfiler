//
//  hookObjcMsgSend-arm64.s
//  staticHook
//
//  Created by 吴凯凯 on 2020/3/19.
//  Copyright © 2020 吴凯凯. All rights reserved.
//

#ifdef __arm64__
#include <arm/arch.h>


.macro ENTRY /* name */
    .text
    .align 5
    .private_extern    $0
$0:
.endmacro

.macro END_ENTRY /* name */
LExit$0:
.endmacro

//由于显示调用堆栈（复制栈帧）有一定性能消耗，可自行评估。1表示显示调用堆栈；0表示不显示调用堆栈
#define SUPPORT_SHOW_CALL_STACK 1

.macro BACKUP_REGISTERS
    stp q6, q7, [sp, #-0x20]!
    stp q4, q5, [sp, #-0x20]!
    stp q2, q3, [sp, #-0x20]!
    stp q0, q1, [sp, #-0x20]!
    stp x6, x7, [sp, #-0x10]!
    stp x4, x5, [sp, #-0x10]!
    stp x2, x3, [sp, #-0x10]!
    stp x0, x1, [sp, #-0x10]!
    str x8,  [sp, #-0x10]!
.endmacro

.macro RESTORE_REGISTERS
    ldr x8,  [sp], #0x10
    ldp x0, x1, [sp], #0x10
    ldp x2, x3, [sp], #0x10
    ldp x4, x5, [sp], #0x10
    ldp x6, x7, [sp], #0x10
    ldp q0, q1, [sp], #0x20
    ldp q2, q3, [sp], #0x20
    ldp q4, q5, [sp], #0x20
    ldp q6, q7, [sp], #0x20
.endmacro

.macro CALL_HOOK_BEFORE
    BACKUP_REGISTERS
    mov x2, lr
    bl _hook_objc_msgSend_before
    RESTORE_REGISTERS
.endmacro

.macro CALL_HOOK_SUPER_BEFORE
    BACKUP_REGISTERS
    ldp    x0, x16, [x0]
    mov x2, lr
    bl _hook_objc_msgSend_before
    RESTORE_REGISTERS
.endmacro

.macro CALL_HOOK_AFTER
    BACKUP_REGISTERS
    mov x0, #0x0
    bl _hook_objc_msgSend_after
    mov lr, x0
    RESTORE_REGISTERS
.endmacro

.macro CALL_HOOK_SUPER_AFTER
    BACKUP_REGISTERS
    mov x0, #0x1
    bl _hook_objc_msgSend_after
    mov lr, x0
    RESTORE_REGISTERS
.endmacro

.macro CALL_ORIGIN_OBJC_MSGSEND
    adrp    x17, _orgin_objc_msgSend@PAGE
    ldr    x17, [x17, _orgin_objc_msgSend@PAGEOFF]
    blr x17
.endmacro

.macro CALL_ORIGIN_OBJC_MSGSENDSUPER2
    adrp    x17, _orgin_objc_msgSendSuper2@PAGE
    ldr    x17, [x17, _orgin_objc_msgSendSuper2@PAGEOFF]
    blr x17
.endmacro

.macro COPY_STACK_FRAME
#if SUPPORT_SHOW_CALL_STACK
    stp x29, x30, [sp, #-0x10]
    mov x17, sp
    sub x17, fp, x17
    sub fp, sp, #0x10
    sub sp, fp, x17
    stp x0, x1, [sp, #-0x10]
    stp x2, x3, [sp, #-0x20]
    mov x0, sp
    add x1, sp, x17
    add x1, x1, #0x10
    mov x3, #0x0
    cmp x3, x17
    b.eq #0x18
    ldr x2, [x1, x3]
    str x2, [x0, x3]
    add x3, x3, #0x8
    cmp x3, x17
    b.lt #-0x10
    ldp x0, x1, [sp, #-0x10]
    ldp x2, x3, [sp, #-0x20]
#endif
.endmacro

.macro FREE_STACK_FRAME
#if SUPPORT_SHOW_CALL_STACK
    mov sp, fp
    add sp, sp, #0x10
    ldr fp, [fp]
#endif
.endmacro

# todo: 目前是全量复制栈帧，但是其实只需要复制参数传递用到的栈，利用函数签名等手段，去判断需要复制的栈帧大小
ENTRY _hook_msgSend
    COPY_STACK_FRAME
    CALL_HOOK_BEFORE
    CALL_ORIGIN_OBJC_MSGSEND
    CALL_HOOK_AFTER
    FREE_STACK_FRAME
    ret
END_ENTRY _hook_msgSend

ENTRY _hook_msgSendSuper2
    COPY_STACK_FRAME
    CALL_HOOK_SUPER_BEFORE
    CALL_ORIGIN_OBJC_MSGSENDSUPER2
    CALL_HOOK_SUPER_AFTER
    FREE_STACK_FRAME
    ret
END_ENTRY _hook_msgSendSuper2

#endif
