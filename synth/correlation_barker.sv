module correlation_barker #(
    parameter int ARCH_TYPE = 0
) (
    input logic i_clk,
    input logic i_rst_n,
    input logic s_tdata,
    input logic s_tvalid,
    input logic s_tlast,
    output logic s_tready,
    output logic m_tuser,
    output logic m_tvalid,
    input logic m_tready
);
    localparam TARGET_SEQ = 11'b11100010010;

    logic [10:0] corr_reg;
    logic tlast_q;

    generate
        if (ARCH_TYPE == 0) begin : dummy
            always_ff @(posedge i_clk) begin
                if (i_rst_n == 1'b0) begin
                    corr_reg <= {11{1'b0}};
                    s_tready <= 1'b0;
                    s_tready <= 1'b0;
                    m_tuser <= 1'b0;
                    m_tvalid <= 1'b0;
                end else begin
                    if (m_tready == 1'b1) begin
                        s_tready <= 1'b1;
                        if (s_tvalid == 1'b1) begin
                            corr_reg <= {corr_reg[9:0], s_tdata};
                            tlast_q <= s_tlast;
                        end else begin
                            tlast_q <= 1'b0;
                        end
                        m_tvalid <= tlast_q;
                    end else begin
                        m_tvalid <= 1'b0;
                    end
                    m_tuser <= ~|(corr_reg ^ TARGET_SEQ);
                end
            end
        end
    endgenerate
endmodule