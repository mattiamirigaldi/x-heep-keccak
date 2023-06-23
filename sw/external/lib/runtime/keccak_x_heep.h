// Copyright EPFL contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef KECCAK_X_HEEP_H_
#define KECCAK_X_HEEP_H_

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

  //#include "core_v_mini_mcu.h"

#define KECCAK_PERIPH_START_ADDRESS (EXT_PERIPHERAL_START_ADDRESS + 0x0000000)
#define KECCAK_PERIPH_SIZE 0x0001000
#define KECCAK_PERIPH_END_ADDRESS (KECCAK_PERIPH_START_ADDRESS + KECCAK_PERIPH_SIZE)

#define KECCAK_DIN_START_ADDR KECCAK_PERIPH_START_ADDRESS
#define KECCAK_CTRL_START_ADDR (KECCAK_PERIPH_START_ADDRESS+0x00000190)
#define KECCAK_STATUS_START_ADDR (KECCAK_PERIPH_START_ADDRESS+0x00000194)
#define KECCAK_DOUT_START_ADDR (KECCAK_PERIPH_START_ADDRESS+0x0000000c8)
  
#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  // KECCAK_X_HEEP_H_