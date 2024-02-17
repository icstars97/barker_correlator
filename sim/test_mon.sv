`include "utils.svh"

module test_mon(
    input logic i_clk,
    input logic i_rst_n,
    axis_1bit s_axis
);
    int i;

    initial begin
        s_axis.tready = 1'b0;
        for (i=0; i<20; i=i+1) @(posedge i_clk);
        s_axis.tready = 1'b1;
    end
endmodule