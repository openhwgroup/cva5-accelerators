
###############################################################
# Set RISCV_PREFIX to your riscv gcc toolchain
CVA5_DIR ?= $(realpath cva5)
ELF_TO_HW_INIT=$(CVA5_DIR)/tools/elf-to-hw-init.py
RISCV_PREFIX ?= riscv32-unknown-elf-
BITSTREAM ?= cva5/examples/nexys/scripts/cva5-competition-baseline/cva5-competition-baseline.runs/impl_1/system_wrapper.bit
###############################################################

###############################################################
#Verilator Wavefore tracing options
TRACE_ENABLE = False
VERILATOR_TRACE_FILE = logs/verilator_trace.vcd

###############################################################
###############################################################
#No changes needed past this point
###############################################################
###############################################################

###############################################################
#CVA5 core makefile
-include cva5/tools/cva5.mak
ELF_TO_HW_INIT_OPTIONS ?= $(RISCV_PREFIX) 0x80000000 131072
###############################################################

###############################################################
#Embench
EMBENCH_DIR=embench-iot
EMBENCH_LOG_DIR=logs/embench

EMBENCH_BENCHMARKS =  \
aha-mont64 \
crc32 \
cubic \
edn \
huffbench \
matmult-int \
md5sum \
minver \
nbody \
nettle-aes \
nettle-sha256 \
nsichneu \
picojpeg \
primecount \
qrduino \
sglib-combined \
slre \
st \
statemate \
tarfind \
ud \
wikisort

#add file path to benchmarks
embench_bins = $(addprefix $(EMBENCH_DIR)/build/bin/, $(EMBENCH_BENCHMARKS))
embench_hw_init = $(addprefix $(EMBENCH_DIR)/build/bin/, $(addsuffix .hw_init, $(EMBENCH_BENCHMARKS)))
embench_raw_binaries = $(addprefix $(EMBENCH_DIR)/build/bin/, $(addsuffix .rawbinary, $(EMBENCH_BENCHMARKS)))
embench_logs = $(addprefix $(EMBENCH_LOG_DIR)/, $(addsuffix .log, $(EMBENCH_BENCHMARKS)))
embench_hw_logs = $(addprefix $(EMBENCH_LOG_DIR)/, $(addsuffix .hw_log, $(EMBENCH_BENCHMARKS)))

.PHONY: extract-reference-binaries
extract-reference-binaries:
	tar -xf reference-binaries.tar.xz -C embench-iot/build/bin/

#embench benchmarks copied into a bin folder to simplify makefile rules
.PHONY: build-embench
build-embench :
	cd $(EMBENCH_DIR);\
	./build_all.py --clean --builddir=build --arch=riscv32 --chip=generic --board=cva5 --cflags="-nostartfiles -march=rv32imzicsr -mabi=ilp32 -O3" --ldflags="-nostartfiles -Xlinker --defsym=__mem_size=262144" --cc-input-pattern="-c {0}" --user-libs="-lm"
	mkdir -p $(EMBENCH_DIR)/build/bin
	$(foreach x,$(EMBENCH_BENCHMARKS), mv $(EMBENCH_DIR)/build/src/$(x)/$(x) $(EMBENCH_DIR)/build/bin/$(x);)
	$(foreach x,$(EMBENCH_BENCHMARKS), python3 $(ELF_TO_HW_INIT) $(ELF_TO_HW_INIT_OPTIONS) $(EMBENCH_DIR)/build/bin/$(x) $(EMBENCH_DIR)/build/bin/$(x).hw_init $(EMBENCH_DIR)/build/bin/$(x).sim_init;)
		
#Benchmarks built by build_embench
.PHONY : $(embench_bins)
.PHONY : $(embench_hw_init)
.PHONY : $(embench_raw_binaries)

#Run verilator
$(EMBENCH_LOG_DIR)/%.log : $(EMBENCH_DIR)/build/bin/%.hw_init $(CVA5_SIM)
	@echo $< > $@
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $@

run-ALL-verilator: $(embench_logs)
	cat $^ > logs/embench.log
	
#Run hardware
$(EMBENCH_LOG_DIR)/%.hw_log : $(EMBENCH_DIR)/build/bin/%.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"
	sleep 1

run-ALL-hardware: $(embench_hw_logs)

################################################
# Individual Benchmarks (Verilator)
run-aha-mont64-verilator: $(EMBENCH_DIR)/build/bin/aha-mont64.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/aha-mont64.log

run-crc32-verilator: $(EMBENCH_DIR)/build/bin/crc32.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/crc32.log

run-cubic-verilator: $(EMBENCH_DIR)/build/bin/cubic.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/cubic.log

