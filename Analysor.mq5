//+------------------------------------------------------------------+
//|                                  UnifiedTradeDashboard.mq5       |
//|   Single draggable tabbed dashboard — READ ONLY                  |
//|                                        Developer: Shayan Ghadamian|
//+------------------------------------------------------------------+
#property version   "1.02"
#property copyright "Shayan Ghadamian"
#property description "Single draggable dashboard with tabs — READ ONLY"
#property strict

//==================================================================
//  THEME
//==================================================================
const color C_BG          = C'14,14,24';
const color C_FRAME       = C'18,18,30';
const color C_TITLE       = C'24,24,40';
const color C_CARD        = C'26,26,44';
const color C_CARD_HI     = C'34,34,54';
const color C_BORDER      = C'46,46,68';
const color C_BORDER_HI   = C'60,60,86';
const color C_DIVIDER     = C'40,40,58';
const color C_TEXT        = C'238,242,255';
const color C_MUTED       = C'148,158,186';
const color C_DIM         = C'92,100,124';
const color C_ACCENT      = C'92,178,255';
const color C_ACCENT_DK   = C'36,92,168';
const color C_ACCENT_LT   = C'152,206,255';
const color C_GREEN       = C'0,220,150';
const color C_GREEN_DK    = C'0,140,96';
const color C_RED         = C'255,74,120';
const color C_RED_DK      = C'172,42,80';
const color C_BTN         = C'38,38,58';
const color C_BTN_HOVER   = C'50,50,74';
const color C_EDIT_BG     = C'20,26,40';
const color C_EDIT_BORD   = C'52,72,100';
const color C_GREEN_DIM   = C'16,72,54';
const color C_RED_DIM     = C'80,22,40';
const color C_RISK_ZONE   = C'42,14,24';
const color C_REW_ZONE    = C'10,40,32';
const color C_PROFIT_ZONE = C'10,46,36';

//==================================================================
//  LAYOUT
//==================================================================
#define UTD_PFX      "UTD_"
#define UTD_CH       "UTD_CH_"
#define UTD_W        640
#define UTD_PAD      16
#define UTD_TITLE_H  48
#define UTD_TABS_H   40
#define UTD_ROW_H    44
#define UTD_MAX_POS  5

int g_panelX = 30;
int g_panelY = 30;

//==================================================================
//  STATE
//==================================================================
int  g_activeTab = 0;
bool g_minimized = false;
bool g_dragActive = false;
int  g_dragAnchorX = 0;
int  g_dragAnchorY = 0;
bool g_prevLeftDown = false;

// pending-edit flag — TRUE after ENDEDIT fires; processed on next fast timer tick
bool g_pnlPendingRead = false;

//==================================================================
//  MTA STATE
//==================================================================
struct MtaPos
{
   ulong              ticket;
   string             symbol;
   ENUM_POSITION_TYPE type;
   double             volume;
   double             priceOpen;
   double             sl;
   double             tp;
   double             profit;
   int                digits;
};

MtaPos              g_pos[];
int                 g_selIdx     = -1;
ulong               g_selTicket  = 0;
int                 g_tpCount    = 0;
int                 g_maxTPs     = 0;
int                 g_simTP      = 0;
int                 g_listOffset = 0;
double              g_entry      = 0;
double              g_origSL     = 0;
double              g_origTP     = 0;
double              g_curSL      = 0;
double              g_tpPrice[];
string              g_selSymbol  = "";
ENUM_POSITION_TYPE  g_selType    = POSITION_TYPE_BUY;
int                 g_selDigits  = 5;
double              g_selVolume  = 0;

//==================================================================
//  P&L STATE
//==================================================================
double pnl_lot    = 0.10;
double pnl_entry  = 1.0850;
double pnl_lev    = 100.0;
double pnl_tpVal  = 1.0900;
double pnl_slVal  = 1.0820;
int    pnl_pair   = 0;
int    pnl_tpMode = 0;
int    pnl_slMode = 0;

//==================================================================
//  FORWARD DECLS
//==================================================================
void UTD_Build();
void PNL_Build(int x0, int y0);
void PNL_ReadEdits();

//==================================================================
//  OBJECT HELPERS
//==================================================================
void mRect(string name, int x, int y, int w, int h,
           color bg, color border, bool back=false)
{
   string nm = UTD_PFX + name;
   if(ObjectFind(0, nm) < 0)
      ObjectCreate(0, nm, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_CORNER,      CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE,   x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE,   y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE,       w);
   ObjectSetInteger(0, nm, OBJPROP_YSIZE,       h);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR,     bg);
   ObjectSetInteger(0, nm, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, nm, OBJPROP_COLOR,       border);
   ObjectSetInteger(0, nm, OBJPROP_BACK,        back);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE,  false);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN,      true);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER,      0);
}

void mText(string name, int x, int y, string text, color clr,
           int size=9, string font="Segoe UI")
{
   string nm = UTD_PFX + name;
   if(ObjectFind(0, nm) < 0)
      ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE,  x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE,  y);
   ObjectSetString (0, nm, OBJPROP_TEXT,       text);
   ObjectSetInteger(0, nm, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,   size);
   ObjectSetString (0, nm, OBJPROP_FONT,       font);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER,     10);
}

void mBtn(string name, int x, int y, int w, int h,
          string text, color bg, color txt, color border, int fs=9)
{
   string nm = UTD_PFX + name;
   if(ObjectFind(0, nm) < 0)
      ObjectCreate(0, nm, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_CORNER,       CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE,    x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE,    y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE,        w);
   ObjectSetInteger(0, nm, OBJPROP_YSIZE,        h);
   ObjectSetString (0, nm, OBJPROP_TEXT,         text);
   ObjectSetString (0, nm, OBJPROP_FONT,         "Segoe UI Semibold");
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,     fs);
   ObjectSetInteger(0, nm, OBJPROP_COLOR,        txt);
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR,      bg);
   ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR, border);
   ObjectSetInteger(0, nm, OBJPROP_BACK,         false);
   ObjectSetInteger(0, nm, OBJPROP_STATE,        false);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE,   false);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN,       true);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER,       100);
}

void mEdit(string name, int x, int y, int w, int h,
           string text, color txtClr)
{
   string nm = UTD_PFX + name;
   if(ObjectFind(0, nm) >= 0) return;
   ObjectCreate(0, nm, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, nm, OBJPROP_CORNER,         CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nm, OBJPROP_XDISTANCE,      x);
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE,      y);
   ObjectSetInteger(0, nm, OBJPROP_XSIZE,          w);
   ObjectSetInteger(0, nm, OBJPROP_YSIZE,          h);
   ObjectSetString (0, nm, OBJPROP_TEXT,           text);
   ObjectSetInteger(0, nm, OBJPROP_COLOR,          txtClr);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,       10);
   ObjectSetString (0, nm, OBJPROP_FONT,           "Consolas");
   ObjectSetInteger(0, nm, OBJPROP_BGCOLOR,        C_EDIT_BG);
   ObjectSetInteger(0, nm, OBJPROP_BORDER_COLOR,   C_EDIT_BORD);
   ObjectSetInteger(0, nm, OBJPROP_READONLY,       false);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE,     false);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN,         true);
   ObjectSetInteger(0, nm, OBJPROP_ZORDER,         50);
   ObjectSetInteger(0, nm, OBJPROP_ALIGN,          ALIGN_LEFT);
}

//==================================================================
//  CLEAR / SHIFT
//==================================================================
void UTD_ClearPanel()
{
   int tot = ObjectsTotal(0, -1, -1);
   for(int i = tot - 1; i >= 0; i--)
   {
      string nm = ObjectName(0, i, -1, -1);
      if(StringFind(nm, UTD_CH) == 0) continue;
      if(StringFind(nm, UTD_PFX) == 0)
         ObjectDelete(0, nm);
   }
}

void UTD_ClearChart()
{
   int tot = ObjectsTotal(0, -1, -1);
   for(int i = tot - 1; i >= 0; i--)
   {
      string nm = ObjectName(0, i, -1, -1);
      if(StringFind(nm, UTD_CH) == 0)
         ObjectDelete(0, nm);
   }
}

