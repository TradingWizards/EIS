/* 
**
**    TradingWizards 
**
**    Revision History
**    Date     Name           Desc
**    6/17/17  JP             First version of Bot based on EIS & ATR
**
**
**
**
**    Basic Entry & Exit Rules
**      ENTRY RULES:
**      Current ATR should be GREATER THAN past ATR
**          Open Price above 65 MA AND EIS prev bar is green
**          Cllose Price below 65 MA AND EIS current bar is green
**      
**      EXIT RULES:
**      SL is based on currency - Check optimization report
**      Trailing stop is based on currency - Check optimization report
**      Close if the Price closes below OR above MA 65 OR prev bar color is different
**
**      POSITION SIZING RULE:
**      1 Lot
*/



/*
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 1

#property indicator_buffers 3
#property indicator_color1 Lime
#property indicator_color2 Blue
#property indicator_color3 Red
*/

#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2
#define SIGNAL_CLOSEBUY 3
#define SIGNAL_CLOSESELL 4


extern int MagicNumber = 12349;
extern bool SignalMail = False;
extern double Lots = 1.0;
extern int Slippage = 3;
extern bool UseStopLoss = True;
extern int StopLoss = 30;
extern bool UseTakeProfit = False;
extern int TakeProfit = 0;
extern bool UseTrailingStop = True;
extern int TrailingStop = 10;
extern int TrailingStopBuff = 5;
extern int atr_period = 7; //20;
extern int atr_shift = 5; //11;

extern int ShowBars = 500;


double alpha = 0;
double alpha_1 = 0;
double atr_current =0.0, atr_past =0.0;
int P = 1;
int Order = SIGNAL_NONE;
int Total, Ticket, Ticket2;
double StopLossLevel, TakeProfitLevel, StopLevel;

double ma_65;

