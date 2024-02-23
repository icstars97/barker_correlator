`ifndef _UTILS_
`define _UTILS_

interface axis_1bit;
    logic tdata;
    logic tvalid;
    logic tlast;
    logic tready;
    logic tuser;

    modport master (
        output tdata, tvalid, tlast, tuser,
        input tready
    );

    modport slave (
        input tdata, tvalid, tlast, tuser,
        output tready
    );
endinterface

function logic mjr4(input logic [3:0] a);
        mjr4 = (a[0] & a[1] & a[2]) | (a[0] & a[1] & a[3]) | (a[0] & a[2] & a[3]) | (a[1] & a[2] & a[3]);
endfunction
`endif