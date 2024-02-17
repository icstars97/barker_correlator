`include "utils.svh"

module correlation_barker_wrapper #(
    parameter int ARCH_TYPE = 1
) (
    input logic i_clk,
    input logic i_rst_n,
    axis_1bit s_axis,
    axis_1bit m_axis
);

    correlation_barker #(
        .ARCH_TYPE(ARCH_TYPE)
    ) correlator_core (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .s_tdata(s_axis.tdata),
        .s_tvalid(s_axis.tvalid),
        .s_tlast(s_axis.tlast),
        .s_tready(s.axis_tready),
        .m_tuser(s_axis.tuser),
        .m_tvalid(m_axis.tvalid),
        .m_tready(m_axis.tready)
    );

    assign m_axis.tdata = 1'b0;
    assign m_axis.tlast = 1'b0;

endmodule