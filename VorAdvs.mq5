//+------------------------------------------------------------------+
//|                                                    VorAdvs.mq5   |
//|       Risk Manager EA — Compact + Settings Panel                 |
//|                                        Developer: Shayan Ghadamian|
//+------------------------------------------------------------------+
#property copyright "Shayan Ghadamian"
#property version   "8.20"
#property strict

//--- inputs
input double InpSize           = 1.0;
input int    InpMode           = 1;
input int    InpPanelX         = 20;
input int    InpPanelY         = 30;
input ulong  InpMagic          = 20241008;
input bool   InpShowChartTimer = true;
input bool   InpShowRedLine    = true;
input int    InpTimerCornerX   = 20;
input int    InpTimerCornerY   = 30;

#define PFX "RM_"
#define PFX_SET "RMS_"

//==================================================================
//  LAYOUT — MAIN PANEL
//==================================================================
#define PANEL_W           220
#define HDR_H             42

#define Y_ACCT_LBL        54
#define Y_BAL_VAL         70
#define Y_BAL_LBL         74
#define Y_LEV_ROW         94
#define Y_DIV1            112

#define Y_CNDL_LBL        122
#define Y_TIMER           134
#define Y_TIMER_TF        144
#define Y_PROG            166
#define Y_DIV2            180

#define Y_SIZE_LBL        190
#define Y_MODE_BTN        206
#define Y_VAL_LBL         236
#define Y_INPUT           248
#define Y_PREVIEW         284
#define PREVIEW_H         54
#define Y_DIV3            346

#define Y_ADV_HDR         356
#define ADV_HDR_H         22
#define Y_ADV_BODY        384

#define Y_ENTRY_LBL       (Y_ADV_BODY + 6)
#define Y_ENTRY_IN        (Y_ADV_BODY + 0)
#define Y_TP_LBL          (Y_ADV_BODY + 36)
#define Y_TP_IN           (Y_ADV_BODY + 30)
#define Y_SL_LBL          (Y_ADV_BODY + 66)
#define Y_SL_IN           (Y_ADV_BODY + 60)
#define Y_ADV_DIV         (Y_ADV_BODY + 92)
#define Y_AN_HDR          (Y_ADV_BODY + 100)
#define Y_PROFIT          (Y_ADV_BODY + 120)
#define Y_LOSS            (Y_ADV_BODY + 138)
#define Y_RR              (Y_ADV_BODY + 156)

#define ADV_BODY_H        176

#define Y_BUYSELL_COLL    384
#define BUYSELL_H         32

#define Y_DIV4_COLL       424
#define Y_POSHDR_COLL     430
#define POSHDR_H          24
#define Y_TOOL_COLL       456
#define TOOL_H            30
#define Y_ROWS_COLL       488
#define ROW_H             46
#define POS_SLOTS         4
#define Y_TOTAL_COLL      672
#define TOTAL_H           32

#define PANEL_H_COLLAPSED (Y_TOTAL_COLL + TOTAL_H + 10)
#define PANEL_H_EXPANDED  (PANEL_H_COLLAPSED + ADV_BODY_H)

//==================================================================
//  LAYOUT — SETTINGS PANEL
//==================================================================
#define SET_W             220
#define SET_H             260
#define SET_HDR_H         32
#define SET_ROW_H         28

#define CT_W 180
#define CT_H 60

#define CLOSE_BTN_W 18
#define CLOSE_BTN_H 18

//==================================================================
//  COLORS
//==================================================================
#define C_BG        C'20,23,28'
#define C_CARD      C'28,32,40'
#define C_CARD2     C'34,38,47'
#define C_BORDER    C'44,49,60'
#define C_DIVIDER   C'38,42,52'
#define C_TEXT      C'240,243,248'
#define C_TEXT2     C'185,192,205'
#define C_MUTED     C'125,133,148'
#define C_MUTED2    C'85,92,105'
#define C_ACCENT    C'77,159,255'
#define C_BUY       C'22,199,132'
#define C_SELL      C'234,57,67'
#define C_INPUT     C'24,28,35'
#define C_INPUT_BRD C'52,58,72'
#define C_WARN      C'245,158,11'
#define C_DANGER    C'239,68,68'
#define C_SHADOW    C'10,12,16'
#define C_CLOSE_BG  C'70,28,32'
#define C_CLOSE_TXT C'255,140,130'
#define C_BTN_GREEN C'22,72,50'
#define C_BTN_AMBER C'80,60,20'
#define C_BTN_BLUE  C'40,62,92'
#define C_GEAR_BG   C'40,44,56'

enum ENUM_SIZE_MODE { MODE_LOT = 0, MODE_PCT = 1, MODE_USD = 2 };

#define DRAG_NONE 0
#define DRAG_MAIN 1
#define DRAG_SET  2

//==================================================================
//  GLOBAL STATE
//==================================================================
int    g_mode    = MODE_PCT;
double g_lotSize = 0;
double g_margin  = 0;
double g_pctBal  = 0;
bool   g_advOpen = false;

//--- runtime-tunable settings (initialized from inputs)
ulong  g_magic        = 0;
bool   g_chartTimerOn = true;
bool   g_redLineOn    = true;
int    g_timerX       = 20;
int    g_timerY       = 30;

bool   g_settingsOpen = false;

int g_dragActive = DRAG_NONE;
int g_dragStartX = 0;
int g_dragStartY = 0;
int g_panelX     = 0;
int g_panelY     = 0;
int g_setX       = 0;
int g_setY       = 0;

//==================================================================
int OnInit()
{
   g_mode = (int)InpMode;
   if(g_mode < 0 || g_mode > 2) g_mode = MODE_PCT;

   g_magic        = InpMagic;
   g_chartTimerOn = InpShowChartTimer;
   g_redLineOn    = InpShowRedLine;
   g_timerX       = InpTimerCornerX;
   g_timerY       = InpTimerCornerY;

   g_panelX = InpPanelX;
   g_panelY = InpPanelY;
   g_setX   = InpPanelX + PANEL_W + 20;
   g_setY   = InpPanelY;

   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);

   Print("=== VorAdvs Permissions Check ===");
   PrintFormat("Terminal Trade Allowed : %s",
               AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ? "YES" : "NO");
   PrintFormat("Expert   Trade Allowed : %s",
               AccountInfoInteger(ACCOUNT_TRADE_EXPERT)  ? "YES" : "NO");
   PrintFormat("MQL      Trade Allowed : %s",
               MQLInfoInteger(MQL_TRADE_ALLOWED)         ? "YES" : "NO");
   Print("=================================");

   BuildPanel();
   BuildChartTimer();
   BuildRedLine();
   BuildSettingsPanel();

   ApplyAdvVisibility();
   ApplySettingsVisibility();

   UpdateBalance(); UpdateLeverage(); UpdateLotStep();
   UpdateCandleTimer(); RefreshAll(); UpdatePositions();
   RefreshSettingsValues();

   EventSetTimer(1);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0, PFX);
   ObjectsDeleteAll(0, PFX_SET);
   ChartRedraw();
}

void OnTimer()
{
   UpdateBalance(); UpdateLeverage(); UpdateLotStep();
   UpdateCandleTimer(); RefreshAll(); UpdatePositions();
}

void OnTick() { UpdateCandleTimer(); }

