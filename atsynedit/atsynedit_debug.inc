{$ifdef nn}begin end;{$endif}

procedure TATSynEdit.DebugFindWrapIndex;
var
  i, j, n1, n2: integer;
begin
  for i:= 0 to Strings.Count-1 do
  begin
    FWrapInfo.FindIndexesOfLineNumber(i, n1, n2);
    if n1<0 then
    begin
      Application.MainForm.caption:= format('fail findindex: %d', [i]);
      Exit
    end;
    for j:= n1 to n2 do
      if FWrapInfo[j].NLineIndex<>i then
      begin
        Application.MainForm.caption:= format('fail findindex: %d', [i]);
        Exit
      end;
  end;
  Application.MainForm.caption:= 'ok findindex';
end;


function DoPartAsString(i: integer; constref P: TATLineParts): string;
begin
  Result:= Format('[%d]: offset %d..%d', [i, P[i].Offset, P[i].Offset+P[i].Len, P[i].Len]);
end;


