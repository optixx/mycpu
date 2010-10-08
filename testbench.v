
// ============================================================================
// TESTBENCH FOR CPU CORE
// ============================================================================

module tb ();

reg clk, rst;
wire [7:0] pc;

yfcpu mycpu (
	clk, rst, pc
);

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, mycpu);
	clk = 1;
	rst = 1;
	#1 rst = 0;
	#1300 rst = 0;
	$finish;
end

always clk = #1 ~clk;

endmodule
