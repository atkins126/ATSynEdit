{
Copyright (C) Alexey Torgashin, uvviewsoft.com
License: MPL 2.0 or LGPL
}
unit ATSynEdit_Gutter_Decor;

{$mode objfpc}{$H+}
{$ModeSwitch advancedrecords}

interface

uses
  Classes, SysUtils, Graphics,
  ATStringProc,
  ATSynEdit_FGL;

type
  TATGutterDecorData = packed record
    Tag: Int64;
    LineNum: integer;
    ImageIndex: integer;
    Text: string[15]; //at last 2-3 UTF8 chars
    TextColor: TColor;
    TextBold: boolean;
    TextItalic: boolean;
    DeleteOnDelLine: boolean;
  end;

  { TATGutterDecorItem }

  PATGutterDecorItem = ^TATGutterDecorItem;
  TATGutterDecorItem = record
    Data: TATGutterDecorData;
    procedure Init(const AData: TATGutterDecorData);
    class operator =(const a, b: TATGutterDecorItem): boolean;
  end;

  { TATGutterDecorItems }

  TATGutterDecorItems = class(specialize TFPGList<TATGutterDecorItem>)
  public
    function ItemPtr(AIndex: integer): PATGutterDecorItem; inline;
  end;

type
  { TATGutterDecor }

  TATGutterDecor = class
  private
    FList: TATGutterDecorItems;
    function GetItem(N: integer): TATGutterDecorItem;
    procedure SetItem(N: integer; const AValue: TATGutterDecorItem);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear;
    procedure Delete(N: integer);
    procedure DeleteForLine(ALine: integer);
    function DeleteByTag(const ATag: Int64): boolean;
    function Count: integer; inline;
    function IsIndexValid(N: integer): boolean; inline;
    property Items[N: integer]: TATGutterDecorItem read GetItem write SetItem; default;
    procedure Add(const AData: TATGutterDecorData);
    function Find(ALineNum: integer): integer;
    procedure DeleteDups;
    procedure Update(AChange: TATLineChangeKind; ALine, AItemCount, ALineCount: integer);
  end;

implementation

{ TATGutterDecorItems }

function TATGutterDecorItems.ItemPtr(AIndex: integer): PATGutterDecorItem;
begin
  Result:= PATGutterDecorItem(InternalGet(AIndex));
end;

{ TATGutterDecorItem }

procedure TATGutterDecorItem.Init(const AData: TATGutterDecorData);
begin
  Data:= AData;
end;

class operator TATGutterDecorItem.=(const a, b: TATGutterDecorItem): boolean;
begin
  Result:= false;
end;

{ TATGutterDecor }

function TATGutterDecor.GetItem(N: integer): TATGutterDecorItem;
begin
  Result:= FList[N];
end;

procedure TATGutterDecor.SetItem(N: integer; const AValue: TATGutterDecorItem);
begin
  FList[N]:= AValue;
end;

constructor TATGutterDecor.Create;
begin
  inherited;
  FList:= TATGutterDecorItems.Create;
end;

destructor TATGutterDecor.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited;
end;

procedure TATGutterDecor.Clear;
begin
  FList.Clear;
end;

procedure TATGutterDecor.Delete(N: integer);
begin
  FList.Delete(N);
end;

procedure TATGutterDecor.DeleteForLine(ALine: integer);
var
  N: integer;
begin
  N:= Find(ALine);
  if N>=0 then
    Delete(N);
end;

function TATGutterDecor.DeleteByTag(const ATag: Int64): boolean;
var
  i: integer;
begin
  Result:= false;
  for i:= FList.Count-1 downto 0 do
    if FList.ItemPtr(i)^.Data.Tag=ATag then
    begin
      Result:= true;
      Delete(i);
    end;
end;

function TATGutterDecor.Count: integer;
begin
  Result:= FList.Count;
end;

function TATGutterDecor.IsIndexValid(N: integer): boolean;
begin
  Result:= (N>=0) and (N<FList.Count);
end;

procedure TATGutterDecor.Add(const AData: TATGutterDecorData);
var
  Item: TATGutterDecorItem;
  nLine, i: integer;
begin
  Item.Init(AData);

  for i:= 0 to Count-1 do
  begin
    nLine:= FList.ItemPtr(i)^.Data.LineNum;

    //item already exists: overwrite
    if nLine=AData.LineNum then
    begin
      Items[i]:= Item;
      Exit
    end;

    //found item for bigger line: insert before it
    if nLine>AData.LineNum then
    begin
      FList.Insert(i, Item);
      Exit;
    end;
  end;

  //not found item for bigger line: append
  FList.Add(Item);
end;

procedure TATGutterDecor.DeleteDups;
var
  Item1, Item2: TATGutterDecorItem;
  i: integer;
begin
  for i:= Count-1 downto 1 do
  begin
    Item1:= GetItem(i);
    Item2:= GetItem(i-1);
    if Item1.Data.LineNum=Item2.Data.LineNum then
      Delete(i);
  end;
end;

function TATGutterDecor.Find(ALineNum: integer): integer;
var
  a, b, m, dif: integer;
begin
  Result:= -1;
  a:= 0;
  b:= Count-1;

  repeat
    if a>b then exit;
    m:= (a+b+1) div 2;

    dif:= FList.ItemPtr(m)^.Data.LineNum-ALineNum;
    if dif=0 then
      exit(m);
    if dif>0 then
      b:= m-1
    else
      a:= m+1;
  until false;
end;


procedure TATGutterDecor.Update(AChange: TATLineChangeKind; ALine, AItemCount,
  ALineCount: integer);
var
  Item: PATGutterDecorItem;
  //bMovedHere: boolean;
  NIndexPlaced, i: integer;
begin
  case AChange of
    cLineChangeEdited:
      begin
      end;

    cLineChangeAdded:
      begin
        for i:= 0 to Count-1 do
        begin
          Item:= FList.ItemPtr(i);
          if Item^.Data.LineNum>=ALine then
          begin
            Item^.Data.LineNum+= AItemCount;
          end;
        end;
      end;

    cLineChangeDeletedAll:
      begin
        Clear;
      end;

    cLineChangeDeleted:
      begin
        for i:= 0 to AItemCount-1 do
        begin
          NIndexPlaced:= Find(ALine+i);
          //bMovedHere:= false;

          if (NIndexPlaced>=0) and FList.ItemPtr(NIndexPlaced)^.Data.DeleteOnDelLine then
          begin
            Delete(NIndexPlaced);
            NIndexPlaced:= -1;
          end;
        end;

        for i:= Count-1 downto 0 do
        begin
          Item:= FList.ItemPtr(i);

          //spec case for item on last line, keep it if deleting last line
          if (Item^.Data.LineNum>ALine) or (Item^.Data.LineNum=ALineCount-1) then
          begin
            Item^.Data.LineNum-= AItemCount;
            {
            if Item^.Data.LineNum=ALine then
              bMovedHere:= true;
            }
          end;
        end;

        {
        //delete new duplicate
        if bMovedHere then
          if NIndexPlaced>=0 then
            Delete(NIndexPlaced);
        }
      end;
  end;
end;


end.
