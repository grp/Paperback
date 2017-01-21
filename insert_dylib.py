# Copyright (c) 2016, Grant Paul
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import sys
import struct
import argparse

import macho

def insert_dylib_macho(contents, dylib, offset=0):
    initial_offset = offset

    big_magic, = struct.unpack_from('>I', contents, offset)
    little_magic, = struct.unpack_from('<I', contents, offset)

    if big_magic in { macho.MH_MAGIC, macho.MH_MAGIC_64 }:
        endian = '>'
    elif little_magic in { macho.MH_MAGIC, macho.MH_MAGIC_64 }:
        endian = '<'
    else:
        raise 'Unknown Mach-O magic.'

    magic, = struct.unpack_from(endian + 'I', contents, offset)

    header_offset = offset
    if magic == macho.MH_MAGIC:
        header = macho.mach_header()
        header.unpack(endian, contents, offset)
        offset += header.calcsize()
    elif magic == macho.MH_MAGIC_64:
        header = macho.mach_header_64()
        header.unpack(endian, contents, offset)
        offset += header.calcsize()
    else:
        raise 'Unknown Mach-O magic.'

    # Find available padding between end of load commands and start of first
    # section or segment. Generally, there should be some added by `-headerpad`.
    first_segment = len(contents)
    for i in range(header.ncmds):
        command = macho.load_command()
        command.unpack(endian, contents, offset)

        if command.cmd in { macho.LC_SEGMENT, macho.LC_SEGMENT_64 }:
            if command.cmd == macho.LC_SEGMENT:
                segment = macho.segment_command()
                segment.unpack(endian, contents, offset)
            elif command.cmd == macho.LC_SEGMENT_64:
                segment = macho.segment_command_64()
                segment.unpack(endian, contents, offset)
            else:
                raise 'Unknown load command.'

            if segment.nsects != 0:
                section_offset = offset + segment.calcsize()
                for j in range(segment.nsects):
                    if command.cmd == macho.LC_SEGMENT:
                        section = macho.section()
                        section.unpack(endian, contents, section_offset)
                        section_offset += section.calcsize()
                    elif command.cmd == macho.LC_SEGMENT_64:
                        section = macho.section_64()
                        section.unpack(endian, contents, section_offset)
                        section_offset += section.calcsize()
                    else:
                        raise 'Unknown load command.'

                    if section.size != 0 and ((section.flags & macho.S_ZEROFILL) != macho.S_ZEROFILL):
                        if section.offset < first_segment:
                            first_segment = section.offset
            elif segment.filesize != 0:
                if segment.fileoff < first_segment:
                    first_segment = segment.fileoff
        elif command.cmd == macho.LC_LOAD_DYLIB:
            dylib_command = macho.dylib_command()
            dylib_command.unpack(endian, contents, offset)

            # Check if dylib is already added.
            dylib_name_offset = offset + dylib_command.calcsize()
            dylib_name_size = dylib_command.cmdsize - dylib_command.calcsize()
            dylib_name = contents[dylib_name_offset:dylib_name_offset + dylib_name_size]
            dylib_name = dylib_name[:dylib_name.find('\0')] # Strip padding.
            if dylib_name == dylib:
                return

        offset += command.cmdsize

    available_space = first_segment - (offset - initial_offset)

    # Padding appears to be required.
    dylib_padded = dylib + ('\0' * ((len(dylib) % 8) + 4))

    dylib_command = macho.dylib_command()
    dylib_command.cmd = macho.LC_LOAD_DYLIB 
    dylib_command.cmdsize = dylib_command.calcsize() + len(dylib_padded)
    dylib_command.name = dylib_command.calcsize()
    dylib_command.timestamp = 0
    dylib_command.current_version = 0
    dylib_command.compatibility_version = 0

    if available_space < dylib_command.cmdsize:
        raise 'Not enough space; use `-headerpad`?'

    contents[offset:offset + dylib_command.calcsize()] = dylib_command.pack(endian)
    offset += dylib_command.calcsize()

    contents[offset:offset + len(dylib_padded)] = dylib_padded

    header.ncmds += 1
    header.sizeofcmds += dylib_command.cmdsize
    contents[header_offset:header_offset + header.calcsize()] = header.pack(endian)

def insert_dylib_fat(contents, dylib, offset=0):
    big_magic, = struct.unpack_from('>I', contents, offset)
    little_magic, = struct.unpack_from('<I', contents, offset)

    if big_magic == macho.FAT_MAGIC:
        endian = '>' # Fat is swapped.
    elif little_magic == macho.FAT_MAGIC:
        endian = '<' # Fat is swapped.
    else:
        insert_dylib_macho(contents, dylib, offset)
        return

    fat_header = macho.fat_header()
    fat_header.unpack(endian, contents, offset)
    offset += fat_header.calcsize()

    arch_offset = offset
    for i in range(fat_header.nfat_arch):
        arch = macho.fat_arch()
        arch.unpack(endian, contents, arch_offset)
        insert_dylib_macho(contents, dylib, arch.offset)
        arch_offset += arch.calcsize()


def main(argv):
    parser = argparse.ArgumentParser(description='Add dylib to Mach-O')
    parser.add_argument('-i', '--input', action='store', required=True, help='input mach-o')
    parser.add_argument('-o', '--output', action='store', required=True, help='output mach-o')
    parser.add_argument('-d', '--dylib', action='append', required=True, help='insert dylibs to load')
    args = parser.parse_args(argv[1:])

    with open(args.input, 'rb') as input:
        contents = bytearray(input.read())

    for dylib in args.dylib:
        insert_dylib_fat(contents, dylib)

    with open(args.output, 'wb') as output:
        output.write(contents)

if __name__ == '__main__':
    main(sys.argv)
