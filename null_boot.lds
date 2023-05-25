OUTPUT_ARCH( "riscv" )
ENTRY( boot_entry )

MEMORY
{
  BOOT (ax) :      ORIGIN = 0x1000,       LENGTH = 0x20
}

SECTIONS
{
  . = ORIGIN(BOOT);
  .boot : {
    PROVIDE( boot_entry = . );
    *(.boot.text.entry)
    *(.boot.*)
    *(.boot)
  } > BOOT =0x0
}