//==================================================================
//  MAIN PANEL
//==================================================================
void BuildPanel()
{
   int x = g_panelX, y = g_panelY;
   int bw = PANEL_W - 28;

   Rect(PFX"bg", x, y, PANEL_W,
        (g_advOpen ? PANEL_H_EXPANDED : PANEL_H_COLLAPSED), C_BG, C_BORDER);

   Rect(PFX"hdrBg",  x, y,       PANEL_W, HDR_H, C_CARD, C_CARD);
   Rect(PFX"hdrAcc", x, y,       3,       HDR_H, C_ACCENT, C_ACCENT);
   Rect(PFX"hdrDiv", x, y+HDR_H, PANEL_W, 1,     C_DIVIDER, C_DIVIDER);

   Lbl(PFX"title", "RISK MANAGER", x+14, y+8, C_TEXT, 10, "Arial Black");
   Lbl(PFX"dev",   "by Shayan Ghadamian", x+14, y+24, C_MUTED, 7, "Arial");

   //--- gear button (opens settings)
   Btn(PFX"gearBtn", "⚙", x+PANEL_W-42, y+10, 22, 22, C_GEAR_BG, C_ACCENT);

   //--- live dot
   Lbl(PFX"liveDot", "●", x+PANEL_W-16, y+14, C_BUY, 9, "Arial");
   ObjectSetInteger(0, PFX"liveDot", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   Lbl(PFX"acctHdr", "ACCOUNT", x+14, y+Y_ACCT_LBL, C_MUTED2, 7, "Arial Black");
   Lbl(PFX"balLbl", "Balance", x+14, y+Y_BAL_LBL, C_MUTED, 8, "Arial");
   Lbl(PFX"balVal", "0.00",    x+PANEL_W-14, y+Y_BAL_VAL, C_TEXT, 10, "Consolas");
   ObjectSetInteger(0, PFX"balVal", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   Lbl(PFX"levLbl",  "Lev",   x+14,  y+Y_LEV_ROW, C_MUTED, 7, "Arial");
   Lbl(PFX"levVal",  "1:100", x+40,  y+Y_LEV_ROW, C_TEXT2, 8, "Consolas");
   Lbl(PFX"stepLbl", "Step",  x+118, y+Y_LEV_ROW, C_MUTED, 7, "Arial");
   Lbl(PFX"stepVal", "0.01",  x+PANEL_W-14, y+Y_LEV_ROW, C_TEXT2, 8, "Consolas");
   ObjectSetInteger(0, PFX"stepVal", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   Rect(PFX"div1", x+14, y+Y_DIV1, bw, 1, C_DIVIDER, C_DIVIDER);

   Lbl(PFX"cndlLbl", "NEXT CANDLE CLOSE", x+14, y+Y_CNDL_LBL, C_MUTED2, 7, "Arial Black");
   Lbl(PFX"timerVal", "00:00:00", x+14, y+Y_TIMER, C_ACCENT, 16, "Consolas");
   Lbl(PFX"timerTf",  "M15",      x+PANEL_W-14, y+Y_TIMER_TF, C_MUTED, 9, "Consolas");
   ObjectSetInteger(0, PFX"timerTf", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   Rect(PFX"progTrack", x+14, y+Y_PROG, bw, 3, C_CARD2, C_CARD2);
   Rect(PFX"progFill",  x+14, y+Y_PROG, 1,  3, C_ACCENT, C_ACCENT);
   Rect(PFX"div2", x+14, y+Y_DIV2, bw, 1, C_DIVIDER, C_DIVIDER);

   Lbl(PFX"sizeHdr", "POSITION SIZE", x+14, y+Y_SIZE_LBL, C_MUTED2, 7, "Arial Black");

   int segW = bw / 3;
   Btn(PFX"lotBtn", "LOT", x+14,         y+Y_MODE_BTN, segW-2, 24, C_CARD2, C_MUTED);
   Btn(PFX"pctBtn", "%",   x+14+segW,    y+Y_MODE_BTN, segW-2, 24, C_CARD2, C_MUTED);
   Btn(PFX"usdBtn", "$",   x+14+segW*2,  y+Y_MODE_BTN, segW-2, 24, C_CARD2, C_MUTED);

   Lbl(PFX"sizeLbl2", "Value", x+14, y+Y_VAL_LBL, C_MUTED, 7, "Arial Black");
   Edit(PFX"sizeIn", DoubleToString(InpSize, 2), x+14, y+Y_INPUT, bw, 26);

   Rect(PFX"preview", x+14, y+Y_PREVIEW, bw, PREVIEW_H, C_CARD, C_BORDER);
   Rect(PFX"prevAcc", x+14, y+Y_PREVIEW, 3,  PREVIEW_H, C_ACCENT, C_ACCENT);

   Lbl(PFX"rowLbl1", "LOTS",       x+24, y+Y_PREVIEW+6,  C_MUTED, 7, "Arial Black");
   Lbl(PFX"rowVal1", "--",         x+PANEL_W-24, y+Y_PREVIEW+4,  C_TEXT,   9, "Consolas");
   ObjectSetInteger(0, PFX"rowVal1", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   Lbl(PFX"rowLbl2", "MARGIN",     x+24, y+Y_PREVIEW+20, C_MUTED, 7, "Arial Black");
   Lbl(PFX"rowVal2", "--",         x+PANEL_W-24, y+Y_PREVIEW+18, C_ACCENT, 9, "Consolas");
   ObjectSetInteger(0, PFX"rowVal2", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   Lbl(PFX"rowLbl3", "OF BALANCE", x+24, y+Y_PREVIEW+34, C_MUTED, 7, "Arial Black");
   Lbl(PFX"rowVal3", "--",         x+PANEL_W-24, y+Y_PREVIEW+32, C_TEXT,   9, "Consolas");
   ObjectSetInteger(0, PFX"rowVal3", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   Rect(PFX"div3", x+14, y+Y_DIV3, bw, 1, C_DIVIDER, C_DIVIDER);

   int advHdrY = y + Y_ADV_HDR;
   Rect(PFX"advHdrBg",  x+14, advHdrY, bw, ADV_HDR_H, C_CARD, C_CARD);
   Rect(PFX"advHdrAcc", x+14, advHdrY, 3,  ADV_HDR_H, C_ACCENT, C_ACCENT);
   Lbl(PFX"advHdr",  "ADVANCED TRADE", x+24, advHdrY+6, C_MUTED2, 7, "Arial Black");
   Lbl(PFX"advChev", "▸", x+PANEL_W-22, advHdrY+4, C_ACCENT, 10, "Arial");
   ObjectSetInteger(0, PFX"advChev", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
   Btn(PFX"advToggle", "", x+14, advHdrY, bw, ADV_HDR_H, C_CARD, C_CARD);
   ObjectSetInteger(0, PFX"advHdr",  OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, PFX"advChev", OBJPROP_SELECTABLE, true);

   Lbl(PFX"entryLbl", "Entry",       x+14, y+Y_ENTRY_LBL, C_MUTED, 8, "Arial");
   Edit(PFX"entryIn", "",            x+58, y+Y_ENTRY_IN,  bw-44, 24);
   Lbl(PFX"tpLbl", "Take Profit",    x+14, y+Y_TP_LBL,    C_MUTED, 8, "Arial");
   Edit(PFX"tpIn", "",               x+58, y+Y_TP_IN,     bw-44, 24);
   Lbl(PFX"slLbl", "Stop Loss",      x+14, y+Y_SL_LBL,    C_MUTED, 8, "Arial");
   Edit(PFX"slIn", "",               x+58, y+Y_SL_IN,     bw-44, 24);

   Rect(PFX"advDiv", x+14, y+Y_ADV_DIV, bw, 1, C_DIVIDER, C_DIVIDER);
   Lbl(PFX"anHdr", "TRADE ANALYSIS", x+14, y+Y_AN_HDR, C_MUTED2, 7, "Arial Black");

   Lbl(PFX"anProfitLbl", "Profit", x+14,  y+Y_PROFIT,     C_MUTED, 8, "Arial Black");
   Lbl(PFX"anProfitUsd", "—",      x+118, y+Y_PROFIT-1,   C_MUTED, 8, "Consolas");
   ObjectSetInteger(0, PFX"anProfitUsd", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
   Lbl(PFX"anProfitPct", "—",      x+160, y+Y_PROFIT-1,   C_MUTED, 8, "Consolas");
   ObjectSetInteger(0, PFX"anProfitPct", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
   Lbl(PFX"anProfitPip", "—",      x+PANEL_W-14, y+Y_PROFIT-1, C_MUTED, 8, "Consolas");
   ObjectSetInteger(0, PFX"anProfitPip", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   Lbl(PFX"anLossLbl", "Loss", x+14,  y+Y_LOSS,   C_MUTED, 8, "Arial Black");
   Lbl(PFX"anLossUsd", "—",    x+118, y+Y_LOSS-1, C_MUTED, 8, "Consolas");
   ObjectSetInteger(0, PFX"anLossUsd", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
   Lbl(PFX"anLossPct", "—",    x+160, y+Y_LOSS-1, C_MUTED, 8, "Consolas");
   ObjectSetInteger(0, PFX"anLossPct", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
   Lbl(PFX"anLossPip", "—",    x+PANEL_W-14, y+Y_LOSS-1, C_MUTED, 8, "Consolas");
   ObjectSetInteger(0, PFX"anLossPip", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   Lbl(PFX"anRrLbl", "R : R", x+14, y+Y_RR,   C_MUTED, 8, "Arial Black");
   Lbl(PFX"anRrVal", "—",     x+118, y+Y_RR-1, C_MUTED, 8, "Consolas");
   ObjectSetInteger(0, PFX"anRrVal", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   int bW = (PANEL_W - 34) / 2;
   int bsY = y + Y_BUYSELL_COLL;
   Btn(PFX"buyBtn",  "▲ BUY",  x+14,      bsY, bW, BUYSELL_H, C_BUY,  C_TEXT);
   Btn(PFX"sellBtn", "▼ SELL", x+14+bW+6, bsY, bW, BUYSELL_H, C_SELL, C_TEXT);

   Rect(PFX"div4", x+14, y+Y_DIV4_COLL, bw, 1, C_DIVIDER, C_DIVIDER);

   Rect(PFX"posHdrBg",  x, y+Y_POSHDR_COLL,           PANEL_W, POSHDR_H, C_CARD, C_CARD);
   Rect(PFX"posHdrAcc", x, y+Y_POSHDR_COLL,           3,       POSHDR_H, C_ACCENT, C_ACCENT);
   Rect(PFX"posHdrDiv", x, y+Y_POSHDR_COLL+POSHDR_H,  PANEL_W, 1,       C_DIVIDER, C_DIVIDER);

   Lbl(PFX"posTitle", "OPEN POSITIONS", x+14, y+Y_POSHDR_COLL+7, C_TEXT, 9, "Arial Black");
   Lbl(PFX"posCount", "0",              x+PANEL_W-14, y+Y_POSHDR_COLL+8, C_MUTED, 9, "Consolas");
   ObjectSetInteger(0, PFX"posCount", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   Rect(PFX"toolBg",  x, y+Y_TOOL_COLL,        PANEL_W, TOOL_H, C_CARD2, C_CARD2);
   Rect(PFX"toolDiv", x, y+Y_TOOL_COLL+TOOL_H, PANEL_W, 1,      C_DIVIDER, C_DIVIDER);

   int tbW = (PANEL_W - 40) / 3;
   int tbY = y + Y_TOOL_COLL + 4;
   Btn(PFX"toolAll",  "ALL",  x+14,          tbY, tbW, 22, C_CLOSE_BG,  C_CLOSE_TXT);
   Btn(PFX"toolWin",  "WIN",  x+14+tbW+4,    tbY, tbW, 22, C_BTN_GREEN, C_BUY);
   Btn(PFX"toolLose", "LOSE", x+14+tbW*2+8,  tbY, tbW, 22, C_BTN_AMBER, C_WARN);

   for(int i = 0; i < POS_SLOTS; i++)
   {
      string s = IntegerToString(i);
      int ry = y + Y_ROWS_COLL + i * ROW_H;

      Rect(PFX"psSep"+s, x+10, ry+ROW_H-1, PANEL_W-20, 1, C_DIVIDER, C_DIVIDER);

      Lbl(PFX"psSym"+s, "--", x+14, ry+6, C_TEXT, 9, "Consolas");
      Lbl(PFX"psPct"+s, "--", x+PANEL_W-36, ry+6, C_MUTED, 8, "Consolas");
      ObjectSetInteger(0, PFX"psPct"+s, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

      Lbl(PFX"psPnl"+s, "--", x+14,  ry+22, C_TEXT,  9, "Consolas");
      Lbl(PFX"psPip"+s, "--", x+90,  ry+23, C_MUTED, 8, "Consolas");
      Lbl(PFX"psTm"+s,  "--", x+PANEL_W-36, ry+23, C_MUTED, 8, "Consolas");
      ObjectSetInteger(0, PFX"psTm"+s, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

      Lbl(PFX"psSl"+s, "SL —", x+14,  ry+36, C_MUTED, 7, "Consolas");
      Lbl(PFX"psTp"+s, "TP —", x+85,  ry+36, C_MUTED, 7, "Consolas");

      CloseBtn(PFX"psClose"+s, "✕", x+PANEL_W-10-CLOSE_BTN_W, ry+2, CLOSE_BTN_W, CLOSE_BTN_H);
      PartBtn(PFX"psHalf"+s,  "½", x+PANEL_W-70, ry+24, 16, 16, C_CARD2, C_TEXT2);
      PartBtn(PFX"psQuart"+s, "¼", x+PANEL_W-52, ry+24, 16, 16, C_CARD2, C_TEXT2);
      PartBtn(PFX"psBe"+s,    "BE", x+PANEL_W-34, ry+24, 22, 16, C_BTN_BLUE, C_ACCENT);
   }

   Rect(PFX"totBg",  x, y+Y_TOTAL_COLL,       PANEL_W, TOTAL_H, C_CARD, C_CARD);
   Rect(PFX"totAcc", x, y+Y_TOTAL_COLL,       3,       TOTAL_H, C_ACCENT, C_ACCENT);

   Lbl(PFX"totLbl", "TOTAL",  x+14,  y+Y_TOTAL_COLL+11, C_MUTED2, 7, "Arial Black");
   Lbl(PFX"totVal", "+$0.00", x+70,  y+Y_TOTAL_COLL+10, C_TEXT,   9, "Consolas");
   Lbl(PFX"totPct", "+0.00%", x+PANEL_W-14, y+Y_TOTAL_COLL+11, C_MUTED, 8, "Consolas");
   ObjectSetInteger(0, PFX"totPct", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   StyleModeButtons();
   ChartRedraw();
}

//==================================================================
//  SETTINGS PANEL
//==================================================================
void BuildSettingsPanel()
{
   int x = g_setX, y = g_setY;
   int bw = SET_W - 28;

   //--- bg
   Rect(PFX_SET"bg", x, y, SET_W, SET_H, C_BG, C_BORDER);
   Rect(PFX_SET"hdr", x, y, SET_W, SET_HDR_H, C_CARD, C_CARD);
   Rect(PFX_SET"acc", x, y, 3, SET_HDR_H, C_ACCENT, C_ACCENT);
   Rect(PFX_SET"hdrDiv", x, y+SET_HDR_H, SET_W, 1, C_DIVIDER, C_DIVIDER);

   Lbl(PFX_SET"title", "SETTINGS", x+14, y+9, C_TEXT, 10, "Arial Black");
   CloseBtn(PFX_SET"close", "✕", x+SET_W-28, y+6, 22, 22);

   //--- rows
   int ry = y + SET_HDR_H + 10;

   //--- magic
   Lbl(PFX_SET"magicLbl", "Magic Number", x+14, ry+6, C_MUTED, 8, "Arial");
   Edit(PFX_SET"magicIn", IntegerToString((long)g_magic), x+90, ry, bw-76, 24);
   ry += SET_ROW_H;

   //--- chart timer toggle
   Lbl(PFX_SET"timerLbl", "Candle Timer", x+14, ry+6, C_MUTED, 8, "Arial");
   Btn(PFX_SET"timerBtn", "ON", x+90, ry, bw-76, 24, C_BTN_GREEN, C_BUY);
   ry += SET_ROW_H;

   //--- red line toggle
   Lbl(PFX_SET"redLbl", "Red Price Line", x+14, ry+6, C_MUTED, 8, "Arial");
   Btn(PFX_SET"redBtn", "ON", x+90, ry, bw-76, 24, C_BTN_GREEN, C_BUY);
   ry += SET_ROW_H;

   //--- timer X
   Lbl(PFX_SET"txLbl", "Timer Offset X", x+14, ry+6, C_MUTED, 8, "Arial");
   Edit(PFX_SET"txIn", IntegerToString(g_timerX), x+90, ry, bw-76, 24);
   ry += SET_ROW_H;

   //--- timer Y
   Lbl(PFX_SET"tyLbl", "Timer Offset Y", x+14, ry+6, C_MUTED, 8, "Arial");
   Edit(PFX_SET"tyIn", IntegerToString(g_timerY), x+90, ry, bw-76, 24);
   ry += SET_ROW_H + 8;

   //--- divider
   Rect(PFX_SET"div1", x+14, ry-4, bw, 1, C_DIVIDER, C_DIVIDER);

   //--- buttons
   int bW = (SET_W - 40) / 2;
   Btn(PFX_SET"applyBtn", "APPLY", x+14,        ry+8, bW, 30, C_BUY,     C_TEXT);
   Btn(PFX_SET"resetBtn", "RESET", x+14+bW+12,  ry+8, bW, 30, C_CARD2,   C_TEXT2);

   RefreshSettingsValues();
   ChartRedraw();
}

void RefreshSettingsValues()
{
   //--- magic
   ObjectSetString(0, PFX_SET"magicIn", OBJPROP_TEXT,
                   IntegerToString((long)g_magic));

   //--- toggle colors
   StyleToggle(PFX_SET"timerBtn", g_chartTimerOn);
   StyleToggle(PFX_SET"redBtn",   g_redLineOn);

   //--- timer offsets
   ObjectSetString(0, PFX_SET"txIn", OBJPROP_TEXT, IntegerToString(g_timerX));
   ObjectSetString(0, PFX_SET"tyIn", OBJPROP_TEXT, IntegerToString(g_timerY));
}

void StyleToggle(string name, bool isOn)
{
   color bg = isOn ? C_BTN_GREEN : C_CARD2;
   color tx = isOn ? C_BUY       : C_MUTED;
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, tx);
   ObjectSetString (0, name, OBJPROP_TEXT, isOn ? "ON" : "OFF");
}

//==================================================================
//  SHOW / HIDE SETTINGS
//==================================================================
void ApplySettingsVisibility()
{
   long tf = g_settingsOpen ? (long)OBJ_ALL_PERIODS : (long)OBJ_NO_PERIODS;

   string ids[] = {
      "bg","hdr","acc","hdrDiv","title","close",
      "magicLbl","magicIn",
      "timerLbl","timerBtn",
      "redLbl","redBtn",
      "txLbl","txIn","tyLbl","tyIn",
      "div1","applyBtn","resetBtn"
   };
   for(int i = 0; i < ArraySize(ids); i++)
      ObjectSetInteger(0, PFX_SET+ids[i], OBJPROP_TIMEFRAMES, tf);

   //--- gear button highlights when open
   color gbg = g_settingsOpen ? C_ACCENT : C_GEAR_BG;
   color gtx = g_settingsOpen ? C_TEXT   : C_ACCENT;
   ObjectSetInteger(0, PFX"gearBtn", OBJPROP_BGCOLOR, gbg);
   ObjectSetInteger(0, PFX"gearBtn", OBJPROP_COLOR, gtx);

   ChartRedraw();
}

//==================================================================
//  APPLY / RESET
//==================================================================
void ApplySettings()
{
   //--- magic
   long newMagic = (long)StringToInteger(ObjectGetString(0, PFX_SET"magicIn", OBJPROP_TEXT));
   if(newMagic > 0) g_magic = (ulong)newMagic;

   //--- timer offsets
   int nx = (int)StringToInteger(ObjectGetString(0, PFX_SET"txIn", OBJPROP_TEXT));
   int ny = (int)StringToInteger(ObjectGetString(0, PFX_SET"tyIn", OBJPROP_TEXT));
   if(nx >= 0) g_timerX = nx;
   if(ny >= 0) g_timerY = ny;

   //--- rebuild chart timer at new position
   ObjectsDeleteAll(0, PFX"CT_");
   BuildChartTimer();
   UpdateCandleTimer();

   //--- apply red line visibility
   if(g_redLineOn && ObjectFind(0, PFX"RedLine") < 0)
      BuildRedLine();
   else if(!g_redLineOn && ObjectFind(0, PFX"RedLine") >= 0)
      ObjectDelete(0, PFX"RedLine");

   PrintFormat("*** SETTINGS APPLIED  magic=%I64u  timer=%d,%d  chartTimer=%s  redLine=%s",
               g_magic, g_timerX, g_timerY,
               (g_chartTimerOn ? "ON" : "OFF"),
               (g_redLineOn ? "ON" : "OFF"));

   //--- refresh settings values (in case of parse errors)
   RefreshSettingsValues();
   ChartRedraw();
}

void ResetSettings()
{
   g_magic        = InpMagic;
   g_chartTimerOn = InpShowChartTimer;
   g_redLineOn    = InpShowRedLine;
   g_timerX       = InpTimerCornerX;
   g_timerY       = InpTimerCornerY;

   //--- reset panel positions
   int dx = InpPanelX - g_panelX;
   int dy = InpPanelY - g_panelY;
   if(dx != 0 || dy != 0)
   {
      MovePanel(dx, dy);
      g_panelX = InpPanelX;
      g_panelY = InpPanelY;
   }

   //--- reset settings window position
   int sdx = (InpPanelX + PANEL_W + 20) - g_setX;
   int sdy = InpPanelY - g_setY;
   if(sdx != 0 || sdy != 0)
   {
      MoveSettings(sdx, sdy);
      g_setX += sdx;
      g_setY += sdy;
   }

   //--- rebuild timer + red line
   ObjectsDeleteAll(0, PFX"CT_");
   BuildChartTimer();
   if(ObjectFind(0, PFX"RedLine") >= 0)
      ObjectDelete(0, PFX"RedLine");
   if(g_redLineOn)
      BuildRedLine();
   UpdateCandleTimer();

   RefreshSettingsValues();
   Print("*** SETTINGS RESET to defaults");
   ChartRedraw();
}

//==================================================================
//  ADV VISIBILITY
//==================================================================
void ApplyAdvVisibility()
{
   long tf = g_advOpen ? (long)OBJ_ALL_PERIODS : (long)OBJ_NO_PERIODS;

   string advBody[] = {
      "entryLbl","entryIn", "tpLbl","tpIn", "slLbl","slIn",
      "advDiv","anHdr",
      "anProfitLbl","anProfitUsd","anProfitPct","anProfitPip",
      "anLossLbl","anLossUsd","anLossPct","anLossPip",
      "anRrLbl","anRrVal"
   };
   for(int i = 0; i < ArraySize(advBody); i++)
      ObjectSetInteger(0, PFX+advBody[i], OBJPROP_TIMEFRAMES, tf);

   ObjectSetString(0, PFX"advChev", OBJPROP_TEXT, g_advOpen ? "▾" : "▸");
   ObjectSetInteger(0, PFX"bg", OBJPROP_YSIZE,
                    g_advOpen ? PANEL_H_EXPANDED : PANEL_H_COLLAPSED);

   int x = g_panelX, y = g_panelY;
   int shift = g_advOpen ? ADV_BODY_H : 0;

   int bW = (PANEL_W-34) / 2;
   int bsY = y + Y_BUYSELL_COLL + shift;
   ObjectSetInteger(0, PFX"buyBtn",  OBJPROP_XDISTANCE, x+14);
   ObjectSetInteger(0, PFX"buyBtn",  OBJPROP_YDISTANCE, bsY);
   ObjectSetInteger(0, PFX"buyBtn",  OBJPROP_XSIZE,     bW);
   ObjectSetInteger(0, PFX"sellBtn", OBJPROP_XDISTANCE, x+14+bW+6);
   ObjectSetInteger(0, PFX"sellBtn", OBJPROP_YDISTANCE, bsY);
   ObjectSetInteger(0, PFX"sellBtn", OBJPROP_XSIZE,     bW);

   ObjectSetInteger(0, PFX"div4", OBJPROP_YDISTANCE, y + Y_DIV4_COLL + shift);

   ObjectSetInteger(0, PFX"posHdrBg",  OBJPROP_YDISTANCE, y + Y_POSHDR_COLL + shift);
   ObjectSetInteger(0, PFX"posHdrAcc", OBJPROP_YDISTANCE, y + Y_POSHDR_COLL + shift);
   ObjectSetInteger(0, PFX"posHdrDiv", OBJPROP_YDISTANCE, y + Y_POSHDR_COLL + POSHDR_H + shift);
   ObjectSetInteger(0, PFX"posTitle",  OBJPROP_YDISTANCE, y + Y_POSHDR_COLL + 7 + shift);
   ObjectSetInteger(0, PFX"posCount",  OBJPROP_YDISTANCE, y + Y_POSHDR_COLL + 8 + shift);

   ObjectSetInteger(0, PFX"toolBg",  OBJPROP_YDISTANCE, y + Y_TOOL_COLL + shift);
   ObjectSetInteger(0, PFX"toolDiv", OBJPROP_YDISTANCE, y + Y_TOOL_COLL + TOOL_H + shift);
   int tbY = y + Y_TOOL_COLL + 4 + shift;
   ObjectSetInteger(0, PFX"toolAll",  OBJPROP_YDISTANCE, tbY);
   ObjectSetInteger(0, PFX"toolWin",  OBJPROP_YDISTANCE, tbY);
   ObjectSetInteger(0, PFX"toolLose", OBJPROP_YDISTANCE, tbY);

   for(int i = 0; i < POS_SLOTS; i++)
   {
      string s = IntegerToString(i);
      int ry = y + Y_ROWS_COLL + i * ROW_H + shift;

      ObjectSetInteger(0, PFX"psSep"+s,   OBJPROP_YDISTANCE, ry+ROW_H-1);
      ObjectSetInteger(0, PFX"psSym"+s,   OBJPROP_YDISTANCE, ry+6);
      ObjectSetInteger(0, PFX"psPct"+s,   OBJPROP_YDISTANCE, ry+6);
      ObjectSetInteger(0, PFX"psPnl"+s,   OBJPROP_YDISTANCE, ry+22);
      ObjectSetInteger(0, PFX"psPip"+s,   OBJPROP_YDISTANCE, ry+23);
      ObjectSetInteger(0, PFX"psTm"+s,    OBJPROP_YDISTANCE, ry+23);
      ObjectSetInteger(0, PFX"psSl"+s,    OBJPROP_YDISTANCE, ry+36);
      ObjectSetInteger(0, PFX"psTp"+s,    OBJPROP_YDISTANCE, ry+36);
      ObjectSetInteger(0, PFX"psClose"+s, OBJPROP_YDISTANCE, ry+2);
      ObjectSetInteger(0, PFX"psHalf"+s,  OBJPROP_YDISTANCE, ry+24);
      ObjectSetInteger(0, PFX"psQuart"+s, OBJPROP_YDISTANCE, ry+24);
      ObjectSetInteger(0, PFX"psBe"+s,    OBJPROP_YDISTANCE, ry+24);
   }

   ObjectSetInteger(0, PFX"totBg",  OBJPROP_YDISTANCE, y + Y_TOTAL_COLL + shift);
   ObjectSetInteger(0, PFX"totAcc", OBJPROP_YDISTANCE, y + Y_TOTAL_COLL + shift);
   ObjectSetInteger(0, PFX"totLbl", OBJPROP_YDISTANCE, y + Y_TOTAL_COLL + 11 + shift);
   ObjectSetInteger(0, PFX"totVal", OBJPROP_YDISTANCE, y + Y_TOTAL_COLL + 10 + shift);
   ObjectSetInteger(0, PFX"totPct", OBJPROP_YDISTANCE, y + Y_TOTAL_COLL + 11 + shift);

   ChartRedraw();
}

//==================================================================
//  CHART TIMER (uses runtime g_timerX/Y)
//==================================================================
void BuildChartTimer()
{
   Rect(PFX"CT_shadow", -g_timerX-3, g_timerY+3, CT_W, CT_H,
        C_SHADOW, C_SHADOW, CORNER_RIGHT_UPPER);
   Rect(PFX"CT_card",   -g_timerX,   g_timerY,   CT_W, CT_H,
        C_CARD, C_BORDER, CORNER_RIGHT_UPPER);
   Rect(PFX"CT_accent", -g_timerX,   g_timerY,   3,    CT_H,
        C_ACCENT, C_ACCENT, CORNER_RIGHT_UPPER);

   Lbl(PFX"CT_head", "CANDLE CLOSES IN",
       -g_timerX+14, g_timerY+8,
       C_MUTED2, 7, "Arial Black", CORNER_RIGHT_UPPER);
   Lbl(PFX"CT_val", "--:--:--",
       -g_timerX+14, g_timerY+18,
       C_ACCENT, 18, "Consolas", CORNER_RIGHT_UPPER);
   Lbl(PFX"CT_tf", "H1",
       -g_timerX+CT_W-14, g_timerY+24,
       C_MUTED, 10, "Consolas", CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, PFX"CT_tf", OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);

   Rect(PFX"CT_barTrack", -g_timerX+14, g_timerY+48, CT_W-28, 3,
        C_CARD2, C_CARD2, CORNER_RIGHT_UPPER);
   Rect(PFX"CT_barFill",  -g_timerX+14, g_timerY+48, 1,       3,
        C_ACCENT, C_ACCENT, CORNER_RIGHT_UPPER);

   ChartRedraw();
}

void BuildRedLine()
{
   string name = PFX"RedLine";
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, SymbolInfoDouble(_Symbol, SYMBOL_BID));
   ObjectSetInteger(0, name, OBJPROP_COLOR, C_DANGER);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK,  true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//==================================================================
//  OBJECT HELPERS
//==================================================================
void Rect(string name, int x, int y, int w, int h, color bg, color border,
          ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,     w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,     h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,   bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR,     border);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,     1);
   ObjectSetInteger(0, name, OBJPROP_CORNER,    corner);
   ObjectSetInteger(0, name, OBJPROP_BACK,      false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,    true);
}

void Lbl(string name, string text, int x, int y, color clr, int size,
         string font="Arial", ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetString (0, name, OBJPROP_TEXT,     text);
   ObjectSetString (0, name, OBJPROP_FONT,     font);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_COLOR,    clr);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0, name, OBJPROP_CORNER,   corner);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,   true);
}

void Edit(string name, string text, int x, int y, int w, int h)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
   ObjectSetString (0, name, OBJPROP_TEXT,     text);
   ObjectSetString (0, name, OBJPROP_FONT,     "Consolas");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_COLOR,    C_TEXT);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,  C_INPUT);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C_INPUT_BRD);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,    w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,    h);
   ObjectSetInteger(0, name, OBJPROP_ALIGN,    ALIGN_CENTER);
   ObjectSetInteger(0, name, OBJPROP_CORNER,   CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,   true);
}

void Btn(string name, string text, int x, int y, int w, int h, color bg, color txt)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetString (0, name, OBJPROP_TEXT,     text);
   ObjectSetString (0, name, OBJPROP_FONT,     "Arial Black");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, name, OBJPROP_COLOR,    txt);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,  bg);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,    w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,    h);
   ObjectSetInteger(0, name, OBJPROP_STATE,    false);
   ObjectSetInteger(0, name, OBJPROP_CORNER,   CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,   true);
}

void CloseBtn(string name, string text, int x, int y, int w, int h)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetString (0, name, OBJPROP_TEXT,     text);
   ObjectSetString (0, name, OBJPROP_FONT,     "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_COLOR,    C_CLOSE_TXT);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,  C_CLOSE_BG);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,    w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,    h);
   ObjectSetInteger(0, name, OBJPROP_STATE,    false);
   ObjectSetInteger(0, name, OBJPROP_CORNER,   CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,   true);
}

void PartBtn(string name, string text, int x, int y, int w, int h, color bg, color txt)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetString (0, name, OBJPROP_TEXT,     text);
   ObjectSetString (0, name, OBJPROP_FONT,     "Arial Black");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 7);
   ObjectSetInteger(0, name, OBJPROP_COLOR,    txt);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR,  bg);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE,    w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE,    h);
   ObjectSetInteger(0, name, OBJPROP_STATE,    false);
   ObjectSetInteger(0, name, OBJPROP_CORNER,   CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,   true);
}