void UTD_ShiftAll(int dx, int dy)
{
   int tot = ObjectsTotal(0, -1, -1);
   for(int i = 0; i < tot; i++)
   {
      string nm = ObjectName(0, i, -1, -1);
      if(StringFind(nm, UTD_PFX) != 0) continue;
      long x = ObjectGetInteger(0, nm, OBJPROP_XDISTANCE);
      long y = ObjectGetInteger(0, nm, OBJPROP_YDISTANCE);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x + dx);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y + dy);
   }
   g_panelX += dx;
   g_panelY += dy;
}

//==================================================================
//  FORMATTERS
//==================================================================
string FmtSigned(double v, bool profit)
{
   if(v == 0) return "0";
   string sign = profit ? "+" : "-";
   string num;
   if(v >= 100)      num = DoubleToString(v, 0);
   else if(v >= 10)  num = DoubleToString(v, 1);
   else              num = DoubleToString(v, 2);
   return sign + num;
}
string FmtUsd(double v)
{
   string sign = (v > 0) ? "+" : ((v < 0) ? "-" : "");
   return sign + "$" + DoubleToString(MathAbs(v), 2);
}
string FmtPct(double v)
{
   string sign = (v > 0) ? "+" : ((v < 0) ? "-" : "");
   double a = MathAbs(v);
   string num;
   if(a < 0.01)     num = DoubleToString(a, 3);
   else if(a < 1.0) num = DoubleToString(a, 2);
   else             num = DoubleToString(a, 1);
   return sign + num + "%";
}

//==================================================================
//  MTA
//==================================================================
string MTA_Hash()
{
   string h = "";
   for(int i = 0; i < ArraySize(g_pos); i++)
      h += IntegerToString((long)g_pos[i].ticket) + "|"
         + DoubleToString(g_pos[i].volume,    2) + "|"
         + DoubleToString(g_pos[i].priceOpen, 5) + "|"
         + DoubleToString(g_pos[i].sl,        5) + "|"
         + DoubleToString(g_pos[i].tp,        5) + "|"
         + DoubleToString(g_pos[i].profit,    2) + ";";
   return h;
}

void MTA_Refresh()
{
   MtaPos tmp[];
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(!PositionSelectByTicket(tk)) continue;

      MtaPos p;
      p.ticket    = tk;
      p.symbol    = PositionGetString(POSITION_SYMBOL);
      p.type      = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      p.volume    = PositionGetDouble(POSITION_VOLUME);
      p.priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
      p.sl        = PositionGetDouble(POSITION_SL);
      p.tp        = PositionGetDouble(POSITION_TP);
      p.profit    = PositionGetDouble(POSITION_PROFIT);
      p.digits    = (int)SymbolInfoInteger(p.symbol, SYMBOL_DIGITS);

      int sz = ArraySize(tmp);
      ArrayResize(tmp, sz + 1);
      tmp[sz] = p;
   }

   ArrayFree(g_pos);
   int cnt = ArraySize(tmp);
   ArrayResize(g_pos, cnt);
   for(int i = 0; i < cnt; i++) g_pos[i] = tmp[i];

   if(g_listOffset + UTD_MAX_POS > cnt && cnt > 0)
      g_listOffset = MathMax(0, cnt - UTD_MAX_POS);
   if(cnt == 0) g_listOffset = 0;

   if(g_selTicket != 0)
   {
      g_selIdx = -1;
      for(int i = 0; i < ArraySize(g_pos); i++)
         if(g_pos[i].ticket == g_selTicket) { g_selIdx = i; break; }

      if(g_selIdx < 0)
      {
         g_selTicket = 0;
         g_tpCount   = 0;
         g_simTP     = 0;
         ArrayFree(g_tpPrice);
         UTD_ClearChart();
      }
   }
   else g_selIdx = -1;
}

int MTA_MaxTPs(double volume, string symbol)
{
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double minL = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   if(step <= 0) step = 0.01;
   if(minL <= 0) minL = step;

   int totalSteps = (int)MathFloor(volume / step + 1e-8);
   int minSteps   = (int)MathCeil (minL   / step - 1e-8);
   if(minSteps < 1) minSteps = 1;
   if(totalSteps < minSteps) return 0;
   return totalSteps / minSteps;
}

double MTA_PerTPVolume()
{
   if(g_tpCount <= 0) return 0;
   double step = SymbolInfoDouble(g_selSymbol, SYMBOL_VOLUME_STEP);
   double per  = g_selVolume / g_tpCount;
   per = MathFloor(per / step + 1e-8) * step;
   return NormalizeDouble(per, 2);
}

color MTA_RColor(double r)
{
   if(r <= 1.0) return C_GREEN;
   if(r <= 2.0) return (color)C'0,200,140';
   if(r <= 3.0) return (color)C'0,180,130';
   if(r <= 5.0) return (color)C'0,160,120';
   return (color)C'0,140,110';
}

void MTA_Select(int idx)
{
   if(idx < 0 || idx >= ArraySize(g_pos)) return;

   g_selIdx    = idx;
   g_selTicket = g_pos[idx].ticket;
   g_selSymbol = g_pos[idx].symbol;
   g_selType   = g_pos[idx].type;
   g_selDigits = g_pos[idx].digits;
   g_selVolume = g_pos[idx].volume;

   g_entry  = g_pos[idx].priceOpen;
   g_origSL = g_pos[idx].sl;
   g_origTP = g_pos[idx].tp;
   g_curSL  = g_origSL;

   g_tpCount = 0;
   g_simTP   = 0;
   ArrayFree(g_tpPrice);

   g_maxTPs = MTA_MaxTPs(g_pos[idx].volume, g_pos[idx].symbol);

   UTD_ClearChart();
   UTD_Build();
}

void MTA_SetTPCount(int n)
{
   if(g_selIdx < 0) return;
   if(n <= 0 || n > g_maxTPs) return;

   g_tpCount = n;
   g_simTP   = 0;
   g_curSL   = g_origSL;
   ArrayFree(g_tpPrice);
   ArrayResize(g_tpPrice, n);

   bool   isBuy  = (g_selType == POSITION_TYPE_BUY);
   double slDist = MathAbs(g_entry - g_origSL);
   if(slDist <= 0) slDist = g_entry * 0.01;

   bool   hasTP  = false;
   double target = 0;
   if(g_origTP > 0)
   {
      if(isBuy && g_origTP > g_entry)  { hasTP = true; target = g_origTP; }
      if(!isBuy && g_origTP < g_entry) { hasTP = true; target = g_origTP; }
   }

   if(hasTP)
   {
      double total = MathAbs(target - g_entry);
      for(int i = 0; i < n; i++)
      {
         double frac = (double)(i + 1) / (double)n;
         double d    = total * frac;
         g_tpPrice[i] = isBuy ? (g_entry + d) : (g_entry - d);
      }
   }
   else
   {
      for(int i = 0; i < n; i++)
      {
         double mult = (double)(i + 1);
         g_tpPrice[i] = isBuy ? (g_entry + mult * slDist)
                              : (g_entry - mult * slDist);
      }
   }

   MTA_DrawChart();
   UTD_Build();
}

void MTA_SimNext()
{
   if(g_selIdx < 0 || g_tpCount <= 0) return;
   if(g_simTP >= g_tpCount) return;

   g_simTP++;
   g_curSL = (g_simTP == 1) ? g_entry : g_tpPrice[g_simTP - 2];

   MTA_DrawChart();
   UTD_Build();
}

void MTA_Reset()
{
   g_simTP = 0;
   g_curSL = g_origSL;
   if(g_tpCount > 0) MTA_DrawChart();
   UTD_Build();
}

//==================================================================
//  MTA — CHART OVERLAY
//==================================================================
void MTA_HLine(string name, double price, color clr, int w, ENUM_LINE_STYLE st)
{
   string nm = UTD_CH + name;
   if(ObjectFind(0, nm) >= 0) ObjectDelete(0, nm);
   ObjectCreate(0, nm, OBJ_HLINE, 0, 0, price);
   ObjectSetInteger(0, nm, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, nm, OBJPROP_WIDTH,      w);
   ObjectSetInteger(0, nm, OBJPROP_STYLE,      st);
   ObjectSetInteger(0, nm, OBJPROP_BACK,       false);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     true);
}

