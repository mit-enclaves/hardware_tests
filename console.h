#ifndef CONSOLE_H
#define CONSOLE_H

#include <stdint.h>
#include <string.h>
#include <stdarg.h>

#define HTIF_BASE 0x10001000

#define assert(x) ({ if (!(x)) die("assertion failed: %s", #x); })
#define die(str, ...) ({ printm("%s:%d: " str "\n", __FILE__, __LINE__, ##__VA_ARGS__); platform_panic(); })

void platform_panic(void) __attribute__((noreturn));

void print_char(char c);
void print_str(char* s);
void print_int(uint64_t n);

void console_putchar(char c);
uint64_t console_getchar();

void printm(const char* s, ...);
void vprintm(const char *s, va_list args);
void putstring(const char* s);

void send_exit_cmd(int c);


#endif // CONSOLE_H