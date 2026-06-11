//+------------------------------------------------------------------+
//| GridEA.mq5                                                       |
//| MetaTrader 5 Grid Expert Advisor                                 |
//| Author: MubinCodes                                               |
//| GitHub: https://github.com/MubinCodes                            |
//|                                                                  |
//| This EA demonstrates grid trading logic, range control,          |
//| profit-target restart, and on-chart monitoring.                  |
//|                                                                  |
//| Disclaimer: This project is for educational and portfolio        |
//| demonstration purposes only. Trading involves risk.              |
//+------------------------------------------------------------------+




#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"





                                             //adding target reached feature
                                             //this is the latest than dream 1
#include <Trade/Trade.mqh>
CTrade trade; // Create a trade object

//magic number
string a=IntegerToString(MathRand())+IntegerToString(MathRand());
int converted= StringToInteger(a);
int magicNumber=converted;


input string gap70= "";//Day Settings 
input bool Allow_Monday_trading=true;
input bool Allow_Tuesday_trading=true;
input bool Allow_Wednesday_trading=true;
input bool Allow_Thursday_trading=true;
input bool Allow_Friday_trading=true;
input bool Allow_Saturday_trading=false;
input bool Allow_Sunday_trading=false;

input group           "Group name #2";
input string gap2= "-----------------------------------------------------" ; // -----------------------------------------------------
input string Sessions="Time"; 
input string Trading_time_start ="02:00"; //Session start(MT5 time)
input string Trading_time_end="23:59"; //Session end (MT5 time)

input string gap40= "-----------------------------------------------------" ; // -----------------------------------------------------


input double LotSize= 0.01;
input double GridGap = 50;
input int TotalGridLines = 100; // GridLines(Each Side)

input string gap41= "-----------------------------------------------------" ; // -----------------------------------------------------

input bool CloseWhenOutOfRange = true;

input string gap42= "-----------------------------------------------------" ; // -----------------------------------------------------

input bool RestartWhenHitProfitTarget = false;
input double TargetAmount = 10;




input group           "";
input string gap72= "-----------------------------------------------------" ; // -----------------------------------------------------

input double FontSize = 15;
input color FontColor = clrRed;

input group           "";
input string gap73= "-----------------------------------------------------" ; // -----------------------------------------------------


input bool RestartWhenOutOfTheRange = false;