void MTA_Lbl(string name, datetime t, double p, string txt, color clr)
{
   string nm = UTD_CH + name;
   if(ObjectFind(0, nm) >= 0) ObjectDelete(0, nm);
   ObjectCreate(0, nm, OBJ_TEXT, 0, t, p);
   ObjectSetString (0, nm, OBJPROP_TEXT,       txt);
   ObjectSetInteger(0, nm, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, nm, OBJPROP_FONTSIZE,   8);
   ObjectSetString (0, nm, OBJPROP_FONT,       "Segoe UI Semibold");
   ObjectSetInteger(0, nm, OBJPROP_ANCHOR,     ANCHOR_LEFT);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     true);
}

void MTA_Tag(string name, double price, color clr)
{
   string nm = UTD_CH + name;
   if(ObjectFind(0, nm) >= 0) ObjectDelete(0, nm);
   ObjectCreate(0, nm, OBJ_ARROW_RIGHT_PRICE, 0, 0, price);
   ObjectSetInteger(0, nm, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, nm, OBJPROP_WIDTH,      1);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     true);
}

void MTA_Rect(datetime t1, double p1, datetime t2, double p2, color clr)
{
   string nm = UTD_CH + "z_" + IntegerToString((int)t1) + "_" + DoubleToString(p1, 6);
   if(ObjectFind(0, nm) >= 0) ObjectDelete(0, nm);
   ObjectCreate(0, nm, OBJ_RECTANGLE, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, nm, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, nm, OBJPROP_FILL,       true);
   ObjectSetInteger(0, nm, OBJPROP_BACK,       true);
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, nm, OBJPROP_HIDDEN,     true);
}

void MTA_DrawChart()
{
   UTD_ClearChart();
   if(g_tpCount <= 0) return;

   if(g_selSymbol != _Symbol)
   {
      MTA_Lbl("NOTE", iTime(_Symbol, _Period, 0),
              iHigh(_Symbol, _Period, 0),
              "  Open " + g_selSymbol + " chart to view the tool  ",
              C_DIM);
      return;
   }

   int      ps   = PeriodSeconds();
   datetime t0   = iTime(_Symbol, _Period, 0);
   datetime tL   = t0 - (datetime)(ps * 60);
   datetime tR   = t0 + (datetime)(ps * 60);
   datetime tLbl = tL + (datetime)(ps * 2);

   bool   isBuy = (g_selType == POSITION_TYPE_BUY);
   double refR  = MathAbs(g_entry - g_origSL);
   if(refR <= 0) refR = g_entry * 0.01;

   double lastTP = g_tpPrice[g_tpCount - 1];
   MTA_Rect(tL, MathMin(g_entry, lastTP), tR, MathMax(g_entry, lastTP), C_REW_ZONE);

   if(g_curSL > 0)
   {
      double slDist = isBuy ? (g_curSL - g_entry) : (g_entry - g_curSL);
      color  slClr  = (slDist < 0) ? C_RISK_ZONE : C_PROFIT_ZONE;
      MTA_Rect(tL, MathMin(g_entry, g_curSL), tR, MathMax(g_entry, g_curSL), slClr);
   }

   MTA_HLine("ENTRY", g_entry, C_ACCENT, 2, STYLE_SOLID);
   MTA_Lbl  ("L_ENTRY", tLbl, g_entry, " Entry", C_ACCENT);
   MTA_Tag  ("R_ENTRY", g_entry, C_ACCENT);

   if(g_simTP > 0 && g_origSL > 0)
   {
      MTA_HLine("OSL", g_origSL, C_RED_DIM, 1, STYLE_DOT);
      MTA_Lbl  ("L_OSL", tLbl, g_origSL, " Orig SL", C_RED_DIM);
      MTA_Tag  ("R_OSL", g_origSL, C_RED_DIM);
   }

   if(g_curSL > 0)
   {
      MTA_HLine("SL", g_curSL, C_RED, 2, STYLE_SOLID);
      MTA_Lbl  ("L_SL", tLbl, g_curSL, " SL", C_RED);
      MTA_Tag  ("R_SL", g_curSL, C_RED);
   }

   for(int i = 0; i < g_tpCount; i++)
   {
      bool  hit = (i < g_simTP);
      color c   = hit ? C_GREEN_DIM : C_GREEN;
      MTA_HLine("TP" + IntegerToString(i + 1), g_tpPrice[i], c, 1, STYLE_SOLID);

      double dist = MathAbs(g_tpPrice[i] - g_entry);
      double rM   = dist / refR;
      string lbl  = " TP" + IntegerToString(i + 1)
                  + "  (" + DoubleToString(rM, 1) + "R)";
      MTA_Lbl("L_TP" + IntegerToString(i + 1), tLbl, g_tpPrice[i], lbl, c);
      MTA_Tag("R_TP" + IntegerToString(i + 1), g_tpPrice[i], c);
   }

   ChartRedraw();
}

//==================================================================
//  MTA — HEIGHT / BUILD
//==================================================================
int MTA_Height()
{
   bool hasSel = (g_selIdx >= 0 && g_selIdx < ArraySize(g_pos));
   bool hasTP  = (hasSel && g_tpCount > 0);

   int nPos = ArraySize(g_pos);
   int rows = MathMax(1, MathMin(nPos, UTD_MAX_POS));

   int h = 0;
   h += 26;
   h += rows * (UTD_ROW_H + 4);
   if(nPos > UTD_MAX_POS) h += 28;
   h += 20;

   h += 22 + 128;
   h += 20;

   h += 24;
   h += 34 + 6;
   h += 24 + 6;
   if(hasTP)
   {
      int prow = MathMin(g_tpCount, 6);
      if(g_tpCount > 6) prow += 1;
      h += prow * 20 + 16;
   }
   h += 20;

   h += 22;
   if(hasTP) h += 22;
   h += 32 + 8;
   h += 44;

   return h;
}

