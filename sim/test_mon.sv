`include "utils.svh"

module test_mon #(
    parameter int CYCLE_COUNT = 128
) (
    input logic i_clk,
    input logic i_rst_n,
    axis_1bit gen_s_axis,
    axis_1bit dut_s_axis
);

    localparam logic [10:0] GOLDEN_SEQ = 11'b11100010010;
    localparam int TREADY_INTERVAL_MAX = 10;
    localparam int TREADY_INTERVAL_MIN = 1;


    int i;

    int tready_seed = 99;
    int tready_interval;
    logic tlast_q;
    logic tvalid_q;
    logic corr_mon;

    logic [10:0] gen_data_reg;
    int cycle_cnt;

    initial begin : tready_gen
        dut_s_axis.tready = 1'b0;
        for (i=0; i<20; i=i+1) @(posedge i_clk);
        dut_s_axis.tready = 1'b1;
        forever begin
            tready_interval = $dist_uniform(tready_seed, TREADY_INTERVAL_MIN, TREADY_INTERVAL_MAX);
            for (i=0; i < tready_interval; i=i+1) @(posedge i_clk);
            dut_s_axis.tready = ~dut_s_axis.tready;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst_n == 1'b0) begin
            cycle_cnt <= 0;
            gen_data_reg <= {11{1'b0}};
            tlast_q <= 1'b0;
            tvalid_q <= 1'b0;
            corr_mon <= 1'b0;
        end else begin
            if ((gen_s_axis.tvalid == 1'b1) && (gen_s_axis.tready == 1'b1)) begin
                gen_data_reg <= {gen_data_reg[9:0], gen_s_axis.tdata};
                tlast_q <= gen_s_axis.tlast;
            end else begin
                tlast_q <= 1'b0;
            end
            if (tlast_q == 1'b1) begin
                if (gen_data_reg == GOLDEN_SEQ) corr_mon <= 1'b1;
                else corr_mon <= 1'b0;
            end

            if (cycle_cnt == CYCLE_COUNT) $finish;
            tvalid_q <= dut_s_axis.tvalid;
            if ((dut_s_axis.tvalid == 1'b1) && (tvalid_q == 1'b0)) begin
                cycle_cnt <= cycle_cnt + 1;
                if (corr_mon != dut_s_axis.tuser) begin
                    $display("error: dut response does not match expected");
                    $finish;
                end
                corr_mon <= 1'b0;
            end
        end

    end
endmodule