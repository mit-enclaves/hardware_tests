#!/usr/bin/env python3

import struct

# Tries to construct page table matching the path
# that triggers our hardware bug.

# Everything is identity, except for [0x19b000, 0x19c000], which maps to 0x8000_0000.

leaf_permissions = 0b11011111 # D A (not G) U X W R V
node_permissions = 0b00000001 # Node

PGSHIFT = 12
PTE_PPN_SHIFT = 10

with open('idpt.bin', 'wb') as f:
    # level = 3
    for i in range(512):
        if (i == 0):
            pte = (((0xFFFFE000) >> PGSHIFT) << (PTE_PPN_SHIFT)) | node_permissions
        else:
            pte = (i << 28) | leaf_permissions
        bytes_to_write = struct.pack('<Q', pte)
        # if this assert fails, you need to find a different way to pack the int pte into 8 bytes in little-endian order
        assert( len(bytes_to_write) == 8 )
        f.write(bytes_to_write)

    # level = 2
    for i in range(512):
        if (i == 0):
            pte = (((0xFFFFF000) >> PGSHIFT) << PTE_PPN_SHIFT) | node_permissions
        elif (i >= 256 and i < 256+16):
            pte = (((0xC000_0000 + (i - 256)*0x1000*512) >> PGSHIFT) << PTE_PPN_SHIFT) | leaf_permissions
        else:
            pte = (((i*0x1000*512) >> PGSHIFT) << PTE_PPN_SHIFT) | leaf_permissions
        bytes_to_write = struct.pack('<Q', pte)
        assert ( len(bytes_to_write) == 8 )
        f.write(bytes_to_write)

    # level = 1
    for i in range(512):
        if (i == 0x19b): # 0x19b5f0 --> 0x19b
            pte = (0x200000d7) # 0x19b000 --> 0x8000_0000
        else:
            pte = (((i*0x1000) >> PGSHIFT) << PTE_PPN_SHIFT) | leaf_permissions
        bytes_to_write = struct.pack('<Q', pte)
        assert ( len(bytes_to_write) == 8)
        f.write(bytes_to_write)