//==================================================================
void StyleModeButtons()
{
   color aBg = C_ACCENT, aTx = C_TEXT,   aBd = C_ACCENT;
   color iBg = C_CARD2,  iTx = C_MUTED,  iBd = C_CARD2;

   ObjectSetInteger(0, PFX"lotBtn", OBJPROP_BGCOLOR,      g_mode==MODE_LOT ? aBg : iBg);
   ObjectSetInteger(0, PFX"lotBtn", OBJPROP_COLOR,        g_mode==MODE_LOT ? aTx : iTx);
   ObjectSetInteger(0, PFX"lotBtn", OBJPROP_BORDER_COLOR, g_mode==MODE_LOT ? aBd : iBd);

   ObjectSetInteger(0, PFX"pctBtn", OBJPROP_BGCOLOR,      g_mode==MODE_PCT ? aBg : iBg);
   ObjectSetInteger(0, PFX"pctBtn", OBJPROP_COLOR,        g_mode==MODE_PCT ? aTx : iTx);
   ObjectSetInteger(0, PFX"pctBtn", OBJPROP_BORDER_COLOR, g_mode==MODE_PCT ? aBd : iBd);

   ObjectSetInteger(0, PFX"usdBtn", OBJPROP_BGCOLOR,      g_mode==MODE_USD ? aBg : iBg);
   ObjectSetInteger(0, PFX"usdBtn", OBJPROP_COLOR,        g_mode==MODE_USD ? aTx : iTx);
   ObjectSetInteger(0, PFX"usdBtn", OBJPROP_BORDER_COLOR, g_mode==MODE_USD ? aBd : iBd);
}