//for my extra use
double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
      trade.SetExpertMagicNumber(magicNumber);
      

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
         
         
         double totalMoneyFromRebate = GetTotalLotsFromHistory() * 15;
         
         Alert("");
         Alert("totalMoneyFromRebate: ",totalMoneyFromRebate);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

        double pip= Point() * 10;
        
        double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), Digits());
		  double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), Digits());
         
        //Current time new shit
        datetime currentTime= TimeCurrent();
        // Time functions 1            
        datetime inStart= GetBrokerTime(Trading_time_start);
        datetime inEnd= GetBrokerTime(Trading_time_end);
        
        
        
        //-------------------------------------------------------------------------
        
        double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        
        
        double currentProfit = accountEquity - accountBalance;
        
        
        ObjectCreate(0, "CurrentProfit", OBJ_LABEL, 0, 0, 0);
        // Set the text properties
        ObjectSetInteger(0, "CurrentProfit", OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, "CurrentProfit", OBJPROP_XDISTANCE, 20);
        ObjectSetInteger(0, "CurrentProfit", OBJPROP_YDISTANCE, 50);
        ObjectSetInteger(0, "CurrentProfit", OBJPROP_COLOR, FontColor);
        ObjectSetInteger(0, "CurrentProfit", OBJPROP_FONTSIZE, FontSize); 
        ObjectSetString(0, "CurrentProfit", OBJPROP_TEXT, "CurrentProfit: " +  DoubleToString(currentProfit, 2));
        
        
        
        
        
        static bool initialOrders = true;
        
        
        static bool tradeToday = false;
        
        if(NewBarAppearedDaily())
        {
            tradeToday = true;
        }
        
        if(currentTime >= inStart && currentTime < inEnd && DayTradingAllowed()
            && Count() == 0 && initialOrders == true) // time filte, start and end time ,   && tradeToday
        {
            double firstBuyLine = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), Digits()); //ASk
            double firstSellLine = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), Digits());//BID
            
            double buyStopLine;
            double sellLimitLine;
            
            double buyLimitLine; 
            double sellStopLine;
            
            int increase = 1;
            
            int originalTotalGridLines = TotalGridLines / 2;
            
            string commentBuy;
            string commentSell;
            
            
            string commentBuyStop;
            string commentSellLimit;
            
            string commentBuyLimit;
            string commentSellStop;
            
            for(int i = 0; i < TotalGridLines; i++)
            {
               
            
               if(Count() == 0) //market orders
               {
                  commentBuy = DoubleToString(firstBuyLine);
                  commentSell = DoubleToString(firstSellLine);
               
                  trade.Buy(LotSize, NULL, firstBuyLine, 0, 0, commentBuy);
                  trade.Sell(LotSize, NULL, firstSellLine, 0, 0, commentSell);
               }
               
               //upside pending
               buyStopLine = firstBuyLine + (GridGap * increase) * pip;
               sellLimitLine = firstSellLine + (GridGap * increase) * pip;
               
               commentBuyStop = DoubleToString(buyStopLine);
               commentSellLimit = DoubleToString(sellLimitLine);
               
               trade.BuyStop(LotSize, buyStopLine, NULL, 0, 0, ORDER_TIME_GTC, 0, commentBuyStop);
               trade.SellLimit(LotSize, sellLimitLine, NULL, 0, 0, ORDER_TIME_GTC, 0, sellLimitLine);
               
               
               
               
               //downside pendings
               buyLimitLine = firstBuyLine - (GridGap * increase) * pip;
               sellStopLine = firstSellLine - (GridGap * increase) * pip;
               
               commentBuyLimit = DoubleToString(buyLimitLine);
               commentSellStop = DoubleToString(sellStopLine);
               
               trade.SellStop(LotSize, sellStopLine, NULL, 0, 0, ORDER_TIME_GTC, 0, sellStopLine);
               trade.BuyLimit(LotSize, buyLimitLine, NULL, 0, 0, ORDER_TIME_GTC, 0, commentBuyLimit);
               
               increase += 1; 
            }
            
            initialOrders = false;
        }
        
        
        
        
        //closing and sending other other
        int firstDistance;
        double positionOpenPrice;
        
        bool closeResult = false;
        
        bool recoveryTradeResult = false;
        
        //Alert("");
        //Alert("Highest price: ",GetHighestPendingOrderPrice());
        
        if(initialOrders == false)
        {
           for(int i = 0; i < PositionsTotal(); i++)
           {
               ulong posiotionTicket = PositionGetTicket(i);
               
               if(PositionGetSymbol(i) == Symbol() && PositionGetInteger(POSITION_MAGIC) == magicNumber) //
               {
                 // positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                  
                  positionOpenPrice = NormalizeDouble(StringToDouble(PositionGetString(POSITION_COMMENT)), Digits());
                  
                  if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) // buy
                  {
                     
                     firstDistance= (Bid- positionOpenPrice)/pip;
                     
                     if(firstDistance >= GridGap)
                     {
                        closeResult = trade.PositionClose(posiotionTicket);
                        
                        if(closeResult) // check the price and place the order accordingly
                        {
                           while(recoveryTradeResult == false)
                           {
                              if(Ask > positionOpenPrice)
                              {
                                 recoveryTradeResult = trade.BuyLimit(LotSize, positionOpenPrice, NULL, 0, 0, ORDER_TIME_GTC, 0, positionOpenPrice);
                              }
                              else if(Ask < positionOpenPrice)
                              {
                                 recoveryTradeResult = trade.BuyStop(LotSize, positionOpenPrice, NULL, 0, 0, ORDER_TIME_GTC, 0, positionOpenPrice);
                              }
                              
                              Sleep(1000);
                           }
                           
                           
                        }
                     }
                     
                     
                     
                  }
                  else if(PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) // Sell
                  {
                       firstDistance= (positionOpenPrice - Bid)/pip;
                       
                       if(firstDistance >= GridGap)
                       {
                           closeResult = trade.PositionClose(posiotionTicket);
                           
                           while(recoveryTradeResult == false)
                           {
                              if(Bid < positionOpenPrice)
                              {
                                 recoveryTradeResult = trade.SellLimit(LotSize, positionOpenPrice, NULL, 0, 0, ORDER_TIME_GTC, 0, positionOpenPrice);
                              }
                              else if(Bid > positionOpenPrice)
                              {
                                 recoveryTradeResult = trade.SellStop(LotSize, positionOpenPrice, NULL, 0, 0, ORDER_TIME_GTC, 0, positionOpenPrice);
                              }
                              
                              Sleep(1000);
                           }
                       }
                  }
               }
           }
           
           
           
           //-----------------------------------------------------------------------
           
               if(CountMarketOrders())
               {
                  double highestLine = GetHighestPendingOrderPrice();
                  double lowestLine = GetLowestPendingOrderPrice();
                  
                  
                  
                  if(RestartWhenOutOfTheRange)
                  {
                     if(Bid > highestLine)
                     {
                        
                        
                        CloseAllOrders();
                        
                        Alert("");
                        Alert("UpperSide");
                        
                        accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
                        initialOrders = true; ////not remove, only restarting
                        tradeToday = false;
                     }
                     
                     
                     if(Bid < lowestLine)
                     {
                        
                        CloseAllOrders();
                        
                        Alert("");
                        Alert("LowerSide");
                        
                        accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
                        initialOrders = true; //not remove, only restarting
                        tradeToday = false;
                     }

                  
                  }
                  else if(RestartWhenOutOfTheRange == false) //no restart. direct close the EA
                  {
                     if(Bid > highestLine)
                     {
                        
                        
                        CloseAllOrders();
                        
                        Alert("");
                        Alert("UpperSide");
                        ExpertRemove(); // remove here
                     }
                     
                     
                     if(Bid < lowestLine)
                     {
                        
                        CloseAllOrders();
                        
                        Alert("");
                        Alert("LowerSide");
                        
                        ExpertRemove(); // remove here
                     }
                  }
                  
                  
                  
               }
           
           
           
           
           
           
           
           //profit target hit
           if(RestartWhenHitProfitTarget)
           {
               if(currentProfit >= TargetAmount)
               {
                  CloseAllOrders();
                        
                  Alert("");
                  Alert("Target reached");
                  
                  
                  accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
                  
                  initialOrders = true; ////not remove, only restarting
                  tradeToday = false;
               }
           }
        }
        
        
        
        
        
        
        
        
        
  } 
