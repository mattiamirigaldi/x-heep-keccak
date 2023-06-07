
echo "Generating Keccak registers RTL"
python3 utilities/lowrisc_opentitan/regtool.py -r -t rtl/gen_sv data/keccak_regs.hjson
echo "Generating Keccak registers SW"
python3 utilities/lowrisc_opentitan/regtool.py --cdefines -o keccak_auto.h data/keccak_regs.hjson