//==================================================================
void MovePanel(int dx, int dy)
{
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total-1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, PFX) != 0) continue;
      if(StringFind(name, PFX_SET) == 0) continue;
      if(StringFind(name, PFX"CT_") == 0) continue;
      if(StringFind(name, PFX"RedLine") == 0) continue;

      int x = (int)ObjectGetInteger(0, name, OBJPROP_XDISTANCE);
      int y = (int)ObjectGetInteger(0, name, OBJPROP_YDISTANCE);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x + dx);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y + dy);
   }
}

void MoveSettings(int dx, int dy)
{
   int total = ObjectsTotal(0, -1, -1);
   for(int i = total-1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, PFX_SET) != 0) continue;

      int x = (int)ObjectGetInteger(0, name, OBJPROP_XDISTANCE);
      int y = (int)ObjectGetInteger(0, name, OBJPROP_YDISTANCE);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x + dx);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y + dy);
   }
}

//==================================================================
void SetSlotVisible(int i, bool visible)
{
   string s = IntegerToString(i);
   long tf = visible ? (long)OBJ_ALL_PERIODS : (long)OBJ_NO_PERIODS;
   ObjectSetInteger(0, PFX"psSep"+s,   OBJPROP_TIMEFRAMES, tf);
   ObjectSetInteger(0, PFX"psSym"+s,   OBJPROP_TIMEFRAMES, tf);
   ObjectSetInteger(0, PFX"psPct"+s,   OBJPROP_TIMEFRAMES, tf);
   ObjectSetInteger(0, PFX"psPnl"+s,   OBJPROP_TIMEFRAMES, tf);
   ObjectSetInteger(0, PFX"psPip"+s,   OBJPROP_TIMEFRAMES, tf);
   ObjectSetInteger(0, PFX"psTm"+s,    OBJPROP_TIMEFRAMES, tf);
   ObjectSetInteger(0, PFX"psSl"+s,    OBJPROP_TIMEFRAMES, tf);
   ObjectSetInteger(0, PFX"psTp"+s,    OBJPROP_TIMEFRAMES, tf);
   ObjectSetInteger(0, PFX"psClose"+s, OBJPROP_TIMEFRAMES, tf);
   ObjectSetInteger(0, PFX"psHalf"+s,  OBJPROP_TIMEFRAMES, tf);
   ObjectSetInteger(0, PFX"psQuart"+s, OBJPROP_TIMEFRAMES, tf);
   ObjectSetInteger(0, PFX"psBe"+s,    OBJPROP_TIMEFRAMES, tf);
}