void MTA_Build(int x0, int y0)
{
   int cx = x0;
   int cw = UTD_W - 2*UTD_PAD;
   int y  = y0;

   bool hasSel  = (g_selIdx >= 0 && g_selIdx < ArraySize(g_pos));
   bool hasTP   = (hasSel && g_tpCount > 0);
   bool sameSym = (hasSel && g_selSymbol == _Symbol);

   int nPos = ArraySize(g_pos);

   mText("M_POS_HDR", cx, y + 4, "OPEN POSITIONS", C_MUTED, 8, "Segoe UI Semibold");
   string cntTxt = IntegerToString(nPos) + " active";
   mText("M_POS_CNT", cx + cw - 70, y + 4, cntTxt, C_DIM, 8);
   y += 26;

   if(nPos == 0)
   {
      mRect("M_NOPOS", cx, y, cw, UTD_ROW_H, C_CARD, C_BORDER);
      mText("M_NOPOS_T", cx + 16, y + 14, "No open positions", C_DIM, 10);
      y += UTD_ROW_H + 4;
   }
   else
   {
      int shown = 0;
      for(int i = g_listOffset; i < nPos && shown < UTD_MAX_POS; i++, shown++)
      {
         bool  sel   = (i == g_selIdx);
         bool  isBuy = (g_pos[i].type == POSITION_TYPE_BUY);
         color bg    = sel ? C_ACCENT_DK : C_CARD;
         color bdr   = sel ? C_ACCENT    : C_BORDER;
         color dir   = isBuy ? C_GREEN : C_RED;
         color pl    = (g_pos[i].profit >= 0) ? C_GREEN : C_RED;

         mRect("M_PBG" + IntegerToString(shown),
               cx, y, cw, UTD_ROW_H, bg, bdr);

         mRect("M_PDIRBG" + IntegerToString(shown),
               cx + 10, y + 11, 26, 22,
               isBuy ? (color)C'15,52,40' : (color)C'54,20,32',
               isBuy ? (color)C'15,52,40' : (color)C'54,20,32');
         mText("M_PDIR" + IntegerToString(shown),
               cx + 16, y + 14,
               isBuy ? "▲" : "▼", dir, 8, "Segoe UI Semibold");

         mText("M_PSYM" + IntegerToString(shown),
               cx + 46, y + 7,
               g_pos[i].symbol + "  ·  " + DoubleToString(g_pos[i].volume, 2),
               C_TEXT, 10, "Segoe UI Semibold");

         mText("M_PTK" + IntegerToString(shown),
               cx + 46, y + 24,
               "#" + IntegerToString((long)g_pos[i].ticket)
               + "  @" + DoubleToString(g_pos[i].priceOpen, g_pos[i].digits),
               C_MUTED, 8);

         string pls = (g_pos[i].profit >= 0 ? "+" : "")
                    + DoubleToString(g_pos[i].profit, 2);
         mText("M_PPL" + IntegerToString(shown),
               cx + cw - 84, y + 14, pls, pl, 10, "Segoe UI Semibold");

         mBtn("M_POS_" + IntegerToString(i),
              cx, y, cw, UTD_ROW_H, "", clrNONE, clrNONE, clrNONE);

         y += UTD_ROW_H + 4;
      }

      if(nPos > UTD_MAX_POS)
      {
         int btnW = 28;
         mRect("M_SCRBG", cx, y, cw, 24, C_CARD, C_BORDER);
         mBtn("M_SCRLU", cx, y, btnW, 24, "‹", C_BTN, C_TEXT, C_BORDER_HI, 12);
         mBtn("M_SCRDN", cx + cw - btnW, y, btnW, 24, "›", C_BTN, C_TEXT, C_BORDER_HI, 12);

         string rng = IntegerToString(g_listOffset + 1)
                    + "–" + IntegerToString(g_listOffset + MathMin(nPos, UTD_MAX_POS))
                    + " of " + IntegerToString(nPos);
         int rw = StringLen(rng) * 6;
         mText("M_SCRT", cx + (cw - rw)/2, y + 7, rng, C_MUTED, 8);
         y += 28;
      }
   }

   y += 20;

   int cardH = 128;
   mRect("M_CARD", cx, y, cw, cardH, C_CARD, C_BORDER);

   if(hasSel)
   {
      MtaPos p = g_pos[g_selIdx];
      bool  isBuy = (p.type == POSITION_TYPE_BUY);
      color dir   = isBuy ? C_GREEN : C_RED;

      mText("M_C_SYM", cx + 16, y + 14,
            p.symbol, C_TEXT, 13, "Segoe UI Semibold");

      mText("M_C_SUB", cx + 16, y + 34,
            "#" + IntegerToString((long)p.ticket)
            + "  ·  " + (isBuy ? "BUY" : "SELL")
            + "  ·  " + DoubleToString(p.volume, 2) + " lots",
            dir, 9);

      string pls = (p.profit >= 0 ? "+" : "") + DoubleToString(p.profit, 2);
      color  plc = (p.profit >= 0) ? C_GREEN : C_RED;
      mText("M_C_PL", cx + cw - 100, y + 14, pls, plc, 12, "Segoe UI Semibold");

      mRect("M_C_DIV", cx + 16, y + 54, cw - 32, 1, C_DIVIDER, C_DIVIDER);

      int cL = cx + 16;
      int cR = cx + 16 + (cw - 32)/2 + 4;

      int ly = y + 64;
      mText("M_C_L1", cL, ly, "Entry", C_DIM, 8);
      mText("M_C_V1", cL, ly + 14,
            DoubleToString(p.priceOpen, p.digits),
            C_TEXT, 11, "Segoe UI Semibold");

      mText("M_C_L2", cR, ly, "Stop Loss", C_DIM, 8);
      mText("M_C_V2", cR, ly + 14,
            (p.sl > 0 ? DoubleToString(p.sl, p.digits) : "—"),
            p.sl > 0 ? C_RED : C_DIM, 11, "Segoe UI Semibold");

      ly += 34;
      mText("M_C_L3", cL, ly, "Take Profit", C_DIM, 8);
      mText("M_C_V3", cL, ly + 14,
            (p.tp > 0 ? DoubleToString(p.tp, p.digits) : "—"),
            p.tp > 0 ? C_GREEN : C_DIM, 11, "Segoe UI Semibold");

      mText("M_C_L4", cR, ly, "Max Slices", C_DIM, 8);
      mText("M_C_V4", cR, ly + 14,
            IntegerToString(g_maxTPs) + "  ·  step "
            + DoubleToString(SymbolInfoDouble(p.symbol, SYMBOL_VOLUME_STEP), 2),
            C_ACCENT, 11, "Segoe UI Semibold");
   }
   else
   {
      mText("M_C_EMPTY", cx + 16, y + 52,
            "No position selected", C_DIM, 11, "Segoe UI Semibold");
      mText("M_C_EMPTY2", cx + 16, y + 76,
            "Tap a row above to begin planning", C_MUTED, 8);
   }

   y += cardH + 20;

   mText("M_TP_HDR", cx, y + 4, "TP PLAN", C_MUTED, 8, "Segoe UI Semibold");
   string tpCount = hasSel
                    ? IntegerToString(g_tpCount) + " / " + IntegerToString(g_maxTPs)
                    : "—";
   mText("M_TP_CNT", cx + cw - 60, y + 4, tpCount, C_DIM, 8);
   y += 24;

   if(hasSel && g_maxTPs > 0)
   {
      int stepH = 34;
      int btnW  = 52;
      int valW  = cw - 2*btnW - 8;

      mBtn("M_TP_DEC", cx, y, btnW, stepH, "−",
           C_BTN, C_TEXT, C_BORDER_HI, 15);

      mRect("M_TP_VBG", cx + btnW + 4, y, valW, stepH, C_CARD_HI, C_BORDER_HI);
      string vs = (g_tpCount > 0) ? IntegerToString(g_tpCount) : "—";
      int vw = StringLen(vs) * 9;
      mText("M_TP_VAL", cx + btnW + 4 + (valW - vw)/2, y + 9,
            vs, C_TEXT, 14, "Segoe UI Semibold");

      mBtn("M_TP_INC", cx + cw - btnW, y, btnW, stepH, "+",
           C_BTN, C_TEXT, C_BORDER_HI, 15);

      y += stepH + 6;

      int presets[] = {2, 3, 5, 10, 20, -1};
      int pW = (cw - 5*4) / 6;
      int pX = cx;
      for(int i = 0; i < 6; i++)
      {
         int val = presets[i];
         if(val == -1 && g_maxTPs < 20) continue;
         if(val >  g_maxTPs) continue;
         bool active = (val == g_tpCount);
         string txt  = (val == -1) ? "Max" : IntegerToString(val);
         string id   = (val == -1) ? "M_TPQ_MAX" : "M_TPQ_" + IntegerToString(val);
         mBtn(id, pX, y, pW, 22, txt,
              active ? C_ACCENT : C_BTN,
              active ? clrWhite : C_TEXT,
              active ? C_ACCENT : C_BORDER_HI, 8);
         pX += pW + 4;
      }
      y += 24 + 6;

      if(hasTP)
      {
         int prow = MathMin(g_tpCount, 6);
         bool more = (g_tpCount > 6);
         int prevH = prow * 20 + (more ? 18 : 0) + 16;

         mRect("M_TP_PBG", cx, y, cw, prevH, C_CARD, C_BORDER);

         double refR = MathAbs(g_entry - g_origSL);
         if(refR <= 0) refR = g_entry * 0.01;
         double perV = MTA_PerTPVolume();

         int ry = y + 8;
         for(int i = 0; i < prow; i++)
         {
            bool   hit = (i < g_simTP);
            double rM  = MathAbs(g_tpPrice[i] - g_entry) / refR;
            color  rc  = MTA_RColor(rM);

            mRect("M_TPD" + IntegerToString(i), cx + 14, ry + 6, 10, 10,
                  hit ? C_GREEN_DK : rc, hit ? C_GREEN_DK : rc);

            mText("M_TPL" + IntegerToString(i), cx + 34, ry + 3,
                  "TP" + IntegerToString(i + 1),
                  C_MUTED, 8, "Segoe UI Semibold");

            mText("M_TPP" + IntegerToString(i), cx + 76, ry + 2,
                  DoubleToString(g_tpPrice[i], g_selDigits),
                  hit ? C_GREEN_DK : C_TEXT, 9, "Segoe UI Semibold");

            mText("M_TPR" + IntegerToString(i), cx + 200, ry + 3,
                  DoubleToString(rM, 1) + "R", rc, 8);

            string vs2 = DoubleToString(perV, 2) + " lots";
            int vw2 = StringLen(vs2) * 6;
            mText("M_TPV" + IntegerToString(i), cx + cw - vw2 - 14, ry + 3,
                  vs2, C_DIM, 8);

            ry += 20;
         }
         if(more)
            mText("M_TP_MORE", cx + 14, ry + 2,
                  "· · ·   " + IntegerToString(g_tpCount - 6) + " more levels",
                  C_DIM, 8);

         y += prevH;
      }
      y += 20;
   }
   else
   {
      mText("M_TP_NONE", cx, y + 4,
            hasSel ? "Volume too small to split" : "Select a position first",
            C_DIM, 9);
      y += 34 + 6 + 24 + 20;
   }

   mText("M_SIM_H", cx, y + 4, "SIMULATION", C_MUTED, 8, "Segoe UI Semibold");
   mText("M_SIM_SUB", cx + 100, y + 4, "visual only", C_DIM, 8);
   y += 22;

   if(hasTP)
   {
      int dots = MathMin(g_tpCount, 20);
      int dw = 12, dg = 4;
      int tw = dots * dw + (dots - 1) * dg;
      if(tw > cw) { dw = 6; dg = 3; tw = dots*dw + (dots-1)*dg; }
      int sx = cx + (cw - tw)/2;

      for(int i = 0; i < dots; i++)
      {
         bool hit = (i < g_simTP);
         mRect("M_SD" + IntegerToString(i),
               sx + i*(dw+dg), y + 4, dw, 12,
               hit ? C_GREEN : C_BTN,
               hit ? C_GREEN : C_BORDER_HI);
      }
      y += 22;
   }

   int half = (cw - 10)/2;
   bool sa = hasTP;
   mBtn("M_SIM", cx, y, half, 32,
        "Simulate Next TP",
        sa ? C_ACCENT_DK : C_BTN,
        sa ? clrWhite    : C_DIM,
        sa ? C_ACCENT    : C_BORDER_HI, 9);
   mBtn("M_RST", cx + half + 10, y, half, 32,
        "Reset", C_BTN, C_TEXT, C_BORDER_HI, 9);

   y += 32 + 8;

   string s1 = "", s2 = "";
   color  s1c = C_TEXT, s2c = C_DIM;
   string icon = "·";

   if(hasTP)
   {
      s1 = "TP " + IntegerToString(g_simTP) + " / " + IntegerToString(g_tpCount) + " hit";
      s1c = C_ACCENT;
      icon = "◆";

      if(g_simTP == 0)
         s2 = "SL at original price " + DoubleToString(g_origSL, g_selDigits);
      else if(g_simTP == 1)
         s2 = "SL → Entry " + DoubleToString(g_entry, g_selDigits);
      else
         s2 = "SL → TP" + IntegerToString(g_simTP - 1) + " "
            + DoubleToString(g_tpPrice[g_simTP - 2], g_selDigits);
   }
   else if(hasSel && !sameSym)
   {
      s1 = "Symbol mismatch";
      s1c = C_RED;
      icon = "!";
      s2 = "Open " + g_selSymbol + " chart to see overlay";
   }
   else
   {
      s1 = hasSel ? "Choose a TP count" : "Select a position to begin";
      s2 = "AutoTrading stays OFF · no orders are sent";
   }

   mRect("M_ST_BG", cx, y, cw, 44, C_TITLE, C_BORDER);
   mRect("M_ST_ACC", cx, y, 3, 44, s1c, s1c);

   mText("M_ST_IC", cx + 14, y + 14, icon, s1c, 12, "Segoe UI Semibold");
   mText("M_ST_1",  cx + 34, y + 8,  s1, s1c, 10, "Segoe UI Semibold");
   mText("M_ST_2",  cx + 34, y + 26, s2, s2c, 8);
}

