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

.macro CALL_HOOK_AFTER
    BACKUP_REGISTERS
    bl _hook_objc_msgSend_after
    mov lr, x0
    RESTORE_REGISTERS
.endmacro

.macro CALL_ORIGIN_OBJC_MSGSEND
    adrp    x17, _orgin_objc_msgSend@PAGE
    ldr    x17, [x17, _orgin_objc_msgSend@PAGEOFF]
    blr x17
.endmacro


ENTRY _hook_msgSend
    CALL_HOOK_BEFORE
    CALL_ORIGIN_OBJC_MSGSEND
    CALL_HOOK_AFTER
    ret
END_ENTRY _hook_msgSend

// void hook_msgSend(...);
//ENTRY _hook_msgSend_stret
//b _hook_msgSend
//END_ENTRY _hook_msgSend_stret

#endif
