// Copyright 2022 EPFL
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

// Designed by Alessandra Dolmeta, Mattia Mirigaldi
// alessandra.dolmeta@polito.it, mattiamirigaldi.98017@gmail.com
//

module keccak_x_heep_top #(
    parameter COREV_PULP = 0,
    parameter FPU        = 0,
    parameter ZFINX      = 0	
) (
    inout logic 					     clk_i,
    inout logic 					     rst_ni,

    inout logic 					     boot_select_i,
    inout logic 					     execute_from_flash_i,

    inout logic 					     jtag_tck_i,
    inout logic 					     jtag_tms_i,
    inout logic 					     jtag_trst_ni,
    inout logic 					     jtag_tdi_i,
    inout logic 					     jtag_tdo_o,

    inout 						     uart_rx_i,
    inout 						     uart_tx_o,

    inout logic [19:0] 					     gpio_io,

    inout logic [3:0] 					     spi_flash_sd_io,
    inout logic [1:0] 					     spi_flash_csb_io,
    inout logic 					     spi_flash_sck_io,

    inout logic [3:0] 					     spi_sd_io,
    inout logic [1:0] 					     spi_csb_io,
    inout logic 					     spi_sck_io,
    inout logic 					     spi2_sd_0_io,
    inout logic 					     spi2_sd_1_io,
    inout logic 					     spi2_sd_2_io,
    inout logic 					     spi2_sd_3_io,
    inout logic [1:0] 					     spi2_csb_o,
    inout logic 					     spi2_sck_o,

    inout logic 					     i2c_scl_io,
    inout logic 					     i2c_sda_io,

    inout logic 					     pdm2pcm_clk_io,
    inout logic 					     pdm2pcm_pdm_io,

    inout logic 					     i2s_sck_io,
    inout logic 					     i2s_ws_io,
    inout logic 					     i2s_sd_io,


    output logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] external_subsystem_powergate_switch_o,
    input logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0]  external_subsystem_powergate_switch_ack_i,
    output logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] external_subsystem_powergate_iso_o,

    output logic [31:0] 				     exit_value_o,
    inout logic 					     exit_valid_o

   );
   
  import obi_pkg::*;
  import reg_pkg::*;
  import keccak_x_heep_pkg::*;

  // External xbar master/slave and peripheral ports
  // obi_req_t [keccak_x_heep_pkg::EXT_XBAR_NMASTER-1:0] ext_xbar_master_req;
  // obi_resp_t [keccak_x_heep_pkg::EXT_XBAR_NMASTER-1:0] ext_xbar_master_resp;
  // obi_req_t ext_xbar_slave_req;
  // obi_resp_t ext_xbar_slave_resp;
  reg_req_t ext_periph_slave_req;
  reg_rsp_t ext_periph_slave_resp;

  // External interrupts
  logic [core_v_mini_mcu_pkg::NEXT_INT-1:0] ext_intr_vector;

  // External subsystems
  logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] external_subsystem_rst_n;
  logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] external_ram_banks_set_retentive;

  // eXtension Interface
   if_xif #() ext_if ();
  
  always_comb begin
    // All interrupt lines set to zero by default
    for (int i = 0; i < core_v_mini_mcu_pkg::NEXT_INT; i++) begin
      ext_intr_vector[i] = 1'b0;
    end
    // Re-assign the interrupt lines used here
    //ext_intr_vector[0] = keccak_int;
  end

  keccak_top keccak_top_i (
      .clk_i,
      .rst_ni,
      .reg_req_i(ext_periph_slave_req),
      .reg_rsp_o(ext_periph_slave_resp)
  );

  x_heep_system #(
      .COREV_PULP(COREV_PULP),
      .FPU(FPU),
      .ZFINX(ZFINX),
      .EXT_XBAR_NMASTER(keccak_x_heep_pkg::EXT_XBAR_NMASTER)
  ) x_heep_system_i (
      .clk_i,
      .rst_ni,
      .boot_select_i,
      .execute_from_flash_i,
      .jtag_tck_i,
      .jtag_tms_i,
      .jtag_trst_ni,
      .jtag_tdi_i,
      .jtag_tdo_o,
      .uart_rx_i,
      .uart_tx_o,
      .exit_valid_o,
      .gpio_0_io(gpio_io[0]),
      .gpio_1_io(gpio_io[1]),
      .gpio_2_io(gpio_io[2]),
      .gpio_3_io(gpio_io[3]),
      .gpio_4_io(gpio_io[4]),
      .gpio_5_io(gpio_io[5]),
      .gpio_6_io(gpio_io[6]),
      .gpio_7_io(gpio_io[7]),
      .gpio_8_io(gpio_io[8]),
      .gpio_9_io(gpio_io[9]),
      .gpio_10_io(gpio_io[10]),
      .gpio_11_io(gpio_io[11]),
      .gpio_12_io(gpio_io[12]),
      .gpio_13_io(gpio_io[13]),
      .gpio_14_io(gpio_io[14]),
      .gpio_15_io(gpio_io[15]),
      .gpio_16_io(gpio_io[16]),
      .gpio_17_io(gpio_io[17]),
      .spi_flash_sck_io,
      .spi_flash_cs_0_io(spi_flash_csb_io[0]),
      .spi_flash_cs_1_io(spi_flash_csb_io[1]),
      .spi_flash_sd_0_io(spi_flash_sd_io[0]),
      .spi_flash_sd_1_io(spi_flash_sd_io[1]),
      .spi_flash_sd_2_io(spi_flash_sd_io[2]),
      .spi_flash_sd_3_io(spi_flash_sd_io[3]),
      .spi_sck_io,
      .spi_cs_0_io(spi_csb_io[0]),
      .spi_cs_1_io(spi_csb_io[1]),
      .spi_sd_0_io(spi_sd_io[0]),
      .spi_sd_1_io(spi_sd_io[1]),
      .spi_sd_2_io(spi_sd_io[2]),
      .spi_sd_3_io(spi_sd_io[3]),
      .pdm2pcm_pdm_io,
      .pdm2pcm_clk_io,
      .i2s_sck_io(i2s_sck_io),
      .i2s_ws_io(i2s_ws_io),
      .i2s_sd_io(i2s_sd_io),
      .spi2_cs_0_io(spi2_csb_o[0]),
      .spi2_cs_1_io(spi2_csb_o[1]),
      .spi2_sck_io(spi_sck_io),
      .spi2_sd_0_io(spi2_sd_0_io),
      .spi2_sd_1_io(spi2_sd_1_io),
      .spi2_sd_2_io(spi2_sd_2_io),
      .spi2_sd_3_io(spi2_sd_3_io),
      .i2c_scl_io(gpio_io[19]),
      .i2c_sda_io(gpio_io[18]),
      .exit_value_o,
      .ext_peripheral_slave_req_o(ext_periph_slave_req),
      .ext_peripheral_slave_resp_i(ext_periph_slave_resp),
      .ext_xbar_slave_resp_i('0),
      .ext_xbar_master_req_i('0),
      .external_subsystem_powergate_switch_o,
      .external_subsystem_powergate_switch_ack_i,
      .external_subsystem_powergate_iso_o,
      .external_subsystem_rst_no(external_subsystem_rst_n),
      .external_ram_banks_set_retentive_o(external_ram_banks_set_retentive),
      .intr_vector_ext_i('0),
      .xif_compressed_if(ext_if),
      .xif_issue_if(ext_if),
      .xif_commit_if(ext_if),
      .xif_mem_if(ext_if),
      .xif_mem_result_if(ext_if),
      .xif_result_if(ext_if)
  );

endmodule  