//==================================================================
void UpdatePositions()
{
   int totalPositions = PositionsTotal();
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double totalProfit = 0.0;

   for(int i = 0; i < POS_SLOTS; i++)
   {
      bool visible = false;
      if(i < totalPositions)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
         {
            string sym    = PositionGetString(POSITION_SYMBOL);
            long   type   = PositionGetInteger(POSITION_TYPE);
            double vol    = PositionGetDouble(POSITION_VOLUME);
            double open   = PositionGetDouble(POSITION_PRICE_OPEN);
            double sl     = PositionGetDouble(POSITION_SL);
            double tp     = PositionGetDouble(POSITION_TP);
            double profit = PositionGetDouble(POSITION_PROFIT)
                          + PositionGetDouble(POSITION_SWAP);
            datetime tm   = (datetime)PositionGetInteger(POSITION_TIME);

            visible = true;
            totalProfit += profit;

            bool isBuy = (type == POSITION_TYPE_BUY);
            string dir = isBuy ? "B" : "S";
            color dirClr = isBuy ? C_BUY : C_SELL;

            double close = isBuy
                           ? SymbolInfoDouble(sym, SYMBOL_BID)
                           : SymbolInfoDouble(sym, SYMBOL_ASK);

            int    digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
            double point  = SymbolInfoDouble(sym, SYMBOL_POINT);
            double pip    = (digits == 3 || digits == 5) ? point * 10.0 : point;

            double diff   = isBuy ? (close - open) : (open - close);
            double pips   = (pip > 0) ? diff / pip : 0;

            double slPips = 0, tpPips = 0;
            bool   hasSL = (sl > 0), hasTP = (tp > 0);
            if(hasSL && pip > 0)
            {
               double d = isBuy ? (close - sl) : (sl - close);
               slPips = d / pip;
            }
            if(hasTP && pip > 0)
            {
               double d = isBuy ? (tp - close) : (close - tp);
               tpPips = d / pip;
            }

            int secs = (int)(TimeCurrent() - tm);
            if(secs < 0) secs = 0;
            int days = secs / 86400;
            int hh   = (secs % 86400) / 3600;
            int mm   = (secs % 3600) / 60;
            int ss   = secs % 60;

            string timeStr;
            if(days > 0)      timeStr = StringFormat("%dd %02dh", days, hh);
            else if(hh > 0)   timeStr = StringFormat("%02d:%02d:%02d", hh, mm, ss);
            else              timeStr = StringFormat("%02d:%02d", mm, ss);

            color timeClr = C_MUTED;
            if(secs > 14400)     timeClr = C_SELL;
            else if(secs > 3600) timeClr = C_WARN;
            else if(secs > 900)  timeClr = C_TEXT2;

            double pct = (bal > 0) ? (profit / bal) * 100.0 : 0;

            color pnlClr = (profit > 0) ? C_BUY
                         : (profit < 0) ? C_SELL
                                        : C_MUTED;

            string symShort = StringSubstr(sym, 0, 6);
            string symLine = symShort + " " + dir + " " + DoubleToString(vol, 2);
            string pnlLine = StringFormat("%s$%.2f", (profit >= 0 ? "+" : ""), profit);
            string pctLine = StringFormat("%s%.1f%%", (pct >= 0 ? "+" : ""), pct);
            string pipLine = StringFormat("%s%.0fp", (pips >= 0 ? "+" : ""), pips);

            string slLine, tpLine;
            color  slClr = C_MUTED2, tpClr = C_MUTED2;
            if(hasSL)
            {
               slLine = StringFormat("SL %.0fp", slPips);
               slClr  = (slPips < 5) ? C_SELL : (slPips < 15 ? C_WARN : C_MUTED);
            }
            else slLine = "SL —";

            if(hasTP)
            {
               tpLine = StringFormat("TP %.0fp", tpPips);
               tpClr  = (tpPips < 5) ? C_BUY : (tpPips < 15 ? C_WARN : C_MUTED);
            }
            else tpLine = "TP —";

            string s = IntegerToString(i);
            ObjectSetString (0, PFX"psSym"+s, OBJPROP_TEXT, symLine);
            ObjectSetInteger(0, PFX"psSym"+s, OBJPROP_COLOR, dirClr);
            ObjectSetString (0, PFX"psPct"+s, OBJPROP_TEXT, pctLine);
            ObjectSetInteger(0, PFX"psPct"+s, OBJPROP_COLOR, pnlClr);
            ObjectSetString (0, PFX"psPnl"+s, OBJPROP_TEXT, pnlLine);
            ObjectSetInteger(0, PFX"psPnl"+s, OBJPROP_COLOR, pnlClr);
            ObjectSetString (0, PFX"psPip"+s, OBJPROP_TEXT, pipLine);
            ObjectSetInteger(0, PFX"psPip"+s, OBJPROP_COLOR, pnlClr);
            ObjectSetString (0, PFX"psTm"+s, OBJPROP_TEXT, timeStr);
            ObjectSetInteger(0, PFX"psTm"+s, OBJPROP_COLOR, timeClr);
            ObjectSetString (0, PFX"psSl"+s, OBJPROP_TEXT, slLine);
            ObjectSetInteger(0, PFX"psSl"+s, OBJPROP_COLOR, slClr);
            ObjectSetString (0, PFX"psTp"+s, OBJPROP_TEXT, tpLine);
            ObjectSetInteger(0, PFX"psTp"+s, OBJPROP_COLOR, tpClr);
         }
      }
      SetSlotVisible(i, visible);
   }

   ObjectSetString(0, PFX"posCount", OBJPROP_TEXT, IntegerToString(totalPositions));

   double totalPct = (bal > 0) ? (totalProfit / bal) * 100.0 : 0;
   color totalClr  = (totalProfit > 0) ? C_BUY
                   : (totalProfit < 0) ? C_SELL
                                       : C_MUTED;

   ObjectSetString(0, PFX"totVal", OBJPROP_TEXT,
                   StringFormat("%s$%.2f",
                                (totalProfit >= 0 ? "+" : ""), totalProfit));
   ObjectSetInteger(0, PFX"totVal", OBJPROP_COLOR, totalClr);

   ObjectSetString(0, PFX"totPct", OBJPROP_TEXT,
                   StringFormat("%s%.1f%%",
                                (totalPct >= 0 ? "+" : ""), totalPct));
   ObjectSetInteger(0, PFX"totPct", OBJPROP_COLOR, totalClr);

   ChartRedraw();
}

