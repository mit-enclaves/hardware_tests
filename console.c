#include "console.h"

volatile uint64_t tohost    __attribute__((section(".htif.tohost")));
volatile uint64_t fromhost  __attribute__((section(".htif.fromhost")));

volatile uint64_t *tohost_t = (uint64_t *) HTIF_BASE;
volatile uint64_t *fromhost_t = (uint64_t *) (HTIF_BASE + 0x8);

volatile int htif_console_buf;

#define TOHOST(base_int)	(uint64_t *)(base_int + TOHOST_OFFSET)
#define FROMHOST(base_int)	(uint64_t *)(base_int + FROMHOST_OFFSET)

#define TOHOST_OFFSET		((uintptr_t)*tohost_t - (uintptr_t)__htif_base)
#define FROMHOST_OFFSET		((uintptr_t)*fromhost_t - (uintptr_t)__htif_base)

# define TOHOST_CMD(dev, cmd, payload) \
  (((uint64_t)(dev) << 56) | ((uint64_t)(cmd) << 48) | (uint64_t)(payload))

#define FROMHOST_DEV(fromhost_value) ((uint64_t)(fromhost_value) >> 56)
#define FROMHOST_CMD(fromhost_value) ((uint64_t)(fromhost_value) << 8 >> 56)
#define FROMHOST_DATA(fromhost_value) ((uint64_t)(fromhost_value) << 16 >> 16)

static void __check_fromhost() { // Code taken from riscv-pk
  uint64_t fh = *fromhost_t;
  if (!fh)
    return;
  *fromhost_t = 0;

  // this should be from the console
  assert(FROMHOST_DEV(fh) == 1);
  switch (FROMHOST_CMD(fh)) {
    case 0:
      htif_console_buf = 1 + (uint8_t)FROMHOST_DATA(fh);
      break;
    case 1:
      break;
    default:
      break;
      assert(0);
  }
}

static void __set_tohost(uintptr_t dev, uintptr_t cmd, uintptr_t data)
{
  while (*tohost_t)
    __check_fromhost();
  *tohost_t = TOHOST_CMD(dev, cmd, data);
}


uint64_t htif_getchar() {
    __check_fromhost();
    int ch = htif_console_buf;
    if (ch >= 0) {
      htif_console_buf = -1;
      __set_tohost(1, 0, 0);
    }

  return ch - 1;
}

void htif_putchar(uint8_t c) {
  __set_tohost(1, 1, c);
}

void putstring(const char* s)
{
  while (*s)
    htif_putchar(*s++);
}

// See LICENSE for license details.

#include <stdint.h>
#include <string.h>
#include <stdarg.h>
#include <stdbool.h>

int vsnprintf(char* out, size_t n, const char* s, va_list vl)
{
  bool format = false;
  bool longarg = false;
  bool longlongarg = false;
  size_t pos = 0;
  for( ; *s; s++)
  {
    if(format)
    {
      switch(*s)
      {
        case 'l':
          if (s[1] == 'l') {
              longlongarg = true;
              s++;
          }
          else
              longarg = true;
          break;
        case 'p':
          longarg = true;
          if (++pos < n) out[pos-1] = '0';
          if (++pos < n) out[pos-1] = 'x';
        case 'x':
        {
          long long num;
          size_t size;
          if (longarg) {
              num = va_arg(vl, long);
	      size = sizeof(long);
	  } else if (longlongarg) {
              num = va_arg(vl, long long);
	      size = sizeof(long long);
	  } else {
              num = va_arg(vl, int);
	      size = sizeof(int);
	  }
          for(int i = 2*(size)-1; i >= 0; i--) {
            int d = (num >> (4*i)) & 0xF;
            if (++pos < n) out[pos-1] = (d < 10 ? '0'+d : 'a'+d-10);
          }
	  longlongarg = false;
          longarg = false;
          format = false;
          break;
        }
        case 'd':
        {
          long long num;
          if (longarg)
              num = va_arg(vl, long);
          else if (longlongarg)
              num = va_arg(vl, long long);
          else
              num = va_arg(vl, int);
          if (num < 0) {
            num = -num;
            if (++pos < n) out[pos-1] = '-';
          }
          long digits = 1;
          for (long long nn = num; nn /= 10; digits++)
            ;
          for (int i = digits-1; i >= 0; i--) {
            if (pos + i + 1 < n) out[pos + i] = '0' + (num % 10);
            num /= 10;
          }
          pos += digits;
          longarg = false;
          longlongarg = false;
          format = false;
          break;
        }
        case 's':
        {
          const char* s2 = va_arg(vl, const char*);
          while (*s2) {
            if (++pos < n)
              out[pos-1] = *s2;
            s2++;
          }
          longarg = false;
          format = false;
          break;
        }
        case 'c':
        {
          if (++pos < n) out[pos-1] = (char)va_arg(vl,int);
          longarg = false;
          format = false;
          break;
        }
        default:
          break;
      }
    }
    else if(*s == '%')
      format = true;
    else
      if (++pos < n) out[pos-1] = *s;
  }
  if (pos < n)
    out[pos] = 0;
  else if (n)
    out[n-1] = 0;
  return pos;
}

int snprintf(char* out, size_t n, const char* s, ...)
{
  va_list vl;
  va_start(vl, s);
  int res = vsnprintf(out, n, s, vl);
  va_end(vl);
  return res;
}

void vprintm(const char* s, va_list vl)
{
  char buf[256];
  vsnprintf(buf, sizeof buf, s, vl);
  putstring(buf);
}

void printm(const char* s, ...)
{
  va_list vl;

  va_start(vl, s);
  vprintm(s, vl);
  va_end(vl);
}

void console_putchar(char c) {
  htif_putchar(c);
}

uint64_t console_getchar() {
  return htif_getchar();
}

void print_char(char c) {
  htif_putchar(c);
}


void print_str(char* s) {
  while (*s != 0) {
    print_char(*s++);
  }
}

void print_int(uint64_t n) {
   uint64_t ru = 1;
   for(uint64_t m = n; m > 1; m /= 10) {
      ru *= 10;
   }
   for(uint64_t i = ru; i >= 1; i /= 10) {
      char c = '0' + ((n / i) % 10);
      print_char(c);
   }
   return;
}

void send_exit_cmd(int c){
  if(c == 0) {
    *tohost_t = TOHOST_CMD(0, 0, 0b01); // report test done; 0 exit code
  }
  else {
    *tohost_t = TOHOST_CMD(0, 0, 0b11); // report test done; 1 exit code
  }
}