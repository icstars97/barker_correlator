`timescale  1ns / 1ps
`include "../synth/utils.svh"

module oversample_circuit_tb();
    localparam int CYCLE_COUNT = 16;
    localparam int ARCH_TYPE = 1;

    localparam int PAUSE_MIN = 0;
    localparam int PAUSE_MAX = 32;
    int vector_seed = 99;
    int pause_seed = 99;
    int pause_length = 0;

    int i;
    int j;
    int k;
    int l;
    int m;
    logic clk = 1'b1;

    logic mon_d = 1'b0;;

    logic [3:0] test_data;
    logic [3:0] prev_test_data;
    logic in_d;
    logic in_v = 0;
    logic rst_n = 1;
    int td_popcount;


    // dut signals
    logic [3:0] ovs_reg; // input shift register for data oversampling
    int ovs_cnt;
    logic ovs_cplt;
    logic ovs_v;
    logic ovs_d;
    logic ovs_last;
    logic tlast_q;

    int pop_cnt;
    int pop_reg;

    always #5 clk = ~clk;

    initial begin : stimulus_gen
        @(posedge clk);
        rst_n = 1'b0;
        @(posedge clk);
        rst_n = 1'b1;
        for (i=0; i<4; i=i+1) @(posedge clk);

        for (i=0; i<CYCLE_COUNT; i=i+1) begin
            test_data = $dist_uniform(vector_seed, 0, 15);
            for (j=0; j<4; j=j+1) begin
                in_d <= test_data[j];
                in_v <= 1'b1;
                @(posedge clk);
                prev_test_data = test_data;
                pause_length = $dist_uniform(pause_seed, PAUSE_MIN, PAUSE_MAX);
                if (pause_length > 0) begin
                    in_v <= 1'b0;
                    for (m=0; m<pause_length; m=m+1) @(posedge clk);
                end

            end

        end
    end

    generate
        if (ARCH_TYPE == 0) begin : majority_circuit
            always_ff @(posedge clk) begin : oversample_unit
                if (rst_n == 1'b0) begin
                    ovs_reg <= 4'b0000;
                    ovs_cnt <= 0;
                    ovs_v <= 1'b0;
                    ovs_d <= 1'b0;
                    ovs_cplt <= 1'b0;
                    ovs_last <= 1'b0;
                    tlast_q <= 1'b0;
                end else begin
                    // if (s_tready == 1'b1) begin
                        if (in_v == 1'b1) begin
                            ovs_reg <= {ovs_reg[2:0], in_d};
                            // tlast_q <= s_tlast;
                            if (ovs_cnt == 3) begin
                                ovs_cnt <= 0;
                                ovs_cplt <= 1'b1;
                            end else begin
                                ovs_cnt <= ovs_cnt + 1'b1;
                                ovs_cplt <= 1'b0;
                            end
                        end else begin
                            ovs_cplt <= 1'b0;
                        end
                        if (ovs_cplt == 1'b1) begin
                            ovs_v <= 1'b1;
                            ovs_d <= mjr4(ovs_reg);
                            // ovs_last <= tlast_q;
                        end else begin
                            ovs_v <= 1'b0;
                            ovs_d <= 1'b0;
                            ovs_last <= 1'b0;
                        end
                    // end

                end
            end
        end

        if (ARCH_TYPE == 1) begin : hamming_weight
            always_ff @(posedge clk) begin: oversample_unit
                if (rst_n == 1'b0) begin
                    pop_cnt <= 0;
                    pop_reg <= 0;
                    ovs_cnt <= 0;
                    ovs_v <= 1'b0;
                    ovs_d <= 1'b0;
                    ovs_cplt <= 1'b0;
                    ovs_last <= 1'b0;
                    tlast_q <= 1'b0;
                end else begin
                    if (in_v == 1'b1) begin
                            if (ovs_cnt == 3) begin
                                pop_reg <= pop_cnt + in_d;
                                pop_cnt <= 0;
                                ovs_cnt <= 0;
                                ovs_cplt <= 1'b1;
                            end else begin
                                ovs_cnt <= ovs_cnt + 1'b1;
                                ovs_cplt <= 1'b0;
                                pop_cnt <= pop_cnt + in_d;
                            end
                    end else begin
                        ovs_cplt <= 1'b0;
                    end
                    if (ovs_cplt == 1'b1) begin
                        ovs_v <= 1'b1;
                        if (pop_reg > 2) ovs_d <= 1'b1;
                        else ovs_d <= 1'b0;
                        pop_reg <= 0;
                        // ovs_last <= tlast_q;
                    end else begin
                        ovs_v <= 1'b0;
                        ovs_d <= 1'b0;
                        ovs_last <= 1'b0;
                    end
                end
            end
        end
    endgenerate

    initial begin : monitor
        for (k=0; k<CYCLE_COUNT; k=k+1) begin
            td_popcount = 0;
            @(posedge ovs_v);
            for (l=0; l<$size(prev_test_data); l=l+1) td_popcount = td_popcount + prev_test_data[l];
            if (td_popcount > $size(prev_test_data) / 2) mon_d = 1'b1;
            else mon_d = 1'b0;
            if (mon_d != ovs_d) begin
                @(posedge clk);
                $display("error: expected data does not match actual");
                $finish();
            end
        end
        @(posedge clk);
        $finish();
    end
endmodule