//+------------------------------------------------------------------+


datetime GetBrokerTime(string timeStr) {
   datetime brokerDate = TimeCurrent(); // Broker's current date and time
   string dateStr = TimeToString(brokerDate, TIME_DATE); // Broker's date as string
   return StringToTime(dateStr + " " + timeStr); // Combine date with desired time
}



// Function to check if trading is allowed on the current day
bool DayTradingAllowed()
{
    // Get current server time
    datetime currentTime = TimeCurrent();

    // Convert to MqlDateTime structure
    MqlDateTime dateTimeStruct;
    TimeToStruct(currentTime, dateTimeStruct);

    // Retrieve the day of the week
    int dayOfWeek = dateTimeStruct.day_of_week;

    // Check trading permission for each day
    switch (dayOfWeek)
    {
        case 0: return Allow_Sunday_trading;    // Sunday
        case 1: return Allow_Monday_trading;   // Monday
        case 2: return Allow_Tuesday_trading;  // Tuesday
        case 3: return Allow_Wednesday_trading;// Wednesday
        case 4: return Allow_Thursday_trading; // Thursday
        case 5: return Allow_Friday_trading;   // Friday
        case 6: return Allow_Saturday_trading; // Saturday
    }
    return false; // Default: not allowed
}


int Count() // all orders including pending
{
   int result = 0;

   // Count open positions
   for(int i = 0; i < PositionsTotal(); i++)
   {
        ulong posiotionTicket = PositionGetTicket(i);
   
        if(PositionGetSymbol(i) == Symbol() && PositionGetInteger(POSITION_MAGIC) == magicNumber) //
        {
           result++;
        }
      
   }
   
   
   // Count pending orders
   for(int i = 0; i < OrdersTotal(); i++)
   {
        ulong orderTicket = OrderGetTicket(i);
        
   
        if(OrderGetString(ORDER_SYMBOL) == Symbol() && OrderGetInteger(ORDER_MAGIC) == magicNumber) //&& PositionGetInteger(POSITION_MAGIC) == magicNumber
        {
           result++;
        }
      
   }
   
   return result;

}




double GetHighestPendingOrderPrice() {
   double highestPrice = 0.0; // Initialize with the lowest possible value

   for (int i = 0; i < OrdersTotal(); i++)
   {
      ulong orderTicket = OrderGetTicket(i);
       
      if(OrderGetString(ORDER_SYMBOL) == Symbol() && OrderGetInteger(ORDER_MAGIC) == magicNumber) //&& PositionGetInteger(POSITION_MAGIC) == magicNumber
      {
         int orderType = OrderGetInteger(ORDER_TYPE); // Get the position type
         
         double orderOpenPrice = OrderGetDouble(ORDER_PRICE_OPEN);
         
         if(orderType == ORDER_TYPE_BUY_STOP)
         {
            if (orderOpenPrice > highestPrice) {
                  highestPrice = orderOpenPrice;
               }
         }
      }
 
   }

   return highestPrice; // Return the highest price found
}