//==================================================================
//  PNL — LOGIC
//==================================================================
double PNL_PipSize()
{
   if(pnl_pair == 1) return 0.01;
   if(pnl_pair == 2) return 0.1;
   return 0.0001;
}

// Reads current committed values from the edit fields.
// Only updates state if the field has non-empty, valid content.
void PNL_ReadEdits()
{
   string nm, txt;
   double v;

   nm = UTD_PFX + "P_LOT";
   if(ObjectFind(0, nm) >= 0)
   {
      txt = ObjectGetString(0, nm, OBJPROP_TEXT);
      if(StringLen(txt) > 0)
      {
         v = StringToDouble(txt);
         if(v > 0.0) pnl_lot = v;
      }
   }

   nm = UTD_PFX + "P_ENT";
   if(ObjectFind(0, nm) >= 0)
   {
      txt = ObjectGetString(0, nm, OBJPROP_TEXT);
      if(StringLen(txt) > 0)
      {
         v = StringToDouble(txt);
         if(v > 0.0) pnl_entry = v;
      }
   }

   nm = UTD_PFX + "P_LV";
   if(ObjectFind(0, nm) >= 0)
   {
      txt = ObjectGetString(0, nm, OBJPROP_TEXT);
      if(StringLen(txt) > 0)
      {
         v = StringToDouble(txt);
         if(v >= 1.0) pnl_lev = v;
      }
   }

   nm = UTD_PFX + "P_TPV";
   if(ObjectFind(0, nm) >= 0)
   {
      txt = ObjectGetString(0, nm, OBJPROP_TEXT);
      if(StringLen(txt) > 0)
         pnl_tpVal = StringToDouble(txt);
   }

   nm = UTD_PFX + "P_SLV";
   if(ObjectFind(0, nm) >= 0)
   {
      txt = ObjectGetString(0, nm, OBJPROP_TEXT);
      if(StringLen(txt) > 0)
         pnl_slVal = StringToDouble(txt);
   }
}

int PNL_Height()
{
   return 460;
}

