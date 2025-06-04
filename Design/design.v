`include "definition_new.v"

module alu #(parameter W = `WIDTH, parameter N = `CMD_WIDTH)(clk, rst, inp_valid, mode, cin, ce, cmd, opa, opb, res, oflow, cout, g, l, e, err);
        input clk, rst, mode, cin, ce;
        input [1:0] inp_valid;
        input [3:0] cmd;
        input [W-1:0] opa, opb;
        `ifdef MUL
            output reg [2*W - 1:0] res;
            reg [2*W-1:0] res_temp, res_temp_delay;
        `else
            output reg [W:0] res;
            reg [W:0] res_temp, res_temp_delay;
        `endif
        output reg oflow, cout, g, l, e, err;
        //temp input buffers
        reg [W-1:0] opa_temp, opb_temp;
        reg [1:0] inp_valid_temp;
        reg mode_temp, cin_temp;
        reg [N-1:0] cmd_temp;
        //temp output buffers
        //reg [2*W - 1 : 0] res_temp, res_temp_delay;
        reg oflow_temp, cout_temp, g_temp, l_temp, e_temp, err_temp;
        //misc
        reg [2:0] shift;
        parameter SHIFT_AMNT = $clog2(W);
        always@(posedge clk or posedge rst)begin
                if(rst)begin
                        res <= 0;
                        oflow <= 0;
                        cout <= 0;
                        g <= 0;
                        l <= 0;
                        e <= 0;
                        err <= 0;
                        res_temp_delay <= 0;
                        res_temp <= 0;
                end
                else if(ce)begin
                        //input load
                        opa_temp <= opa;
                        opb_temp <= opb;
                        inp_valid_temp <= inp_valid;
                        mode_temp <= mode;
                        cin_temp <= cin;
                        cmd_temp <= cmd;

                        //output load
                        if((cmd_temp == `MULT_SHIFT || cmd_temp == `MULT_INC) && mode_temp == 1)begin
                                res_temp_delay <= res_temp;
                                res <= res_temp_delay;
                                cout <= 0;
                                oflow <= 0;
                                l <= 0;
                                g <= 0;
                                e <= 0;
                                err <= 0;
                        end
                        else begin
                                res <= res_temp;
                                cout <= cout_temp;
                                oflow <= oflow_temp;
                                l <= l_temp;
                                g <= g_temp;
                                e <= e_temp;
                                err <= err_temp;
                        end
                end
                else
                        err <= 1;
        end

        always@(*)begin
                //reset all outputs to 0
                res_temp = 0;
                oflow_temp = 0;
                cout_temp = 0;
                g_temp = 0;
                l_temp = 0;
                e_temp = 0;
                err_temp = 0;
                case(inp_valid_temp)
                        2'b01 : begin
                                if(mode_temp)begin
                                        case (cmd_temp)
                                                `INC_A : begin
                                                        res_temp  = opa_temp + 1;
                                                        cout_temp = res_temp[W];
                                    //                    oflow_temp = res_temp[W];
                                                end
                                                `DEC_A : begin
                                                        res_temp = opa_temp - 1;
                                      //                  cout_temp = res_temp[W];
                                                        oflow_temp  = res_temp[W];
                                                end
                                                default : err_temp = 1;
                                          endcase
                                 end
                                 else begin
                                        case(cmd_temp)
                                                `NOT_A : begin
                                                        res_temp = ~opa_temp;
                                                end
                                                `SHR1_A : begin
                                                        res_temp = opa_temp >> 1;
                                                end
                                                `SHL1_A : begin
                                                        res_temp = opa_temp << 1;
                                                end
                                                default: err_temp = 1;
                                        endcase
                                        res_temp[2*W-1 : 8] = 0;
                                end
                        end
                        2'b10: begin
                                if(mode_temp)begin
                                        case (cmd_temp)
                                                `INC_B : begin
                                                        res_temp  = opb_temp + 1;
                                                        cout_temp = res_temp[W];
                                                        //oflow_temp = res_temp[W];
                                                end
                                                `DEC_B : begin
                                                        res_temp = opb_temp - 1;
                                                        oflow_temp  = res_temp[W];
                                                        //cout_temp = res_temp[W];
                                                end
                                                default : err_temp = 1;
                                         endcase
                                 end
                                 else begin
                                           case(cmd_temp)
                                                `NOT_B : begin
                                                        res_temp = ~opb_temp;
                                                end
                                                `SHR1_B : begin
                                                        res_temp = opb_temp >> 1;
                                                end
                                                `SHL1_B : begin
                                                        res_temp = opb_temp << 1;
                                                end
                                                default : begin
                                                        err_temp = 1;
                                                end
                                           endcase
                                           res_temp[2*W-1 : 8] = 0;
                                 end
                        end
                        2'b11 : begin
                                if(mode_temp)begin
                                        case(cmd_temp)
                                                `ADD : begin
                                                        res_temp = opa_temp + opb_temp;
                                                        cout_temp = res_temp[W];
                                                        //oflow_temp = res_temp[W];
                                                end
                                                `SUB : begin
                                                        res_temp = opa_temp - opb_temp;
                                                        oflow_temp = opa_temp < opb_temp;

                                                end
                                                `ADD_CIN : begin
                                                        res_temp = opa_temp + opb_temp + cin_temp;
                                                        cout_temp = res_temp[W];
                                                        //oflow_temp = res_temp[W];
                                                end
                                                `SUB_CIN : begin
                                                        res_temp = opa_temp - opb_temp - cin_temp;
                                                        //cout_temp = opa_temp < (opb_temp + cin_temp);
                                                        oflow_temp = opa_temp < (opb_temp + cin_temp);
                                                end
                                                `INC_A : begin
                                                        res_temp = opa_temp + 1;
                                                        cout_temp = res_temp[W];
                                                        //oflow_temp = res_temp[W];
                                                end
                                                `DEC_A : begin
                                                        res_temp = opa_temp - 1;
                                                        //cout_temp = res_temp[W];
                                                        oflow_temp = res_temp[W];
                                                end
                                                `INC_B : begin
                                                        res_temp = opb_temp + 1;
                                                        cout_temp = res_temp[W];
                                                        //oflow_temp = res_temp[W];
                                                end
                                                `DEC_B : begin
                                                        res_temp = opb_temp - 1;
                                                        //cout_temp = res_temp[W];
                                                        oflow_temp = res_temp[W];
                                                end
                                                `CMP : begin
                                                        g_temp = opa_temp > opb_temp;
                                                        l_temp = opa_temp < opb_temp;
                                                        e_temp = opa_temp == opb_temp;
                                                end
                                                `MULT_INC : begin
                                                        res_temp = (opa_temp + 1) * (opb_temp + 1);
                                                        //cout_temp = res_temp[W];
                                                        //oflow_temp = (2**width >= (opa+1) * (opb + 1));
                                                end
                                                `MULT_SHIFT : begin
                                                        res_temp = (opa_temp << 1) * opb_temp;
                                                        //cout_temp = res_temp[W];
                                                        //oflow_temp = res_temp[W];
                                                end
                                                `ADD_SIGN : begin
                                                        res_temp = $signed(opa_temp) + $signed(opb_temp);
                                                        if((($signed(opa_temp) > 0) && ($signed(opb_temp) > 0) && ($signed(res_temp[W-1:0]) <0)) || (($signed(opa_temp) < 0) && ($signed(opb_temp) < 0) && ($signed(res_temp[W-1:0]) > 0)))
                                                            oflow_temp = 1;
                                                end
                                                `SUB_SIGN : begin
                                                        res_temp = $signed(opa_temp) - $signed(opb_temp);
                                                        if((($signed(opa_temp) > 0 && $signed(opb_temp) < 0) && $signed(res_temp[W-1:0])<0) || (($signed(opa_temp) < 0 && $signed(opb_temp) > 0) && $signed(res_temp[W-1:0])>0))
                                                            oflow_temp = 1;
                                                end
                                                default : err_temp = 1;
                                        endcase
                                end
                                else begin
                                        //logical
                                        case(cmd_temp)
                                                `AND : begin
                                                        res_temp = opa_temp & opb_temp;
                                                end
                                                `NAND : begin
                                                        res_temp = ~(opa_temp & opb_temp);
                                                end
                                                `OR : begin
                                                        res_temp = opa_temp | opb_temp;
                                                end
                                                `NOR : begin
                                                        res_temp = ~ (opa_temp | opb_temp);
                                                end
                                                `XOR : begin
                                                        res_temp = opa_temp ^ opb_temp;
                                                end
                                                `XNOR : begin
                                                        res_temp = ~(opa_temp ^ opb_temp);
                                                end
                                                `NOT_A : begin
                                                        res_temp = ~opa_temp;
                                                end
                                                `NOT_B : begin
                                                        res_temp = ~opb_temp;
                                                end
                                                `SHR1_A : begin
                                                        res_temp = opa_temp >> 1;
                                                end
                                                `SHL1_A : begin
                                                        res_temp = opa_temp << 1;
                                                end
                                                `SHR1_B : begin
                                                        res_temp = opb_temp >> 1;
                                                end
                                                `SHL1_B : begin
                                                        res_temp = opb_temp << 1;
                                                end
                                                `ROL_A_B : begin
                                                        shift = opb_temp[SHIFT_AMNT - 1 : 0];
                                                        if(|opb_temp[W - 1 : W - SHIFT_AMNT - 1]) //if there is atleast one 1 in these bits, give error
                                                                err_temp = 1;
                                                        else begin
                                                                res_temp = (opa_temp << shift) | (opa_temp >> (W - shift));
                                                                res_temp[2*W-1:9] = 0;
                                                        end
                                                end
                                                `ROR_A_B : begin
                                                        shift = opb_temp[SHIFT_AMNT - 1 : 0];
                                                        if(|opb_temp[W - 1 : W - SHIFT_AMNT - 1])//if there is atleast one 1 in these bits, give error
                                                                err_temp = 1;
                                                        else begin
                                                                res_temp = (opa_temp >> shift) | (opa_temp << (W - shift));
                                                                res_temp[2*W-1 : 9] = 0;
                                                        end
                                                end
                                                default : err_temp = 1;
                                        endcase
                                        res_temp[2*W-1:8] = 0;
                                end
                        end
                        default : err_temp = 1;
                endcase
        end



endmodule
