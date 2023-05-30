# Copyright EPFL contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Modified by Alessandra Dolmeta: alessandra.dolmeta@polito.it

echo "Generating ntt_intt_pwm Register RTL"
python3 ../utilities/lowrisc_opentitan/regtool.py -r -t ../rtl ntt_intt_pwm_regs.hjson
echo "Generating ntt_intt_pwm Register SW"
python3 ../utilities/lowrisc_opentitan/regtool.py  --cdefines -o ../sw/ntt_intt_pwm_regs.h ntt_intt_pwm_regs.hjson