double GetLowestPendingOrderPrice() {
   double lowestPrice = INT_MAX; // Initialize with the lowest possible value

   for (int i = 0; i < OrdersTotal(); i++)
   {
      ulong orderTicket = OrderGetTicket(i);
       
      if(OrderGetString(ORDER_SYMBOL) == Symbol() && OrderGetInteger(ORDER_MAGIC) == magicNumber) //&& PositionGetInteger(POSITION_MAGIC) == magicNumber
      {
         int orderType = OrderGetInteger(ORDER_TYPE); // Get the position type
         
         double orderOpenPrice = OrderGetDouble(ORDER_PRICE_OPEN);
         
         if(orderType == ORDER_TYPE_SELL_STOP)
         {
            if (orderOpenPrice < lowestPrice) {
                  lowestPrice = orderOpenPrice;
               }
         }
      }
 
   }

   return lowestPrice; // Return the highest price found
}




void CloseAllOrders() //including pending
{
   // Count of open positions
   int totalOrders = PositionsTotal();
   ulong MagicNumber = PositionGetInteger(POSITION_MAGIC);

   // Loop through each open position
   for (int i = totalOrders - 1; i >= 0; i--)
   {       
      // Get the position ticket
      ulong ticket = PositionGetTicket(i);
      
      string symbol = PositionGetString(POSITION_SYMBOL);
      
      if(_Symbol == symbol && MagicNumber == magicNumber)
      {
          trade.PositionClose(ticket);
      }

      
   }
   
   
   int PendingOrders = OrdersTotal();
   
   // Loop through each open position
   for (int i = PendingOrders - 1; i >= 0; i--)
   { 
      ulong ticket = OrderGetTicket(i);
      string symbol = OrderGetString(ORDER_SYMBOL);
      if(_Symbol == symbol && MagicNumber == magicNumber)
      {
          trade.OrderDelete(ticket);
      }
   }
}


int CountMarketOrders() 
{
   int result = 0;

   // Count open positions
   for(int i = 0; i < PositionsTotal(); i++)
   {
        ulong posiotionTicket = PositionGetTicket(i);
   
        if(PositionGetSymbol(i) == Symbol() && PositionGetInteger(POSITION_MAGIC) == magicNumber) //
        {
           result++;
        }
      
   }
   
   
   
   
   return result;

}




double GetTotalLotsFromHistory()
{
   double totalLots = 0.0;

   // Get the time range for history (from the beginning of trading history)
   datetime fromTime = 0;
   datetime toTime = TimeCurrent();
   HistorySelect(fromTime, toTime);

   int totalDeals = HistoryDealsTotal();

   for (int i = 0; i < totalDeals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);

      // Ensure the ticket is valid
      if (ticket == 0)
         continue;

      string symbol      = HistoryDealGetString(ticket, DEAL_SYMBOL);
      int magic          = (int)HistoryDealGetInteger(ticket, DEAL_MAGIC);
      int type           = (int)HistoryDealGetInteger(ticket, DEAL_TYPE);
      double lots        = HistoryDealGetDouble(ticket, DEAL_VOLUME);
      ulong entryType    = HistoryDealGetInteger(ticket, DEAL_ENTRY); // Only count entry deals (not close-only legs)

      // Filter for symbol and magic number
      if (magic == magicNumber  && symbol == Symbol())
      {
         // Count only executed Buy/Sell orders (not SL/TP/close legs or pending orders)
         if ((type == DEAL_TYPE_BUY || type == DEAL_TYPE_SELL) && entryType == DEAL_ENTRY_IN)
         {
            totalLots += lots;
         }
      }
   }

   return totalLots;
}









bool NewBarAppearedDaily()
{
    static datetime lastBarTime = 0; // Stores the time of the last bar
    datetime currentBarTime = iTime(_Symbol, PERIOD_D1, 0); // Time of the current bar

    // Check if the current bar time is different from the last recorded bar time
    if (currentBarTime != lastBarTime)
    {
        lastBarTime = currentBarTime; // Update lastBarTime to the current bar time
        return true; // A new bar has appeared
    }

    return false; // No new bar
}
     

