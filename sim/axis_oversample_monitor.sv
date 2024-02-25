`include "utils.svh"
module axis_oversample_monitor #(
    parameter int CYCLE_COUNT = 8
) (
    input logic i_clk,
    input logic i_rst_n,
    axis_1bit gen_s_axis,
    axis_1bit dut_s_axis
);
    localparam int TREADY_INTERVAL_MAX = 10;
    localparam int TREADY_INTERVAL_MIN = 1;

    int i;
    int j;
    int k;
    int l;
    int tready_seed = 99;
    int tready_interval;

    int tdata_sample_cnt;
    int tlast_sample_cnt;
    logic tdata_actual;
    logic tlast_actual;


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
        for (j=0; j<CYCLE_COUNT; j=j+1) begin
            l=0;
            tdata_sample_cnt = 0;
            tlast_sample_cnt = 0;
            while(l < 4) begin
                @(posedge i_clk);
                if (gen_s_axis.tvalid == 1'b1) begin
                    tdata_sample_cnt = tdata_sample_cnt + gen_s_axis.tdata;
                    tlast_sample_cnt = tlast_sample_cnt + gen_s_axis.tlast;
                    l = l + 1;
                end
            end
            if (tdata_sample_cnt > 2) tdata_actual = 1'b1;
            else tdata_actual = 1'b0;
            if (tlast_sample_cnt > 2) tlast_actual = 1'b1;
            else tlast_actual = 1'b0;
        end
        @(negedge dut_s_axis.tvalid);
        $finish();
    end

    initial begin : output_bus_monitor
        forever begin
            @(posedge i_clk);
            if (dut_s_axis.tvalid == 1'b1) begin
                if (dut_s_axis.tdata != tdata_actual) begin
                    $display("error: dut tdata output and actual tdata mismatch");
                    $finish();
                end
                if (dut_s_axis.tlast != tlast_actual) begin
                    $display("error: dut tlast output and actual tlast mismatch");
                    $finish();
                end
            end
        end
    end
endmodule