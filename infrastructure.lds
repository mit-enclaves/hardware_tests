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
  .text.illegal_address_giga (NOLOAD) : {
    _illegal_address_giga = .;
  } > DRAM =0x0
  
  . = 0xFFFFD000;
  .os_page_table ALIGN(0x1000) : {
    *(.os_page_table)
  } > DRAM =0x0
}
