XST=/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/xst
NGDBUILD=/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/ngdbuild
MAP=/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/map
PAR=/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/par
TRCE=/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/trce
BITGEN=/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/bitgen
ISE=/opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/ise

MAIN_FILE=pulses
FILES=$(MAIN_FILE).vhdl avr_interface.vhdl cclk_detector.vhdl spi_slave.vhdl serial_rx.vhdl serial_tx.vhdl var_pulse.vhdl
FILE_TYPE=vhdl

OUTPUT=$(MAIN_FILE).bit

PROCESSOR=xc6slx9-tqg144-2

TMP_DIR=syn

XST_TMPDIR=$(TMP_DIR)/xst
XST_PRJ=$(TMP_DIR)/xst_in.prj
XST_OUT=$(TMP_DIR)/xst_out
XST_OPTIONS=-ifn $(XST_PRJ) -ofn $(XST_OUT) -ofmt NGC -p $(PROCESSOR) -top $(MAIN_FILE) -opt_mode Speed -opt_level 1 -power NO -iuc NO -keep_hierarchy No -netlist_hierarchy As_Optimized -rtlview Yes -glob_opt AllClockNets -read_cores YES -write_timing_constraints NO -cross_clock_analysis NO -hierarchy_separator / -bus_delimiter \<\> -case Maintain -slice_utilization_ratio 100 -bram_utilization_ratio 100 -dsp_utilization_ratio 100 -lc Auto -reduce_control_sets Auto -fsm_extract YES -fsm_encoding Auto -safe_implementation No -fsm_style LUT -ram_extract Yes -ram_style Auto -rom_extract Yes -shreg_extract YES -rom_style Auto -auto_bram_packing NO -resource_sharing YES -async_to_sync NO -shreg_min_size 2 -use_dsp48 Auto -iobuf YES -max_fanout 100000 -bufg 16 -register_duplication YES -register_balancing No -optimize_primitives NO -use_clock_enable Auto -use_sync_set Auto -use_sync_reset Auto -iob Auto -equivalent_register_removal YES -slice_utilization_ratio_maxmargin 5
XST_SETTINGS=$(TMP_DIR)/xst_settings.xst
XST_LOG=$(TMP_DIR)/xst_log.syr

NGD_CONSTRAINTS=-uc mojo.ucf
NGD_OPTIONS=-dd _ngo -sd ipcore_dir -nt timestamp $(NGD_CONSTRAINTS) -p $(PROCESSOR)
NGD_OUT=$(TMP_DIR)/ngd_out.ngd

MAP_OPTIONS=-p $(PROCESSOR) -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off
MAP_OUT=$(TMP_DIR)/map_out_map.ncd
MAP_CONSTRAINTS=$(TMP_DIR)/map_out.pcf

PAR_OPTIONS=-w -ol high -mt off
PAR_OUT=$(TMP_DIR)/par_out.ncd
PAR_CONSTRAINTS=$(MAP_CONSTRAINTS)

TRCE_OUT=$(TMP_DIR)/trace_out.twr
TRCE_REPORT=$(TMP_DIR)/trace_report.twx
TRCE_OPTIONS=-v 3 -s 2 -n 3 -fastpaths -xml $(TRCE_REPORT)

BITGEN_OPTIONS=-w -g Binary:yes -g Compress -g CRC:Enable -g Reset_on_err:No -g ConfigRate:2 -g ProgPin:PullUp -g TckPin:PullUp -g TdiPin:PullUp -g TdoPin:PullUp -g TmsPin:PullUp -g UnusedPin:PullDown -g UserID:0xFFFFFFFF -g ExtMasterCclk_en:No -g SPI_buswidth:1 -g TIMER_CFG:0xFFFF -g multipin_wakeup:No -g StartUpClk:CClk -g DONE_cycle:4 -g GTS_cycle:5 -g GWE_cycle:6 -g LCK_cycle:NoWait -g Security:None -g DonePipe:Yes -g DriveDone:No -g en_sw_gsr:No -g drive_awake:No -g sw_clk:Startupclk -g sw_gwe_cycle:5 -g sw_gts_cycle:4

all: xst ngd map par trce bitgen clean_partial
prebuild:
	mkdir -p $(TMP_DIR)
