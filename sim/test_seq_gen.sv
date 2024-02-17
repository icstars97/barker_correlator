`timescale 1ns / 1ps



module test_seq_gen(
    input logic i_clk,
    input logic i_rst_n,
    axis_1bit m_axis
);

    localparam logic [10:0] GOLDEN_SEQ = 11'b11100010010;
    localparam int PAUSE_MIN = 0;
    localparam int PAUSE_MAX = 32;

    int bit_cnt;
    int pause_cnt;
    int pause_length;

    typedef enum {s_reset, s_idle, s_gen, s_pause} gen_state;
    gen_state state;
    gen_state next_state;

    always_ff @(posedge i_clk) begin
        if (i_rst_n == 1'b0) state <= s_reset;
        else state <= next_state;
    end

    always_comb begin
        case (state)

            s_reset : next_state = s_idle;

            s_idle : if (m_axis.tready == 1'b1) next_state = s_gen;

            s_gen : begin
                if (m_axis.tready == 1'b0) begin
                    next_state = s_idle;
                end else if (pause_length == 0) next_state = s_gen;
                else next_state = s_pause;
            end

            s_pause : begin
                if (m_axis.tready == 1'b0) next_state = s_gen;
                else next_state = s_idle;
            end

        endcase
    end

    always_ff @(i_clk) begin
        case (state)

            s_reset : begin
                m_axis.s_tdata <= 1'b0;
                m_axis.tvalid <= 1'b0;
                m_axis.tlast <= 1'b0;
                bit_cnt <= 0;
                pause_cnt <= 0;
                pause_length <= 0;
            end

            s_idle : begin
                m_axis.tvalid <= 1'b0;
                m_axis.tlast <= 1'b0;
            end

            s_gen : begin
                if (bit_cnt == 10) begin
                    bit_cnt <= 0;
                    m_axis.tlast <= 1'b1;
                end else bit_cnt <= bit_cnt + 1'b1;
                m_axis.tdata <= GOLDEN_SEQ[bit_cnt];
                pause_length <= $urandom_range(PAUSE_MIN, PAUSE_MAX);
                m_axis.tvalid <= 1'b1;
            end

            s_pause : begin
                m_axis.tvalid <= 1'b0;
                m_axis.tlast <= 1'b0;
                if (pause_cnt == pause_length - 1) pause_cnt <= 0;
                else pause_cnt <= pause_cnt + 1;
            end

        endcase
    end

    assign m_axis.tuser = 1'b0;
endmodule
