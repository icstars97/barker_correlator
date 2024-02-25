`include "../synth/utils.svh"

module axis_oversample_tb();

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    int i;

    always #5 clk = ~clk;

    initial begin
        for (i=0; i<5; i=i+1) @(posedge clk);
        rst_n = 1'b1;
    end

    axis_1bit ovs_m_axis();
    axis_1bit ovs_s_axis();

    test_seq_gen u_stimulus_gen (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .m_axis_tdata(ovs_s_axis.tdata),
        .m_axis_tvalid(ovs_s_axis.tvalid),
        .m_axis_tlast(ovs_s_axis.tlast),
        .m_axis_tready(ovs_s_axis.tready)
    );

    axis_oversample #(
        .ARCH_TYPE(1)
    ) u_dut (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .s_axis(ovs_s_axis.slave),
        .m_axis(ovs_m_axis.master)
    );

    axis_oversample_monitor #(
        .CYCLE_COUNT(32)
    ) u_mon (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .gen_s_axis(ovs_s_axis.slave),
        .dut_s_axis(ovs_m_axis.slave)
    );
    // assign ovs_m_axis.tready = 1'b1;

endmodule