`include "utils.svh"

module axis_oversample #(
    parameter int ARCH_TYPE = 0
) (
    input logic i_clk,
    input logic i_rst_n,
    axis_1bit s_axis,
    axis_1bit m_axis
);

    logic [3:0] ovs_data_reg;
    logic [3:0] ovs_data_reg_prev;
    logic [3:0] ovs_last_reg;
    logic [3:0] ovs_last_reg_prev;
    logic [2:0] sample_cnt;
    logic ovs_cplt;
    logic ovs_data_rdy;

    logic [2:0] ovs_data_cnt;
    logic [2:0] ovs_data_cnt_prev;
    logic [2:0] ovs_last_cnt;
    logic [2:0] ovs_last_cnt_prev;


    generate
        if (ARCH_TYPE == 0) begin : majority_circuit
            always_ff @(posedge i_clk) begin
                if (i_rst_n == 1'b0) begin
                    s_axis.tready <= 1'b0;
                    m_axis.tdata <= 1'b0;
                    m_axis.tvalid <= 1'b0;
                    m_axis.tlast <= 1'b0;
                    sample_cnt <= 4'h0;
                    ovs_data_reg <= 4'h0;
                    ovs_last_reg <= 4'h0;
                    ovs_data_reg_prev <= 4'h0;
                    ovs_last_reg_prev <= 4'h0;
                end else begin
                    s_axis.tready <= m_axis.tready;
                    if (s_axis.tvalid == 1'b1) begin
                            ovs_data_reg <= {ovs_data_reg[2:0], s_axis.tdata};
                            ovs_last_reg <= {ovs_last_reg[2:0], s_axis.tlast};
                        if (sample_cnt == 4'h3) begin
                            sample_cnt <= 4'h0;
                            ovs_cplt <= 1'b1;
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                        end
                    end
                    if (ovs_cplt == 1'b1) begin
                        ovs_data_reg_prev <= ovs_data_reg;
                        ovs_last_reg_prev <= ovs_last_reg;
                        ovs_data_rdy <= 1'b1;
                        ovs_cplt <= 1'b0;
                    end
                    if (m_axis.tready == 1'b1) begin
                        if (ovs_data_rdy == 1'b1) begin
                            ovs_data_rdy <= 1'b0;
                            m_axis.tdata <= mjr4(ovs_data_reg_prev);
                            m_axis.tvalid <= 1'b1;
                            m_axis.tlast <= mjr4(ovs_last_reg_prev);
                        end else begin
                            m_axis.tdata <= 1'b0;
                            m_axis.tvalid <= 1'b0;
                            m_axis.tlast <= 1'b0;
                        end
                    end else begin
                        m_axis.tdata <= 1'b0;
                        m_axis.tvalid <= 1'b0;
                        m_axis.tlast <= 1'b0;
                    end
                end
            end
        end

        if (ARCH_TYPE == 1) begin : vector_popcount
            always_ff @(posedge i_clk) begin
                if (i_rst_n == 1'b0) begin
                    s_axis.tready <= 1'b0;
                    m_axis.tdata <= 1'b0;
                    m_axis.tvalid <= 1'b0;
                    m_axis.tlast <= 1'b0;
                    sample_cnt <= 4'h0;
                    ovs_data_cnt <= 4'h0;
                    ovs_last_cnt <= 4'h0;
                    ovs_data_cnt_prev <= 4'h0;
                    ovs_last_cnt_prev <= 4'h0;
                end else begin
                    s_axis.tready <= m_axis.tready;
                    if (s_axis.tvalid == 1'b1) begin
                        if (sample_cnt == 4'h3) begin
                            sample_cnt <= 4'h0;
                            ovs_cplt <= 1'b1;
                            ovs_data_cnt_prev <= ovs_data_cnt + s_axis.tdata;
                            ovs_last_cnt_prev <= ovs_last_cnt + s_axis.tlast;
                            ovs_data_cnt <= 0;
                            ovs_last_cnt <= 0;
                        end else begin
                            sample_cnt <= sample_cnt + 1'b1;
                            ovs_data_cnt <= ovs_data_cnt + s_axis.tdata;
                            ovs_last_cnt <= ovs_last_cnt + s_axis.tlast;
                        end
                    end
                    if (m_axis.tready == 1'b1) begin
                        if (ovs_cplt == 1'b1) begin
                            ovs_cplt <= 1'b0;
                            if (ovs_data_cnt_prev > 2) m_axis.tdata <= 1'b1;
                            else m_axis.tdata <= 1'b0;
                            if (ovs_last_cnt_prev > 2) m_axis.tlast <= 1'b1;
                            else m_axis.tlast <= 1'b0;
                            m_axis.tvalid <= 1'b1;
                        end else begin
                            m_axis.tdata <= 1'b0;
                            m_axis.tvalid <= 1'b0;
                            m_axis.tlast <= 1'b0;
                        end
                    end else begin
                        m_axis.tdata <= 1'b0;
                        m_axis.tvalid <= 1'b0;
                        m_axis.tlast <= 1'b0;
                    end
                end
            end
        end
    endgenerate

    assign m_axis.tuser = 1'b0;
endmodule