//==================================================================
//  PNL — PANEL
//==================================================================
void PNL_Build(int x0, int y0)
{
   int cx = x0;
   int cw = UTD_W - 2*UTD_PAD;
   int y  = y0;

   double pipSize = PNL_PipSize();
   double lot   = (pnl_lot   > 0) ? pnl_lot   : 0.10;
   double entry = (pnl_entry != 0) ? pnl_entry : 1.0850;
   double lev   = (pnl_lev   >= 1) ? pnl_lev   : 100;

   // ---- Row 1: Lot / Entry / Lv
   mText("P_L1", cx, y + 6, "Lot", C_MUTED, 8, "Segoe UI Semibold");
   mEdit("P_LOT", cx + 44, y, 100, 28,
         DoubleToString(pnl_lot, 2), C_TEXT);

   mText("P_L2", cx + 172, y + 6, "Entry", C_MUTED, 8, "Segoe UI Semibold");
   mEdit("P_ENT", cx + 226, y, 140, 28,
         DoubleToString(pnl_entry, 5), C_TEXT);

   mText("P_L3", cx + 396, y + 6, "Leverage", C_MUTED, 8, "Segoe UI Semibold");
   mEdit("P_LV", cx + 466, y, 126, 28,
         DoubleToString(pnl_lev, 0), C_TEXT);

   y += 40;

   // ---- Row 2: pair buttons
   mText("P_L4", cx, y + 6, "Pair", C_MUTED, 8, "Segoe UI Semibold");

   int bW = 152, bH = 28;
   int bX = cx + 44;

   mBtn("P_PSTD", bX,               y, bW, bH, "Standard FX",
        (pnl_pair == 0 ? C_ACCENT : C_BTN),
        (pnl_pair == 0 ? clrWhite : C_MUTED),
        (pnl_pair == 0 ? C_ACCENT : C_BORDER_HI), 8);
   mBtn("P_PJPY", bX + bW + 6,      y, bW, bH, "JPY pair",
        (pnl_pair == 1 ? C_ACCENT : C_BTN),
        (pnl_pair == 1 ? clrWhite : C_MUTED),
        (pnl_pair == 1 ? C_ACCENT : C_BORDER_HI), 8);
   mBtn("P_PXAU", bX + 2*(bW+6),    y, bW, bH, "Gold (XAU)",
        (pnl_pair == 2 ? C_ACCENT : C_BTN),
        (pnl_pair == 2 ? clrWhite : C_MUTED),
        (pnl_pair == 2 ? C_ACCENT : C_BORDER_HI), 8);

   y += 46;

   // ---- TAKE PROFIT block
   mRect("P_TP_BG", cx, y, cw, 92, C_CARD, C_BORDER);
   mRect("P_TP_ACC", cx, y, 3, 92, C_GREEN, C_GREEN);

   mText("P_TP_T", cx + 14, y + 8, "TAKE PROFIT", C_GREEN, 10, "Segoe UI Semibold");

   int mW = 68, mH = 26, mX = cx + 14, mY = y + 30;
   mBtn("P_TPM_P",   mX,                mY, mW, mH, "Price",
        (pnl_tpMode == 0 ? C_ACCENT_DK : C_BTN),
        (pnl_tpMode == 0 ? clrWhite : C_MUTED),
        (pnl_tpMode == 0 ? C_ACCENT : C_BORDER_HI), 8);
   mBtn("P_TPM_PIP", mX + mW + 4,       mY, mW, mH, "Pip",
        (pnl_tpMode == 1 ? C_ACCENT_DK : C_BTN),
        (pnl_tpMode == 1 ? clrWhite : C_MUTED),
        (pnl_tpMode == 1 ? C_ACCENT : C_BORDER_HI), 8);
   mBtn("P_TPM_PCT", mX + 2*(mW+4),     mY, mW, mH, "%",
        (pnl_tpMode == 2 ? C_ACCENT_DK : C_BTN),
        (pnl_tpMode == 2 ? clrWhite : C_MUTED),
        (pnl_tpMode == 2 ? C_ACCENT : C_BORDER_HI), 8);

   mText("P_TPV_L", cx + 274, y + 36, "Value", C_MUTED, 8, "Segoe UI Semibold");
   mEdit("P_TPV", cx + 322, y + 30, cw - 336, 26,
         DoubleToString(pnl_tpVal, 5), C_TEXT);

   string tpHint = "Enter target price (e.g. 1.0900)";
   if(pnl_tpMode == 1) tpHint = "Enter pip distance (e.g. 50 for +50 pips)";
   else if(pnl_tpMode == 2) tpHint = "Enter % move (e.g. 0.5 for +0.5%)";
   mText("P_TP_H", cx + 14, y + 70, tpHint, C_DIM, 8);

   y += 100;

   // ---- STOP LOSS block
   mRect("P_SL_BG", cx, y, cw, 92, C_CARD, C_BORDER);
   mRect("P_SL_ACC", cx, y, 3, 92, C_RED, C_RED);

   mText("P_SL_T", cx + 14, y + 8, "STOP LOSS", C_RED, 10, "Segoe UI Semibold");

   mY = y + 30;
   mBtn("P_SLM_P",   mX,                mY, mW, mH, "Price",
        (pnl_slMode == 0 ? C_ACCENT_DK : C_BTN),
        (pnl_slMode == 0 ? clrWhite : C_MUTED),
        (pnl_slMode == 0 ? C_ACCENT : C_BORDER_HI), 8);
   mBtn("P_SLM_PIP", mX + mW + 4,       mY, mW, mH, "Pip",
        (pnl_slMode == 1 ? C_ACCENT_DK : C_BTN),
        (pnl_slMode == 1 ? clrWhite : C_MUTED),
        (pnl_slMode == 1 ? C_ACCENT : C_BORDER_HI), 8);
   mBtn("P_SLM_PCT", mX + 2*(mW+4),     mY, mW, mH, "%",
        (pnl_slMode == 2 ? C_ACCENT_DK : C_BTN),
        (pnl_slMode == 2 ? clrWhite : C_MUTED),
        (pnl_slMode == 2 ? C_ACCENT : C_BORDER_HI), 8);

   mText("P_SLV_L", cx + 274, y + 36, "Value", C_MUTED, 8, "Segoe UI Semibold");
   mEdit("P_SLV", cx + 322, y + 30, cw - 336, 26,
         DoubleToString(pnl_slVal, 5), C_TEXT);

   string slHint = "Enter stop price (e.g. 1.0820)";
   if(pnl_slMode == 1) slHint = "Enter pip distance (e.g. 30 for -30 pips)";
   else if(pnl_slMode == 2) slHint = "Enter % move (e.g. 0.3 for -0.3%)";
   mText("P_SL_H", cx + 14, y + 70, slHint, C_DIM, 8);

   y += 100;

   // ---- compute
   string dir = "LONG";
   if(pnl_tpMode == 0 && pnl_tpVal != 0.0)
   {
      if(pnl_tpVal > entry)      dir = "LONG";
      else if(pnl_tpVal < entry) dir = "SHORT";
   }
   else if(pnl_slMode == 0 && pnl_slVal != 0.0)
   {
      if(pnl_slVal < entry)      dir = "LONG";
      else if(pnl_slVal > entry) dir = "SHORT";
   }
   else
   {
      if((pnl_tpMode == 1 || pnl_tpMode == 2) && pnl_tpVal < 0.0) dir = "SHORT";
      else if((pnl_slMode == 1 || pnl_slMode == 2) && pnl_slVal < 0.0) dir = "LONG";
   }
   bool isLong = (dir == "LONG");

   double tpPrice;
   if(pnl_tpMode == 0) tpPrice = pnl_tpVal;
   else if(pnl_tpMode == 1)
   {
      double d = MathAbs(pnl_tpVal);
      tpPrice = isLong ? entry + d*pipSize : entry - d*pipSize;
   }
   else
   {
      double p = MathAbs(pnl_tpVal)/100.0;
      tpPrice = isLong ? entry*(1.0+p) : entry*(1.0-p);
   }

   double slPrice;
   if(pnl_slMode == 0) slPrice = pnl_slVal;
   else if(pnl_slMode == 1)
   {
      double d = MathAbs(pnl_slVal);
      slPrice = isLong ? entry - d*pipSize : entry + d*pipSize;
   }
   else
   {
      double p = MathAbs(pnl_slVal)/100.0;
      slPrice = isLong ? entry*(1.0-p) : entry*(1.0+p);
   }

   if(!MathIsValidNumber(tpPrice) || tpPrice <= 0) tpPrice = entry;
   if(!MathIsValidNumber(slPrice) || slPrice <= 0) slPrice = entry;

   double tpPips = MathAbs(tpPrice - entry) / pipSize;
   double slPips = MathAbs(slPrice - entry) / pipSize;
   double tpPts  = tpPips * 10.0;
   double slPts  = slPips * 10.0;

   double pipVal = 10.0 * lot;
   double tpUsd  =  tpPips * pipVal;
   double slUsd  = -slPips * pipVal;

   double notional = lot * 100000.0;
   double margin   = (lev > 0) ? notional / lev : 0.0;
   double tpPctN = (notional>0) ? (tpUsd/notional)*100.0 : 0.0;
   double slPctN = (notional>0) ? (slUsd/notional)*100.0 : 0.0;
   double tpPctL = (margin  >0) ? (tpUsd/margin  )*100.0 : 0.0;
   double slPctL = (margin  >0) ? (slUsd/margin  )*100.0 : 0.0;

   string rrTxt = "R:R  --";
   if(slPips > 0.0001)      rrTxt = StringFormat("R:R  %.2f : 1", tpPips/slPips);
   else if(tpPips > 0.0001) rrTxt = "R:R  inf : 1";

   // ---- direction + R:R badges
   mRect("P_BADGE1", cx, y, 224, 32, C_CARD_HI, C_BORDER);
   mText("P_B1_L", cx + 14, y + 8, "Direction:", C_MUTED, 9);
   mText("P_B1_V", cx + 100, y + 7, dir,
         isLong ? C_GREEN : C_RED, 13, "Segoe UI Semibold");

   mRect("P_BADGE2", cx + 236, y, cw - 236, 32, C_CARD_HI, C_BORDER);
   mText("P_B2_L", cx + 250, y + 8, "Reward / Risk:", C_MUTED, 9);
   mText("P_B2_V", cx + 366, y + 7, rrTxt,
         C_ACCENT, 13, "Segoe UI Semibold");

   y += 42;

   // ---- results table
   mRect("P_TBL_H", cx, y, cw, 24, C_TITLE, C_BORDER);

   int c1 = cx + 16;
   int c2 = cx + 100;
   int c3 = cx + 210;
   int c4 = cx + 320;
   int c5 = cx + 428;
   int c6 = cx + 528;

   mText("P_H0", c1, y + 5, "SIDE",   C_MUTED, 8, "Segoe UI Semibold");
   mText("P_H1", c2, y + 5, "Pips",   C_MUTED, 8, "Segoe UI Semibold");
   mText("P_H2", c3, y + 5, "Points", C_MUTED, 8, "Segoe UI Semibold");
   mText("P_H3", c4, y + 5, "USD",    C_MUTED, 8, "Segoe UI Semibold");
   mText("P_H4", c5, y + 5, "% noLv", C_MUTED, 8, "Segoe UI Semibold");
   mText("P_H5", c6, y + 5, "% w/Lv", C_MUTED, 8, "Segoe UI Semibold");

   int tpY = y + 30;
   mRect("P_TBL_TP", cx, tpY, cw, 30, C_CARD, C_BORDER);

   mText("P_TP_SIDE", c1, tpY + 9, "TP", C_GREEN, 10, "Segoe UI Semibold");

   bool tpOn = (tpPips > 0.0001);
   color tpC = tpOn ? C_GREEN : C_DIM;
   if(tpOn)
   {
      mText("P_TP_PIPS", c2, tpY + 9, FmtSigned(tpPips, true), tpC, 10, "Segoe UI Semibold");
      mText("P_TP_PTS",  c3, tpY + 9, FmtSigned(tpPts,  true), tpC, 10, "Segoe UI Semibold");
      mText("P_TP_USD",  c4, tpY + 9, FmtUsd(tpUsd),           tpC, 10, "Segoe UI Semibold");
      mText("P_TP_PCTN", c5, tpY + 9, FmtPct(tpPctN),          tpC, 10, "Segoe UI Semibold");
      mText("P_TP_PCTL", c6, tpY + 9, FmtPct(tpPctL),          tpC, 10, "Segoe UI Semibold");
   }
   else
   {
      mText("P_TP_PIPS", c2, tpY + 9, "0",     C_DIM, 10);
      mText("P_TP_PTS",  c3, tpY + 9, "0",     C_DIM, 10);
      mText("P_TP_USD",  c4, tpY + 9, "$0.00", C_DIM, 10);
      mText("P_TP_PCTN", c5, tpY + 9, "0%",    C_DIM, 10);
      mText("P_TP_PCTL", c6, tpY + 9, "0%",    C_DIM, 10);
   }

   int slY = tpY + 34;
   mRect("P_TBL_SL", cx, slY, cw, 30, C_CARD, C_BORDER);

   mText("P_SL_SIDE", c1, slY + 9, "SL", C_RED, 10, "Segoe UI Semibold");

   bool slOn = (slPips > 0.0001);
   color slC = slOn ? C_RED : C_DIM;
   if(slOn)
   {
      mText("P_SL_PIPS", c2, slY + 9, FmtSigned(slPips, false), slC, 10, "Segoe UI Semibold");
      mText("P_SL_PTS",  c3, slY + 9, FmtSigned(slPts,  false), slC, 10, "Segoe UI Semibold");
      mText("P_SL_USD",  c4, slY + 9, FmtUsd(slUsd),            slC, 10, "Segoe UI Semibold");
      mText("P_SL_PCTN", c5, slY + 9, FmtPct(slPctN),           slC, 10, "Segoe UI Semibold");
      mText("P_SL_PCTL", c6, slY + 9, FmtPct(slPctL),           slC, 10, "Segoe UI Semibold");
   }
   else
   {
      mText("P_SL_PIPS", c2, slY + 9, "0",     C_DIM, 10);
      mText("P_SL_PTS",  c3, slY + 9, "0",     C_DIM, 10);
      mText("P_SL_USD",  c4, slY + 9, "$0.00", C_DIM, 10);
      mText("P_SL_PCTN", c5, slY + 9, "0%",    C_DIM, 10);
      mText("P_SL_PCTL", c6, slY + 9, "0%",    C_DIM, 10);
   }

   mText("P_FOOT", cx, slY + 42,
         "Pip value: $10 per pip per 1.0 lot   ·   % = notional / leverage",
         C_DIM, 8);
}

