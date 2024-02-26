
// detects 11 bit barker pattern in input data stream
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
    localparam logic [10:0] TARGET_SEQ = 11'b11100010010;

    logic [10:0] corr_reg;
    logic tlast_q;

    logic [10:0] ref_reg;
    logic mismatch_reg;

    generate
        if (ARCH_TYPE == 0) begin : dummy // low performance, low resource cost
            always_ff @(posedge i_clk) begin
                if (i_rst_n == 1'b0) begin
                    corr_reg <= {11{1'b0}};
                    s_tready <= 1'b0;
                    s_tready <= 1'b0;
                    m_tuser <= 1'b0;
                    m_tvalid <= 1'b0;
                    tlast_q <= 1'b0;
                end else begin
                    if (s_tvalid == 1'b1) begin
                        corr_reg <= {corr_reg[9:0], s_tdata};
                        tlast_q <= s_tlast;
                    end else if (m_tready == 1'b1) tlast_q <= 1'b0;
                    // all data latched, ready to xor
                    if ((tlast_q == 1'b1) && (m_tready == 1'b1)) begin
                        m_tvalid <= 1'b1;
                        m_tuser <= ~|(corr_reg ^ TARGET_SEQ);
                    end else begin
                        m_tuser <= 1'b0;
                        m_tvalid <= 1'b0;
                    end
                    if (m_tready == 1'b1) begin
                        s_tready <= 1'b1;
                    end else begin
                        m_tvalid <= 1'b0;
                        m_tuser <= 1'b0;
                        s_tready <= 1'b0;
                    end

                end
            end
        end

        if (ARCH_TYPE == 1) begin : reverse_feed // higher performance, slightly higher resource cost
            always_ff @(posedge i_clk) begin
                if (i_rst_n == 1'b0) begin
                    s_tready <= 1'b0;
                    m_tuser <= 1'b0;
                    m_tvalid <= 1'b0;
                    tlast_q <= 1'b0;
                    mismatch_reg <= 1'b0;
                    ref_reg <= TARGET_SEQ;
                end else begin
                    if (s_tvalid == 1'b1) begin
                        mismatch_reg <= mismatch_reg | (s_tdata ^ ref_reg[10]);
                        ref_reg <= {ref_reg[9:0], ref_reg[10]};
                        tlast_q <= s_tlast;
                    end else if (m_tready == 1'b1) tlast_q <= 1'b0;
                    if ((tlast_q == 1'b1) && (m_tready == 1'b1)) begin
                        m_tvalid <= 1'b1;
                        m_tuser <= ~mismatch_reg;
                        mismatch_reg <= 1'b0;
                    end else begin
                        m_tuser <= 1'b0;
                        m_tvalid <= 1'b0;
                    end
                    if (m_tready == 1'b1) begin
                        s_tready <= 1'b1;
                    end else begin
                        m_tvalid <= 1'b0;
                        m_tuser <= 1'b0;
                        s_tready <= 1'b0;
                    end
                end
            end
        end
    endgenerate
endmodule