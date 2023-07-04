// Copyright 2022 EPFL
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

`ifdef USE_UPF
import UPF::*;
`endif

module testharness #(
    parameter COREV_PULP                  = 0,
    parameter FPU                         = 0,
    parameter ZFINX                       = 0,
    parameter X_EXT                       = 0,         // eXtension interface in cv32e40x
    parameter JTAG_DPI                    = 0,
    parameter USE_EXTERNAL_DEVICE_EXAMPLE = 1,
    parameter CLK_FREQUENCY               = 'd100_000  //KHz
) (
    inout wire clk_i,
    inout wire rst_ni,

    inout wire boot_select_i,
    inout wire execute_from_flash_i,

    inout  wire         jtag_tck_i,
    inout  wire         jtag_tms_i,
    inout  wire         jtag_trst_ni,
    inout  wire         jtag_tdi_i,
    inout  wire         jtag_tdo_o,
    output logic [31:0] exit_value_o,
    inout  wire         exit_valid_o
);

  `include "tb_util.svh"

  import obi_pkg::*;
  import reg_pkg::*;
  import testharness_pkg::*;
  import addr_map_rule_pkg::*;

  localparam SWITCH_ACK_LATENCY = 15;
  localparam EXT_XBAR_NMASTER_RND = USE_EXTERNAL_DEVICE_EXAMPLE ? testharness_pkg::EXT_XBAR_NMASTER : 1;
  localparam HEEP_EXT_XBAR_NMASTER = USE_EXTERNAL_DEVICE_EXAMPLE ? testharness_pkg::EXT_XBAR_NMASTER : 0;

  localparam int unsigned LOG_EXT_XBAR_NSLAVE = EXT_XBAR_NSLAVE > 32'd1 ? $clog2(
      EXT_XBAR_NSLAVE
  ) : 32'd1;

  localparam EXT_DOMAINS_RND = core_v_mini_mcu_pkg::EXTERNAL_DOMAINS == 0 ? 1 : core_v_mini_mcu_pkg::EXTERNAL_DOMAINS;
  localparam NEXT_INT_RND = core_v_mini_mcu_pkg::NEXT_INT == 0 ? 1 : core_v_mini_mcu_pkg::NEXT_INT;
  
 
  wire uart_rx;
  wire uart_tx;
  logic sim_jtag_enable = (JTAG_DPI == 1);
  wire sim_jtag_tck;
  wire sim_jtag_tms;
  wire sim_jtag_trst;
  wire sim_jtag_tdi;
  wire sim_jtag_tdo;
  wire sim_jtag_trstn;
  wire [31:0] gpio;


  logic [EXT_PERIPHERALS_PORT_SEL_WIDTH-1:0] ext_periph_select;

  // External xbar master/slave and peripheral ports
  obi_req_t [EXT_XBAR_NMASTER_RND-1:0] ext_master_req;
  obi_req_t [EXT_XBAR_NMASTER_RND-1:0] heep_slave_req;
  obi_resp_t [EXT_XBAR_NMASTER_RND-1:0] ext_master_resp;
  obi_resp_t [EXT_XBAR_NMASTER_RND-1:0] heep_slave_resp;
  obi_req_t heep_core_instr_req;
  obi_resp_t heep_core_instr_resp;
  obi_req_t heep_core_data_req;
  obi_resp_t heep_core_data_resp;
  obi_req_t heep_debug_master_req;
  obi_resp_t heep_debug_master_resp;
  obi_req_t heep_dma_read_ch0_req;
  obi_resp_t heep_dma_read_ch0_resp;
  obi_req_t heep_dma_write_ch0_req;
  obi_resp_t heep_dma_write_ch0_resp;
  obi_req_t heep_dma_addr_ch0_req;
  obi_resp_t heep_dma_addr_ch0_resp;
  obi_req_t [EXT_XBAR_NSLAVE-1:0] ext_slave_req;
  obi_resp_t [EXT_XBAR_NSLAVE-1:0] ext_slave_resp;


  // Since not used an external device with master port 
  assign ext_master_req[testharness_pkg::EXT_MASTER0_IDX].req = '0;
  assign ext_master_req[testharness_pkg::EXT_MASTER0_IDX].we = '0;
  assign ext_master_req[testharness_pkg::EXT_MASTER0_IDX].be = '0;
  assign ext_master_req[testharness_pkg::EXT_MASTER0_IDX].addr = '0;
  assign ext_master_req[testharness_pkg::EXT_MASTER0_IDX].wdata = '0;

   
  // External subsystems
  logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] external_subsystem_powergate_switch;
  logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] external_subsystem_powergate_switch_ack;
  logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] external_subsystem_powergate_iso;  
  logic [EXT_DOMAINS_RND-1:0] external_subsystem_rst_n;
  logic [EXT_DOMAINS_RND-1:0] external_ram_banks_set_retentive;

  `ifdef USE_UPF
    initial begin
      $display("%t: All Power Supply ON", $time);
      supply_on("VDD", 1.2);
      supply_on("VSS", 0);
    end
  `endif
 

  keccak_x_heep_top #(
      .COREV_PULP(COREV_PULP),
      .FPU(FPU),
      .ZFINX(ZFINX)
  ) keccak_x_heep_top_i (
      .clk_i,
      .rst_ni,

      .boot_select_i,
      .execute_from_flash_i,

      .jtag_tck_i  (sim_jtag_tck),
      .jtag_tms_i  (sim_jtag_tms),
      .jtag_trst_ni(sim_jtag_trstn),
      .jtag_tdi_i  (sim_jtag_tdi),
      .jtag_tdo_o  (sim_jtag_tdo),

      .gpio_io(gpio),

      .uart_rx_i(uart_rx),
      .uart_tx_o(uart_tx),

      .ext_xbar_master_req_i(heep_slave_req),
      .ext_xbar_master_resp_o(heep_slave_resp),
      .ext_core_instr_req_o(heep_core_instr_req),
      .ext_core_instr_resp_i(heep_core_instr_resp),
      .ext_core_data_req_o(heep_core_data_req),
      .ext_core_data_resp_i(heep_core_data_resp),
      .ext_debug_master_req_o(heep_debug_master_req),
      .ext_debug_master_resp_i(heep_debug_master_resp),
      .ext_dma_read_ch0_req_o(heep_dma_read_ch0_req),
      .ext_dma_read_ch0_resp_i(heep_dma_read_ch0_resp),
      .ext_dma_write_ch0_req_o(heep_dma_write_ch0_req),
      .ext_dma_write_ch0_resp_i(heep_dma_write_ch0_resp),
      .ext_dma_addr_ch0_req_o(heep_dma_addr_ch0_req),
      .ext_dma_addr_ch0_resp_i(heep_dma_addr_ch0_resp),

      .external_subsystem_powergate_switch_o(external_subsystem_powergate_switch),
      .external_subsystem_powergate_switch_ack_i(external_subsystem_powergate_switch_ack),
      .external_subsystem_powergate_iso_o(external_subsystem_powergate_iso),
      .external_subsystem_rst_no(external_subsystem_rst_n),
      .external_ram_banks_set_retentive_o(external_ram_banks_set_retentive),

      .exit_value_o,
      .exit_valid_o
  );

   // Testbench external bus
  // ----------------------
  // The external bus connects the external peripherals among them and to
  // the corresponding X-HEEP slave port (to the internal system bus).
  ext_bus #(
      .EXT_XBAR_NMASTER(EXT_XBAR_NMASTER),
      .EXT_XBAR_NSLAVE (EXT_XBAR_NSLAVE)
  ) ext_bus_i (
      .clk_i                    (clk_i),
      .rst_ni                   (rst_ni),
      .addr_map_i               (EXT_XBAR_ADDR_RULES),
      .default_idx_i            (SLOW_MEMORY_IDX[LOG_EXT_XBAR_NSLAVE-1:0]),
      .heep_core_instr_req_i    (heep_core_instr_req),
      .heep_core_instr_resp_o   (heep_core_instr_resp),
      .heep_core_data_req_i     (heep_core_data_req),
      .heep_core_data_resp_o    (heep_core_data_resp),
      .heep_debug_master_req_i  (heep_debug_master_req),
      .heep_debug_master_resp_o (heep_debug_master_resp),
      .heep_dma_read_ch0_req_i  (heep_dma_read_ch0_req),
      .heep_dma_read_ch0_resp_o (heep_dma_read_ch0_resp),
      .heep_dma_write_ch0_req_i (heep_dma_write_ch0_req),
      .heep_dma_write_ch0_resp_o(heep_dma_write_ch0_resp),
      .heep_dma_addr_ch0_req_i  (heep_dma_addr_ch0_req),
      .heep_dma_addr_ch0_resp_o (heep_dma_addr_ch0_resp),
      .ext_master_req_i         (ext_master_req),
      .ext_master_resp_o        (ext_master_resp),
      .heep_slave_req_o         (heep_slave_req),
      .heep_slave_resp_i        (heep_slave_resp),
      .ext_slave_req_o          (ext_slave_req),
      .ext_slave_resp_i         (ext_slave_resp)
  );

  logic pdm;

  //pretending to be SWITCH CELLs that delay by SWITCH_ACK_LATENCY cycles the ACK signal
  logic
      tb_cpu_subsystem_powergate_switch_ack[SWITCH_ACK_LATENCY+1],
      tb_peripheral_subsystem_powergate_switch_ack[SWITCH_ACK_LATENCY+1];
  logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] tb_memory_subsystem_banks_powergate_switch_ack[SWITCH_ACK_LATENCY+1];
  logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] tb_external_subsystem_powergate_switch_ack[SWITCH_ACK_LATENCY+1];
  logic delayed_tb_cpu_subsystem_powergate_switch_ack;
  logic delayed_tb_peripheral_subsystem_powergate_switch_ack;
  logic [core_v_mini_mcu_pkg::NUM_BANKS-1:0] delayed_tb_memory_subsystem_banks_powergate_switch_ack;
  logic [core_v_mini_mcu_pkg::EXTERNAL_DOMAINS-1:0] delayed_tb_external_subsystem_powergate_switch_ack;

  always_ff @(negedge clk_i) begin
    tb_cpu_subsystem_powergate_switch_ack[0] <= keccak_x_heep_top_i.x_heep_system_i.cpu_subsystem_powergate_switch;
    tb_peripheral_subsystem_powergate_switch_ack[0] <= keccak_x_heep_top_i.x_heep_system_i.peripheral_subsystem_powergate_switch;
    tb_memory_subsystem_banks_powergate_switch_ack[0] <= keccak_x_heep_top_i.x_heep_system_i.memory_subsystem_banks_powergate_switch;
    tb_external_subsystem_powergate_switch_ack[0] <= external_subsystem_powergate_switch;
    for (int i = 0; i < SWITCH_ACK_LATENCY; i++) begin
      tb_memory_subsystem_banks_powergate_switch_ack[i+1] <= tb_memory_subsystem_banks_powergate_switch_ack[i];
      tb_cpu_subsystem_powergate_switch_ack[i+1] <= tb_cpu_subsystem_powergate_switch_ack[i];
      tb_peripheral_subsystem_powergate_switch_ack[i+1] <= tb_peripheral_subsystem_powergate_switch_ack[i];
      tb_external_subsystem_powergate_switch_ack[i+1] <= tb_external_subsystem_powergate_switch_ack[i];
    end
  end

  assign delayed_tb_cpu_subsystem_powergate_switch_ack = tb_cpu_subsystem_powergate_switch_ack[SWITCH_ACK_LATENCY];
  assign delayed_tb_peripheral_subsystem_powergate_switch_ack = tb_peripheral_subsystem_powergate_switch_ack[SWITCH_ACK_LATENCY];
  assign delayed_tb_memory_subsystem_banks_powergate_switch_ack = tb_memory_subsystem_banks_powergate_switch_ack[SWITCH_ACK_LATENCY];
  assign delayed_tb_external_subsystem_powergate_switch_ack = tb_external_subsystem_powergate_switch_ack[SWITCH_ACK_LATENCY];

  always_comb begin
`ifndef VERILATOR
    force keccak_x_heep_top_i.x_heep_system_i.core_v_mini_mcu_i.cpu_subsystem_powergate_switch_ack_i = delayed_tb_cpu_subsystem_powergate_switch_ack;
    force keccak_x_heep_top_i.x_heep_system_i.core_v_mini_mcu_i.peripheral_subsystem_powergate_switch_ack_i = delayed_tb_peripheral_subsystem_powergate_switch_ack;
    force keccak_x_heep_top_i.x_heep_system_i.core_v_mini_mcu_i.memory_subsystem_banks_powergate_switch_ack_i = delayed_tb_memory_subsystem_banks_powergate_switch_ack;
    force external_subsystem_powergate_switch_ack = delayed_tb_external_subsystem_powergate_switch_ack;
