module demosaic(clk, reset, in_en, data_in, wr_r, addr_r, wdata_r, rdata_r, wr_g, addr_g, wdata_g, rdata_g, wr_b, addr_b, wdata_b, rdata_b, done);
input clk;
input reset;
input in_en;
input [7:0] data_in;
output reg wr_r;
output reg [13:0] addr_r;
output reg [7:0] wdata_r;
input [7:0] rdata_r;
output reg wr_g;
output reg [13:0] addr_g;
output reg [7:0] wdata_g;
input [7:0] rdata_g;
output reg wr_b;
output reg [13:0] addr_b;
output reg [7:0] wdata_b;
input [7:0] rdata_b;
output  reg done;


reg [2:0] state, nextstate;
reg [7:0] count;
reg [6:0] wr_count;
reg [13:0] addr, center;
reg odd, select, row, o;
reg [9:0] temp [0:1];

localparam READ_DATA = 0;
localparam Demosaicing = 1;
localparam Write = 2;
localparam Finish = 3;
localparam IDLE = 4;

always @(posedge clk) begin
    if(reset) state <= READ_DATA;
    else state <= nextstate;
end

//next state logic
always @(*) begin
    case (state)
        IDLE : nextstate = (center == 16254)? Finish: Demosaicing;
        READ_DATA: nextstate = (addr == 16383)? IDLE: READ_DATA;
        Demosaicing: nextstate = (o == 1'd1)? Write: Demosaicing;
        Write: nextstate = IDLE;
        default: nextstate = READ_DATA;
    endcase
end

//main sequential circuit
always @(posedge clk) begin
    if (reset) begin
        done <= 1'd0;
        wr_r <= 1'd0;
        wr_g <= 1'd0;
        wr_b <= 1'd0;
        addr_r <= 14'd0;
        addr_g <= 14'd0;
        addr_b <= 14'd0;
        addr <= 14'd0;
        count <= 8'd0;
        wr_count <= 7'd0;
        row <= 1'd0;
        select <= 1'd0;
        center <= 14'd129;
        o <= 1'd0;
    end
    else begin
        case (state)
            IDLE: begin
                wr_r <= 1'd0;
                wr_g <= 1'd0;
                wr_b <= 1'd0;
                count <= 8'd0;
                o <= 1'd0;
                if (wr_count == 126) begin
                    center <= center + 2;
                    row <= row + 1'd1;
                    wr_count <= 0;
                end
            end
            READ_DATA: begin
                count <= count + 1'd1;
                addr <= addr + 1'd1;
                case ({odd, select})
                    2'b00: begin
                        wr_g <= 1'd1;
                        addr_g <= addr;
                        wdata_g <= data_in;
                        select <= 1'd1;
                    end 
                    2'b01: begin
                        wr_r <= 1'd1;
                        addr_r <= addr;
                        wdata_r <= data_in;
                        select <= 1'd0;
                    end
                    2'b10: begin
                        wr_b <= 1'd1;
                        addr_b <= addr;
                        wdata_b <= data_in;
                        select <= 1'd1;
                    end
                    2'b11: begin
                        wr_g <= 1'd1;
                        addr_g <= addr;
                        wdata_g <= data_in;
                        select <= 1'd0;
                    end
                endcase
            end
            Demosaicing: begin
                count <= count + 1;
                case ({row, select})
                    2'b00: begin
                        case (count)
                            0: addr_r <= center - 128; 
                            1: begin
                                addr_r <= center + 128;
                                temp[0] <= rdata_r;
                            end
                            2: begin
                                addr_b <= center - 1;
                                temp[0] <= temp[0] + rdata_r;
                            end
                            3: begin
                                addr_b <= center + 1;
                                temp[1] <= rdata_b;
                            end
                            4: begin
                                temp[1] <= temp[1] + rdata_b;
                                o <= 1'd1;
                            end
                        endcase
                    end 
                    2'b01: begin
                        case (count)
                            0: addr_r <= center - 129; 
                            1: begin
                                addr_r <= center -127;
                                temp[0] <= rdata_r;
                            end
                            2: begin
                                addr_r <= center + 127;
                                temp[0] <= temp[0] + rdata_r;
                            end
                            3: begin
                                addr_r <= center + 129;
                                temp[0] <= temp[0] + rdata_r;
                            end
                            4: begin
                                addr_g <= center - 128;
                                temp[0] <= temp[0] + rdata_r;
                            end
                            5: begin
                                addr_g <= center - 1;
                                temp[1] <= rdata_g;
                            end
                            6: begin
                                addr_g <= center + 1;
                                temp[1] <= temp[1] + rdata_g;
                            end
                            7: begin
                                addr_g <= center + 128;
                                temp[1] <= temp[1] + rdata_g;
                            end
                            8: begin
                                temp[1] <= temp[1] + rdata_g;
                                o <= 1'd1;
                            end
                        endcase
                    end
                    2'b10: begin
                        case (count)
                            0: addr_b <= center - 129; 
                            1: begin
                                addr_b <= center -127;
                                temp[0] <= rdata_b;
                            end
                            2: begin
                                addr_b <= center + 127;
                                temp[0] <= temp[0] + rdata_b;
                            end
                            3: begin
                                addr_b <= center + 129;
                                temp[0] <= temp[0] + rdata_b;
                            end
                            4: begin
                                addr_g <= center - 128;
                                temp[0] <= temp[0] + rdata_b;
                            end
                            5: begin
                                addr_g <= center - 1;
                                temp[1] <= rdata_g;
                            end
                            6: begin
                                addr_g <= center + 1;
                                temp[1] <= temp[1] + rdata_g;
                            end
                            7: begin
                                addr_g <= center + 128;
                                temp[1] <= temp[1] + rdata_g;
                            end
                            8: begin
                                temp[1] <= temp[1] + rdata_g;
                                o <= 1'd1;
                            end
                        endcase
                    end
                    2'b11: begin
                        case (count)
                            0: addr_b <= center - 128; 
                            1: begin
                                addr_b <= center + 128;
                                temp[0] <= rdata_b;
                            end
                            2: begin
                                addr_r <= center - 1;
                                temp[0] <= temp[0] + rdata_b;
                            end
                            3: begin
                                addr_r <= center + 1;
                                temp[1] <= rdata_r;
                            end
                            4: begin
                                temp[1] <= temp[1] + rdata_r;
                                o <= 1'd1;
                            end
                        endcase
                    end 
                endcase        
            end
            Write: begin
                wr_count <= wr_count + 1'd1;
                center <= center + 1;
                case ({row, select})
                    2'b00: begin
                        wr_r <= 1'd1;
                        wr_b <= 1'd1;
                        addr_r <= center;
                        addr_b <= center;
                        wdata_r <= temp[0] >> 1;
                        wdata_b <= temp[1] >> 1;
                        select <= 1'd1;
                    end 
                    2'b01: begin
                        wr_r <= 1'd1;
                        wr_g <= 1'd1;
                        addr_r <= center;
                        addr_g <= center;
                        wdata_r <= temp[0] >> 2;
                        wdata_g <= temp[1] >> 2;
                        select <= 1'd0;
                    end
                    2'b10: begin
                        wr_b <= 1'd1;
                        wr_g <= 1'd1;
                        addr_b <= center;
                        addr_g <= center;
                        wdata_b <= temp[0] >> 2;
                        wdata_g <= temp[1] >> 2;
                        select <= 1'd1;
                    end
                    2'b11: begin
                        wr_b <= 1'd1;
                        wr_r <= 1'd1;
                        addr_b <= center;
                        addr_r <= center;
                        wdata_b <= temp[0] >> 1;
                        wdata_r <= temp[1] >> 1;
                        select <= 1'd0;
                    end 
                endcase
            end
            Finish: begin
                done <= 1'd1;
            end 
        endcase
    end
end

always @(*) begin
    if (count < 8'd128) begin
        odd = 1'd0;
    end
    else begin
        odd = 1'd1;
    end
end

endmodule
