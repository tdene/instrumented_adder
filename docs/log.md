# Wed 25 May 12:46:15 CEST 2022

* updated to ngspice3.7
* added harden rule to Makefile 
* fixed bypass reversal
* given up on Pyspice
* have 2 spice files for with and without bypass adder
* results seem wrong (see below)
* using bit 7 of the adder, reharden, fails to oscillate with adder. bypass as before. increase number of inverters to 101 (from 21)
* pretty cumbersome to changes adders at the moment. have to change:
    * config.tcl for source,
    * the makefile for test rule, 
    * the instrumented_adder.v, for the include
    * re-harden
* And waveform of the ring is no good. bad reset? Trying different spice setup
* Doing a separate reset and run seems to improve the ring osc waveform
* but then kogge-stone stopped oscillating, so had to include extra inverter
* Teo updated lib to prepend module names, so all can be included. Now updating spice needs:
    * change verilog
    * reharden


## Results

All measurements in seconds and are time for 7 ring oscillation periods (check .meas setup in spice file)

| name             | time for n loops      | bit connected | number inverters | extra inv
| ---------------- | --------------------- | ------------- | ---------------- | ---------
|yosys bypass      | 1.833742e-08       7  |  0            |  21              | 1
|ripple bypass     | 1.828263e-08       7  |  0            |  21              | 1
|sklansky bypass   | 1.828272e-08       7  |  0            |  21              | 1
|kogge-stone bypass| 1.833742e-08       7  |  0            |  21              | 1
|yosys adder       | 2.148156e-08       7  |  0            |  21              | 0        
|ripple adder      | 2.094202e-08       7  |  0            |  21              | 0
|sklansky adder    | 2.095268e-08       7  |  0            |  21              | 0        
|kogge-stone adder | 2.094274e-08       7  |  0            |  21              | 0        

| name             | time for n loops      | bit connected | number inverters | extra inv
| ---------------- | --------------------- | ------------- | ---------------- | ---------
|yosys bypass      | 1.245878e-08       7  |  7            |  21              | 1
|yosys adder       | 1.275221e-08       7  |  7            |  21              | 0        
|sklansky adder    | 1.286283e-08       7  |  7            |  21              | 0        
|ripple adder      | 1.285714e-08       7  |  7            |  21              | 0
|kogge-stone adder | 1.285516e-08       7  |  7            |  21              | 0        

These took too long, so measured 6 loops, then divide by 6, multiply by 7 to compare above 

| name             | time for n loops      | bit connected | number inverters | extra inv
| ---------------- | --------------------- | ------------- | ---------------- | ---------
|yosys adder       | 1.911594e-08       6  |  0            |  21              | 0
|sklansky adder    | 1.867272e-08       6  |  0            |  21              | 0        
|kogge-stone adder | 1.866273e-08       6  |  0            |  21              | 0
|ripple adder      | 1.865568e-08       6  |  0            |  21              | 0
|kogge-stone adder | 2.1773  8-08   (6) 7  |  0            |  21              | 0        


# Tue 24 May 12:29:46 CEST 2022

* Adding the [.spiceinit](../spice/.spiceinit) file drops simulation time from 50 minutes down to 2:30. See this [ngspice note](http://ngspice.sourceforge.net/applic.html)
* useful ngspice stuff: display to show all vectors. Then use "" to be able to plot vectors like ring_osc_counter[0] (needs quotes to work)
* overflow never going high, put the counter on external pins and were floating? maybe not reset properly? tried adding or posedge reset and that failed to floorplan(!), moved back to up counter and used external inputs as compare
* think I might have been copying the wrong spice file
* learnt the measure tool to count ring osc cycles
* with bypass 8 cycles takes 1.43e-8 s and without 1.34e-8 s

![counting ring osc cycles](spice_pics/sim2.png)

# Mon 23 May 12:46:45 CEST 2022

* adding uic (thanks Thomas) to .tran helps simulation run [see this pic](spice_pics/sim1.png)
* still takes about an hour. Thomas can get it to run an <1 minute so trying to get the same setup here

# Thu 19 May 11:01:18 CEST 2022

* fixed the issue with the mismatched reset names.
* 10 inverters, chain oscillates at 0.69ns = 1.6GHz.
* takes about 3:30 to run
* use the spice file from the openlane run and remove magic steps by including the primitives spice file
* add the if/else to use inverters or delays
* added [a fake adder](../src/fake_adder.v)
* analog simulation takes too long > 1 hour.
* trying with only 10 inverters, updated the tests and changed to a down counter
* fails

# Wed 18 May 16:08:55 CEST 2022

Be on commit 6eb633ea6bb33440104e7584073c98a0a11cab58 to reproduce this issue. Fixed with a working reset. 

Trying to simulate a [ring of inverters](../src/instrumented_adder.v). I don't think this can be done with the digital sim tools, so I am 
trying to use a spice file extracted from the GDS of the hardened verilog.

## Use OpenLane to build GDS

    make mount
    ./flow -design wrapped_instrumented_inverter

I added the complete run directory: [runs/RUN_2022.05.18_14.08.09](../runs/RUN_2022.05.18_14.08.09).

Configuration [config.tcl](../config.tcl) needed 'set ::env(SYNTH_READ_BLACKBOX_LIB) 1' setting.

## Check synth log

    cat runs/RUN_2022.05.18_14.08.09/reports/synthesis/1-synthesis.stat.rpt.strategy4

    === instrumented_adder ===

       Number of wires:                 26
       Number of wire bits:             29
       Number of public wires:          14
       Number of public wire bits:      17
       Number of memories:               0
       Number of memory bits:            0
       Number of processes:              0
       Number of cells:                 27
         sky130_fd_sc_hd__a21oi_2        2
         sky130_fd_sc_hd__a31o_2         2
         sky130_fd_sc_hd__a41o_2         1
         sky130_fd_sc_hd__and2b_2        1
         sky130_fd_sc_hd__buf_1          3
         sky130_fd_sc_hd__dfxtp_2        4
         sky130_fd_sc_hd__inv_2         10
         sky130_fd_sc_hd__nor2_2         3
         sky130_fd_sc_hd__o21a_2         1

       Chip area for module '\instrumented_adder': 216.457600

## Get non-blackboxed spice file

    cd runs/RUN_2022.05.18_14.08.09/results/final/gds
    ln -s ../../finishing/.magicrc # get a local copy of magicrc file to be able to open the gds with magic
    magic instrumented_adder.gds

Then in the magic command window type:

    extract
    ext2spice lvs
    ext2spice
    quit

Then you will have the full spice file. I've copied this to [./spice/instrumented_adder.spice](../spice/instrumented_adder.spice)

## Try to simulate with spice

Check the commented [spice/simulation.spice](../spice/simulation.spice) file. It provides power, clock and an initial reset.
The [simulation fails to converge](../spice/spice.log) and I never get to see the inverter loop oscillating.

    cd spice
    ngspice simulation.spice

If you want to run the simulation, change the PDK include line at the top of simulation.spice to match your local library install.

