import unittest
import resolver

test "license name":
  let
    mozilla = newLicense("MPL-2.0")
    proprietary = newLicense("Megacorp-Proprietary")

  check:
    mozilla.name == "Mozilla Public License 2.0"
    proprietary.name == "Unknown"

test "is FSF":
  let
    bsd0 = newLicense("0BSD")
    mozilla = newLicense("MPL-2.0")
    proprietary = newLicense("Megacorp-Proprietary")

  check:
    bsd0.isFsfLibre == false
    mozilla.isFsfLibre == true
    proprietary.isFsfLibre == false

test "is OSI":
  let
    bsd0 = newLicense("0BSD")
    mozilla = newLicense("MPL-2.0")
    proprietary = newLicense("Megacorp-Proprietary")

  check:
    bsd0.isOsiApproved == true
    mozilla.isOsiApproved == true
    proprietary.isOsiApproved == false

test "is deprecated":
  let
    gpl3 = newLicense("GPL-3.0")
    mozilla = newLicense("MPL-2.0")
    proprietary = newLicense("Megacorp-Proprietary")

  check:
    gpl3.isDeprecated == true
    mozilla.isDeprecated == false
    proprietary.isDeprecated == false