//==================================================================
bool CloseTicket(ulong ticket, double volumeToClose)
{
   if(ticket <= 0 || volumeToClose <= 0) return false;
   if(!PositionSelectByTicket(ticket)) return false;

   string sym  = PositionGetString(POSITION_SYMBOL);
   long   type = PositionGetInteger(POSITION_TYPE);

   ENUM_ORDER_TYPE closeType = (type == POSITION_TYPE_BUY)
                               ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;

   double price = (closeType == ORDER_TYPE_BUY)
                    ? SymbolInfoDouble(sym, SYMBOL_ASK)
                    : SymbolInfoDouble(sym, SYMBOL_BID);
   if(price <= 0) return false;

   double vol = NormalizeDouble(volumeToClose, 8);

   ENUM_ORDER_TYPE_FILLING fills[3];
   fills[0] = ORDER_FILLING_FOK;
   fills[1] = ORDER_FILLING_IOC;
   fills[2] = ORDER_FILLING_RETURN;

   for(int i = 0; i < 3; i++)
   {
      MqlTradeRequest req; MqlTradeResult res;
      ZeroMemory(req); ZeroMemory(res);

      req.action       = TRADE_ACTION_DEAL;
      req.position     = ticket;
      req.symbol       = sym;
      req.volume       = vol;
      req.type         = closeType;
      req.price        = price;
      req.deviation    = 20;
      req.magic        = g_magic;
      req.comment      = "VorAdvs close";
      req.type_filling = fills[i];

      bool sent = OrderSend(req, res);

      if(sent && (res.retcode == TRADE_RETCODE_DONE ||
                  res.retcode == TRADE_RETCODE_PLACED ||
                  res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         PrintFormat("*** CLOSED %I64u lots=%s", ticket, DoubleToString(vol, 2));
         return true;
      }
      if(res.retcode == TRADE_RETCODE_INVALID_FILL) continue;
      PrintFormat("!! Close failed %I64u LastError=%d retcode=%d",
                  ticket, GetLastError(), res.retcode);
      return false;
   }
   return false;
}

void ClosePositionBySlot(int slot)
{
   if(slot < 0 || slot >= PositionsTotal()) return;
   ulong ticket = PositionGetTicket(slot);
   if(ticket <= 0) return;
   if(!PositionSelectByTicket(ticket)) return;
   double vol = PositionGetDouble(POSITION_VOLUME);
   CloseTicket(ticket, vol);
   UpdatePositions();
}

void ClosePartialBySlot(int slot, double fraction)
{
   if(slot < 0 || slot >= PositionsTotal()) return;
   ulong ticket = PositionGetTicket(slot);
   if(ticket <= 0) return;
   if(!PositionSelectByTicket(ticket)) return;

   double vol = PositionGetDouble(POSITION_VOLUME);
   string sym = PositionGetString(POSITION_SYMBOL);
   double minLot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;

   double partVol = vol * fraction;
   partVol = MathFloor(partVol / step + 1e-9) * step;
   partVol = NormalizeDouble(partVol, 8);

   if(partVol < minLot || vol - partVol < minLot)
      partVol = vol;
   if(partVol > maxLot) partVol = maxLot;

   CloseTicket(ticket, partVol);
   UpdatePositions();
}

//==================================================================
void MoveSLToBreakeven(int slot)
{
   if(slot < 0 || slot >= PositionsTotal())
   {
      PrintFormat("!! BE: slot %d out of range (%d positions)",
                  slot, PositionsTotal());
      return;
   }

   ulong ticket = PositionGetTicket(slot);
   if(ticket <= 0)
   {
      PrintFormat("!! BE: PositionGetTicket(%d) failed. err=%d",
                  slot, GetLastError());
      return;
   }
   if(!PositionSelectByTicket(ticket))
   {
      PrintFormat("!! BE: PositionSelectByTicket(%I64u) failed. err=%d",
                  ticket, GetLastError());
      return;
   }

   string sym       = PositionGetString(POSITION_SYMBOL);
   long   type      = PositionGetInteger(POSITION_TYPE);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);

   int    symDigits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double symPoint  = SymbolInfoDouble(sym, SYMBOL_POINT);
   if(symPoint <= 0) symPoint = _Point;

   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);

   bool isBuy = (type == POSITION_TYPE_BUY);

   if(currentSL > 0 && MathAbs(currentSL - openPrice) < symPoint * 0.5)
   {
      PrintFormat("!! BE: %I64u already at breakeven (SL=%.*f)",
                  ticket, symDigits, currentSL);
      return;
   }

   long   stopsLevel = SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist    = stopsLevel * symPoint;

   if(isBuy)
   {
      double gap = bid - openPrice;
      if(gap < minDist)
      {
         PrintFormat("!! BE blocked: BUY not in profit enough. "
                     "bid=%.*f  entry=%.*f  gap=%.1f pips  (need %.1f)",
                     symDigits, bid,
                     symDigits, openPrice,
                     gap / symPoint,
                     minDist / symPoint);
         return;
      }
   }
   else
   {
      double gap = openPrice - ask;
      if(gap < minDist)
      {
         PrintFormat("!! BE blocked: SELL not in profit enough. "
                     "ask=%.*f  entry=%.*f  gap=%.1f pips  (need %.1f)",
                     symDigits, ask,
                     symDigits, openPrice,
                     gap / symPoint,
                     minDist / symPoint);
         return;
      }
   }

   MqlTradeRequest req; MqlTradeResult res;
   ZeroMemory(req); ZeroMemory(res);

   req.action   = TRADE_ACTION_SLTP;
   req.symbol   = sym;
   req.position = ticket;
   req.sl       = NormalizeDouble(openPrice, symDigits);
   if(currentTP > 0)
      req.tp    = NormalizeDouble(currentTP, symDigits);

   PrintFormat(">> BE: %I64u %s  SL %.*f -> %.*f  market=%.*f",
               ticket, (isBuy ? "BUY" : "SELL"),
               symDigits, currentSL,
               symDigits, req.sl,
               symDigits, (isBuy ? bid : ask));

   bool sent = OrderSend(req, res);

   if(sent && (res.retcode == TRADE_RETCODE_DONE ||
               res.retcode == TRADE_RETCODE_PLACED))
   {
      PrintFormat("*** BE SUCCESS  ticket=%I64u  SL=%.*f",
                  ticket, symDigits, req.sl);
   }
   else
   {
      PrintFormat("!! BE FAILED  ticket=%I64u  err=%d  retcode=%d  comment=%s",
                  ticket, GetLastError(), res.retcode, res.comment);
   }

   UpdatePositions();
}

void CloseAllByFilter(int filter)
{
   int total = PositionsTotal();
   if(total <= 0) { Print("No positions to close"); return; }

   PrintFormat("Closing %s (%d positions)...",
               (filter == 0 ? "ALL" : (filter == 1 ? "WINNERS" : "LOSERS")),
               total);

   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;

      double profit = PositionGetDouble(POSITION_PROFIT)
                    + PositionGetDouble(POSITION_SWAP);

      if(filter == 1 && profit <= 0) continue;
      if(filter == 2 && profit >= 0) continue;

      double vol = PositionGetDouble(POSITION_VOLUME);
      CloseTicket(ticket, vol);
   }
   UpdatePositions();
}

//==================================================================
string TFToString(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN";
   }
   return "??";
}

