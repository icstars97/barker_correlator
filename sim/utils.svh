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

`endif