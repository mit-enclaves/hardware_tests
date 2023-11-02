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
    *(.got)
    *(.got.plt)
    *(.rodata)
    *(.text)
  } > DRAM =0x0

  . = 0x801FE000;
  .text.illegal_address_kilo (NOLOAD) : {
    _illegal_address_kilo = .;
  } > DRAM =0x0

  . = 0x80200000;
  .text.illegal_address_mega (NOLOAD) : {
    _illegal_address_mega = .;
  } > DRAM =0x0
  
  . = 0x82000000;
  .text.illegal_address_region (NOLOAD) : {
    _illegal_address_region = .;
  } > DRAM =0x0
  
  . = 0xC0000000;
  .text.enclave_program ALIGN(0x1000) : {
    *(.text.enclave_program)
    *(.got)
    *(.got.plt)
    *(.rodata)
    *(.text)
  } > DRAM =0x0

  . = 0xFFFFB000;
  .text.enclave_page_table ALIGN(0x1000) : {
    *(.text.enclave_page_table)
  } > DRAM =0x0

  . = 0xFFFFD000;
  .text.page_table ALIGN(0x1000) : {
    *(.text.page_table)
  } > DRAM =0x0
}