run-edn-verilator: $(EMBENCH_DIR)/build/bin/edn.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/edn.log

run-huffbench-verilator: $(EMBENCH_DIR)/build/bin/huffbench.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/huffbench.log

run-matmult-int-verilator: $(EMBENCH_DIR)/build/bin/matmult-int.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/matmult-int.log

run-md5sum-verilator: $(EMBENCH_DIR)/build/bin/md5sum.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/md5sum.log

run-minver-verilator: $(EMBENCH_DIR)/build/bin/minver.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/minver.log

run-nbody-verilator: $(EMBENCH_DIR)/build/bin/nbody.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/nbody.log

run-nettle-aes-verilator: $(EMBENCH_DIR)/build/bin/nettle-aes.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/nettle-aes.log

run-nettle-sha256-verilator: $(EMBENCH_DIR)/build/bin/nettle-sha256.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/nettle-sha256.log

run-nsichneu-verilator: $(EMBENCH_DIR)/build/bin/nsichneu.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/nsichneu.log

run-picojpeg-verilator: $(EMBENCH_DIR)/build/bin/picojpeg.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/picojpeg.log

run-primecount-verilator: $(EMBENCH_DIR)/build/bin/primecount.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/primecount.log

run-qrduino-verilator: $(EMBENCH_DIR)/build/bin/qrduino.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/qrduino.log

run-sglib-combined-verilator: $(EMBENCH_DIR)/build/bin/sglib-combined.hw_init
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/sglib-combined.log

run-slre-verilator: $(EMBENCH_DIR)/build/bin/slre.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/slre.log

run-st-verilator: $(EMBENCH_DIR)/build/bin/st.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/st.log

run-statemate-verilator: $(EMBENCH_DIR)/build/bin/statemate.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/statemate.log

run-tarfind-verilator: $(EMBENCH_DIR)/build/bin/tarfind.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/tarfind.log

run-ud-verilator: $(EMBENCH_DIR)/build/bin/ud.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/ud.log

run-wikisort-verilator: $(EMBENCH_DIR)/build/bin/wikisort.hw_init $(CVA5_SIM)
	$(CVA5_SIM) "/dev/null" "/dev/null" $< $(VERILATOR_TRACE_FILE) > $(EMBENCH_LOG_DIR)/wikisort.log





################################################
# Individual Benchmarks (Hardware)
run-aha-mont64-hardware: $(EMBENCH_DIR)/build/bin/aha-mont64.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-crc32-hardware: $(EMBENCH_DIR)/build/bin/crc32.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-cubic-hardware: $(EMBENCH_DIR)/build/bin/cubic.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-edn-hardware: $(EMBENCH_DIR)/build/bin/edn.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-huffbench-hardware: $(EMBENCH_DIR)/build/bin/huffbench.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"
	
run-matmult-int-hardware: $(EMBENCH_DIR)/build/bin/matmult-int.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"
	
run-md5sum-hardware: $(EMBENCH_DIR)/build/bin/md5sum.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"
	
run-minver-hardware: $(EMBENCH_DIR)/build/bin/minver.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"
	
run-nbody-hardware: $(EMBENCH_DIR)/build/bin/nbody.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"
	
run-nettle-aes-hardware: $(EMBENCH_DIR)/build/bin/nettle-aes.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"
	
run-nettle-sha256-hardware: $(EMBENCH_DIR)/build/bin/nettle-sha256.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-nsichneu-hardware: $(EMBENCH_DIR)/build/bin/nsichneu.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-picojpeg-hardware: $(EMBENCH_DIR)/build/bin/picojpeg.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-primecount-hardware: $(EMBENCH_DIR)/build/bin/primecount.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-qrduino-hardware: $(EMBENCH_DIR)/build/bin/qrduino.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-sglib-combined-hardware: $(EMBENCH_DIR)/build/bin/sglib-combined.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"
	
run-slre-hardware: $(EMBENCH_DIR)/build/bin/slre.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-st-hardware: $(EMBENCH_DIR)/build/bin/st.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-statemate-hardware: $(EMBENCH_DIR)/build/bin/statemate.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-tarfind-hardware: $(EMBENCH_DIR)/build/bin/tarfind.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-ud-hardware: $(EMBENCH_DIR)/build/bin/ud.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

run-wikisort-hardware: $(EMBENCH_DIR)/build/bin/wikisort.rawbinary
	xsct -eval \
	"connect; fpga $(BITSTREAM); target 2; dow -data $< 0x80000000; mwr 0x88100008 0x0"

###############################################################

.PHONY: clean-logs
clean-logs:
	rm $(embench_logs)

.PHONY: clean
clean : clean-cva5-sim

