# Copyright EPFL contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0


# Makefile to generates keccak-x-heep files and build the design with fusesoc

MAKE                       = make

# Get the absolute path
mkfile_path := $(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")

# Include the self-documenting tool
FILE=$(mkfile_path)/Makefile
include $(mkfile_path)/util/generate-makefile-help

# Setup to autogenerate python virtual environment
VENVDIR?=$(WORKDIR)/.venv
REQUIREMENTS_TXT?=$(wildcard python-requirements.txt)
include Makefile.venv

# FUSESOC and Python values (default)
ifndef CONDA_DEFAULT_ENV
$(info USING VENV)
FUSESOC = $(PWD)/$(VENV)/fusesoc
PYTHON  = python
else
$(info USING MINICONDA $(CONDA_DEFAULT_ENV))
FUSESOC := $(shell which fusesoc)
PYTHON  := $(shell which python)
endif

# Linker options are 'on_chip' (default),'flash_load','flash_exec','freertos'
LINKER   ?= on_chip

# Target options are 'sim' (default) and 'pynq-z2'
TARGET   ?= sim
PAD_CFG  ?= pad_cfg.hjson
PAD_CFG_LINUX  ?= hw/linux_femu/pad_cfg.hjson
#MCU_CFG  ?= hw/vendor/esl_epfl_x_heep/mcu_cfg.hjson
MCU_CFG  ?= mcu_cfg.hjson

# Compiler options are 'gcc' (default) and 'clang'
COMPILER ?= gcc

# Compiler prefix options are 'riscv32-unknown-' (default)
COMPILER_PREFIX ?= riscv32-unknown-

# Arch options are any RISC-V ISA string supported by the CPU. Default 'rv32imc'
ARCH     ?= rv32imc

# Path relative from the location of sw/Makefile from which to fetch source files. The directory of that file is the default value.
SOURCE 	 ?= "."

# Application options
USE_DMA   ?= 1

# 1 external domain for the KECCAK
EXTERNAL_DOMAINS = 1

## @section Installation

## Generates mcu files core-v-mini-mcu files and build the design with fusesoc
## @param CPU=[cv32e20(default),cv32e40p,cv32e40x]
## @param BUS=[onetoM(default),NtoM]
## @param MEMORY_BANKS=[2(default) to (16 - MEMORY_BANKS_IL)]
## @param MEMORY_BANKS_IL=[0(default),2,4,8]
mcu-gen:
	cd hw/vendor/esl_epfl_x_heep && \
	python util/mcu_gen.py --pads_cfg $(PAD_CFG) --cfg $(MCU_CFG) --outdir hw/core-v-mini-mcu/include --cpu $(CPU) --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --external_domains $(EXTERNAL_DOMAINS) --pkg-sv hw/core-v-mini-mcu/include/core_v_mini_mcu_pkg.sv.tpl && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir hw/core-v-mini-mcu/ --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --tpl-sv hw/core-v-mini-mcu/system_bus.sv.tpl  && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir hw/core-v-mini-mcu/ --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --tpl-sv hw/core-v-mini-mcu/system_xbar.sv.tpl  && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir hw/core-v-mini-mcu/ --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --tpl-sv hw/core-v-mini-mcu/memory_subsystem.sv.tpl  && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir hw/core-v-mini-mcu/ --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --tpl-sv hw/core-v-mini-mcu/peripheral_subsystem.sv.tpl  && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir tb/ --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --tpl-sv tb/tb_util.svh.tpl  && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir hw/system/ --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --tpl-sv hw/system/pad_ring.sv.tpl && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir hw/core-v-mini-mcu/ --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --tpl-sv hw/core-v-mini-mcu/core_v_mini_mcu.sv.tpl  && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir hw/system/ --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --tpl-sv hw/system/x_heep_system.sv.tpl  && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir sw/device/lib/runtime --cpu $(CPU) --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --header-c sw/device/lib/runtime/core_v_mini_mcu.h.tpl  && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir sw/linker --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --linker_script sw/linker/link.ld.tpl  && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir . --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --pkg-sv ./core-v-mini-mcu.upf.tpl  && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir hw/ip/power_manager/rtl --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --external_domains $(EXTERNAL_DOMAINS) --pkg-sv hw/ip/power_manager/data/power_manager.sv.tpl  && \
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG) --outdir hw/ip/power_manager/data --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --external_domains $(EXTERNAL_DOMAINS) --pkg-sv hw/ip/power_manager/data/power_manager.hjson.tpl  && \
	bash -c "cd hw/ip/power_manager; source power_manager_gen.sh; cd ../../../"  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --pads_cfg $(PAD_CFG) --outdir sw/device/lib/drivers/power_manager --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --external_domains $(EXTERNAL_DOMAINS) --pkg-sv sw/device/lib/drivers/power_manager/data/power_manager.h.tpl && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --pads_cfg $(PAD_CFG) --outdir hw/system/pad_control/data --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --pkg-sv hw/system/pad_control/data/pad_control.hjson.tpl && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --pads_cfg $(PAD_CFG) --outdir hw/system/pad_control/rtl --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --pkg-sv hw/system/pad_control/rtl/pad_control.sv.tpl  && \
	bash -c "cd hw/system/pad_control; source pad_control_gen.sh; cd ../../../"  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --pads_cfg $(PAD_CFG) --outdir sw/linker --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --linker_script sw/linker/link_flash_exec.ld.tpl  && \
	python util/mcu_gen.py --cfg mcu_cfg.hjson --pads_cfg $(PAD_CFG) --outdir sw/linker --bus $(BUS) --memorybanks $(MEMORY_BANKS) --memorybanks_il $(MEMORY_BANKS_IL) --linker_script sw/linker/link_flash_load.ld.tpl  && \
	python ./util/structs_periph_gen.py  && \
	$(MAKE) verible