//==================================================================
//  FRAME
//==================================================================
int FRAME_TotalH()
{
   int contentH = (g_activeTab == 0) ? MTA_Height() : PNL_Height();
   if(g_minimized) contentH = 0;
   return UTD_TITLE_H + UTD_TABS_H + contentH + UTD_PAD;
}

void UTD_BuildFrame(int totalH)
{
   int px = g_panelX;
   int py = g_panelY;

   mRect("FRAME_BG", px, py, UTD_W, totalH, C_FRAME, C_BORDER_HI);
   mRect("FRAME_ACCENT", px, py, 4, UTD_TITLE_H, C_ACCENT, C_ACCENT);

   mRect("FRAME_TITLE", px, py, UTD_W, UTD_TITLE_H, C_TITLE, C_TITLE);

   mText("FRAME_ICON", px + 18, py + 14, "⚡", C_ACCENT, 16, "Segoe UI Semibold");
   mText("FRAME_NAME", px + 44, py + 10, "TRADE DASHBOARD",
         C_TEXT, 12, "Segoe UI Semibold");
   mText("FRAME_SUB",  px + 44, py + 28,
         "drag title bar to move   ·   read-only   ·   no AutoTrading",
         C_MUTED, 8);

   int btnW = 34, btnH = 28;
   int btnY = py + (UTD_TITLE_H - btnH)/2;
   int minX = px + UTD_W - UTD_PAD - btnW;
   int rstX = minX - 6 - btnW;

   mText("FRAME_DRAGHINT", rstX - 150, py + 18,
         "· · ·   drag here   · · ·", C_DIM, 8);

   mBtn("FRAME_RESET", rstX, btnY, btnW, btnH, "↺",
        C_BTN, C_ACCENT, C_BORDER_HI, 14);
   mBtn("FRAME_MIN",   minX, btnY, btnW, btnH,
        (g_minimized ? "▾" : "▴"),
        C_BTN, C_MUTED, C_BORDER_HI, 12);

   if(g_minimized) return;

   int ty = py + UTD_TITLE_H;
   mRect("FRAME_TABSTRIP", px, ty, UTD_W, UTD_TABS_H, C_TITLE, C_BORDER);

   int tabW = UTD_W / 2;
   bool a0 = (g_activeTab == 0);
   bool a1 = (g_activeTab == 1);

   mRect("FRAME_TAB0BG", px, ty + 1, tabW, UTD_TABS_H - 2,
         a0 ? C_CARD : C_TITLE, a0 ? C_CARD : C_TITLE);
   mRect("FRAME_TAB1BG", px + tabW, ty + 1, tabW, UTD_TABS_H - 2,
         a1 ? C_CARD : C_TITLE, a1 ? C_CARD : C_TITLE);

   if(a0) mRect("FRAME_TAB0U", px, ty + UTD_TABS_H - 3, tabW, 3, C_ACCENT, C_ACCENT);
   if(a1) mRect("FRAME_TAB1U", px + tabW, ty + UTD_TABS_H - 3, tabW, 3,
                C_ACCENT, C_ACCENT);

   mText("FRAME_TAB0T", px + 30, ty + 12,
         "📋  TRADE ASSISTANT",
         a0 ? C_TEXT : C_MUTED, 10, "Segoe UI Semibold");
   mText("FRAME_TAB1T", px + tabW + 30, ty + 12,
         "📊  P&L ANALYSER",
         a1 ? C_TEXT : C_MUTED, 10, "Segoe UI Semibold");

   mBtn("FRAME_TAB0", px, ty, tabW, UTD_TABS_H, "",
        clrNONE, clrNONE, clrNONE);
   mBtn("FRAME_TAB1", px + tabW, ty, tabW, UTD_TABS_H, "",
        clrNONE, clrNONE, clrNONE);
}

