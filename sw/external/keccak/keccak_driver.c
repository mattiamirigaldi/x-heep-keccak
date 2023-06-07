#include <stdint.h>
#include <stdio.h>
#include <keccak_driver.h>
#include <keccak_auto.h>

#define KECCAK_BUSY 0 

void set_input(uint32_t* Din){
   uint32_t volatile *Din_reg_start = (uint32_t*)KECCAK_DIN_START_ADDR;
   for (int i = 0; i<50; i++)
   {
     Din_reg_start[i] = Din[i];
   }
}

void trigger_keccak(void)
{
  uint32_t volatile * ctrl_reg = (uint32_t*)KECCAK_CTRL_START_ADDR;
  asm volatile ("": : : "memory");
  *ctrl_reg = 1 << KECCAK_CTRL_START_BIT;
  asm volatile ("": : : "memory");
}

void poll_done(void){
   uint32_t volatile *status_reg = (uint32_t*)KECCAK_STATUS_START_ADDR;
   uint32_t current_status;
   //printf("Keccak : Checking if keccak is busy, current status %d\n", status_reg);
   // Busy waiting till the Keccak is ready to start
   do {
	current_status = (*status_reg)&(1<<KECCAK_STATUS_STATUS_BIT);
   } while ( current_status == KECCAK_BUSY);
   //printf("Keccak : ready\n");
}

void get_result(uint32_t* Dout){
   
   uint32_t volatile *Dout_reg_start = (uint32_t*)KECCAK_DOUT_START_ADDR;
   for (volatile int i = 0; i<50; i++){
     Dout[i] = Dout_reg_start[i];	
		
   }
}


void KeccakF1600_StatePermute(uint32_t Din[50], uint32_t Dout[50] ){
	set_input(Din);
	trigger_keccak();
	poll_done();
	get_result(Dout);	
}
