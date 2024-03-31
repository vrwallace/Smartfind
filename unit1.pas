unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Spin, strutils, Math, LCLProc,lazfileutils,lazutils,LazUTF8;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Buttonss: TButton;
    Buttonst: TButton;
    Buttongo: TButton;
    CheckBoxrecursive: TCheckBox;
    ComboBoxignore: TComboBox;
    EditSourcedir: TEdit;
    Editdestinationdir: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    MemoResults: TMemo;
    MemoMatches: TMemo;
    RadioButtonfind: TRadioButton;
    RadioButtonfindandcopy: TRadioButton;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    SpinEditPercent: TSpinEdit;
    procedure Button1Click(Sender: TObject);
    procedure ButtonssClick(Sender: TObject);
    procedure ButtonstClick(Sender: TObject);
    procedure ButtongoClick(Sender: TObject);

    procedure DumpExceptionCallStack(E: Exception);
    procedure GroupBox2Click(Sender: TObject);

    function LevenshteinDistance(const s1: string; s2: string): integer;
    function LevenshteinDistanceText(const s1, s2: string): integer;
    procedure RadioButtonfindandcopyClick(Sender: TObject);
    procedure RadioButtonfindClick(Sender: TObject);
    procedure statusstateenable(ienabled: boolean);

  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  stoppressed: integer = 0;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.ButtonssClick(Sender: TObject);
begin
  try

    if SelectDirectoryDialog1.Execute then
    begin

      if midstr(selectdirectorydialog1.filename, 2, 2) <> ':\' then
      begin
        ShowMessage('Must be a mapped drive with a drive letter!');
        editsourcedir.Text := '';
      end
      else
        editsourcedir.Text := selectdirectorydialog1.filename;

    end;
  except
    on E: Exception do
      DumpExceptionCallStack(E);
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  stoppressed := 1;
end;

procedure TForm1.ButtonstClick(Sender: TObject);

begin
  try

    if SelectDirectoryDialog1.Execute then
    begin

      if midstr(selectdirectorydialog1.filename, 2, 2) <> ':\' then
      begin
        ShowMessage('Must be a mapped drive with a drive letter!');
        editdestinationdir.Text := '';
      end
      else
        editdestinationdir.Text := selectdirectorydialog1.filename;

    end;
  except
    on E: Exception do
      DumpExceptionCallStack(E);
  end;
end;

procedure TForm1.ButtongoClick(Sender: TObject);
var
  periodindex, match, i, memomatchesindex: integer;
  Result, maxlength, editsn, editpercent: float;
  FilesFoundToCopy: TStringList;
  list: TStringList;
  cleanfilename: string;
  currentmatchitem: string;
  cleancurrentmatchitem: string;
