# comparator
Check whether ACD input is reasonably close to reference value

- Variables (remap to new registers if required)
  - 0x0c - refByte2
  - 0x0d - refByte1
  - 0x0e - refByte0
  - 0x0f - inByte2
  - 0x10 - inByte1
  - 0x11 - inByte0
  - 0x12 - xorResult
  - 0x13 - flags
- Subroutines
  - checkTolerance </br>
    Checking if first 5 bits of most significant reference byte and ADC input byte are identical (overall values within ~5% of each other). Clears bit 0 of flags register if within reange; sets if out of range.
