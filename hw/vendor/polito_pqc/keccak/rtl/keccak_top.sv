//
// keccak_top: keccak accelerator top-level. 
// Designed by Alessandra Dolmeta, Mattia Mirigaldi
// alessandra.dolmeta@polito.it, mattiamirigaldi.98017@gmail.com
//

module keccak_top 
	import keccak_reg_pkg::*;
	import reg_pkg::*;
(
	input logic clk_i,
	input logic rst_ni,
	// APB interface
    input  reg_req_t reg_req_i,
    output reg_rsp_t reg_rsp_o
);
   
	keccak_reg2hw_t reg_file_to_ip;
	keccak_hw2reg_t ip_to_reg_file;

	keccak_reg_top #(
	.reg_req_t(reg_req_t),
	.reg_rsp_t(reg_rsp_t)
	) i_regfile (
		.clk_i,
		.rst_ni,
		.devmode_i(1'b1),
		// From the bus to regfile
		.reg_req_i(reg_req_i),
		.reg_rsp_o(reg_rsp_o),
		
		// Signals from regfile to keccak IP
		.reg2hw(reg_file_to_ip),
		.hw2reg(ip_to_reg_file) 
	);

        
   // wiring signals between control unit and ip
   wire logic [1599:0] din_keccak, dout_keccak;
   assign din_keccak = reg_file_to_ip.din;
			       			        	
	keccak i_keccak (
		.clk(clk_i),
		.rst_n(rst_ni),
		.start(reg_file_to_ip.ctrl.q),
		.din(din_keccak),
		.dout(dout_keccak),
		.status_d(ip_to_reg_file.status.d),
		.status_de(ip_to_reg_file.status.de)	 
	);

  assign ip_to_reg_file.dout = dout_keccak;
   
  
endmodule : keccak_top
