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
    int j;
    int k;
    int l;
    int m;

    int tready_seed = 99;
    int tready_interval;
    logic corr_mon;

    logic [10:0] gen_data_reg;
    int cycle_cnt;

    int tdata_sample_cnt;

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

    initial begin : input_bus_monitor
        for (m=0; m< CYCLE_COUNT; m=m+1) begin
            gen_data_reg <= {11{1'b0}};
            for (j=10; j>=0; j=j-1) begin
                l=0;
                tdata_sample_cnt = 0;
                while(l < 4) begin
                    @(posedge i_clk);
                    if (gen_s_axis.tvalid == 1'b1) begin
                        tdata_sample_cnt = tdata_sample_cnt + gen_s_axis.tdata;
                        l = l + 1;
                    end
                end
                if (tdata_sample_cnt > 2) gen_data_reg[j] = 1'b1;
                else  gen_data_reg[j] = 1'b0;
            end
            if (gen_data_reg == GOLDEN_SEQ) corr_mon <= 1'b1;
            else corr_mon <= 1'b0;
        end
        @(negedge dut_s_axis.tvalid);
        $display("simulation finished");
        $finish();
    end

    initial begin : output_bus_monitor
        forever begin
            @(posedge i_clk);
            if (dut_s_axis.tvalid == 1'b1) begin
                if (dut_s_axis.tuser != corr_mon) begin
                    $display("error: dut tuser output and expected response do not match");
                    $finish();
                end
            end
        end
    end
endmodule