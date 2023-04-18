/* Copyright (C) 2017 Embecosm Limited and University of Bristol

   Contributor Graham Markall <graham.markall@embecosm.com>

   This file is part of Embench and was formerly part of the Bristol/Embecosm
   Embedded Benchmark Suite.

   SPDX-License-Identifier: GPL-3.0-or-later */

#ifndef BOARD_SUPPORT_H
#define BOARD_SUPPORT_H
#include <stdio.h>

#define CPU_MHZ 1

//Base address for a 16550 UART
#define UART_BASE_ADDR 0x88000000
#define UART_RX_TX_REG (UART_BASE_ADDR + 0x1000)
#define TX_BUFFER_EMPTY 0x00000020
#define RX_HAS_DATA 0x00000001
#define LINE_STATUS_REG_ADDR (UART_RX_TX_REG + 0x14)

#define RGB_LEDS 0x88200000

//64-bit variables for cycle and instruction counts
extern unsigned long long _start_time, _end_time, _user_time;
extern unsigned long long _start_instruction_count, _end_instruction_count, _user_instruction_count;
extern unsigned long long _scaled_IPC;

//Custom NOPs for Verilator logging and operation
#define  VERILATOR_START_PROFILING __asm__ volatile ("addi x0, x0, 0xC" : : : "memory")
#define  VERILATOR_STOP_PROFILING __asm__ volatile ("addi x0, x0, 0xD" : : : "memory")
#define  VERILATOR_EXIT_SUCCESS __asm__ volatile ("addi x0, x0, 0xA" : : : "memory")
#define  VERILATOR_EXIT_ERROR __asm__ volatile ("addi x0, x0, 0xF" : : : "memory")

//External Functions
void _exit (int status) _ATTRIBUTE ((__noreturn__));
#endif