# Runs verible formating
verible:
	cd hw/vendor/esl_epfl_x_heep && \
	util/format-verible;

## @section Linux-Emulation

## Generates FEMU
linux-femu-gen: mcu-gen
	python util/mcu_gen.py --cfg $(MCU_CFG) --pads_cfg $(PAD_CFG_LINUX) --outdir hw/linux_femu/rtl/ --tpl-sv hw/linux_femu/rtl/linux_femu_keccak.sv.tpl
	$(MAKE) verible


# @section simulation

app-helloworld:
	$(MAKE) -C sw x_heep_applications/hello_world/hello_world.hex  TARGET=$(TARGET)

app-keccak:
	$(MAKE) -C sw applications/keccak_test/main.hex  TARGET=$(TARGET) USE_DMA=$(USE_DMA)

app-kyber512: 
	$(MAKE) -C sw applications/kyber512/keygen/keygen.hex TARGET=$(TARGET)

# Tools specific fusesoc call

# Simulation
verilator-sim: mcu-gen
	fusesoc --cores-root . run --no-export --target=sim --tool=verilator $(FUSESOC_FLAGS) --setup --build polito:systems:keccak_pqc 2>&1 | tee buildsim.log

questasim-sim: mcu-gen
	fusesoc --cores-root . run --no-export --target=sim --tool=modelsim $(FUSESOC_FLAGS) --setup --build polito:systems:keccak_pqc 2>&1 | tee buildsim.log

questasim-sim-opt: questasim-sim
	$(MAKE) -C build/systems_keccak-x-heep_0/sim-modelsim opt

vcs-sim:
	fusesoc --cores-root . run --no-export --target=sim --tool=vcs $(FUSESOC_FLAGS) --setup --build pqc-x-heep 2>&1 | tee buildsim.log

run-helloworld-verilator: mcu-gen verilator-sim app-helloworld
	cd ./build/polito_system_keccak_pqc_0/sim-verilator; \
	./Vtestharness +firmware=../../../sw/x_heep_applications/hello_world/hello_world.hex; \
	cat uart0.log; \
	cd ../../..;

run-keccak-verilator: mcu-gen verilator-sim app-keccak
	cd ./build/polito_system_keccak_x_heep/sim-verilator; \
	./Vtestharness +firmware=../../../sw/applications/keccak_test/main.hex; \
	cat uart0.log; \
	cd ../../..;

run-helloworld-questasim: mcu-gen questasim-sim app-helloworld
	cd ./build/polito_systems_keccak_pqc_0/sim-modelsim; \
	make run PLUSARGS="c firmware=../../../sw/x_heep_applications/hello_world/hello_world.hex"; \
	cat uart0.log; \
	cd ../../..;

run-keccak-questasim: mcu-gen questasim-sim app-keccak
	cd ./build/polito_systems_keccak_pqc_0/sim-modelsim; \
	make run PLUSARGS="c firmware=../../../sw/applications/keccak_test/main.hex"; \
	cat uart0.log; \
	cd ../../..;

run-kyber768keygen: mcu-gen verilator-sim
	cd ./build/openhwgroup.org_systems_core-v-mini-mcu_0/sim-verilator; \
	./Vtestharness +firmware=../../../sw/build/main.hex; \
	cat uart0.log; \
	cd ../../..;

## @section Vivado

## Builds (synthesis and implementation) the bitstream for the FPGA version using Vivado
## @param FPGA_BOARD=nexys-a7-100t,pynq-z2
## @param FUSESOC_FLAGS=--flag=<flagname>
vivado-keccak-fpga:
	fusesoc --cores-root . run --no-export --target=$(FPGA_BOARD) $(FUSESOC_FLAGS) --setup --build polito:systems:keccak_pqc 2>&1 | tee buildvivado.log

vivado-keccak-fpga-nobuild:
	$(FUSESOC) --cores-root . run --no-export --target=$(FPGA_BOARD) $(FUSESOC_FLAGS) --setup polito:systems:keccak_pqc 2>&1 | tee buildvivado.log




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