void UpdateCandleTimer()
{
   ENUM_TIMEFRAMES tf = (ENUM_TIMEFRAMES)Period();
   int periodSec = PeriodSeconds(tf);
   if(periodSec <= 0) return;

   datetime now         = TimeCurrent();
   datetime candleOpen  = (datetime)((now / periodSec) * periodSec);
   datetime candleClose = candleOpen + periodSec;
   int      remainSec   = (int)(candleClose - now);
   if(remainSec < 0) remainSec = 0;

   int h = remainSec / 3600;
   int m = (remainSec % 3600) / 60;
   int s = remainSec % 60;

   string txt = StringFormat("%02d:%02d:%02d", h, m, s);

   color c = C_ACCENT;
   if(remainSec <= 3)       c = C_DANGER;
   else if(remainSec <= 10) c = C_WARN;

   //--- main panel timer
   ObjectSetString (0, PFX"timerVal", OBJPROP_TEXT, txt);
   ObjectSetInteger(0, PFX"timerVal", OBJPROP_COLOR, c);
   ObjectSetString (0, PFX"timerTf",  OBJPROP_TEXT, TFToString(tf));

   int barMaxW = PANEL_W - 28;
   double progress = 1.0 - ((double)remainSec / (double)periodSec);
   int barW = (int)MathRound(barMaxW * progress);
   if(barW < 1) barW = 1;
   if(barW > barMaxW) barW = barMaxW;
   ObjectSetInteger(0, PFX"progFill", OBJPROP_XSIZE,    barW);
   ObjectSetInteger(0, PFX"progFill", OBJPROP_BGCOLOR,  c);
   ObjectSetInteger(0, PFX"progFill", OBJPROP_COLOR,    c);

   //--- chart timer
   if(g_chartTimerOn)
   {
      ObjectSetString (0, PFX"CT_val", OBJPROP_TEXT, txt);
      ObjectSetInteger(0, PFX"CT_val", OBJPROP_COLOR, c);
      ObjectSetString (0, PFX"CT_tf",  OBJPROP_TEXT, TFToString(tf));
      ObjectSetInteger(0, PFX"CT_tf",  OBJPROP_COLOR, c);
      ObjectSetInteger(0, PFX"CT_accent", OBJPROP_BGCOLOR, c);

      int ctBarMaxW = CT_W - 28;
      int ctBarW = (int)MathRound(ctBarMaxW * progress);
      if(ctBarW < 1) ctBarW = 1;
      if(ctBarW > ctBarMaxW) ctBarW = ctBarMaxW;
      ObjectSetInteger(0, PFX"CT_barFill", OBJPROP_XSIZE,   ctBarW);
      ObjectSetInteger(0, PFX"CT_barFill", OBJPROP_BGCOLOR, c);
      ObjectSetInteger(0, PFX"CT_barFill", OBJPROP_COLOR,   c);
   }

   //--- red line
   if(g_redLineOn)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(bid > 0)
      {
         ObjectSetDouble (0, PFX"RedLine", OBJPROP_PRICE, bid);
         ObjectSetInteger(0, PFX"RedLine", OBJPROP_COLOR, c);
      }
   }
}

//==================================================================
int LotDigits(double step)
{
   if(step <= 0) return 2;
   int d = 0; double s = step;
   while(s < 0.9999 && d < 8) { s *= 10.0; d++; }
   return d;
}

double NormalizeLot(double lots)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step   <= 0) step   = 0.01;
   if(minLot <= 0) minLot = step;
   if(maxLot <= 0) maxLot = 100.0;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;
   lots = MathFloor(lots / step + 1e-9) * step;
   return NormalizeDouble(lots, LotDigits(step));
}

double MarginPerLot()
{
   double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(price <= 0) price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(price <= 0) return 0;
   double m = 0;
   if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1.0, price, m) && m > 0) return m;
   double contract = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   long   lev      = AccountInfoInteger(ACCOUNT_LEVERAGE);
   if(lev <= 0)      lev = 100;
   if(contract <= 0) contract = 100000;
   return (contract * price) / (double)lev;
}

double PointValuePerLot()
{
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickSize <= 0 || tickValue <= 0) return 0;
   return (tickValue / tickSize) * _Point;
}

void UpdateBalance()
{
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   string cur = AccountInfoString(ACCOUNT_CURRENCY);
   ObjectSetString(0, PFX"balVal", OBJPROP_TEXT,
                   DoubleToString(bal, 2) + " " + cur);
}

void UpdateLeverage()
{
   long lev = AccountInfoInteger(ACCOUNT_LEVERAGE);
   if(lev <= 0) lev = 1;
   ObjectSetString(0, PFX"levVal", OBJPROP_TEXT, "1:" + IntegerToString(lev));
}

void UpdateLotStep()
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   int digits = LotDigits(step);
   ObjectSetString(0, PFX"stepVal", OBJPROP_TEXT,
                   DoubleToString(step, digits) + " (" + IntegerToString(digits) + "d)");
}

//==================================================================
void UpdateAnalysis()
{
   double bal  = AccountInfoDouble(ACCOUNT_BALANCE);
   double lots = g_lotSize;

   double entryP = StringToDouble(ObjectGetString(0, PFX"entryIn", OBJPROP_TEXT));
   double tpP    = StringToDouble(ObjectGetString(0, PFX"tpIn",    OBJPROP_TEXT));
   double slP    = StringToDouble(ObjectGetString(0, PFX"slIn",    OBJPROP_TEXT));

   if(entryP <= 0)
   {
      entryP = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(entryP <= 0) entryP = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   }

   double pvpl = PointValuePerLot();
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double pipFactor = (digits == 3 || digits == 5) ? 10.0 : 1.0;

   if(tpP > 0 && lots > 0 && pvpl > 0)
   {
      double distPts    = MathAbs(tpP - entryP) / _Point;
      double profitUsd  = distPts * pvpl * lots;
      double profitPct  = (bal > 0) ? (profitUsd / bal) * 100.0 : 0;
      double profitPips = distPts / pipFactor;

      ObjectSetString (0, PFX"anProfitUsd", OBJPROP_TEXT, StringFormat("+$%.1f", profitUsd));
      ObjectSetString (0, PFX"anProfitPct", OBJPROP_TEXT, StringFormat("+%.1f%%", profitPct));
      ObjectSetString (0, PFX"anProfitPip", OBJPROP_TEXT, StringFormat("+%.0fp", profitPips));
      ObjectSetInteger(0, PFX"anProfitUsd", OBJPROP_COLOR, C_BUY);
      ObjectSetInteger(0, PFX"anProfitPct", OBJPROP_COLOR, C_BUY);
      ObjectSetInteger(0, PFX"anProfitPip", OBJPROP_COLOR, C_BUY);
   }
   else
   {
      ObjectSetString (0, PFX"anProfitUsd", OBJPROP_TEXT, "—");
      ObjectSetString (0, PFX"anProfitPct", OBJPROP_TEXT, "—");
      ObjectSetString (0, PFX"anProfitPip", OBJPROP_TEXT, "—");
      ObjectSetInteger(0, PFX"anProfitUsd", OBJPROP_COLOR, C_MUTED);
      ObjectSetInteger(0, PFX"anProfitPct", OBJPROP_COLOR, C_MUTED);
      ObjectSetInteger(0, PFX"anProfitPip", OBJPROP_COLOR, C_MUTED);
   }

   if(slP > 0 && lots > 0 && pvpl > 0)
   {
      double distPts  = MathAbs(slP - entryP) / _Point;
      double lossUsd  = distPts * pvpl * lots;
      double lossPct  = (bal > 0) ? (lossUsd / bal) * 100.0 : 0;
      double lossPips = distPts / pipFactor;

      ObjectSetString (0, PFX"anLossUsd", OBJPROP_TEXT, StringFormat("-$%.1f", lossUsd));
      ObjectSetString (0, PFX"anLossPct", OBJPROP_TEXT, StringFormat("-%.1f%%", lossPct));
      ObjectSetString (0, PFX"anLossPip", OBJPROP_TEXT, StringFormat("-%.0fp", lossPips));
      ObjectSetInteger(0, PFX"anLossUsd", OBJPROP_COLOR, C_SELL);
      ObjectSetInteger(0, PFX"anLossPct", OBJPROP_COLOR, C_SELL);
      ObjectSetInteger(0, PFX"anLossPip", OBJPROP_COLOR, C_SELL);
   }
   else
   {
      ObjectSetString (0, PFX"anLossUsd", OBJPROP_TEXT, "—");
      ObjectSetString (0, PFX"anLossPct", OBJPROP_TEXT, "—");
      ObjectSetString (0, PFX"anLossPip", OBJPROP_TEXT, "—");
      ObjectSetInteger(0, PFX"anLossUsd", OBJPROP_COLOR, C_MUTED);
      ObjectSetInteger(0, PFX"anLossPct", OBJPROP_COLOR, C_MUTED);
      ObjectSetInteger(0, PFX"anLossPip", OBJPROP_COLOR, C_MUTED);
   }

   if(tpP > 0 && slP > 0)
   {
      double tpDist = MathAbs(tpP - entryP);
      double slDist = MathAbs(slP - entryP);
      if(slDist > 0 && tpDist > 0)
      {
         double rr = tpDist / slDist;
         color rrClr = (rr >= 2.0) ? C_BUY : (rr >= 1.0 ? C_WARN : C_SELL);
         ObjectSetString (0, PFX"anRrVal", OBJPROP_TEXT, StringFormat("1 : %.2f", rr));
         ObjectSetInteger(0, PFX"anRrVal", OBJPROP_COLOR, rrClr);
      }
      else
      {
         ObjectSetString (0, PFX"anRrVal", OBJPROP_TEXT, "—");
         ObjectSetInteger(0, PFX"anRrVal", OBJPROP_COLOR, C_MUTED);
      }
   }
   else
   {
      ObjectSetString (0, PFX"anRrVal", OBJPROP_TEXT, "—");
      ObjectSetInteger(0, PFX"anRrVal", OBJPROP_COLOR, C_MUTED);
   }

   ChartRedraw();
}

void RefreshAll()
{
   double bal      = AccountInfoDouble(ACCOUNT_BALANCE);
   double inputVal = StringToDouble(ObjectGetString(0, PFX"sizeIn", OBJPROP_TEXT));

   g_lotSize = 0; g_margin = 0; g_pctBal = 0;

   if(inputVal > 0 && bal > 0)
   {
      double mpl = MarginPerLot();
      if(mpl > 0)
      {
         double rawLots = 0;
         if     (g_mode == MODE_LOT) rawLots = inputVal;
         else if(g_mode == MODE_PCT) rawLots = (bal * inputVal / 100.0) / mpl;
         else                        rawLots = inputVal / mpl;
         double lots = NormalizeLot(rawLots);
         g_lotSize = lots;
         g_margin  = NormalizeDouble(lots * mpl, 2);
         g_pctBal  = NormalizeDouble((g_margin / bal) * 100.0, 2);
      }
   }

   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   int digits = LotDigits(step);

   ObjectSetString(0, PFX"rowVal1", OBJPROP_TEXT, DoubleToString(g_lotSize, digits));
   ObjectSetString(0, PFX"rowVal2", OBJPROP_TEXT, "$" + DoubleToString(g_margin, 2));
   ObjectSetString(0, PFX"rowVal3", OBJPROP_TEXT, DoubleToString(g_pctBal, 2) + " %");

   UpdateAnalysis();
}

