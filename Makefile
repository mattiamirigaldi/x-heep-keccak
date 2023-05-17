# Copyright EPFL contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0


# Makefile to generates keccak-x-heep files and build the design with fusesoc

.PHONY: clean help

TARGET ?= sim

# 1 external domain for the KECCAK
EXTERNAL_DOMAINS = 1

# Generates mcu files
mcu-gen:
	cd hw/vendor/esl_epfl_x_heep && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir hw/core-v-mini-mcu/include --cpu $(CPU) --bus $(BUS) --memorybanks $(MEMORY_BANKS) --external_domains $(EXTERNAL_DOMAINS) --pkg-sv hw/core-v-mini-mcu/include/core_v_mini_mcu_pkg.sv.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir hw/core-v-mini-mcu/ --memorybanks $(MEMORY_BANKS) --tpl-sv hw/core-v-mini-mcu/system_bus.sv.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir ../../../tb/ --memorybanks $(MEMORY_BANKS) --tpl-sv ../../../tb/tb_util.svh.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir hw/system/ --tpl-sv hw/system/pad_ring.sv.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir hw/core-v-mini-mcu/ --tpl-sv hw/core-v-mini-mcu/core_v_mini_mcu.sv.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir hw/system/ --tpl-sv hw/system/x_heep_system.sv.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir sw/device/lib/runtime --cpu $(CPU) --memorybanks $(MEMORY_BANKS) --header-c sw/device/lib/runtime/core_v_mini_mcu.h.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir sw/linker --memorybanks $(MEMORY_BANKS) --linker_script sw/linker/link.ld.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir . --memorybanks $(MEMORY_BANKS) --pkg-sv ./core-v-mini-mcu.upf.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir hw/ip/power_manager/rtl --memorybanks $(MEMORY_BANKS) --external_domains $(EXTERNAL_DOMAINS) --pkg-sv hw/ip/power_manager/data/power_manager.sv.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir hw/ip/power_manager/data --memorybanks $(MEMORY_BANKS) --external_domains $(EXTERNAL_DOMAINS) --pkg-sv hw/ip/power_manager/data/power_manager.hjson.tpl  && \
	bash -c "cd hw/ip/power_manager; source power_manager_gen.sh; cd ../../../"  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir sw/device/lib/drivers/power_manager --memorybanks $(MEMORY_BANKS) --external_domains $(EXTERNAL_DOMAINS) --pkg-sv sw/device/lib/drivers/power_manager/data/power_manager.h.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir hw/system/pad_control/data --pkg-sv hw/system/pad_control/data/pad_control.hjson.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir hw/system/pad_control/rtl --pkg-sv hw/system/pad_control/rtl/pad_control.sv.tpl  && \
	bash -c "cd hw/system/pad_control; source pad_control_gen.sh; cd ../../../"  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir sw/linker --memorybanks $(MEMORY_BANKS) --linker_script sw/linker/link_flash_exec.ld.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --outdir sw/linker --memorybanks $(MEMORY_BANKS) --linker_script sw/linker/link_flash_load.ld.tpl;
	$(MAKE) verible

# Runs verible formating
verible:
	util/format-verible;

app-helloworld:
	$(MAKE) -C sw x_heep_applications/hello_world/hello_world.hex  TARGET=$(TARGET)

app-keccak:
	$(MAKE) -C sw applications/keccak_test/main.hex  TARGET=$(TARGET)

# Tools specific fusesoc call

# Simulation
verilator-sim: mcu-gen
	fusesoc --cores-root . run --no-export --target=sim --tool=verilator $(FUSESOC_FLAGS) --setup --build keccak-x-heep 2>&1 | tee buildsim.log

questasim-sim: mcu-gen
	fusesoc --cores-root . run --no-export --target=sim --tool=modelsim $(FUSESOC_FLAGS) --setup --build keccak-x-heep 2>&1 | tee buildsim.log

questasim-sim-opt: questasim-sim
	$(MAKE) -C build/system_keccak_x_heep/sim-modelsim opt

vcs-sim:
	fusesoc --cores-root . run --no-export --target=sim --tool=vcs $(FUSESOC_FLAGS) --setup --build keccak-x-heep 2>&1 | tee buildsim.log

run-helloworld-verilator: mcu-gen verilator-sim app-helloworld
	cd ./build/system_keccak_x_heep/sim-verilator; \
	./Vtestharness +firmware=../../../sw/x_heep_applications/hello_world/hello_world.hex; \
	cat uart0.log; \
	cd ../../..;

run-keccak-verilator: mcu-gen verilator-sim app-keccak
	cd ./build/system_keccak_x_heep/sim-verilator; \
	./Vtestharness +firmware=../../../sw/applications/keccak_test/main.hex; \
	cat uart0.log; \
	cd ../../..;

run-helloworld-questasim: mcu-gen questasim-sim app-helloworld
	cd ./build/system_keccak_x_heep/sim-modelsim; \
	make run PLUSARGS="c firmware=../../../sw/x_heep_applications/hello_world/hello_world.hex"; \
	cat uart0.log; \
	cd ../../..;

run-keccak-questasim: mcu-gen questasim-sim app-keccak
	cd ./build/system_keccak_x_heep/sim-modelsim; \
	make run-gui PLUSARGS="c firmware=../../../sw/applications/keccak_test/main.hex"; \
	cat uart0.log; \
	cd ../../..;
 


help:
	@echo "SIMULATION BUILD TARGETS"
	@echo "Build for simulation :"
	@echo "\tmake [verilator,questasim,vcs]-sim"
	@echo "\tex: make verilator-sim"
	@echo "Change cpu and/or bus:"
	@echo "\tmake <toolname>-sim CPU=[cv32e20(default),cv32e40p] BUS=[onetoM(default),NtoM]"
	@echo "\tex: make verilator-sim CPU=cv32e40p BUS=NtoM)"
	@echo "Add fusesoc flags:"
	@echo "\tmake <toolname>-sim FUSESOC_FLAGS=\"--flag=<flagname0> --flag=<flagname1>\""
	@echo "\tex: make verilator-sim FUSESOC_FLAGS=\"--flag=use_external_device_example --flag=use_jtag_dpi\""
	@echo ""
	@echo "SOFTWARE BUILD TARGETS"
	@echo "Build example applications:"
	@echo "\tmake app-[helloworld,cgra-test,cgra-dbl-search]"
	@echo "\tex: make app-helloworld"
	@echo ""
	@echo "RUN BASIC EXAMPLES"
	@echo "\tex: make run-helloworld-<verilator,questasim>"
	@echo "\tex: make run-cgra-test-<verilator,questasim>"

clean: clean-app clean-sim

clean-sim:
	@rm -rf build

clean-app:
	$(MAKE) -C sw clean
