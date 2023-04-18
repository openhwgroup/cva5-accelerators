/* Copyright (C) 2017 Embecosm Limited and University of Bristol

   Contributor Graham Markall <graham.markall@embecosm.com>

   This file is part of Embench and was formerly part of the Bristol/Embecosm
   Embedded Benchmark Suite.

   SPDX-License-Identifier: GPL-3.0-or-later */

#include "boardsupport.h"
#include <stdio.h>
#include <sys/stat.h>
#include <support.h>

unsigned long long begin_time, end_time, user_time;
unsigned long long start_instruction_count, end_instruction_count, user_instruction_count;
unsigned long long scaled_IPC;

static int output_char(char c)
{
  unsigned char line_status;
  //Ensure space in buffer

  do {
    asm volatile("fence;\n" :::);
    line_status = *((volatile unsigned char *)LINE_STATUS_REG_ADDR);
  } while (!(line_status & TX_BUFFER_EMPTY));
  *(unsigned char *)UART_RX_TX_REG = (unsigned char)c;
  asm volatile("fence;\n" :::);
  return c;
}


extern char* _end; /* Defined by the linker */

char* _sbrk(int incr)
{
  static char *heap_end = NULL;
  char *prev_heap_end;

  if (!heap_end)
    heap_end = (char *)&_end;

  prev_heap_end = heap_end;
  heap_end += incr;
  return prev_heap_end;
}

int _write(int file, char *data, int len)
{
  for (int i = 0; i < len; i++)
  {
    output_char(data[i]);
  }
  return len;
}

int _fstat(int file, struct stat *st)
{
  st->st_mode = S_IFCHR;
  return 0;
}

int _lseek(int file, int offset, int whence)
{
  return 0;
}

int _read (int file, char *buf, int count)
{
  return 0;
}

int _close (int file)
{
  return 0;
}



void _ATTRIBUTE ((__noreturn__)) _exit (int status) {
  unsigned int pwm_count = 0;
  unsigned int rgb_output = 0;
  unsigned int toggle_value = 0;
   if (status == 0) {
    toggle_value = 4;//blue
    _write(0, "Result: CORRECT\r\n", 17);
  } else {
    toggle_value = 1;//red
    _write(0, "Result: FAILED\r\n", 16);
  }
  VERILATOR_EXIT_SUCCESS;
  //RGB board status, PWM to reduce brightness
  do {
    pwm_count++;
    if ((pwm_count % 64) == 0) {
      rgb_output = toggle_value;
    }
    else {
      rgb_output = 0;
    }
    *(volatile unsigned int*)RGB_LEDS = rgb_output;
  }
  while(1);
}

unsigned long long read_cycle()
{
  unsigned long long result;
  unsigned long lower;
  unsigned long upper1;
  unsigned long upper2;

  asm volatile(
      "repeat_cycle_%=: csrr %0, cycleh;\n"
      "        csrr %1, cycle;\n"
      "        csrr %2, cycleh;\n"
      "        bne %0, %2, repeat_cycle_%=;\n"
      : "=r"(upper1), "=r"(lower), "=r"(upper2) // Outputs   : temp variable for load result
      :
      :);
  *(unsigned long *)(&result) = lower;
  *((unsigned long *)(&result) + 1) = upper1;

  return result;
}

unsigned long long read_inst()
{
  unsigned long long result;
  unsigned long lower;
  unsigned long upper1;
  unsigned long upper2;

  asm volatile(
      "repeat_inst_%=: csrr %0, instreth;\n"
      "        csrr %1, instret;\n"
      "        csrr %2, instreth;\n"
      "        bne %0, %2, repeat_inst_%=;\n"
      : "=r"(upper1), "=r"(lower), "=r"(upper2) // Outputs   : temp variable for load result
      :
      :);
  *(unsigned long *)(&result) = lower;
  *((unsigned long *)(&result) + 1) = upper1;

  return result;
}

void initialise_board() {}

void __attribute__((noinline)) __attribute__((externally_visible))
start_trigger()
{
  begin_time = read_cycle();
  start_instruction_count = read_inst();
  VERILATOR_START_PROFILING;
}

void __attribute__((noinline)) __attribute__((externally_visible))
stop_trigger()
{
  VERILATOR_STOP_PROFILING;
  end_time = read_cycle();
  end_instruction_count = read_inst();

  user_time = end_time - begin_time;
  user_instruction_count = end_instruction_count - start_instruction_count;
  scaled_IPC = (user_instruction_count * 1000000) / user_time;

  printf("Start time: %u\r\n", (unsigned int)begin_time);
  printf("End time: %u\r\n", (unsigned int)end_time);
  printf("User time: %u\r\n", (unsigned int)user_time);
  printf("Start inst: %u\r\n", (unsigned int)start_instruction_count);
  printf("End inst: %u\r\n", (unsigned int)end_instruction_count);
  printf("User inst: %u\r\n", (unsigned int)user_instruction_count);
  printf("IPCx1M: %u\r\n", (unsigned int)scaled_IPC);
}