xst: $(XST_OUT) xst_clean
$(XST_OUT): prebuild
	-rm $(XST_SETTINGS)
	-rm $(XST_PRJ)
	echo "set -tmpdir \""$(XST_TMPDIR)"\"" >> $(XST_SETTINGS)
	echo "set -xsthdpdir \"xst\"" >> $(XST_SETTINGS)
	echo "run" >> $(XST_SETTINGS)
	echo $(XST_OPTIONS) >> $(XST_SETTINGS)
	$(foreach file,$(FILES), echo $(FILE_TYPE) "work" $(file) >> $(XST_PRJ);)
	mkdir -p $(XST_TMPDIR)
	$(XST) -ifn $(XST_SETTINGS) -ofn $(XST_LOG)
.PHONY: xst_clean
xst_clean:
	-mv $(MAIN_FILE).lso $(TMP_DIR)/
	-mv _xmsgs $(TMP_DIR)/
	-mv xst $(TMP_DIR)/
ngd: $(NGD_OUT) ngd_clean
$(NGD_OUT): $(XST_OUT)
	$(NGDBUILD) $(NGD_OPTIONS) $(XST_OUT) $(NGD_OUT)
.PHONY: ngd_clean
ngd_clean:
	-mv _xmsgs/* $(TMP_DIR)/_xmsgs/
	-rmdir _xmsgs
	-mv _ngo $(TMP_DIR)/
	-mv xlnx_auto_0_xdb $(TMP_DIR)/
map: $(MAP_OUT) map_clean
$(MAP_OUT): $(NGD_OUT)
	$(MAP) $(MAP_OPTIONS) -o $(MAP_OUT) $(NGD_OUT) $(MAP_CONSTRAINTS)
.PHONY: map_clean
map_clean:
	-mv _xmsgs/* $(TMP_DIR)/_xmsgs/
	-rmdir _xmsgs
	-mv $(MAIN_FILE)_map.xrpt $(TMP_DIR)/
	-mv xilinx_device_details.xml $(TMP_DIR)/xilinx_device_details.xml
par: $(PAR_OUT) par_clean
$(PAR_OUT): $(MAP_OUT)
	$(PAR) $(PAR_OPTIONS) $(MAP_OUT) $(PAR_OUT) $(PAR_CONSTRAINTS)
.PHONY: par_clean
par_clean:
	-mv _xmsgs/* $(TMP_DIR)/_xmsgs/
	-rmdir _xmsgs
	-mv par_usage_statistics.html $(TMP_DIR)/
	-mv $(MAIN_FILE)_par.xrpt $(TMP_DIR)/
trce: $(TRCE_OUT) trce_clean
$(TRCE_OUT): $(PAR_OUT)
	$(TRCE) $(TRCE_OPTIONS) $(PAR_OUT) -o $(TRCE_OUT) $(PAR_CONSTRAINTS)
.PHONY: trce_clean
trce_clean:
	-mv _xmsgs/* $(TMP_DIR)/_xmsgs/
	-rmdir _xmsgs
bitgen: $(OUTPUT) bitgen_clean
$(OUTPUT): $(PAR_OUT)
	$(BITGEN) $(BITGEN_OPTIONS) $(PAR_OUT) $(OUTPUT)
.PHONY: bitgen_clean
bitgen_clean:
	-mv _xmsgs/* $(TMP_DIR)/_xmsgs/
	-rmdir _xmsgs
	-mv xilinx_device_details.xml $(TMP_DIR)/xilinx_device_details_bitgen.xml
	-mv $(MAIN_FILE).bit $(TMP_DIR)/
	-mv $(MAIN_FILE).bgn $(TMP_DIR)/
	-mv $(MAIN_FILE).drc $(TMP_DIR)/
	-mv $(MAIN_FILE)_bitgen.xwbt $(TMP_DIR)/
	-mv usage_statistics_webtalk.html $(TMP_DIR)/
	-mv webtalk.log $(TMP_DIR)/
.PHONY: clean_partial
clean_partial: xst_clean ngd_clean map_clean par_clean trce_clean bitgen_clean
.PHONY: clean
clean: clean_partial
	-rm -r $(TMP_DIR)
	-rm webtalk.log
	-rm $(MAIN_FILE).bin
ise:
	$(ISE)