begin
  try
    stoppressed := 0;
    memoresults.Clear;
    application.processmessages;
    if trim(memomatches.Text) = '' then
    begin
      ShowMessage('No Items to Match!');
      exit;
    end;


    if not DirPathExists(EditSourcedir.Text) then
    begin
      ShowMessage(EditSourcedir.Text + ' Source Not Valid!');
      exit;
    end;

    if radiobuttonfindandcopy.Checked then
    begin
      if not DirPathExists(Editdestinationdir.Text) then
      begin
        ShowMessage(Editdestinationdir.Text + ' Destination Not Valid!');
        exit;
      end;
    end;



    statusstateenable(False);

    memoresults.Lines.add('Finding files...');
    application.processmessages;


    if checkboxrecursive.Checked then
      FilesFoundToCopy := FindAllFiles(editsourcedir.Text, '*', True)
    else
      FilesFoundToCopy := FindAllFiles(editsourcedir.Text, '*', False);



    try
      for i := 0 to FilesFoundToCopy.Count - 1 do
      begin
        application.ProcessMessages;
        match := 0;
        if stoppressed = 1 then
        begin
          stoppressed := 0;
          statusstateenable(True);
          Memoresults.Lines.Add('Stopped due to user request!');
          exit;
        end;


        for memomatchesindex := 0 to memomatches.Lines.Count - 1 do
        begin
          application.ProcessMessages;

          if stoppressed = 1 then
          begin
            stoppressed := 0;
            statusstateenable(True);
            Memoresults.Lines.Add('Stopped due to user request!');
            exit;
          end;

          currentmatchitem := trim(memomatches.Lines.Strings[memomatchesindex]);

          // clean matchitemstart
          if currentmatchitem <> '' then
          begin
            if ((pos('.', ExtractFileName(currentmatchitem)) > 0) and
              ((comboboxignore.ItemIndex = 1) or (comboboxignore.ItemIndex = 2))) then
            begin
              try
                List := TStringList.Create;
                List.Delimiter := '.';
                List.DelimitedText := ExtractFileName(currentmatchitem);


                cleancurrentmatchitem := '';

                for periodindex := 0 to (list.Count - 1) - 1 do
                begin
                if (periodindex=0) then
                cleancurrentmatchitem := cleancurrentmatchitem +list[periodindex]
                else
                cleancurrentmatchitem := cleancurrentmatchitem +'.'+list[periodindex]
                end;

              finally
                list.Free;
              end;


              cleancurrentmatchitem := trim(cleancurrentmatchitem);
            end
            else
              cleancurrentmatchitem := trim(ExtractFileName(currentmatchitem));

          end;


          // clean matchitemend



          if cleancurrentmatchitem <> '' then
          begin
            if ((pos('.', ExtractFileName(FilesFoundToCopy.Strings[i])) > 0) and
              ((comboboxignore.ItemIndex = 0) or (comboboxignore.ItemIndex = 2))) then
            begin
              try
                List := TStringList.Create;
                List.Delimiter := '.';
                List.DelimitedText := ExtractFileName(FilesFoundToCopy.Strings[i]);


                cleanfilename := '';

                for periodindex := 0 to (list.Count - 1) - 1 do
                begin

                  if (periodindex=0) then
                  cleanfilename := cleanfilename +  list[periodindex]
                  else
                  cleanfilename := cleanfilename +  '.' + list[periodindex];

                end;

              finally
                list.Free;
              end;

              cleanfilename := trim(cleanfilename);
            end
            else
              cleanfilename := trim(ExtractFileName(FilesFoundToCopy.Strings[i]));



            editsn := LevenshteinDistanceText(cleancurrentmatchitem, cleanfilename);

            if (length(cleancurrentmatchitem) > length(cleanfilename)) then
              maxlength := length(cleancurrentmatchitem)
            else
              maxlength := length(cleanfilename);
            Result := maxlength - editsn;
            editpercent := ((Result / maxlength) * 100);
            if (editpercent >= spineditpercent.Value) then
              match := 1
            else
              match := 0;

            //Memoresults.Lines.Add(memomatches.Lines.Strings[memomatchesindex] + ' <=> ' + FilesFoundToCopy.Strings[i] + '['+floattostr(editsn)+']['+floattostr(editpercent)+'%]['+inttostr(match)+']');
            if ((match = 1) and (radiobuttonfindandcopy.Checked = True)) then
            begin
              if not (fileexists(editdestinationdir.Text + '\' +
                ExtractFileName(FilesFoundToCopy.Strings[i]))) then
              begin
                if FileUtil.CopyFile(FilesFoundToCopy.Strings[i],
                  editdestinationdir.Text + '\' +
                  ExtractFileName(FilesFoundToCopy.Strings[i]), True) then
                begin
                  Memoresults.Lines.Add('File: ' + FilesFoundToCopy.Strings[i] +
                    ' Copied to: ' + editdestinationdir.Text + '\' +
                    ExtractFileName(FilesFoundToCopy.Strings[i]) +
                    ' [' + floattostr(editsn) + '][[IM: ' +
                    cleancurrentmatchitem + ' vs FN: ' + cleanfilename +
                    '][' + floattostr(editpercent) + '%]][' + IntToStr(match) + ']');

                end
                else
                  Memoresults.Lines.Add('File Copy Failed:' +
                    FilesFoundToCopy.Strings[i] + ' [' +
                    floattostr(editsn) + '][[IM: ' + cleancurrentmatchitem + ' vs FN: ' +
                    cleanfilename + '][' + floattostr(editpercent) +
                    '%]][' + IntToStr(match) + ']');

              end
              else
                Memoresults.Lines.Add('File found on destintation not copied: ' +
                  FilesFoundToCopy.Strings[i] + ' [' +
                  floattostr(editsn) + '][[IM: ' + cleancurrentmatchitem + ' vs FN: ' +
                  cleanfilename + '][' + floattostr(editpercent) +
                  '%]][' + IntToStr(match) + ']');

            end;


            if ((match = 1) and (radiobuttonfind.Checked = True)) then
            begin
              Memoresults.Lines.Add(FilesFoundToCopy.Strings[i] + #9 +
                ' [' + floattostr(editsn) + '][[IM: ' +
                cleancurrentmatchitem + ' vs FN: ' + cleanfilename +
                '][' + floattostr(editpercent) + '%]][' + IntToStr(match) + ']');

            end;




            //outmatch
          end;

        end;
      end;


    finally
      FilesFoundToCopy.Free;
    end;
  except
    on E: Exception do
    begin
      statusstateenable(True);
      DumpExceptionCallStack(E);

    end;
  end;
  memoresults.Lines.add('Complete!');
  statusstateenable(True);
