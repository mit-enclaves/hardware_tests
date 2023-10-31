OUTPUT_ARCH( "riscv" )
ENTRY( entry )

SECTIONS
{
  . = 0x80000000;
  .text ALIGN(0x1000) : {
    *(.text.entry)
    *(.got)
    *(.got.plt)
    *(.rodata)
    *(.text)
  }

  .htif ALIGN(0x1000) (NOLOAD) : {
    *(.htif.fromhost)
    *(.htif.tohost)
  }

  . = 0x801FE000;
  .text.illegal_address_kilo (NOLOAD) : {
    _illegal_address_kilo = .;
  }

  . = 0x80200000;
  .text.illegal_address_mega (NOLOAD) : {
    _illegal_address_mega = .;
  }
  
  . = 0x82000000;
  .text.illegal_address_region (NOLOAD) : {
    _illegal_address_region = .;
  }
  
  . = 0xC0000000;
  .text.enclave_program ALIGN(0x1000) : {
    *(.text.enclave_program)
    *(.got)
    *(.got.plt)
    *(.rodata)
    *(.text)
  }

  . = 0xFFFFB000;
  .text.enclave_page_table ALIGN(0x1000) : {
    *(.text.enclave_page_table)
  }

  . = 0xFFFFD000;
  .text.page_table ALIGN(0x1000) : {
    *(.text.page_table)
  }
}
