OUTPUT_ARCH( "riscv" )
ENTRY( entry )

MEMORY
{
  HTIF (awx) : ORIGIN = 0x10001000, LENGTH = 0x10
  DRAM (awx) : ORIGIN = 0x80000000, LENGTH = 0x80000000
}

SECTIONS
{
  . = ORIGIN(HTIF);
  .htif ALIGN(0x1000) : {
    PROVIDE( __htif_base = . );
    *(.htif.tohost)
    *(.htif.fromhost)
    *(.htif.*)
    *(.htif)
  } > HTIF =0x0
}

SECTIONS
{
  . = 0x80000000;
  .text ALIGN(0x1000) : {
    *(.text.entry)
    *(.text)
  } > DRAM =0x0

  .data ALIGN(0x1000) : {
    *(.data)
    *(.data.*)
  } > DRAM =0x0

  .bss ALIGN(0x1000) : {
    *(.bss)
    *(.bss.*)
  } > DRAM =0x0

  .rodata ALIGN(0x1000) : {
    *(.rodata)
    *(.rodata.*)
    *(.got)
    *(.got.plt)
  } > DRAM =0x0

  . = 0x82000000;
  .text.enclave_program ALIGN(0x1000) : {
    *(.text.enclave_program)
  } > DRAM =0x0

  . = 0xFFFFB000;
  .enclave_page_table ALIGN(0x1000) : {
    *(.enclave_page_table)
  } > DRAM =0x0

  . = 0xFFFFD000;
  .os_page_table ALIGN(0x1000) : {
    *(.page_table)
  } > DRAM =0x0
}
