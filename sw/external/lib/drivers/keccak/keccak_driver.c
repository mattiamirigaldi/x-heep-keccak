#include <stdint.h>
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>

#include "keccak_x_heep.h"
#include "core_v_mini_mcu.h"
#include "keccak_driver.h"
#include "keccak_auto.h"
#include "stats.h"

// To manage interrupt
#include "csr.h"
#include "rv_plic.h"
#include "rv_plic_regs.h"
#include "rv_plic_structs.h"
#include "hart.h"

#define KECCAK_BUSY 0 

// Interrupt controller variables
plic_result_t plic_res;
plic_irq_id_t intr_num;

void handler_irq_ext(){
  printf("D\n");
}

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
  
void KeccakF1600_StatePermute(uint32_t Din[50], uint32_t Dout[50])
{
  uint32_t volatile *Din_reg_start = (uint32_t*)KECCAK_DIN_START_ADDR;
  uint32_t volatile *ctrl_reg = (uint32_t*)KECCAK_CTRL_START_ADDR;
  uint32_t volatile *status_reg = (uint32_t*)KECCAK_STATUS_START_ADDR;
  uint32_t current_status;
  uint32_t volatile *Dout_reg_start = (uint32_t*)KECCAK_DOUT_START_ADDR;
  unsigned int instr, cycles, ldstall, jrstall, imstall;

  printf("Interrupt id : %d\n", EXT_INTR_0);
  printf("Init the PLIC...");
  plic_res = plic_Init();

  if (plic_res != kPlicOk) {
      return -1;
  }
  // Keccak accelerator send interrupt on ext_intr line 0
  
  // Set Keccak priority to 1 (target threshold is by default 0) to trigger an interrupt to the target (the processor)
    plic_res = plic_irq_set_priority(EXT_INTR_0, 1);
    if (plic_res == kPlicOk) {
        printf("success\n");
    } else {
        printf("fail\n;");
    }

  // Enable the interrupt in reg 0 
  printf("Enable Keccak interrupt...");
  plic_res = plic_irq_set_enabled(EXT_INTR_0, kPlicToggleEnabled);
  if (plic_res == kPlicOk) {
      printf("Success\n");
  } else {
      printf("Fail\n;");
  }

  // Enable interrupt on processor side
  // Enable global interrupt for machine-level interrupts
  CSR_SET_BITS(CSR_REG_MSTATUS, 0x8);
  // Set mie.MEIE bit to one to enable machine-level external interrupts
  const uint32_t mask = 1 << 11;//IRQ_EXT_ENABLE_OFFSET;
  CSR_SET_BITS(CSR_REG_MIE, mask);

  printf("!\n");
  CSR_WRITE(CSR_REG_MCYCLE, 0);
  printf("!\n");
  for (int i = 0; i<50; i++)
  {
     Din_reg_start[i] = Din[i];
  }
  printf("!\n");
  asm volatile ("": : : "memory");
  *ctrl_reg = 1 << KECCAK_CTRL_START_BIT;
  asm volatile ("": : : "memory");
  *ctrl_reg = 0 << KECCAK_CTRL_START_BIT;
  printf("!\n");
  // Busy waiting till the Keccak has finished permutation
  //do {
  //  printf(".\n");
  //	  current_status = (*status_reg)&(1<<KECCAK_STATUS_STATUS_BIT);
  //} while ( current_status == KECCAK_BUSY);

  // Wait till keccak is done
  while(plic_intr_flag==0) {
      wait_for_interrupt();
  }
  printf("Keccak finished...\r\n");
  printf("!\n");
  for (volatile int i = 0; i<50; i++){
     Dout[i] = Dout_reg_start[i];	
  }
  printf("!\n");
  // stop the HW counter used for monitoring
  CSR_READ(CSR_REG_MCYCLE, &cycles);
  printf("Number of clock cycles : %d\n", cycles);
  //printf("Number of instructions : %d\nNumber of clock cycles: %d\nCPI: %f%f\n",instr_cnt, cycles_cnt, (float) instr_cnt/cycles_cnt);
  
}
