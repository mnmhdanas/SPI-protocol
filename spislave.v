
module spi_slave(start,MODE,TxData,RxData,Sclk,SS,MOSI,MISO);


// spi 4 wires
input start;
input SS,MOSI,Sclk;
output reg MISO;
////

input [1:0]MODE;
  input [7:0] TxData;
  output reg [7:0]  RxData;

///

wire CPOL,CPHA;
reg Dout;
reg [7:0]SlaveReg;

    assign CPOL = (MODE==2) || (MODE==3);
    assign CPHA = (MODE==1) || (MODE==3);

       //assign MISO = (SS) ? 1'bz: SlaveReg[7];
    
  
  reg [5:0] sclkcount = 0;
    always@(posedge Sclk)
      begin
        if(sclkcount==9)
          begin
            sclkcount = 0;
          end  
        else if((sclkcount>=0)&&(sclkcount<=8))
          begin
            sclkcount <= sclkcount +1;
          end
        else 
          begin
            sclkcount <= sclkcount ;
          end
      end
  
  //always@(*)
    //begin 
     // if((MODE==0)&&(sclk_counts == 1))
      //  MISO = TxData[7];
    //end
    
  
  always@(start)
       begin
         if(start) 
        SlaveReg <= TxData;
        else
        SlaveReg <= SlaveReg;
       end

     always @ (posedge Sclk)
         case ( {CPOL, CPHA} )
          2'b00:begin 
                 RxData <= {RxData[6:0], MOSI};
                end
          2'b01,2'b10: begin
                   SlaveReg <= {SlaveReg[6:0], 1'b0};
                   MISO <= SlaveReg[7];
                     end
         2'b11: begin
                 RxData <= {RxData[6:0], MOSI};
                end
         default: ;
         endcase

     always @ (negedge Sclk)
         case ( {CPOL, CPHA} )
         2'b00: begin
           SlaveReg <= {SlaveReg[6:0], 1'b0};
           MISO <= SlaveReg[7];
                end
        2'b01,2'b10: begin
                     RxData <= {RxData[6:0], MOSI};
                     end
        2'b11: begin
              SlaveReg <= {SlaveReg[6:0], 1'b0};
              MISO <= SlaveReg[7];
              end
         default: ;
          endcase
     
  reg [5:0]sclkcountdelayed;
  always@(negedge Sclk)
      sclkcountdelayed <= sclkcount;
  
  reg [7:0] slavereceived;
  always@(sclkcount,sclkcountdelayed)
    case(MODE)
      0: if(sclkcount==9)
           slavereceived <= RxData;
      1: if(sclkcountdelayed == 8)
            slavereceived <= RxData;
      2: if(sclkcountdelayed == 8)
            slavereceived <= RxData;
      3: if(sclkcount ==8)
           slavereceived <= RxData;
      default:;
    endcase
 
           
            
           
  
 endmodule