void SwitchMode(int newMode)
{
   if(newMode == g_mode) return;

   double newInput = 0;
   if     (newMode == MODE_LOT) newInput = g_lotSize;
   else if(newMode == MODE_PCT) newInput = g_pctBal;
   else                         newInput = g_margin;

   if(newInput <= 0)
   {
      double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      if(newMode == MODE_LOT)      newInput = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      else if(newMode == MODE_PCT) newInput = 1.0;
      else                         newInput = bal * 0.01;
   }

   g_mode = newMode;
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   int digits = LotDigits(step);
   ObjectSetString(0, PFX"sizeIn", OBJPROP_TEXT, DoubleToString(newInput, digits));

   StyleModeButtons();
   RefreshAll();
}

void ToggleAdv()
{
   g_advOpen = !g_advOpen;
   ApplyAdvVisibility();
}

void ToggleSettings()
{
   g_settingsOpen = !g_settingsOpen;
   ApplySettingsVisibility();
   if(g_settingsOpen) RefreshSettingsValues();
}

//==================================================================
//  CHART EVENTS
//==================================================================
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_MOUSE_MOVE)
   {
      int mx = (int)lparam;
      int my = (int)dparam;
      long state = StringToInteger(sparam);
      bool leftDown = (state & 1) != 0;

      if(leftDown && g_dragActive == DRAG_NONE)
      {
         //--- main header?
         if(mx >= g_panelX && mx <= g_panelX + PANEL_W &&
            my >= g_panelY && my <= g_panelY + HDR_H)
         {
            g_dragActive = DRAG_MAIN;
            g_dragStartX = mx;
            g_dragStartY = my;
            ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
         }
         //--- settings header?
         else if(g_settingsOpen &&
                 mx >= g_setX && mx <= g_setX + SET_W &&
                 my >= g_setY && my <= g_setY + SET_HDR_H)
         {
            g_dragActive = DRAG_SET;
            g_dragStartX = mx;
            g_dragStartY = my;
            ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
         }
      }
      else if(leftDown && g_dragActive != DRAG_NONE)
      {
         int dx = mx - g_dragStartX;
         int dy = my - g_dragStartY;
         if(dx != 0 || dy != 0)
         {
            if(g_dragActive == DRAG_MAIN)
            { MovePanel(dx, dy); g_panelX += dx; g_panelY += dy; }
            else if(g_dragActive == DRAG_SET)
            { MoveSettings(dx, dy); g_setX += dx; g_setY += dy; }
            g_dragStartX = mx;
            g_dragStartY = my;
            ChartRedraw();
         }
      }
      else if(!leftDown && g_dragActive != DRAG_NONE)
      {
         g_dragActive = DRAG_NONE;
         ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
      }
      return;
   }

   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      //--- gear (settings)
      if(sparam == PFX"gearBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         ToggleSettings();
         return;
      }

      //--- settings close ×
      if(sparam == PFX_SET"close")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         g_settingsOpen = false;
         ApplySettingsVisibility();
         return;
      }

      //--- settings: chart timer toggle
      if(sparam == PFX_SET"timerBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         g_chartTimerOn = !g_chartTimerOn;
         StyleToggle(PFX_SET"timerBtn", g_chartTimerOn);
         //--- apply immediately
         if(g_chartTimerOn)
         {
            if(ObjectFind(0, PFX"CT_card") < 0) BuildChartTimer();
         }
         else
         {
            ObjectsDeleteAll(0, PFX"CT_");
         }
         PrintFormat("*** Chart Timer set to %s", g_chartTimerOn ? "ON" : "OFF");
         return;
      }

      //--- settings: red line toggle
      if(sparam == PFX_SET"redBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         g_redLineOn = !g_redLineOn;
         StyleToggle(PFX_SET"redBtn", g_redLineOn);
         if(g_redLineOn && ObjectFind(0, PFX"RedLine") < 0)
            BuildRedLine();
         else if(!g_redLineOn && ObjectFind(0, PFX"RedLine") >= 0)
            ObjectDelete(0, PFX"RedLine");
         PrintFormat("*** Red Line set to %s", g_redLineOn ? "ON" : "OFF");
         return;
      }

      //--- settings: apply / reset
      if(sparam == PFX_SET"applyBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         ApplySettings();
         return;
      }
      if(sparam == PFX_SET"resetBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         ResetSettings();
         return;
      }

      //--- ADV toggle
      if(sparam == PFX"advToggle" ||
         sparam == PFX"advHdr"    ||
         sparam == PFX"advChev")
      {
         ObjectSetInteger(0, PFX"advToggle", OBJPROP_STATE, false);
         ToggleAdv();
         return;
      }

      //--- toolbar
      if(sparam == PFX"toolAll")
      { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); CloseAllByFilter(0); return; }
      if(sparam == PFX"toolWin")
      { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); CloseAllByFilter(1); return; }
      if(sparam == PFX"toolLose")
      { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); CloseAllByFilter(2); return; }

      //--- per-position
      for(int i = 0; i < POS_SLOTS; i++)
      {
         string si = IntegerToString(i);
         if(sparam == PFX"psClose"+si)
         { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); ClosePositionBySlot(i); return; }
         if(sparam == PFX"psHalf"+si)
         { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); ClosePartialBySlot(i, 0.50); return; }
         if(sparam == PFX"psQuart"+si)
         { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); ClosePartialBySlot(i, 0.25); return; }
         if(sparam == PFX"psBe"+si)
         { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); MoveSLToBreakeven(i); return; }
      }

      //--- mode
      if(sparam == PFX"lotBtn")
      { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); SwitchMode(MODE_LOT); return; }
      if(sparam == PFX"pctBtn")
      { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); SwitchMode(MODE_PCT); return; }
      if(sparam == PFX"usdBtn")
      { ObjectSetInteger(0, sparam, OBJPROP_STATE, false); SwitchMode(MODE_USD); return; }

      //--- trade
      if(sparam == PFX"buyBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         RefreshAll();
         if(g_lotSize > 0) OpenOrder(ORDER_TYPE_BUY);
      }
      if(sparam == PFX"sellBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         RefreshAll();
         if(g_lotSize > 0) OpenOrder(ORDER_TYPE_SELL);
      }
   }

   if(id == CHARTEVENT_OBJECT_ENDEDIT)
   {
      if(sparam == PFX"sizeIn")
         RefreshAll();
      else if(sparam == PFX"entryIn" || sparam == PFX"tpIn" || sparam == PFX"slIn")
         UpdateAnalysis();
   }
}

//==================================================================
//  OPEN ORDER
//==================================================================
void OpenOrder(ENUM_ORDER_TYPE type)
{
   if(g_lotSize <= 0) { Print("!! g_lotSize=0"); return; }
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) { Print("!! TRADE_ALLOWED=false"); return; }
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))  { Print("!! TRADE_EXPERT=false");  return; }
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))         { Print("!! MQL_TRADE_ALLOWED=false"); return; }

   double price = (type == ORDER_TYPE_BUY)
                    ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                    : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(price <= 0) { Print("!! price=0"); return; }

   double tpP = 0, slP = 0;
   if(g_advOpen)
   {
      tpP = StringToDouble(ObjectGetString(0, PFX"tpIn", OBJPROP_TEXT));
      slP = StringToDouble(ObjectGetString(0, PFX"slIn", OBJPROP_TEXT));
   }

   if(type == ORDER_TYPE_BUY)
   {
      if(slP > 0 && slP >= price)
      { PrintFormat("!! BUY: SL %.5f must be below %.5f", slP, price); return; }
      if(tpP > 0 && tpP <= price)
      { PrintFormat("!! BUY: TP %.5f must be above %.5f", tpP, price); return; }
   }
   else
   {
      if(slP > 0 && slP <= price)
      { PrintFormat("!! SELL: SL %.5f must be above %.5f", slP, price); return; }
      if(tpP > 0 && tpP >= price)
      { PrintFormat("!! SELL: TP %.5f must be below %.5f", tpP, price); return; }
   }

   double sendLots = NormalizeLot(g_lotSize);

   ENUM_ORDER_TYPE_FILLING fills[3];
   fills[0] = ORDER_FILLING_FOK;
   fills[1] = ORDER_FILLING_IOC;
   fills[2] = ORDER_FILLING_RETURN;

   for(int i = 0; i < 3; i++)
   {
      MqlTradeRequest req; MqlTradeResult res;
      ZeroMemory(req); ZeroMemory(res);

      req.action       = TRADE_ACTION_DEAL;
      req.symbol       = _Symbol;
      req.volume       = sendLots;
      req.type         = type;
      req.price        = price;
      req.deviation    = 20;
      req.magic        = g_magic;
      req.comment      = "VorAdvs";
      req.type_filling = fills[i];

      if(slP > 0) req.sl = NormalizeDouble(slP, _Digits);
      if(tpP > 0) req.tp = NormalizeDouble(tpP, _Digits);

      bool sent = OrderSend(req, res);

      if(sent && (res.retcode == TRADE_RETCODE_DONE ||
                  res.retcode == TRADE_RETCODE_PLACED ||
                  res.retcode == TRADE_RETCODE_DONE_PARTIAL))
      {
         PrintFormat("*** SUCCESS ticket=%I64u", res.order);
         UpdatePositions();
         return;
      }
      if(res.retcode == TRADE_RETCODE_INVALID_FILL) continue;
      PrintFormat("!! Fatal LastError=%d retcode=%d", GetLastError(), res.retcode);
      return;
   }
   Print("!! All filling modes rejected.");
}
//+------------------------------------------------------------------+