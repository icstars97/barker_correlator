`timescale 1ns / 1ps
`include "utils.svh"

// test environment for barker correlator
module correlator_tb();

    localparam int PER_CLK_GEN = 40;
    localparam int PER_CLK_CORR = 10;

    logic clk25 = 1'b0;
    logic clk_corr = 1'b1;
    logic rst_n = 1'b0;

    int i;

    logic gen_m_axis_tdata;
    logic gen_m_axis_tvalid;
    logic gen_m_axis_tlast;
    logic gen_m_axis_tready;

    axis_1bit corr_m_axis();
    axis_1bit corr_s_axis();

    always #(PER_CLK_GEN / 2) clk25 = ~clk25;
    always #(PER_CLK_CORR / 2) clk_corr = ~clk_corr;

    initial begin
        for (i=0; i<5; i=i+1) @(posedge clk25);
        rst_n = 1'b1;
    end

    // test pattern generator
    test_seq_gen u_stimulus_gen (
        .i_clk(clk_corr),
        .i_rst_n(rst_n),
        .m_axis_tdata(corr_s_axis.tdata),
        .m_axis_tvalid(corr_s_axis.tvalid),
        .m_axis_tlast(corr_s_axis.tlast),
        .m_axis_tready(corr_s_axis.tready)
    );

    correlation_barker_wrapper #(
        .ARCH_TYPE(1)
    ) u_dut (
        .i_clk(clk_corr),
        .i_rst_n(rst_n),
        .s_axis(corr_s_axis.slave),
        .m_axis(corr_m_axis.master)
    );

    // compare correct response with actual
    test_mon #(
        .CYCLE_COUNT(8192)
    ) u_monitor (
        .i_clk(clk_corr),
        .i_rst_n(rst_n),
        .gen_s_axis(corr_s_axis.slave),
        .dut_s_axis(corr_m_axis.slave)
    );

endmodule