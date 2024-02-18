`timescale 1ns / 1ps


// barker correlator test sequence generation unit
module test_seq_gen(
    input logic i_clk,
    input logic i_rst_n,
    output logic m_axis_tdata,
    output logic m_axis_tvalid,
    output logic m_axis_tlast,
    input logic m_axis_tready
);

    localparam logic [10:0] GOLDEN_SEQ = 11'b11100010010;

    localparam int PAUSE_MIN = 0;
    localparam int PAUSE_MAX = 32;

    int pause_seed = 99;
    int error_seed = 99;

    int bit_cnt;
    int pause_cnt;
    int pause_length;
    int err_inj_index;

    typedef enum {s_reset, s_idle, s_gen, s_pause} gen_state;
    gen_state state;
    gen_state next_state;

    // state latch
    always_ff @(posedge i_clk) begin
        if (i_rst_n == 1'b0) state <= s_reset;
        else state <= next_state;
    end

    // next state decode
    always_comb begin
        case (state)

            s_reset : next_state = s_idle;

            s_idle : if (m_axis_tready == 1'b1) next_state = s_gen;

            s_gen : begin
                if (m_axis_tready == 1'b0) begin
                    next_state = s_idle;
                end else if (bit_cnt == 0) begin
                    if (pause_length == 0) next_state = s_gen;
                    else next_state = s_pause;
                end
            end

            s_pause : begin
                if (m_axis_tready == 1'b0) next_state = s_gen;
                else if (pause_cnt == pause_length - 1) next_state = s_gen;
            end

        endcase
    end

    // outputs decode
    always_ff @(posedge i_clk) begin
        case (state)

            s_reset : begin
                m_axis_tdata <= 1'b0;
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                bit_cnt <= 10;
                pause_cnt <= 0;
                pause_length <= 0;
                err_inj_index <= 99;
            end

            s_idle : begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end

            s_gen : begin
                if (bit_cnt == 0) begin
                    bit_cnt <= 10;
                    m_axis_tlast <= 1'b1;
                end else begin
                    bit_cnt <= bit_cnt - 1'b1;
                    m_axis_tlast <= 1'b0;
                end

                // get random inter frame gap
                if (bit_cnt == 1) pause_length <= $dist_uniform(pause_seed, PAUSE_MIN, PAUSE_MAX);

                // if bit flip index is greater than sequence length - 1 error is not injected
                if ((err_inj_index < 11) && (err_inj_index == bit_cnt)) m_axis_tdata <= ~GOLDEN_SEQ[bit_cnt];
                else m_axis_tdata <= GOLDEN_SEQ[bit_cnt];

                m_axis_tvalid <= 1'b1;
            end

            s_pause : begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                if (pause_cnt == pause_length - 1) begin
                    pause_cnt <= 0;
                    // get erro injection index for next frame
                    err_inj_index <= $dist_uniform(error_seed, 0, 21);
                end else pause_cnt <= pause_cnt + 1;
            end

        endcase
    end

endmodule
