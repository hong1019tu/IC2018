module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output reg[5:0] IROM_A;
output reg IRAM_valid;
output reg[7:0] IRAM_D;
output reg[5:0] IRAM_A;
output reg busy;
output reg done;
reg [9:0]x,y,addr,count;
reg signed [15:0] sum;
reg [7:0] arr [63:0];
reg signed [9:0] load,load2,load3;//for write
reg [7:0]max1,max2,max3,min1,min2,min3;

always @(posedge clk or posedge reset) begin
    if(reset)begin
      IROM_rd <= 1'd0;
      IROM_A <= 6'd0;
      IRAM_valid <= 1'd0;
      IRAM_A <= 6'd0;
      busy <= 1'd1;
      done <= 1'd0;
      load <= -10'd1;//for all
      load2 <= -10'd2;//for write
      count <= 10'd0;
      load3 <= -10'd1;//for avg and max
    end
    else begin
      load <= load + 10'd1;
      if(load == -10'd1)begin
        IROM_rd <= 1'd1;
      end
      else if(load <= 64) begin
        arr[load] <= IROM_Q;
        IROM_A <= IROM_A + 6'd1;
      end
      if (load == 65) begin
        IROM_rd <= 1'd0;
        x <= 3;
        y <= 3;
        busy <= 1'd0;
      end
      else if(load > 10'd64)begin
        busy <= 1'd1;
        case (cmd)
            4'd0:begin//write
              load2 <= load2 + 10'd1;
              if(load2 == -10'd2)begin
                IRAM_valid <= 1;
              end      
              else if (load2 == -10'd1) begin
                IRAM_D <= arr[0];
              end     
              else if (load2 < 10'd63) begin
                IRAM_D <= arr[load2 + 1];
                IRAM_A <= IRAM_A + 6'd1;
              end
              else if (load2 == 63) begin
                busy <= 1'd0;
                done <= 1'd1;
                load2 <= -10'd2;
              end
            end
            4'd1:begin//u
              if (y > 0) begin
                y <= y - 1;
                busy <= 1'd0;
              end
              else begin
                y <= y;
                busy <= 1'd0;
              end
            end
            4'd2:begin//d
              if (y < 6) begin
                y <= y + 1;
                busy <= 1'd0;
              end
              else begin
                y <= y;
                busy <= 1'd0;
              end
            end
            4'd3:begin//l
              if (x > 0) begin
                x <= x - 1;
                busy <= 1'd0;
              end
              else begin
                x <= x;
                busy <= 1'd0;
              end
            end
            4'd4:begin//r
              if (x < 6) begin
                x <= x + 1;
                busy <= 1'd0;
              end
              else begin
                x <= x;
                busy <= 1'd0;
              end
            end
            4'd5:begin//max
                load3 <= load3 + 10'd1;
                if(load3 == -10'd1)begin
                    max1 <= (arr[addr]>arr[addr+1])?arr[addr]:arr[addr+1];
                    max2 <= (arr[addr+8]>arr[addr+9])?arr[addr+8]:arr[addr+9];
                end
                else if (load3 == 10'd0) begin
                    max3 <= (max1>max2)?max1:max2;
                end
                else if (load3 == 10'd1) begin
                    arr[addr] <= max3;
                    arr[addr+1] <= max3;
                    arr[addr+8] <= max3;
                    arr[addr+9] <= max3;
                    load3 <= -10'd1;
                    busy <= 1'd0;
                end
            end
            4'd6:begin//min
              load3 <= load3 + 10'd1;
                if(load3 == -10'd1)begin
                    min1 <= (arr[addr]<arr[addr+1])?arr[addr]:arr[addr+1];
                    min2 <= (arr[addr+8]<arr[addr+9])?arr[addr+8]:arr[addr+9];
                end
                else if (load3 == 10'd0) begin
                    min3 <= (min1<min2)?min1:min2;
                end
                else if (load3 == 10'd1) begin
                    arr[addr] <= min3;
                    arr[addr+1] <= min3;
                    arr[addr+8] <= min3;
                    arr[addr+9] <= min3;
                    load3 <= -10'd1;
                    busy <= 1'd0;
                end
            end
            4'd7:begin//avg
              load3 <= load3 + 10'd1;
              if(load3 == -10'd1)begin
                sum <= arr[addr] + arr[addr+1] + arr[addr+8] + arr[addr+9];
              end
              else if (load3 >= 10'd0) begin
                if (sum - $signed(4) >= 0) begin
                  sum <= sum - $signed(4); 
                  count <= count + 10'd1; 
                end
                else begin
                  arr[addr] <= count;
                  arr[addr+1] <= count;
                  arr[addr+8] <= count;
                  arr[addr+9] <= count;
                  load3 <= -1;
                  count <= 0;
                  busy <= 1'd0;
                end
              end  
            end
            4'd8:begin//ccr
              arr[addr] <= arr[addr+1];
              arr[addr+1] <= arr[addr+9];
              arr[addr+8] <= arr[addr];
              arr[addr+9] <= arr[addr+8];
              busy <= 1'd0;
            end
            4'd9:begin//cr
              arr[addr] <= arr[addr+8];
              arr[addr+8] <= arr[addr+9];
              arr[addr+1] <= arr[addr];
              arr[addr+9] <= arr[addr+1];
              busy <= 1'd0;
            end
            4'd10:begin//m_x
              arr[addr] <= arr[addr+8];
              arr[addr+8] <= arr[addr];
              arr[addr+1] <= arr[addr+9];
              arr[addr+9] <= arr[addr+1];
              busy <= 1'd0;
            end
            4'd11:begin//m_y
              arr[addr] <= arr[addr+1];
              arr[addr+1] <= arr[addr];
              arr[addr+8] <= arr[addr+9];
              arr[addr+9] <= arr[addr+8];
              busy <= 1'd0;
            end  
        endcase
      end
    end 
end//always
always @(*) begin
  addr <= y * 8 + x;
end
endmodule



