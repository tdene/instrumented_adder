`default_nettype none
`timescale 1ns/1ns

module instrumented_adder(

    input wire clk,
    input wire reset,
    input wire run,
    input wire bypass,
    input wire extra_inverter,
    input wire [7:0] a_input,
    input wire [7:0] b,
    input wire [7:0] counter_end,
    output wire chain,
    output wire time_count_overflow,
    output wire [7:0] sum_out,
    output wire [7:0] counter_out,
    output wire [RING_OSC_COUNTER_BITS-1:0] ring_osc_counter_out

);
    `ifdef COCOTB_SIM
    initial begin
        $dumpfile ("instrumented_adder.vcd");
        $dumpvars (0, instrumented_adder);
        #1;
    end
    `endif

    localparam NUM_INVERTERS = 21; // keep to an odd number
    localparam TIME_COUNTER_BITS = 8;
    localparam RING_OSC_COUNTER_BITS = 8;

    reg [TIME_COUNTER_BITS-1:0] counter;
    reg [RING_OSC_COUNTER_BITS-1:0] ring_osc_counter;
    assign chain = chain_out;
    assign sum_out = sum;
    assign counter_out = counter;
    assign time_count_overflow = counter == counter_end -1;
    assign ring_osc_counter_out = ring_osc_counter;

    // counter for the incoming clock
    always @(posedge clk or posedge reset) begin
        if(reset)
            counter <= 0;
        else if (counter < counter_end - 1'b1)
            counter <= counter + 1'b1;
    end

    // counter for the ring oscillator
    always @(posedge chain_out or posedge reset) begin
        if(reset)
            ring_osc_counter <= 0;
        else
            ring_osc_counter <= ring_osc_counter + 1'b1;
    end

    // setup loop of inverters
    // http://svn.clairexen.net/handicraft/2015/ringosc/ringosc.v
    wire chain_in, chain_out, chain_in_pre_xor;
    wire [NUM_INVERTERS-1:0] buffers_in, buffers_out;
    assign buffers_in = {buffers_out[NUM_INVERTERS-2:0], chain_in};
    assign chain_out = run ~& buffers_out[NUM_INVERTERS-1];
    wire chain_out_bypass;

    // connect either output of the inverter chain or output of the adder back to input
    assign chain_out_bypass =  bypass ? chain_out : sum[7]; 
    assign a                =  { chain_out , a_input[6:0] };

    assign chain_in_pre_xor = reset ? 0: chain_out_bypass;
    assign chain_in         = extra_inverter ^ chain_in_pre_xor;

    
    // instantiate the inverters
    inv_with_delay buffers [NUM_INVERTERS-1:0] (
        .A(buffers_in),
        .Y(buffers_out)
    );

    // instantiate adder
    wire [7:0] a;
    wire [7:0] sum;

      //behavioral behavioral   (.a(a), .b(b), .sum(sum));
  //   sklansky        sklansky     (.a_in(a), .b_in(b), .sum(sum));
      //ripple_carry     ripple_carry     (.a_in(a), .b_in(b), .sum(sum));
    kogge_stone      kogge_stone  (.a_in(a), .b_in(b), .sum(sum));

endmodule

// do this so can use iverilog to check digital
module inv_with_delay(input A, output Y);
    wire Y;
    `ifdef COCOTB_SIM
    assign #1 Y = ~A;
    `else
    sky130_fd_sc_hd__inv_2 _0_ ( .A(A), .Y(Y));
    `endif
endmodule

// take a long time to add some numbers
module behavioral(cout, sum, a, b, cin);

	input [7:0] a, b;
	input cin;
	output [7:0] sum;
	output cout;

    `ifdef COCOTB_SIM
    assign #50 sum = a + b;
    `else
    assign sum = a + b;
    `endif
endmodule
