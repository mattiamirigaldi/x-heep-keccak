# Copyright EPFL contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Modified by Alessandra Dolmeta: alessandra.dolmeta@polito.it

echo "Generating Keccak Register RTL"
python3 ../utilities/lowrisc_opentitan/regtool.py -r -t ../rtl keccak_regs.hjson
echo "Generating Keccak Register SW"
python3 ../utilities/lowrisc_opentitan/regtool.py  --cdefines -o ../sw/keccak_regs.h keccak_regs.hjson