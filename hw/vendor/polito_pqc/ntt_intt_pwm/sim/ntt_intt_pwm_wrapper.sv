module ntt_intt_pwm_sram_wrapper (
    input  logic                 clk_i,    // Clock
    input  logic                 rst_ni,   // Asynchronous reset active low
    // input ports
    input  logic                 req_i,    // request
    input  logic                 we_i,     // write enable
    input  logic [AddrWidth-1:0] addr_i,   // request address
    input  logic [         31:0] wdata_i,  // write data
    input  logic [          3:0] be_i,     // write byte enable
    input  logic                 set_retentive_i,
    // output ports
    output logic [         31:0] rdata_o   // read data
);

  tc_sram #(
      .NumWords (NumWords),
      .DataWidth(DataWidth),
      .NumPorts (32'd1)
  ) tc_ram_i (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .req_i  (req_i),
      .we_i   (we_i),
      .addr_i (addr_i),
      .wdata_i(wdata_i),
      .be_i   (be_i),
      // output ports
      .rdata_o(rdata_o)
  );


endmodule