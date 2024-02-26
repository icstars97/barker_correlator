`include "utils.svh"

module correlation_barker_wrapper #(
    parameter int ARCH_TYPE = 1
) (
    input logic i_clk,
    input logic i_rst_n,
    axis_1bit s_axis,
    axis_1bit m_axis
);
    axis_1bit ovs_axis();

    axis_oversample #(
        .ARCH_TYPE(0)
    ) axis_ovs (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .s_axis(s_axis),
        .m_axis(ovs_axis.master)
    );

    correlation_barker #(
        .ARCH_TYPE(ARCH_TYPE)
    ) correlator_core (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .s_tdata(ovs_axis.tdata),
        .s_tvalid(ovs_axis.tvalid),
        .s_tlast(ovs_axis.tlast),
        .s_tready(ovs_axis.tready),
        .m_tuser(m_axis.tuser),
        .m_tvalid(m_axis.tvalid),
        .m_tready(m_axis.tready)
    );

    assign m_axis.tdata = 1'b0;
    assign m_axis.tlast = 1'b0;

endmodule