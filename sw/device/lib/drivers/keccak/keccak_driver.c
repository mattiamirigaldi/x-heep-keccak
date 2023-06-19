#include <stdint.h>
#include <stdio.h>
#include <stddef.h>


#include "keccak_x_heep.h"
#include "core_v_mini_mcu.h"
#include "keccak_driver.h"
#include "keccak_auto.h"
#include "stats.h"
#include "csr.h"

#define KECCAK_BUSY 0 
  
//void set_input(uint32_t* Din){
//  uint32_t volatile *Din_reg_start = (uint32_t*)KECCAK_DIN_START_ADDR;
//  //printf("Setting Inputs, starting from address %04X\n",KECCAK_DIN_START_ADDR);
//  for (int i = 0; i<50; i++)
//    {
//   Din_reg_start[i] = Din[i];
//    }
//  //printf("Finished setting inputs\n");
//} 
//  
//vo trigger_keccak(void)
//{ 
//  nt32_t volatile *ctrl_reg = (uint32_t*)KECCAK_CTRL_START_ADDR;
//  rintf("Writing crtl to address %04X\n",KECCAK_CTRL_START_ADDR);
//  m volatile ("": : : "memory");
//  trl_reg = 1 << KECCAK_CTRL_START_BIT;
//  intf("ctrl_reg value is %04X\n",*ctrl_reg);
//  m volatile ("": : : "memory");
//  intf("Keccak triggered\n");
//  trl_reg = 0 << KECCAK_CTRL_START_BIT;
//} 
//  
//vo poll_done(void){
//  int32_t volatile *status_reg = (uint32_t*)KECCAK_STATUS_START_ADDR;
//  int32_t current_status;
//  rintf("Keccak : Checking if keccak is busy, current status %d\n", *status_reg);
//  printf("Checking status at address : %04X\n",KECCAK_STATUS_START_ADDR);
//  / Busy waiting till the Keccak is ready to start
//  o {
//  	current_status = (*status_reg)&(1<<KECCAK_STATUS_STATUS_BIT);
//   while ( current_status == KECCAK_BUSY);
//  rintf("Keccak : finished\n");
//} 
//  
//vo get_result(uint32_t* Dout){
//  
//  int32_t volatile *Dout_reg_start = (uint32_t*)KECCAK_DOUT_START_ADDR;
//  or (volatile int i = 0; i<50; i++){
//   Dout[i] = Dout_reg_start[i];	
//  		
//  
//  rintf("Result got\n");
//} 
//  
  
//oid KeccakF1600_StatePermute(uint32_t Din[50], uint32_t Dout[50] ){
//	set_input(Din);
//	trigger_keccak();
//	poll_done();
//	get_result(Dout);
//	return;
//
  
void KeccakF1600_StatePermute(uint32_t Din[50], uint32_t Dout[50] ){
  uint32_t volatile *Din_reg_start = (uint32_t*)KECCAK_DIN_START_ADDR;
  uint32_t volatile *ctrl_reg = (uint32_t*)KECCAK_CTRL_START_ADDR;
  uint32_t volatile *status_reg = (uint32_t*)KECCAK_STATUS_START_ADDR;
  uint32_t current_status;
  uint32_t volatile *Dout_reg_start = (uint32_t*)KECCAK_DOUT_START_ADDR;
  unsigned int instr, cycles, ldstall, jrstall, imstall;

  CSR_WRITE(CSR_REG_MCYCLE, 0);
  for (int i = 0; i<50; i++)
  {
     Din_reg_start[i] = Din[i];
  }

  asm volatile ("": : : "memory");
  *ctrl_reg = 1 << KECCAK_CTRL_START_BIT;
  asm volatile ("": : : "memory");
  *ctrl_reg = 0 << KECCAK_CTRL_START_BIT;
  // Busy waiting till the Keccak has finished permutation
  do {
	  current_status = (*status_reg)&(1<<KECCAK_STATUS_STATUS_BIT);
  } while ( current_status == KECCAK_BUSY);
  
  for (volatile int i = 0; i<50; i++){
     Dout[i] = Dout_reg_start[i];	
  }
  // stop the HW counter used for monitoring
  CSR_READ(CSR_REG_MCYCLE, &cycles);
  printf("Number of clock cycles : %d\n", cycles);
  //printf("Number of instructions : %d\nNumber of clock cycles: %d\nCPI: %f%f\n",instr_cnt, cycles_cnt, (float) instr_cnt/cycles_cnt);
  
}
