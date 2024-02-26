`timescale  1ns / 1ps

module correlation_barker_tb();
    localparam TARGET_SEQ = 11'b11100010010;

    logic clk25 = 1'b0;
    logic clk100 = 1'b1;
    logic i_rst_n;
    logic s_tdata;
    logic s_tvalid;
    logic s_tlast;
    logic s_tready;
    logic m_tuser;
    logic m_tvalid;
    logic m_tready;

    int i;
    int cnt;

    always #20 clk25 = ~clk25;
    always #5 clk100 = ~clk100;

    initial begin
        i_rst_n = 1'b1;
        @(posedge clk25);
        i_rst_n = 1'b0;
        @(posedge clk25);
        i_rst_n = 1'b1;
        m_tready = 1'b1;
        for (i=0; i<7; i=i+1) begin
            @(posedge m_tvalid);
        end
        $finish();
    end

    always @(posedge clk25) begin
        if (i_rst_n == 1'b0) begin
            s_tdata <= 1'b0;
            s_tvalid <= 1'b0;
            s_tlast <= 1'b0;
        end else begin
            s_tvalid <= 1'b1;
            s_tdata <= TARGET_SEQ[10-cnt];
            if (cnt < 10) begin
                cnt <= cnt + 1;
                s_tlast <= 1'b0;
            end else begin
                cnt <= 0;
                s_tlast <= 1'b1;
            end
        end
    end

    correlation_barker #(
        .ARCH_TYPE(0)
    ) dut (
        .i_clk(clk100),
        .i_rst_n(i_rst_n),
        .s_tdata(s_tdata),
        .s_tvalid(s_tvalid),
        .s_tlast(s_tlast),
        .s_tready(s_tready),
        .m_tuser(m_tuser),
        .m_tvalid(m_tvalid),
        .m_tready(m_tready)
    );
endmodule