end;




procedure TForm1.DumpExceptionCallStack(E: Exception);
var
  I: integer;
  Frames: PPointer;
  Report: string;
begin
  statusstateenable(True);
  Report := 'Program exception! ' + LineEnding + 'Stacktrace:' +
    LineEnding + LineEnding;
  if E <> nil then
  begin
    Report := Report + 'Exception class: ' + E.ClassName + LineEnding +
      'Message: ' + E.Message + LineEnding;
  end;
  Report := Report + BackTraceStrFunc(ExceptAddr);
  Frames := ExceptFrames;
  for I := 0 to ExceptFrameCount - 1 do
    Report := Report + LineEnding + BackTraceStrFunc(Frames[I]);

  MemoResults.Lines.Add('Error Report: ' + Report);
  ShowMessage(Report);
  //Halt; // End of program execution
end;

procedure TForm1.GroupBox2Click(Sender: TObject);
begin

end;






 {------------------------------------------------------------------------------
  Name:    LevenshteinDistance
  Params: s1, s2 - UTF8 encoded strings
  Returns: Minimum number of single-character edits.
  Compare 2 UTF8 encoded strings, case sensitive.
------------------------------------------------------------------------------}

function tform1.LevenshteinDistance(const s1: string; s2: string): integer;
var
  length1, length2, i, j, value1, value2, value3: integer;
  matrix: array of array of integer;
begin
  length1 := UTF8Length(s1);
  length2 := UTF8Length(s2);
  SetLength(matrix, length1 + 1, length2 + 1);
  for i := 0 to length1 do
    matrix[i, 0] := i;
  for j := 0 to length2 do
    matrix[0, j] := j;
  for i := 1 to length1 do
    for j := 1 to length2 do
    begin
      if UTF8Copy(s1, i, 1) = UTF8Copy(s2, j, 1) then
        matrix[i, j] := matrix[i - 1, j - 1]
      else
      begin
        value1 := matrix[i - 1, j] + 1;
        value2 := matrix[i, j - 1] + 1;
        value3 := matrix[i - 1, j - 1] + 1;
        matrix[i, j] := min(value1, min(value2, value3));
      end;
    end;
  Result := matrix[length1, length2];
end;

{------------------------------------------------------------------------------
  Name:    LevenshteinDistanceText
  Params: s1, s2 - UTF8 encoded strings
  Returns: Minimum number of single-character edits.
  Compare 2 UTF8 encoded strings, case insensitive.
------------------------------------------------------------------------------}
function tform1.LevenshteinDistanceText(const s1, s2: string): integer;
var
  s1lower, s2lower: string;
begin
  s1lower := UTF8LowerCase(s1);
  s2lower := UTF8LowerCase(s2);
  Result := LevenshteinDistance(s1lower, s2lower);
end;

procedure TForm1.RadioButtonfindandcopyClick(Sender: TObject);
begin
  editdestinationdir.Enabled := True;
  buttonst.Enabled := True;

end;

procedure TForm1.RadioButtonfindClick(Sender: TObject);
begin
  editdestinationdir.Enabled := False;
  buttonst.Enabled := False;
  editdestinationdir.Text := '';

end;

procedure tform1.statusstateenable(ienabled: boolean);
begin

  if ((radiobuttonfind.Checked = True) and (ienabled = True)) then
  begin
    buttonss.Enabled := ienabled;
    SpinEditPercent.Enabled := ienabled;
    EditSourcedir.Enabled := ienabled;
    Buttongo.Enabled := ienabled;
    checkboxrecursive.Enabled := ienabled;
    radiobuttonfind.Enabled := ienabled;
    radiobuttonfindandcopy.Enabled := ienabled;
    memomatches.Enabled := ienabled;
    comboboxignore.Enabled := ienabled;
    application.processmessages;
  end
  else
  begin
    buttonss.Enabled := ienabled;
    buttonst.Enabled := ienabled;
    SpinEditPercent.Enabled := ienabled;
    EditSourcedir.Enabled := ienabled;
    Editdestinationdir.Enabled := ienabled;
    Buttongo.Enabled := ienabled;
    checkboxrecursive.Enabled := ienabled;
    radiobuttonfind.Enabled := ienabled;
    radiobuttonfindandcopy.Enabled := ienabled;
    memomatches.Enabled := ienabled;
    comboboxignore.Enabled := ienabled;
    application.processmessages;
  end;

end;

end.
