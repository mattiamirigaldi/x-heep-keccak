
echo "Generating Keccak registers RTL"
/home/mattia.mirigaldi/projects/pqc_x_heep/hw/vendor/esl_epfl_x_heep/hw/vendor/pulp_platform_register_interface/vendor/lowrisc_opentitan/util/regtool.py -r -t rtl/gen_sv data/keccak_regs.hjson
#python3 utilities/register_interface/vendor/lowrisc_opentitan/util/regtool.py -r -t rtl/gen_sv data/keccak_regs.hjson
#python3 utilities/lowrisc_opentitan/regtool.py -r -t rtl/gen_sv data/keccak_regs.hjson
echo "Generating Keccak registers SW"
/home/mattia.mirigaldi/projects/pqc_x_heep/hw/vendor/esl_epfl_x_heep/hw/vendor/pulp_platform_register_interface/vendor/lowrisc_opentitan/util/regtool.py --cdefines -o keccak_auto.h data/keccak_regs.hjson
#python3 utilities/register_interface/vendor/lowrisc_opentitan/util/regtool.py --cdefines -o keccak_auto.h data/keccak_regs.hjson
#python3 utilities/lowrisc_opentitan/regtool.py --cdefines -o keccak_auto.h data/keccak_regs.hjson