//==================================================================
//  MASTER BUILD
//  NOTE: no PNL_ReadEdits() here — that would clobber in-progress
//        typing. Reads are triggered only by ENDEDIT + deferred timer,
//        or before any button click that changes state.
//==================================================================
void UTD_Build()
{
   UTD_ClearPanel();

   int totalH = FRAME_TotalH();
   UTD_BuildFrame(totalH);

   if(g_minimized)
   {
      ChartRedraw();
      return;
   }

   int contentX = g_panelX + UTD_PAD;
   int contentY = g_panelY + UTD_TITLE_H + UTD_TABS_H + 12;

   if(g_activeTab == 0) MTA_Build(contentX, contentY);
   else                 PNL_Build(contentX, contentY);

   ChartRedraw();
}

//==================================================================
//  CLICK HANDLER
//==================================================================
void UTD_OnClick(const string &sparam)
{
   ObjectSetInteger(0, sparam, OBJPROP_STATE, false);

   // ----- FRAME -----
   if(StringFind(sparam, UTD_PFX "FRAME_") == 0)
   {
      string sfx = StringSubstr(sparam, StringLen(UTD_PFX "FRAME_"));

      if(sfx == "RESET") { g_panelX = 30; g_panelY = 30; UTD_Build(); return; }
      if(sfx == "MIN")   { g_minimized = !g_minimized; UTD_Build(); return; }
      if(sfx == "TAB0")
      {
         if(g_activeTab != 0) { PNL_ReadEdits(); g_activeTab = 0; UTD_Build(); }
         return;
      }
      if(sfx == "TAB1")
      {
         if(g_activeTab != 1) { PNL_ReadEdits(); g_activeTab = 1; UTD_Build(); }
         return;
      }
      return;
   }

   // ----- MTA -----
   if(StringFind(sparam, UTD_PFX "M_") == 0)
   {
      string sfx = StringSubstr(sparam, StringLen(UTD_PFX "M_"));

      if(StringFind(sfx, "POS_") == 0)
      {
         int idx = (int)StringToInteger(StringSubstr(sfx, 4));
         MTA_Select(idx);
         return;
      }
      if(sfx == "SCRLU")
      {
         if(g_listOffset > 0) { g_listOffset--; UTD_Build(); }
         return;
      }
      if(sfx == "SCRDN")
      {
         int n = ArraySize(g_pos);
         if(g_listOffset + UTD_MAX_POS < n) { g_listOffset++; UTD_Build(); }
         return;
      }
      if(sfx == "TP_DEC") { if(g_tpCount > 1)       MTA_SetTPCount(g_tpCount - 1); return; }
      if(sfx == "TP_INC") { if(g_tpCount < g_maxTPs) MTA_SetTPCount(g_tpCount + 1); return; }

      if(StringFind(sfx, "TPQ_") == 0)
      {
         string v = StringSubstr(sfx, 4);
         int n = (v == "MAX") ? g_maxTPs : (int)StringToInteger(v);
         if(n > 0 && n <= g_maxTPs) MTA_SetTPCount(n);
         return;
      }

      if(sfx == "SIM") { MTA_SimNext();  return; }
      if(sfx == "RST") { MTA_Reset();    return; }
      return;
   }

   // ----- PNL -----
   if(StringFind(sparam, UTD_PFX "P_") == 0)
   {
      string sfx = StringSubstr(sparam, StringLen(UTD_PFX "P_"));

      if(sfx == "PSTD") { pnl_pair = 0; UTD_Build(); return; }
      if(sfx == "PJPY") { pnl_pair = 1; UTD_Build(); return; }
      if(sfx == "PXAU") { pnl_pair = 2; UTD_Build(); return; }

      if(sfx == "TPM_P")   { pnl_tpMode = 0; UTD_Build(); return; }
      if(sfx == "TPM_PIP") { pnl_tpMode = 1; UTD_Build(); return; }
      if(sfx == "TPM_PCT") { pnl_tpMode = 2; UTD_Build(); return; }

      if(sfx == "SLM_P")   { pnl_slMode = 0; UTD_Build(); return; }
      if(sfx == "SLM_PIP") { pnl_slMode = 1; UTD_Build(); return; }
      if(sfx == "SLM_PCT") { pnl_slMode = 2; UTD_Build(); return; }
      return;
   }
}

//==================================================================
//  LIFECYCLE
//==================================================================
int OnInit()
{
   g_pnlPendingRead = false;
   MTA_Refresh();
   UTD_Build();
   EventSetTimer(2);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   UTD_ClearPanel();
   UTD_ClearChart();
   ChartRedraw();
}

void OnTick() { /* display only */ }

void OnTimer()
{
   // ---- Deferred read: MT5 has now committed the typed text
   if(g_pnlPendingRead)
   {
      g_pnlPendingRead = false;
      EventSetTimer(2);   // replace millisecond timer with normal 2s tick

      PNL_ReadEdits();
      if(g_activeTab == 1 && !g_minimized)
      {
         int cx = g_panelX + UTD_PAD;
         int cy = g_panelY + UTD_TITLE_H + UTD_TABS_H + 12;
         PNL_Build(cx, cy);   // in-place refresh — edit fields stay untouched
         ChartRedraw();
      }
      return;
   }

   // ---- Normal MTA refresh (skip while user is on P&L tab to avoid
   //      destroying edit fields mid-typing)
   if(g_activeTab == 1) return;

   string oldHash = MTA_Hash();
   int    oldSel  = g_selIdx;
   MTA_Refresh();
   string newHash = MTA_Hash();

   if(oldHash != newHash || oldSel != g_selIdx)
      UTD_Build();
}

//==================================================================
//  EVENTS
//==================================================================
void OnChartEvent(const int id, const long &lparam,
                  const double &dparam, const string &sparam)
{
   // ---------- DRAG ----------
   if(id == CHARTEVENT_MOUSE_MOVE)
   {
      int mx = (int)lparam;
      int my = (int)dparam;
      int st = (int)StringToInteger(sparam);
      bool leftDown = ((st & 1) != 0);

      if(leftDown && !g_prevLeftDown)
      {
         int btnW = 34, btnH = 28;
         int btnY = g_panelY + (UTD_TITLE_H - btnH)/2;
         int minX = g_panelX + UTD_W - UTD_PAD - btnW;
         int rstX = minX - 6 - btnW;

         bool inTitle = (mx >= g_panelX && mx < g_panelX + UTD_W &&
                         my >= g_panelY && my < g_panelY + UTD_TITLE_H);
         bool onReset = (mx >= rstX && mx < rstX + btnW &&
                         my >= btnY && my < btnY + btnH);
         bool onMin   = (mx >= minX && mx < minX + btnW &&
                         my >= btnY && my < btnY + btnH);

         if(inTitle && !onReset && !onMin)
         {
            g_dragActive  = true;
            g_dragAnchorX = mx;
            g_dragAnchorY = my;
         }
      }

      if(!leftDown && g_dragActive)
         g_dragActive = false;

      if(g_dragActive && leftDown)
      {
         int dx = mx - g_dragAnchorX;
         int dy = my - g_dragAnchorY;
         if(dx != 0 || dy != 0)
         {
            UTD_ShiftAll(dx, dy);
            g_dragAnchorX = mx;
            g_dragAnchorY = my;
            ChartRedraw();
         }
      }

      g_prevLeftDown = leftDown;
      return;
   }

   // ---------- EDIT COMMITTED ----------
   // Do NOT read here — MT5 hasn't committed OBJPROP_TEXT yet.
   // Set a flag and let the fast millisecond timer do the read.
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
   {
      if(StringFind(sparam, UTD_PFX "P_") == 0)
      {
         g_pnlPendingRead = true;
         EventSetMillisecondTimer(80);   // fires ~80 ms from now
      }
      return;
   }

   // ---------- CLICK ----------
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(StringFind(sparam, UTD_PFX) == 0)
      {
         // sync state from any committed edit fields before handling click
         PNL_ReadEdits();
         UTD_OnClick(sparam);
      }
   }
}
//+------------------------------------------------------------------+