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

    int error_seed = 99;

    int err_inj_index;

    int i;
    int j;

    initial begin : test_data_gen
        m_axis_tdata <= 1'b0;
        m_axis_tlast <= 1'b0;
        m_axis_tvalid <= 1'b0;
        forever begin
            err_inj_index <= $dist_uniform(error_seed, 0, 21);
            for (i=10; i>=0; i=i-1) begin
                j = 0;
                while(j<4) begin
                    @(posedge i_clk);
                    if (m_axis_tready == 1'b1) begin
                        if ((err_inj_index < 11) && (err_inj_index == i)) m_axis_tdata <= ~GOLDEN_SEQ[i];
                        else m_axis_tdata <= GOLDEN_SEQ[i];
                        m_axis_tvalid <= 1'b1;
                        if (i == 0) m_axis_tlast <= 1'b1;
                        else m_axis_tlast <= 1'b0;
                        j = j + 1;
                    end else begin
                        m_axis_tdata <= 1'b0;
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                    end
                end
            end
        end
    end
endmodule
