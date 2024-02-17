`timescale 1ns / 1ps
`include "utils.svh"

module correlator_tb();

    logic clk25 = 1'b0;
    logic rst_n = 1'b0;

    int i;

    axis_1bit corr_m_axis();
    axis_1bit corr_s_axis();

    always #20 clk25 = ~clk25;

    initial begin
        for (i=0; i<5; i=i+1) @(posedge clk25);
        rst_n = 1'b1;
        for (i=0; i<5000; i=i+1) @(posedge clk25);
        $finish();
    end

    test_seq_gen u_stimulus_gen (
        .i_clk(clk25),
        .i_rst_n(rst_n),
        .m_axis(corr_s_axis.master)
    );

    correlation_barker_wrapper #(
        .ARCH_TYPE(0)
    ) u_dut (
        .i_clk(clk25),
        .i_rst_n(rst_n),
        .s_axis(corr_s_axis.slave),
        .m_axis(corr_m_axis.master)
    );

    test_mon u_monitor (
        .i_clk(clk25),
        .i_rst_n(rst_n),
        .s_axis(corr_m_axis.slave)
    );

endmodule