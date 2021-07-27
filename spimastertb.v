
module spimastertb();
  
  reg clk,rst,start,MISO;
  reg [7:0] DatatoTransmit;
  reg [1:0] MODE,clkdiv;
  
  wire finish,Sclk,MOSI,SS;
  wire [7:0] DataReceived;
  
  spi_master DUT(clk,rst,start,MODE,clkdiv,DatatoTransmit,finish,
                  DataReceived,MISO,Sclk,MOSI,SS);
  
  initial
  begin
    $dumpfile("spimastertb.vcd");
    $dumpvars(0,spimastertb);
    #1000 $finish;
  end
  
  initial 
    begin
      clk = 1;
      forever #5 clk = ~ clk;
    end
  
  
  initial 
    begin
     
      clkdiv=2'b00; MODE=2'b01;start=0;
      #20 rst = 1;
      #10 rst = 0;
      #10 DatatoTransmit=8'b11011101;
      #80 start = 1;
      #10 start = 0;
      // 140 sec next line
      #10 MISO = 1;
      #40 MISO = 1;
      #40 MISO = 0;
      #40 MISO = 0;
      #40 MISO = 1;
      #40 MISO = 1;
      #40 MISO = 1;
      #40 MISO = 0;
     
      
    end
endmodule
  
  