double eis_up = 0.0, eis_down = 0.0, eis_neutral = 0.0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   
   if(Digits == 5 || Digits == 3 || Digits == 1)P = 10;else P = 1; // To account for 5 digit brokers


   return(0);
}
//+------------------------------------------------------------------+
//| Expert initialization function - END                             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   return(0);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function - END                           |
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
int start() {

   bool IsTrade = False;
   
   
   atr_current =0.0;
   atr_past =0.0;
   
   Total = OrdersTotal();
   Order = SIGNAL_NONE;

   //+------------------------------------------------------------------+
   //| Variable Setup                                                   |
   //+------------------------------------------------------------------+
 
   //Print ( "In Start ");

   ma_65 = iMA(NULL, 0, 65, 0, MODE_EMA, PRICE_CLOSE, 1);

   atr_current = iATR(NULL, 0, atr_period, 1);    // ATR(20) now
   atr_past = iATR(NULL, 0, atr_period, atr_shift);      // ATR(20) 10 periods ago
   
   //Print ( "iOpen is " + DoubleToString(iOpen(NULL, 0, 0)) + " ma_65 is " + DoubleToString(ma_65) );
   
   StopLevel = (MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD)) / P; 
   
   if (StopLoss < StopLevel) StopLoss = StopLevel;
   if (TakeProfit < StopLevel) TakeProfit = StopLevel;

   //+------------------------------------------------------------------+
   //| Variable Setup - END                                             |
   //+------------------------------------------------------------------+

   //Check position


   for (int i = 0; i < Total; i ++) {
      Ticket2 = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType() <= OP_SELL &&  OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {

         IsTrade = True;


         if(OrderType() == OP_BUY) {
            //Close

            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Buy)                                           |
            //+------------------------------------------------------------------+

            /* 
               EXIT RULES:
            */
                      
            if(Bid < ma_65 || eis_down == 1 || eis_neutral == 1 ) Order = SIGNAL_CLOSEBUY; // Rule to EXIT a Long trade

            //+------------------------------------------------------------------+
            //| Signal End(Exit Buy)                                             |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSEBUY) {
               Ticket2 = OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, MediumSeaGreen);
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Close Buy");
               IsTrade = False;
               continue;
            }
            //Trailing stop
            if(UseTrailingStop && TrailingStop > 0) {                 
               if(Bid - OrderOpenPrice() > P * Point * (TrailingStop) ) {
                  Print ( "In Buy SL["+ DoubleToString(OrderStopLoss()) + "] Bid [" + DoubleToString(Bid) +"] P*Pt*TS["+DoubleToString(P * Point * TrailingStop) +
                           "] Bid-P*Pt*TS[" + DoubleToString(Bid - P * Point * TrailingStop) );               
                  if(OrderStopLoss() < Bid - P * Point * TrailingStop) {
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - P * Point * TrailingStop, OrderTakeProfit(), 0, MediumSeaGreen);
                     continue;
                  }
               }
            }
         } else {
            //Close

            //+------------------------------------------------------------------+
            //| Signal Begin(Exit Sell)                                          |
            //+----------------------------------------------------------f--------+

            if (Ask > ma_65 || eis_up == 1 || eis_neutral == 1) Order = SIGNAL_CLOSESELL; // Rule to EXIT a Short trade

            //+------------------------------------------------------------------+
            //| Signal End(Exit Sell)                                            |
            //+------------------------------------------------------------------+

            if (Order == SIGNAL_CLOSESELL) {
               Ticket2 = OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, DarkOrange);
               if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Close Sell");
               IsTrade = False;
               continue;
            }
            //Trailing stop
            if(UseTrailingStop && TrailingStop > 0) {                 
               if((OrderOpenPrice() - Ask) > (P * Point * (TrailingStop))) {
                  Print ( "In Sell SL["+ DoubleToString(OrderStopLoss()) + "] Ask [" + DoubleToString(Ask) +"] P*Pt*TS["+DoubleToString(P * Point * TrailingStop) +
                           "] Ask+P*Pt*TS[" + DoubleToString(Ask + P * Point * TrailingStop) );
                  if((OrderStopLoss() > (Ask + P * Point * TrailingStop)) || (OrderStopLoss() == 0)) {
                     Ticket2 = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + P * Point * TrailingStop, OrderTakeProfit(), 0, DarkOrange);
                     continue;
                  }
               }
            }
         }
      }
   }

   //+------------------------------------------------------------------+
   //| Signal Begin(Entries)                                            |
   //+------------------------------------------------------------------+

   /* 
   ** ENTRY RULES:
   **   Enter a long trade when price above ma_65 and prev bar is green
   **   Enter a short trade when price below ma_65 and prev baris red
   */
   
   if (NewBar() && atr_current > atr_past)
   {
      if ( iClose(NULL, 0, 1) > ma_65 )
      {
         Print (" iClose is > ma_65 ");
            
         //setupEIS();
         //eis_up = iCustom(NULL, 0, "Elder_Impulse_System", 2000, 0, 1);
         //eis_down = iCustom(NULL, 0, "Elder_Impulse_System", 2000, 2, 1);
      
         Print ("EIS Ind is " + DoubleToString(eis_up) );
            
         if (eis_up == 1)
         {
            Order = SIGNAL_BUY; // Rule to ENTER a Long trade
         }
      }
      
      if ( iClose(NULL, 0, 1) < ma_65 )
      {
         Print ("iClose is < ma_65 ");
         
         //setupEIS();
         
         //eis_up = iCustom(NULL, 0, "Elder_Impulse_System", 2000, 0, 1);
         //eis_down = iCustom(NULL, 0, "Elder_Impulse_System", 2000, 2, 1);      
         
         Print ("EIS Ind is " + DoubleToString(eis_down) );
         
         if (eis_down == 1)
         {
            Order = SIGNAL_SELL; // Rule to ENTER a Short trade
         }      
      }
   }


   //+------------------------------------------------------------------+
   //| Signal End                                                       |
   //+------------------------------------------------------------------+

   //Buy
   if (Order == SIGNAL_BUY) {
      if(!IsTrade) {
         //Check free margin
         if (AccountFreeMargin() < (1000 * Lots)) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
            return(0);
         }

         if (UseStopLoss) StopLossLevel = Ask - StopLoss * Point * P; else StopLossLevel = 0.0;
         if (UseTakeProfit) TakeProfitLevel = Ask + TakeProfit * Point * P; else TakeProfitLevel = 0.0;

         Ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, Slippage, StopLossLevel, TakeProfitLevel, "Buy(#" + MagicNumber + ")", MagicNumber, 0, DodgerBlue);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				Print("BUY order opened : ", OrderOpenPrice());
                if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Ask, Digits) + " Open Buy");
			} else {
				Print("Error opening BUY order : ", GetLastError());
			}
         }
         return(0);
      }
   }

   //Sell
   if (Order == SIGNAL_SELL) {
      if(!IsTrade) {
         //Check free margin
         if (AccountFreeMargin() < (1000 * Lots)) {
            Print("We have no money. Free Margin = ", AccountFreeMargin());
            return(0);
         }

         if (UseStopLoss) StopLossLevel = Bid + StopLoss * Point * P; else StopLossLevel = 0.0;
         if (UseTakeProfit) TakeProfitLevel = Bid - TakeProfit * Point * P; else TakeProfitLevel = 0.0;

         Ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, Slippage, StopLossLevel, TakeProfitLevel, "Sell(#" + MagicNumber + ")", MagicNumber, 0, DeepPink);
         if(Ticket > 0) {
            if (OrderSelect(Ticket, SELECT_BY_TICKET, MODE_TRADES)) {
				Print("SELL order opened : ", OrderOpenPrice());
                if (SignalMail) SendMail("[Signal Alert]", "[" + Symbol() + "] " + DoubleToStr(Bid, Digits) + " Open Sell");
			} else {
				Print("Error opening SELL order : ", GetLastError());
			}
         }
         return(0);
      }
   }

   return(0);
}
//+------------------------------------------------------------------+

bool NewBar() 
{
   
   static datetime New_Time=0; // New_Time = 0 when New_Bar() is first called
   
   if(New_Time!=Time[0])
   {      // If New_Time is not the same as the time of the current bar's open, this is a new bar
      
      New_Time=Time[0];        // Assign New_Time as time of current bar's open
      
      Print ( "New Bar is  set and atr_current is [" + DoubleToString(atr_current) + "] atr_past is [" + DoubleToString(atr_past) +  "]" );
      
      /*
      ** Set EIS
      */
         eis_up = iCustom(NULL, 0, "Elder_Impulse_System", ShowBars, 0, 1);
         eis_down = iCustom(NULL, 0, "Elder_Impulse_System", ShowBars, 2, 1);
         eis_neutral = iCustom(NULL, 0, "Elder_Impulse_System", ShowBars, 1, 1);
      
      return(true);
   
   }
   
   return(false);

}