`else
    keccak_x_heep_top_i.x_heep_system_i.cpu_subsystem_powergate_switch_ack = delayed_tb_cpu_subsystem_powergate_switch_ack;
    keccak_x_heep_top_i.x_heep_system_i.peripheral_subsystem_powergate_switch_ack = delayed_tb_peripheral_subsystem_powergate_switch_ack;
    keccak_x_heep_top_i.x_heep_system_i.memory_subsystem_banks_powergate_switch_ack = delayed_tb_memory_subsystem_banks_powergate_switch_ack;
    external_subsystem_powergate_switch_ack = delayed_tb_external_subsystem_powergate_switch_ack;
`endif
  end

  uartdpi #(
      .BAUD('d256000),
      .FREQ(CLK_FREQUENCY * 1000),  //Hz
      .NAME("uart0")
  ) i_uart0 (
      .clk_i,
      .rst_ni,
      .tx_o(uart_rx),
      .rx_i(uart_tx)
  );

  // jtag calls from dpi
  SimJTAG #(
      .TICK_DELAY(1),
      .PORT      (4567)
  ) i_sim_jtag (
      .clock(clk_i),
      .reset(~rst_ni),
      .enable(sim_jtag_enable),
      .init_done(rst_ni),
      .jtag_TCK(sim_jtag_tck),
      .jtag_TMS(sim_jtag_tms),
      .jtag_TDI(sim_jtag_tdi),
      .jtag_TRSTn(sim_jtag_trstn),
      .jtag_TDO_data(sim_jtag_tdo),
      .jtag_TDO_driven(1'b1),
      .exit()
  );


endmodule  // testharness
