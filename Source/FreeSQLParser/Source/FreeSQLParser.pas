unit FreeSQLParser;

interface {********************************************************************}

uses
  Classes,
  SQLUtils,
  fspTypes, fspConst;

type
  TMySQLParser = class
  public
    type
      TFileType = (ftSQL, ftFormatedSQL, ftDebugHTML);

  protected
    type
      TOffset = Integer;

  private
    type
      TCreateTableIndexAdd = (iaAdd, iaCreate, iaNone);
      TIntegerArray = array of Integer;
      TParseFunction = function(): TOffset of object;
      TTableOptionNodes = record
        AutoIncrementValue: TOffset;
        AvgRowLengthValue: TOffset;
        CharacterSetValue: TOffset;
        ChecksumValue: TOffset;
        CollateValue: TOffset;
        CommentValue: TOffset;
        ConnectionValue: TOffset;
        DataDirectoryValue: TOffset;
        DelayKeyWriteValue: TOffset;
        EngineValue: TOffset;
        IndexDirectoryValue: TOffset;
        InsertMethodValue: TOffset;
        KeyBlockSizeValue: TOffset;
        MaxRowsValue: TOffset;
        MinRowsValue: TOffset;
        PackKeysValue: TOffset;
        PageChecksum: TOffset;
        PasswordValue: TOffset;
        RowFormatValue: TOffset;
        StatsAutoRecalcValue: TOffset;
        StatsPersistentValue: TOffset;
        UnionList: TOffset;
      end;
      TValueAssign = (vaYes, vaNo, vaAuto);

      TStringBuffer = class
      private
        Buffer: record
          Mem: PChar;
          MemSize: Integer;
          Write: PChar;
        end;
        function GetData(): Pointer; inline;
        function GetLength(): Integer; inline;
        function GetSize(): Integer; inline;
        function GetText(): PChar; inline;
        procedure Reallocate(const NeededLength: Integer);
      public
        procedure Clear();
        constructor Create(const InitialLength: Integer);
        procedure Delete(const Start: Integer; const Length: Integer);
        destructor Destroy(); override;
        function Read(): string; inline;
        procedure Write(const Text: PChar; const Length: Integer); overload; {$IFNDEF Debug} inline; {$ENDIF}
        procedure Write(const Text: string); overload; {$IFNDEF Debug} inline; {$ENDIF}
        procedure Write(const Char: Char); overload; {$IFNDEF Debug} inline; {$ENDIF}
        property Data: Pointer read GetData;
        property Length: Integer read GetLength;
        property Size: Integer read GetSize;
        property Text: PChar read GetText;
      end;

      TWordList = class
      private type
        TIndex = SmallInt;
        TIndices = array [0..5] of TIndex;
      private
        FCount: TIndex;
        FIndex: array of PChar;
        FFirst: array of Integer;
        FParser: TMySQLParser;
        FText: string;
        function GetText(): string;
        function GetWord(Index: TIndex): string;
        procedure SetText(AText: string);
      protected
        procedure Clear();
        property Parser: TMySQLParser read FParser;
      public
        constructor Create(const ASQLParser: TMySQLParser; const AText: string = '');
        destructor Destroy(); override;
        function IndexOf(const Word: PChar; const Length: Integer): Integer; overload;
        function IndexOf(const Word: string): Integer; overload; {$IFNDEF Debug} inline; {$ENDIF}
        property Count: TIndex read FCount;
        property Text: string read GetText write SetText;
        property Word[Index: TIndex]: string read GetWord; default;
      end;

      TFormatHandle = class(TStringBuffer)
      private
        Indent: Integer;
        IndentSpaces: array[0 .. 1024 - 1] of Char;
      public
        constructor Create();
        procedure DecreaseIndent();
        destructor Destroy(); override;
        procedure IncreaseIndent();
        procedure WriteIndent(); {$IFNDEF Debug} inline; {$ENDIF}
        procedure WriteReturn(); {$IFNDEF Debug} inline; {$ENDIF}
        procedure WriteSpace(); {$IFNDEF Debug} inline; {$ENDIF}
      end;

    const
      IndentSize = 2;

  public
    type
      PNode = ^TNode;
      PToken = ^TToken;
      PStmt = ^TStmt;

      { Base nodes ------------------------------------------------------------}

      TNode = packed record
      private
        FNodeType: TNodeType;
        FParser: TMySQLParser;
      private
        class function Create(const AParser: TMySQLParser; const ANodeType: TNodeType): TOffset; static; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOffset(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
        property Offset: TOffset read GetOffset;
      public
        property NodeType: TNodeType read FNodeType;
        property Parser: TMySQLParser read FParser;
      end;

      PRoot = ^TRoot;
      TRoot = packed record
      private
        Heritage: TNode;
      private
        FFirstStmt: TOffset; // Cache for speeding
        FFirstToken: TOffset; // Cache for speeding
        FFirstTokenAll: TOffset;
        FLastStmt: TOffset; // Cache for speeding
        FLastToken: TOffset; // Cache for speeding
        FLastTokenAll: TOffset;
        procedure AddStmt(const AStmt: TOffset);
        class function Create(const AParser: TMySQLParser;
          const AFirstTokenAll, ALastTokenAll: TOffset;
          const StmtCount: Integer; const Stmts: array of TOffset): TOffset; static;
        function GetFirstStmt(): PStmt; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFirstToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFirstTokenAll(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastStmt(): PStmt; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastTokenAll(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOffset(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
        property Offset: TOffset read GetOffset;
        property Parser: TMySQLParser read Heritage.FParser;
      public
        property FirstStmt: PStmt read GetFirstStmt;
        property FirstToken: PToken read GetFirstToken;
        property FirstTokenAll: PToken read GetFirstTokenAll;
        property LastStmt: PStmt read GetLastStmt;
        property LastToken: PToken read GetLastToken;
        property LastTokenAll: PToken read GetLastTokenAll;
        property NodeType: TNodeType read Heritage.FNodeType;
      end;

      PChild = ^TChild;
      TChild = packed record  // Every node, except TRoot
      private
        Heritage: TNode;
      private
        FParentNode: TOffset;
        class function Create(const AParser: TMySQLParser; const ANodeType: TNodeType): TOffset; static; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFFirstToken(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFirstToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFLastToken(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetNextSibling(): PChild; {$IFNDEF Debug} inline; {$ENDIF}
        function GetParentNode(): PNode; {$IFNDEF Debug} inline; {$ENDIF}
        property FFirstToken: TOffset read GetFFirstToken;
        property FLastToken: TOffset read GetFLastToken;
        property Parser: TMySQLParser read Heritage.FParser;
      public
        property FirstToken: PToken read GetFirstToken;
        property LastToken: PToken read GetLastToken;
        property NextSibling: PChild read GetNextSibling;
        property NodeType: TNodeType read Heritage.FNodeType;
        property ParentNode: PNode read GetParentNode;
      end;

      TToken = packed record
      private
        Heritage: TChild;
      private
        FErrorCode: Integer;
        FErrorPos: PChar;
        {$IFDEF Debug}
        FIndex: Integer;
        {$ENDIF}
        FKeywordIndex: TWordList.TIndex;
        FLength: Integer;
        FNewSQL: TOffset;
        FOperatorType: TOperatorType;
        FSQL: PChar;
        FTokenType: TTokenType;
        FUsageType: TUsageType;
        class function Create(const AParser: TMySQLParser;
          const ASQL: PChar; const ALength: Integer;
          const AErrorCode: Integer; const AErrorPos: PChar;
          const ATokenType: TTokenType; const AOperatorType: TOperatorType;
          const AKeywordIndex: TWordList.TIndex; const AUsageType: TUsageType): TOffset; static; {$IFNDEF Debug} inline; {$ENDIF}
        function GetAsString(): string;
        function GetDbIdentType(): TDbIdentType;
        function GetGeneration(): Integer;
        {$IFNDEF Debug}
        function GetIndex(): Integer;
        {$ENDIF}
        function GetIsUsed(): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
        function GetNextToken(): PToken;
        function GetNextTokenAll(): PToken;
        function GetOffset(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
        function GetParentNode(): PNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetSQL(): PChar;
        function GetText(): string;
        procedure SetText(AText: string);
        property ErrorCode: Integer read FErrorCode;
        property ErrorPos: PChar read FErrorPos;
        property Generation: Integer read GetGeneration;
        {$IFDEF Debug}
        property Index: Integer read FIndex;
        {$ELSE}
        property Index: Integer read GetIndex; // VERY slow. Should be used for internal debugging only.
        {$ENDIF}
        property IsUsed: Boolean read GetIsUsed;
        property KeywordIndex: TWordList.TIndex read FKeywordIndex;
        property Length: Integer read FLength;
        property Offset: TOffset read GetOffset;
        property Parser: TMySQLParser read Heritage.Heritage.FParser;
        property SQL: PChar read GetSQL;
      public
        property AsString: string read GetAsString;
        property DbIdentType: TDbIdentType read GetDbIdentType;
        property NextToken: PToken read GetNextToken;
        property NextTokenAll: PToken read GetNextTokenAll;
        property OperatorType: TOperatorType read FOperatorType;
        property ParentNode: PNode read GetParentNode;
        property Text: string read GetText write SetText;
        property TokenType: fspTypes.TTokenType read FTokenType;
        property UsageType: TUsageType read FUsageType;
      end;

      PRange = ^TRange;
      TRange = packed record
      private
        Heritage: TChild;
        property FParentNode: TOffset read Heritage.FParentNode write Heritage.FParentNode;
      private
        FFirstToken: TOffset; // Cache for speeding
        FLastToken: TOffset; // Cache for speeding
        class function Create(const AParser: TMySQLParser; const ANodeType: TNodeType): TOffset; static; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFirstToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOffset(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
        function GetParentNode(): PNode; {$IFNDEF Debug} inline; {$ENDIF}
        procedure AddChild(const AChild: TOffset);
        property Offset: TOffset read GetOffset;
        property Parser: TMySQLParser read Heritage.Heritage.FParser;
      public
        property FirstToken: PToken read GetFirstToken;
        property LastToken: PToken read GetLastToken;
        property NodeType: TNodeType read Heritage.Heritage.FNodeType;
        property ParentNode: PNode read GetParentNode;
      end;

      TStmt = packed record
      private
        Heritage: TRange;
        property FFirstToken: TOffset read Heritage.FFirstToken write Heritage.FFirstToken;
        property FLastToken: TOffset read Heritage.FLastToken write Heritage.FLastToken;
      private
        FErrorCode: Integer;
        FErrorToken: TOffset;
        FFirstTokenAll: TOffset;
        FLastTokenAll: TOffset;
        FStmtType: TStmtType; // Cache for speeding
        class function Create(const AParser: TMySQLParser; const AStmtType: TStmtType): TOffset; static;
        function GetErrorMessage(): string;
        function GetErrorToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFirstToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetFirstTokenAll(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastToken(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetLastTokenAll(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetNextStmt(): PStmt;
        function GetParentNode(): PNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetText(): string;
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      public
        property ErrorCode: Integer read FErrorCode;
        property ErrorMessage: string read GetErrorMessage;
        property ErrorToken: PToken read GetErrorToken;
        property FirstToken: PToken read GetFirstToken;
        property FirstTokenAll: PToken read GetFirstTokenAll;
        property LastToken: PToken read GetLastToken;
        property LastTokenAll: PToken read GetLastTokenAll;
        property NextStmt: PStmt read GetNextStmt;
        property ParentNode: PNode read GetParentNode;
        property StmtType: TStmtType read FStmtType;
        property Text: string read GetText;
      end;

      { Normal nodes ----------------------------------------------------------}

    protected type
      PAnalyzeStmt = ^TAnalyzeStmt;
      TAnalyzeStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          NoWriteToBinlogTag: TOffset;
          TableTag: TOffset;
          TablesList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PAlterDatabaseStmt = ^TAlterDatabaseStmt;
      TAlterDatabaseStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IdentTag: TOffset;
          CharacterSetValue: TOffset;
          CollateValue: TOffset;
          UpgradeDataDirectoryNameTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PAlterEventStmt = ^TAlterEventStmt;
      TAlterEventStmt = packed record
      private type
        TNodes = packed record
          AlterTag: TOffset;
          DefinerNode: TOffset;
          EventTag: TOffset;
          EventIdent: TOffset;
          OnSchedule: packed record
            Tag: TOffset;
            Value: TOffset;
          end;
          OnCompletitionTag: TOffset;
          RenameValue: TOffset;
          EnableTag: TOffset;
          CommentValue: TOffset;
          DoTag: TOffset;
          Body: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PAlterInstanceStmt = ^TAlterInstanceStmt;
      TAlterInstanceStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          RotateTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PAlterRoutineStmt = ^TAlterRoutineStmt;
      TAlterRoutineStmt = packed record
      private type
        TNodes = packed record
          AlterTag: TOffset;
          IdentNode: TOffset;
          CharacteristicList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        Nodes: TNodes;
        FRoutineType: TRoutineType;
        class function Create(const AParser: TMySQLParser; const ARoutineType: TRoutineType; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
        property RoutineType: TRoutineType read FRoutineType;
      end;

      PAlterServerStmt = ^TAlterServerStmt;
      TAlterServerStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IdentNode: TOffset;
          Options: packed record
            Tag: TOffset;
            List: TOffset;
          end;
        end;
      private
        Heritage: TStmt;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PAlterTableStmt = ^TAlterTableStmt;
      TAlterTableStmt = packed record
      private type

        PAlterColumn = ^TAlterColumn;
        TAlterColumn = packed record
        private type
          TNodes = packed record
            AlterTag: TOffset;
            ColumnIdent: TOffset;
            SetDefaultValue: TOffset;
            DropDefaultTag: TOffset;
          end;
        private
          Heritage: TRange;
        private
          Nodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PConvertTo = ^TConvertTo;
        TConvertTo = packed record
        private type
          TNodes = packed record
            ConvertToTag: TOffset;
            CharacterSetValue: TOffset;
            CollateValue: TOffset;
          end;
        private
          Heritage: TRange;
        private
          Nodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PDropObject = ^TDropObject;
        TDropObject = packed record
        private type
          TNodes = packed record
            DropTag: TOffset;
            ItemTypeTag: TOffset;
            Ident: TOffset;
          end;
        private
          Heritage: TRange;
        private
          Nodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PExchangePartition = ^TExchangePartition;
        TExchangePartition = packed record
        private type
          TNodes = packed record
            ExchangePartitionTag: TOffset;
            PartitionIdent: TOffset;
            WithTableTag: TOffset;
            TableIdent: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PReorganizePartition = ^TReorganizePartition;
        TReorganizePartition = packed record
        private type
          TNodes = packed record
            ReorganizePartitionTag: TOffset;
            PartitionIdentList: TOffset;
            IntoTag: TOffset;
            PartitionList: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          AlterTag: TOffset;
          IgnoreTag: TOffset;
          TableTag: TOffset;
          IdentNode: TOffset;
          SpecificationList: TOffset;
          AlgorithmValue: TOffset;
          ConvertToCharacterSetNode: TOffset;
          DiscardTablespaceTag: TOffset;
          EnableKeys: TOffset;
          ForceTag: TOffset;
          ImportTablespaceTag: TOffset;
          LockValue: TOffset;
          OrderByValue: TOffset;
          RenameNode: TOffset;
          TableOptionsNodes: TTableOptionNodes;
        end;
      private
        Heritage: TStmt;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PAlterViewStmt = ^TAlterViewStmt;
      TAlterViewStmt = packed record
      private type
        TNodes = packed record
          AlterTag: TOffset;
          AlgorithmValue: TOffset;
          DefinerNode: TOffset;
          SQLSecurityTag: TOffset;
          ViewTag: TOffset;
          IdentNode: TOffset;
          Columns: TOffset;
          AsTag: TOffset;
          SelectStmt: TOffset;
          OptionTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PBeginStmt = ^TBeginStmt;
      TBeginStmt = packed record
      private type
        TNodes = packed record
          BeginTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PBetweenOp = ^TBetweenOp;
      TBetweenOp = packed record
      private type
        TNodes = packed record
          Expr: TOffset;
          Max: TOffset;
          Min: TOffset;
          Operator1: TOffset;
          Operator2: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const AOperator1, AOperator2, AExpr, AMin, AMax: TOffset): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PBinaryOp = ^TBinaryOp;
      TBinaryOp = packed record
      private type
        TNodes = packed record
          Operand1: TOffset;
          OperatorToken: TOffset;
          Operand2: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const AOperator, AOperand1, AOperand2: TOffset): TOffset; static;
        function GetOperand1(): PChild; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOperand2(): PChild; {$IFNDEF Debug} inline; {$ENDIF}
        function GetOperator(): PChild; {$IFNDEF Debug} inline; {$ENDIF}
      public
        property Operand1: PChild read GetOperand1;
        property Operand2: PChild read GetOperand2;
        property Operator: PChild read GetOperator;
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PCallStmt = ^TCallStmt;
      TCallStmt = packed record
      private type
        TNodes = packed record
          CallTag: TOffset;
          ProcedureIdent: TOffset;
          ParamList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCaseOp = ^TCaseOp;
      TCaseOp = packed record
      private type

        PBranch = ^TBranch;
        TBranch = packed record
        private type
          TNodes = packed record
            WhenTag: TOffset;
            CondExpr: TOffset;
            ThenTag: TOffset;
            ResultExpr: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          CaseTag: TOffset;
          CompareExpr: TOffset;
          BranchList: TOffset;
          ElseTag: TOffset;
          ElseExpr: TOffset;
          EndTag: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PCaseStmt = ^TCaseStmt;
      TCaseStmt = packed record
      private type

        PBranch = ^TBranch;
        TBranch = packed record
        private type
          TNodes = packed record
            Tag: TOffset;
            ConditionExpr: TOffset;
            ThenTag: TOffset;
            StmtList: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          CaseTag: TOffset;
          CompareExpr: TOffset;
          BranchList: TOffset;
          EndTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCastFunc = ^TCastFunc;
      TCastFunc = packed record
      private type
        TNodes = packed record
          FuncToken: TOffset;
          OpenBracket: TOffset;
          Expr: TOffset;
          AsTag: TOffset;
          DataType: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PCharFunc = ^TCharFunc;
      TCharFunc = packed record
      private type
        TNodes = packed record
          FuncToken: TOffset;
          OpenBracket: TOffset;
          ValueList: TOffset;
          UsingTag: TOffset;
          CharsetIdent: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PChecksumStmt = ^TChecksumStmt;
      TChecksumStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          TablesList: TOffset;
          OptionTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCheckStmt = ^TCheckStmt;
      TCheckStmt = packed record
      private type

        POption = ^TOption;
        TOption = packed record
        private type
          TNodes = packed record
            OptionTag: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; overload; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          StmtTag: TOffset;
          TablesList: TOffset;
          OptionList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCloseStmt = ^TCloseStmt;
      TCloseStmt = packed record
      private type
        TNodes = packed record
          CloseTag: TOffset;
          CursorIdent: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCommitStmt = ^TCommitStmt;
      TCommitStmt = packed record
      private type
        TNodes = packed record
          CommitTag: TOffset;
          ChainTag: TOffset;
          ReleaseTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCompoundStmt = ^TCompoundStmt;
      TCompoundStmt = packed record
      private type
        TNodes = packed record
          BeginLabelToken: TOffset;
          BeginTag: TOffset;
          StmtList: TOffset;
          EndTag: TOffset;
          EndLabelToken: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PConvertFunc = ^TConvertFunc;
      TConvertFunc = packed record
      private type
        TNodes = packed record
          FuncToken: TOffset;
          OpenBracket: TOffset;
          Expr: TOffset;
          Comma: TOffset;
          DataType: TOffset;
          UsingTag: TOffset;
          CharsetIdent: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PCreateDatabaseStmt = ^TCreateDatabaseStmt;
      TCreateDatabaseStmt = packed record
      private type
        TNodes = packed record
          CreateTag: TOffset;
          DatabaseTag: TOffset;
          IfNotExistsTag: TOffset;
          DatabaseIdent: TOffset;
          CharacterSetValue: TOffset;
          CollateValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCreateEventStmt = ^TCreateEventStmt;
      TCreateEventStmt = packed record
      private type
        TNodes = packed record
          CreateTag: TOffset;
          DefinerNode: TOffset;
          EventTag: TOffset;
          IfNotExistsTag: TOffset;
          EventIdent: TOffset;
          OnScheduleValue: TOffset;
          OnCompletitionTag: TOffset;
          EnableTag: TOffset;
          CommentValue: TOffset;
          DoTag: TOffset;
          Body: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCreateIndexStmt = ^TCreateIndexStmt;
      TCreateIndexStmt = packed record
      private type
        TNodes = packed record
          CreateTag: TOffset;
          IndexTag: TOffset;
          IndexIdent: TOffset;
          OnTag: TOffset;
          TableIdent: TOffset;
          IndexTypeValue: TOffset;
          KeyColumnList: TOffset;
          AlgorithmValue: TOffset;
          CommentValue: TOffset;
          KeyBlockSizeValue: TOffset;
          LockValue: TOffset;
          ParserValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCreateRoutineStmt = ^TCreateRoutineStmt;
      TCreateRoutineStmt = packed record
      private type
        TNodes = packed record
          CreateTag: TOffset;
          DefinerNode: TOffset;
          RoutineTag: TOffset;
          IdentNode: TOffset;
          ParameterList: TOffset;
          Returns: TOffset;
          CharacteristicList: TOffset;
          Body: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        FRoutineType: TRoutineType;
        class function Create(const AParser: TMySQLParser; const ARoutineType: TRoutineType; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
        property RoutineType: TRoutineType read FRoutineType;
      end;

      PCreateServerStmt = ^TCreateServerStmt;
      TCreateServerStmt = packed record
      private type
        TNodes = packed record
          CreateTag: TOffset;
          ServerTag: TOffset;
          ServerIdent: TOffset;
          ForeignDataWrapperValue: TOffset;
          Options: packed record
            Tag: TOffset;
            List: TOffset;
          end;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCreateTableStmt = ^TCreateTableStmt;
      TCreateTableStmt = packed record
      private type

        TColumnAdd = (caAdd, caChange, caModify, caNone);

        PColumn = ^TColumn;
        TColumn = packed record
        private type
          TNodes = packed record
            AddTag: TOffset;
            ColumnTag: TOffset;
            OldNameIdent: TOffset;
            NameIdent: TOffset;
            DataTypeNode: TOffset;
            BinaryTag: TOffset;
            Null: TOffset;
            DefaultValue: TOffset;
            OnUpdateTag: TOffset;
            AutoIncrementTag: TOffset;
            KeyTag: TOffset;
            CommentValue: TOffset;
            ColumnFormat: TOffset;
            Position: TOffset;
          end;
        private
          Heritage: TRange;
        private
          Nodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PForeignKey = ^TForeignKey;
        TForeignKey = packed record
        private type
          TNodes = packed record
            AddTag: TOffset;
            ConstraintTag: TOffset;
            SymbolIdent: TOffset;
            ForeignKeyTag: TOffset;
            NameIdent: TOffset;
            ColumnNameList: TOffset;
            ReferencesTag: TOffset;
            ParentTableIdent: TOffset;
            IndicesList: TOffset;
            MatchValue: TOffset;
            OnDeleteValue: TOffset;
            OnUpdateValue: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PKey = ^TKey;
        TKey = packed record
        private type
          TNodes = packed record
            AddTag: TOffset;
            ConstraintTag: TOffset;
            SymbolIdent: TOffset;
            KeyTag: TOffset;
            KeyIdent: TOffset;
            ColumnIdentList: TOffset;
            KeyBlockSizeValue: TOffset;
            IndexTypeTag: TOffset;
            ParserValue: TOffset;
            CommentValue: TOffset;
          end;
        private
          Heritage: TRange;
        private
          Nodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PKeyColumn = ^TKeyColumn;
        TKeyColumn = packed record
        private type
          TNodes = packed record
            IdentTag: TOffset;
            OpenBracketToken: TOffset;
            LengthToken: TOffset;
            CloseBracketToken: TOffset;
            SortTag: TOffset;
          end;
        private
          Heritage: TRange;
        private
          Nodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PPartition = ^TPartition;
        TPartition = packed record
        private type
          TNodes = packed record
            AddTag: TOffset;
            PartitionTag: TOffset;
            NameIdent: TOffset;
            ValuesNode: TOffset;
            EngineValue: TOffset;
            CommentValue: TOffset;
            DataDirectoryValue: TOffset;
            IndexDirectoryValue: TOffset;
            MaxRowsValue: TOffset;
            MinRowsValue: TOffset;
            SubPartitionList: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PPartitionValues = ^TPartitionValues;
        TPartitionValues = packed record
        private type
          TNodes = packed record
            ValuesTag: TOffset;
            DescriptionValue: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          CreateTag: TOffset;
          TemporaryTag: TOffset;
          TableTag: TOffset;
          IfNotExistsTag: TOffset;
          TableIdent: TOffset;
          OpenBracketToken: TOffset;
          DefinitionList: TOffset;
          TableOptionsNodes: TTableOptionNodes;
          TableOptionList: TOffset;
          PartitionOption: packed record
            PartitionByTag: TOffset;
            PartitionKindTag: TOffset;
            PartitionAlgorithmValue: TOffset;
            PartitionExpr: TOffset;
            PartitionColumnsTag: TOffset;
            PartitionColumnList: TOffset;
            PartitionsValue: TOffset;
            SubPartitionByTag: TOffset;
            SubPartitionKindTag: TOffset;
            SubPartitionAlgorithmValue: TOffset;
            SubPartitionExprList: TOffset;
            SubPartitionsValue: TOffset;
          end;
          PartitionDefinitionList: TOffset;
          LikeTag: TOffset;
          LikeTableIdent: TOffset;
          CloseBracketToken: TOffset;
          IgnoreReplaceTag: TOffset;
          AsTag: TOffset;
          SelectStmt: TOffset;
        end;

      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCreateTriggerStmt = ^TCreateTriggerStmt;
      TCreateTriggerStmt = packed record
      private type
        TNodes = packed record
          CreateTag: TOffset;
          DefinerNode: TOffset;
          TriggerTag: TOffset;
          TriggerIdent: TOffset;
          ActionValue: TOffset;
          OnTag: TOffset;
          TableIdentNode: TOffset;
          ForEachRowTag: TOffset;
          Body: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCreateUserStmt = ^TCreateUserStmt;
      TCreateUserStmt = packed record
      private type
        TNodes = packed record
          CreateTag: TOffset;
          IfTag: TOffset;
          UserSpecifications: TOffset;
          WithTag: TOffset;
          ResourcesList: TOffset;
          PasswordOption: TOffset;
          PasswordDays: TOffset;
          DayTag: TOffset;
          AccountTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCreateViewStmt = ^TCreateViewStmt;
      TCreateViewStmt = packed record
      private type
        TNodes = packed record
          CreateTag: TOffset;
          OrReplaceTag: TOffset;
          AlgorithmValue: TOffset;
          DefinerNode: TOffset;
          SQLSecurityTag: TOffset;
          ViewTag: TOffset;
          IdentNode: TOffset;
          Columns: TOffset;
          AsTag: TOffset;
          SelectStmt: TOffset;
          OptionTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PCurrentTimestamp = ^TCurrentTimestamp;
      TCurrentTimestamp = packed record
      private type
        TNodes = packed record
          CurrentTimestampTag: TOffset;
          OpenBracketToken: TOffset;
          LengthInteger: TOffset;
          CloseBracketToken: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PDataType = ^TDataType;
      TDataType = packed record
      private type
        TNodes = packed record
          NationalTag: TOffset;
          IdentToken: TOffset;
          OpenBracketToken: TOffset;
          LengthToken: TOffset;
          CommaToken: TOffset;
          DecimalsToken: TOffset;
          CloseBracketToken: TOffset;
          ItemsList: TOffset;
          UnsignedTag: TOffset;
          ZerofillTag: TOffset;
          CharacterSetValue: TOffset;
          CollateValue: TOffset;
          BinaryTag: TOffset;
          ASCIITag: TOffset;
          UnicodeTag: TOffset;
        end;
      private
        Heritage: TRange;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PDbIdent = ^TDbIdent;
      TDbIdent = packed record
      private type
        TNodes = packed record
          Ident: TOffset;
          DatabaseDot: TOffset;
          DatabaseIdent: TOffset;
          TableDot: TOffset;
          TableIdent: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FDbIdentType: TDbIdentType;
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ADbIdentType: TDbIdentType; const ANodes: TNodes): TOffset; overload; static;
        class function Create(const AParser: TMySQLParser; const ADbIdentType: TDbIdentType;
          const AIdent, ADatabaseDot, ADatabaseIdent, ATableDot, ATableIdent: TOffset): TOffset; overload; static;
        function GetDatabaseIdent(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetIdent(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
        function GetParentNode(): PNode; {$IFNDEF Debug} inline; {$ENDIF}
        function GetTableIdent(): PToken; {$IFNDEF Debug} inline; {$ENDIF}
      public
        property DatabaseIdent: PToken read GetDatabaseIdent;
        property DbIdentType: TDbIdentType read FDbIdentType;
        property Ident: PToken read GetIdent;
        property ParentNode: PNode read GetParentNode;
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        property TableIdent: PToken read GetTableIdent;
      end;

      PDeallocatePrepareStmt = ^TDeallocatePrepareStmt;
      TDeallocatePrepareStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          StmtIdent: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDeclareStmt = ^TDeclareStmt;
      TDeclareStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IdentList: TOffset;
          TypeNode: TOffset;
          DefaultValue: TOffset;
          CursorForTag: TOffset;
          SelectStmt: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDeclareConditionStmt = ^TDeclareConditionStmt;
      TDeclareConditionStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Ident: TOffset;
          ConditionTag: TOffset;
          ForTag: TOffset;
          ErrorCode: TOffset;
          SQLStateTag: TOffset;
          ErrorString: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDeclareCursorStmt = ^TDeclareCursorStmt;
      TDeclareCursorStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Ident: TOffset;
          CursorTag: TOffset;
          ForTag: TOffset;
          SelectStmt: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDeclareHandlerStmt = ^TDeclareHandlerStmt;
      TDeclareHandlerStmt = packed record
      private type

        PCondition = ^TCondition;
        TCondition = packed record
        private type
          TNodes = packed record
            ErrorCode: TOffset;
            SQLStateTag: TOffset;
            ConditionIdent: TOffset;
            SQLWarningsTag: TOffset;
            NotFoundTag: TOffset;
            SQLExceptionTag: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; overload; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          StmtTag: TOffset;
          ActionTag: TOffset;
          HandlerTag: TOffset;
          ForTag: TOffset;
          ConditionsExpr: TOffset;
          Stmt: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDeleteStmt = ^TDeleteStmt;
      TDeleteStmt = packed record
      private type
        TNodes = packed record
          DeleteTag: TOffset;
          LowPriorityTag: TOffset;
          QuickTag: TOffset;
          IgnoreTag: TOffset;
          FromTag: TOffset;
          TableList: TOffset;
          PartitionTag: TOffset;
          PartitionList: TOffset;
          UsingValue: TOffset;
          WhereValue: TOffset;
          OrderByValue: TOffset;
          LimitValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDoStmt = ^TDoStmt;
      TDoStmt = packed record
      private type
        TNodes = packed record
          DoTag: TOffset;
          ExprList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDropDatabaseStmt = ^TDropDatabaseStmt;
      TDropDatabaseStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IfExistsTag: TOffset;
          DatabaseIdent: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDropEventStmt = ^TDropEventStmt;
      TDropEventStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IfExistsTag: TOffset;
          EventIdent: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDropIndexStmt = ^TDropIndexStmt;
      TDropIndexStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IndexIdent: TOffset;
          OnTag: TOffset;
          TableIdent: TOffset;
          AlgorithmValue: TOffset;
          LockValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDropRoutineStmt = ^TDropRoutineStmt;
      TDropRoutineStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IfExistsTag: TOffset;
          RoutineIdent: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        FRoutineType: TRoutineType;
        class function Create(const AParser: TMySQLParser; const ARoutineType: TRoutineType; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
        property RoutineType: TRoutineType read FRoutineType;
      end;

      PDropServerStmt = ^TDropServerStmt;
      TDropServerStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IfExistsTag: TOffset;
          ServerIdent: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDropTableStmt = ^TDropTableStmt;
      TDropTableStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IfExistsTag: TOffset;
          TableIdentList: TOffset;
          RestrictCascadeTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDropTriggerStmt = ^TDropTriggerStmt;
      TDropTriggerStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IfExistsTag: TOffset;
          TriggerIdent: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDropUserStmt = ^TDropUserStmt;
      TDropUserStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IfExistsTag: TOffset;
          UserList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PDropViewStmt = ^TDropViewStmt;
      TDropViewStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IfExistsTag: TOffset;
          ViewIdentList: TOffset;
          RestrictCascadeTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PExecuteStmt = ^TExecuteStmt;
      TExecuteStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          StmtVariable: TOffset;
          UsingTag: TOffset;
          VariableIdents: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PExistsFunc = ^TExistsFunc;
      TExistsFunc = packed record
      private type
        TNodes = packed record
          FuncToken: TOffset;
          OpenBracket: TOffset;
          SubQuery: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PExplainStmt = ^TExplainStmt;
      TExplainStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          TableIdent: TOffset;
          ColumnIdent: TOffset;
          ExplainType: TOffset;
          AssignToken: TOffset;
          FormatKeyword: TOffset;
          ExplainStmt: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PExtractFunc = ^TExtractFunc;
      TExtractFunc = packed record
      private type
        TNodes = packed record
          FuncToken: TOffset;
          OpenBracket: TOffset;
          UnitTag: TOffset;
          FromTag: TOffset;
          DateExpr: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PFetchStmt = ^TFetchStmt;
      TFetchStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          FromTag: TOffset;
          CursorIdent: TOffset;
          IntoTag: TOffset;
          VariableList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PFlushStmt = ^TFlushStmt;
      TFlushStmt = packed record
      private type

          POption = ^TOption;
          TOption = packed record
          private type
            TNodes = packed record
              OptionTag: TOffset;
              TablesList: TOffset;
            end;
          private
            Heritage: TRange;
          private
            FNodes: TNodes;
            class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
          public
            property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
          end;

        TNodes = packed record
          StmtTag: TOffset;
          NoWriteToBinLogTag: TOffset;
          OptionList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PFunctionCall = ^TFunctionCall;
      TFunctionCall = packed record
      private type
        TNodes = packed record
          Ident: TOffset;
          ArgumentsList: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const AIdent, AArgumentsList: TOffset): TOffset; overload; static;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; overload; static;
        function GetArguments(): PChild; {$IFNDEF Debug} inline; {$ENDIF}
        function GetIdent(): PChild; {$IFNDEF Debug} inline; {$ENDIF}
      public
        property Arguments: PChild read GetArguments;
        property Ident: PChild read GetIdent;
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PFunctionReturns = ^TFunctionReturns;
      TFunctionReturns = packed record
      private type
        TNodes = packed record
          ReturnsTag: TOffset;
          DataTypeNode: TOffset;
          CharsetValue: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PGetDiagnosticsStmt = ^TGetDiagnosticsStmt;
      TGetDiagnosticsStmt = packed record
      private type

        PStmtInfo = ^TStmtInfo;
        TStmtInfo = packed record
        private type
          TNodes = packed record
            Target: TOffset;
            EqualOp: TOffset;
            ItemTag: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PConditionalInfo = ^TConditionalInfo;
        TConditionalInfo = packed record
        private type
          TNodes = packed record
            Target: TOffset;
            EqualOp: TOffset;
            ItemTag: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          StmtTag: TOffset;
          ScopeTag: TOffset;
          DiagnosticsTag: TOffset;
          ConditionTag: TOffset;
          ConditionNumber: TOffset;
          InfoList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PGrantStmt = ^TGrantStmt;
      TGrantStmt = packed record
      private type

        PPrivileg = ^TPrivileg;
        TPrivileg = packed record
        private type
          TNodes = packed record
            PrivilegTag: TOffset;
            ColumnList: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PUserSpecification = ^TUserSpecification;
        TUserSpecification = packed record
        private type
          TNodes = packed record
            UserIdent: TOffset;
            IdentifiedToken: TOffset;
            PluginIdent: TOffset;
            AsToken: TOffset;
            AuthString: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          StmtTag: TOffset;
          PrivilegesList: TOffset;
          OnTag: TOffset;
          OnUser: TOffset;
          ObjectValue: TOffset;
          ToTag: TOffset;
          UserSpecifications: TOffset;
          RequireTag: TOffset;
          WithTag: TOffset;
          ResourcesList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PGroupConcatFunc = ^TGroupConcatFunc;
      TGroupConcatFunc = packed record
      private type

        PExpr = ^TExpr;
        TExpr = packed record
        private type
          TNodes = packed record
            Expr: TOffset;
            Direction: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          FuncToken: TOffset;
          OpenBracket: TOffset;
          DistinctTag: TOffset;
          ExprList: TOffset;
          OrderByTag: TOffset;
          OrderByExprList: TOffset;
          SeparatorValue: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PHelpStmt = ^THelpStmt;
      THelpStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          HelpString: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PIfStmt = ^TIfStmt;
      TIfStmt = packed record
      private type

        PBranch = ^TBranch;
        TBranch = packed record
        private type
          TNodes = packed record
            Tag: TOffset;
            ConditionExpr: TOffset;
            ThenTag: TOffset;
            StmtList: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          BranchList: TOffset;
          EndTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PIgnoreLines = ^TIgnoreLines;
      TIgnoreLines = packed record
      private type
        TNodes = packed record
          IgnoreTag: TOffset;
          NumberToken: TOffset;
          LinesTag: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PInOp = ^TInOp;
      TInOp = packed record
      private type
        TNodes = packed record
          Operand: TOffset;
          NotToken: TOffset;
          InToken: TOffset;
          List: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PInsertStmt = ^TInsertStmt;
      TInsertStmt = packed record
      private type

        PSetItem = ^TSetItem;
        TSetItem = packed record
        private type
          TNodes = packed record
            FieldToken: TOffset;
            AssignToken: TOffset;
            ValueNode: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          InsertTag: TOffset;
          PriorityTag: TOffset;
          IgnoreTag: TOffset;
          IntoTag: TOffset;
          TableIdent: TOffset;
          PartitionTag: TOffset;
          PartitionList: TOffset;
          ColumnList: TOffset;
          ValuesTag: TOffset;
          ValuesList: TOffset;
          SetTag: TOffset;
          SetList: TOffset;
          SelectStmt: TOffset;
          OnDuplicateKeyUpdateTag: TOffset;
          UpdateList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PIntervalOp = ^TIntervalOp;
      TIntervalOp = packed record
      private type

        PListItem = ^TListItem;
        TListItem = packed record
        private type
          TNodes = packed record
            PlusToken: TOffset;
            IntervalTag: TOffset;
            Interval: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        end;

        TNodes = packed record
          QuantityExp: TOffset;
          UnitTag: TOffset;
        end;
      private
        Heritage: TRange;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      end;

      TIntervalList = array [0..15 - 1] of TOffset;

      PIterateStmt = ^TIterateStmt;
      TIterateStmt = packed record
      private type
        TNodes = packed record
          IterateToken: TOffset;
          LabelToken: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PKillStmt = ^TKillStmt;
      TKillStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          ProcessIdToken: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PLeaveStmt = ^TLeaveStmt;
      TLeaveStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          LabelToken: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PLikeOp = ^TLikeOp;
      TLikeOp = packed record
      private type
        TNodes = packed record
          Operand1: TOffset;
          NotToken: TOffset;
          LikeToken: TOffset;
          Operand2: TOffset;
          EscapeToken: TOffset;
          EscapeCharToken: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      // PList = ^TList; defined after TList definition, otherwise its assigns Classes.TList
      TList = packed record
      private type
        TNodes = packed record
          OpenBracket: TOffset;
          FirstChild: TOffset;
          DelimiterType: fspTypes.TTokenType;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes; const AChildrenCount: Integer; const AChildren: array of TOffset): TOffset; static;
        function GetCount(): Integer;
        function GetFirstChild(): PChild; {$IFNDEF Debug} inline; {$ENDIF}
        property Count: Integer read GetCount; // This is slow, should not be used.
      public
        property DelimiterType: fspTypes.TTokenType read Nodes.DelimiterType;
        property FirstChild: PChild read GetFirstChild;
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;
      PList = ^TList;

      PLoadDataStmt = ^TLoadDataStmt;
      TLoadDataStmt = packed record
      private type
        TNodes = packed record
          LoadDataTag: TOffset;
          PriorityTag: TOffset;
          InfileTag: TOffset;
          FilenameString: TOffset;
          ReplaceIgnoreTag: TOffset;
          IntoTableValue: TOffset;
          PartitionValue: TOffset;
          CharacterSetValue: TOffset;
          ColumnsTag: TOffset;
          ColumnsTerminatedByValue: TOffset;
          EnclosedByValue: TOffset;
          EscapedByValue: TOffset;
          LinesTag: TOffset;
          StartingByValue: TOffset;
          LinesTerminatedByValue: TOffset;
          IgnoreLines: TOffset;
          ColumnList: TOffset;
          SetList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PLoadXMLStmt = ^TLoadXMLStmt;
      TLoadXMLStmt = packed record
      private type
        TNodes = packed record
          LoadXMLTag: TOffset;
          PriorityTag: TOffset;
          LocalTag: TOffset;
          InfileTag: TOffset;
          FilenameString: TOffset;
          ReplaceIgnoreTag: TOffset;
          IntoTableValue: TOffset;
          PartitionValue: TOffset;
          CharacterSetValue: TOffset;
          RowsIdentifiedByValue: TOffset;
          IgnoreLines: TOffset;
          ColumnList: TOffset;
          SetList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PLockStmt = ^TLockStmt;
      TLockStmt = packed record
      private type

        PItem = ^TItem;
        TItem = packed record
        private type
          TNodes = packed record
            TableIdent: TOffset;
            AsTag: TOffset;
            AliasIdent: TOffset;
            TypeTag: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          LockTablesTag: TOffset;
          ItemList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PLoopStmt = ^TLoopStmt;
      TLoopStmt = packed record
      private type
        TNodes = packed record
          BeginLabelToken: TOffset;
          BeginTag: TOffset;
          StmtList: TOffset;
          EndTag: TOffset;
          EndLabelToken: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PPositionFunc = ^TPositionFunc;
      TPositionFunc = packed record
      private type
        TNodes = packed record
          FuncToken: TOffset;
          OpenBracket: TOffset;
          SubStr: TOffset;
          InTag: TOffset;
          Str: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PPrepareStmt = ^TPrepareStmt;
      TPrepareStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          StmtIdent: TOffset;
          FromTag: TOffset;
          StmtVariable: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PPurgeStmt = ^TPurgeStmt;
      TPurgeStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          TypeTag: TOffset;
          LogsTag: TOffset;
          Value: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      POpenStmt = ^TOpenStmt;
      TOpenStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          CursorIdent: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      POptimizeStmt = ^TOptimizeStmt;
      TOptimizeStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          OptionTag: TOffset;
          TableTag: TOffset;
          TablesList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PRegExpOp = ^TRegExpOp;
      TRegExpOp = packed record
      private type
        TNodes = packed record
          Operand1: TOffset;
          NotToken: TOffset;
          RegExpToken: TOffset;
          Operand2: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PReleaseStmt = ^TReleaseStmt;
      TReleaseStmt = packed record
      private type
        TNodes = packed record
          ReleaseTag: TOffset;
          Ident: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PRenameStmt = ^TRenameStmt;
      TRenameStmt = packed record
      private type

        PPair = ^TPair;
        TPair = packed record
        private type
          TNodes = packed record
            OrgNode: TOffset;
            ToTag: TOffset;
            NewNode: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          RenameTag: TOffset;
          RenameList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PRepairStmt = ^TRepairStmt;
      TRepairStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          OptionTag: TOffset;
          TableTag: TOffset;
          TablesList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PRepeatStmt = ^TRepeatStmt;
      TRepeatStmt = packed record
      private type
        TNodes = packed record
          BeginLabelToken: TOffset;
          RepeatTag: TOffset;
          StmtList: TOffset;
          UntilTag: TOffset;
          SearchConditionExpr: TOffset;
          EndTag: TOffset;
          EndLabelToken: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PResetStmt = ^TResetStmt;
      TResetStmt = packed record
      private type

        POption = ^TOption;
        TOption = packed record
        private type
          TNodes = packed record
            OptionTag: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          StmtTag: TOffset;
          OptionList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PReturnStmt = ^TReturnStmt;
      TReturnStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Expr: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PRevokeStmt = ^TRevokeStmt;
      TRevokeStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          PrivilegesList: TOffset;
          CommaToken: TOffset;
          GrantOptionTag: TOffset;
          OnTag: TOffset;
          OnUser: TOffset;
          ObjectValue: TOffset;
          FromTag: TOffset;
          UserIdentList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PRollbackStmt = ^TRollbackStmt;
      TRollbackStmt = packed record
      private type
        TNodes = packed record
          RollbackTag: TOffset;
          ToValue: TOffset;
          ChainTag: TOffset;
          ReleaseTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PRoutineParam = ^TRoutineParam;
      TRoutineParam = packed record
      private type
        TNodes = packed record
          DirektionTag: TOffset;
          IdentToken: TOffset;
          DataTypeNode: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PSavepointStmt = ^TSavepointStmt;
      TSavepointStmt = packed record
      private type
        TNodes = packed record
          SavepointTag: TOffset;
          Ident: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PSchedule = ^TSchedule;
      TSchedule = packed record
      private type
        TNodes = packed record
          At: packed record
            Tag: TOffset;
            Timestamp: TOffset;
            IntervalList: TIntervalList;
          end;
          Every: packed record
            Tag: TOffset;
            Interval: TOffset;
          end;
          Starts: packed record
            Tag: TOffset;
            Timestamp: TOffset;
            IntervalList: TIntervalList;
          end;
          Ends: packed record
            Tag: TOffset;
            Timestamp: TOffset;
            IntervalList: TIntervalList;
          end;
        end;
      private
        Heritage: TRange;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PSecretIdent = ^TSecretIdent;
      TSecretIdent = packed record
      private type
        TNodes = packed record
          OpenBracket: TOffset;
          ItemToken: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PSelectStmt = ^TSelectStmt;
      TSelectStmt = packed record
      private type

        PColumn = ^TColumn;
        TColumn = packed record
        private type
          TNodes = packed record
            ExprNode: TOffset;
            AsToken: TOffset;
            AliasIdent: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PTableFactor = ^TTableFactor;
        TTableFactor = packed record
        private type

          PIndexHint = ^TIndexHint;
          TIndexHint = packed record
          public type
            TNodes = record
              KindTag: TOffset;
              ForValue: TOffset;
              IndexList: TOffset;
            end;
          private
            Heritage: TRange;
          private
            FNodes: TNodes;
            class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
          public
            property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
          end;

          TNodes = packed record
            TableIdent: TOffset;
            PartitionTag: TOffset;
            Partitions: TOffset;
            AsToken: TOffset;
            AliasToken: TOffset;
            IndexHintList: TOffset;
            SelectStmt: TOffset;
          end;

        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PTableReferenceJoin = ^TTableReferenceJoin;
        TTableReferenceJoin = packed record
        private type
          TNodes = packed record
            JoinTag: TOffset;
            RightTable: TOffset;
            OnTag: TOffset;
            Condition: TOffset;
          end;
          TKeywordTokens = array [0..3] of Integer;
        private
          Heritage: TRange;
        private
          FJoinType: TJoinType;
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const AJoinType: TJoinType; const ANodes: TNodes): TOffset; static;
        public
          property JoinType: TJoinType read FJoinType;
        end;

        PTableReferenceOj = ^TTableReferenceOj;
        TTableReferenceOj = packed record
        private type
          TNodes = packed record
            OpenBracketToken: TOffset;
            OjTag: TOffset;
            TableReference: TOffset;
            CloseBracketToken: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PTableFactorReferences = ^TTableFactorReferences;
        TTableFactorReferences = packed record
        private type
          TNodes = packed record
            ReferenceList: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PTableFactorSelect = ^TTableFactorSelect;
        TTableFactorSelect = packed record
        private type
          TNodes = packed record
            SelectStmt: TOffset;
            AsToken: TOffset;
            AliasToken: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PGroup = ^TGroup;
        TGroup = packed record
        private type
          TNodes = packed record
            Expr: TOffset;
            Direction: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PGroups = ^TGroups;
        TGroups = packed record
        private type
          TNodes = packed record
            ColumnList: TOffset;
            WithRollupTag: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        POrder = ^TOrder;
        TOrder = packed record
        private type
          TNodes = packed record
            Expr: TOffset;
            DirectionTag: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        PInto = ^TInto;
        TInto = packed record
        private type
          TNodes = packed record
            IntoTag: TOffset;
            OutfileValue: TOffset;
            DumpfileTag: TOffset;
            Filename: TOffset;
            CharacterSetValue: TOffset;
            Variable: TOffset;
            FieldsTerminatedByValue: TOffset;
            OptionalEnclosedByValue: TOffset;
            LinesTerminatedByValue: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          SelectTag: TOffset;
          DistinctTag: TOffset;
          HighPriorityTag: TOffset;
          StraightJoinTag: TOffset;
          SQLSmallResultTag: TOffset;
          SQLBigResultTag: TOffset;
          SQLBufferResultTag: TOffset;
          SQLNoCacheTag: TOffset;
          SQLCalcFoundRowsTag: TOffset;
          ColumnsList: TOffset;
          Into1: TOffset;
          From: record
            Tag: TOffset;
            Expr: TOffset;
          end;
          Where: record
            Tag: TOffset;
            Expr: TOffset;
          end;
          GroupBy: record
            Tag: TOffset;
            Expr: TOffset;
          end;
          Having: record
            Tag: TOffset;
            Expr: TOffset;
          end;
          OrderBy: record
            Tag: TOffset;
            Expr: TOffset;
          end;
          Limit: record
            LimitTag: TOffset;
            OffsetTag: TOffset;
            OffsetToken: TOffset;
            CommaToken: TOffset;
            RowCountToken: TOffset;
          end;
          Proc: record
            Tag: TOffset;
            Ident: TOffset;
            ParamList: TOffset;
          end;
          Into2: TOffset;
          ForUpdatesTag: TOffset;
          LockInShareMode: TOffset;
          Union: record
            Tag: TOffset;
            SelectStmt: TOffset;
          end;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PSetStmt = ^TSetStmt;
      TSetStmt = packed record
      private type

        PAssignment = ^TAssignment;
        TAssignment = packed record
        private type
          TNodes = packed record
            ScopeTag: TOffset;
            Variable: TOffset;
            AssignToken: TOffset;
            ValueExpr: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          SetTag: TOffset;
          ScopeTag: TOffset;
          AssignmentList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PSetNamesStmt = ^TSetNamesStmt;
      TSetNamesStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          ConstValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PSetPasswordStmt = ^TSetPasswordStmt;
      TSetPasswordStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          ForValue: TOffset;
          AssignToken: TOffset;
          PasswordExpr: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PSetTransactionStmt = ^TSetTransactionStmt;
      TSetTransactionStmt = packed record
      private type

        PCharacteristic = ^TCharacteristic;
        TCharacteristic = packed record
        private type
          TNodes = packed record
            KindTag: TOffset;
            Value: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          SetTag: TOffset;
          ScopeTag: TOffset;
          TransactionTag: TOffset;
          CharacteristicList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowAuthorsStmt = ^TShowAuthorsStmt;
      TShowAuthorsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowBinaryLogsStmt = ^TShowBinaryLogsStmt;
      TShowBinaryLogsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowBinlogEventsStmt = ^TShowBinlogEventsStmt;
      TShowBinlogEventsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          InValue: TOffset;
          FromValue: TOffset;
          LimitTag: TOffset;
          OffsetToken: TOffset;
          CommaToken: TOffset;
          RowCountToken: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowCharacterSetStmt = ^TShowCharacterSetStmt;
      TShowCharacterSetStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          LikeValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowCollationStmt = ^TShowCollationStmt;
      TShowCollationStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          LikeValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowContributorsStmt = ^TShowContributorsStmt;
      TShowContributorsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowCountErrorsStmt = ^TShowCountErrorsStmt;
      TShowCountErrorsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          CountFunctionCall: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowCountWarningsStmt = ^TShowCountWarningsStmt;
      TShowCountWarningsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          CountFunctionCall: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowCreateDatabaseStmt = ^TShowCreateDatabaseStmt;
      TShowCreateDatabaseStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          IfNotExistsTag: TOffset;
          Ident: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowCreateEventStmt = ^TShowCreateEventStmt;
      TShowCreateEventStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Ident: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowCreateFunctionStmt = ^TShowCreateFunctionStmt;
      TShowCreateFunctionStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Ident: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowCreateProcedureStmt = ^TShowCreateProcedureStmt;
      TShowCreateProcedureStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Ident: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowCreateTableStmt = ^TShowCreateTableStmt;
      TShowCreateTableStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Ident: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowCreateTriggerStmt = ^TShowCreateTriggerStmt;
      TShowCreateTriggerStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Ident: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowCreateViewStmt = ^TShowCreateViewStmt;
      TShowCreateViewStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Ident: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowDatabasesStmt = ^TShowDatabasesStmt;
      TShowDatabasesStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          LikeValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowEngineStmt = ^TShowEngineStmt;
      TShowEngineStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Ident: TOffset;
          KindTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowEnginesStmt = ^TShowEnginesStmt;
      TShowEnginesStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowErrorsStmt = ^TShowErrorsStmt;
      TShowErrorsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Limit: record
            LimitTag: TOffset;
            OffsetToken: TOffset;
            CommaToken: TOffset;
            RowCountToken: TOffset;
          end;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowEventsStmt = ^TShowEventsStmt;
      TShowEventsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          FromValue: TOffset;
          LikeValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowFunctionCodeStmt = ^TShowFunctionCodeStmt;
      TShowFunctionCodeStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowFunctionStatusStmt = ^TShowFunctionStatusStmt;
      TShowFunctionStatusStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowGrantsStmt = ^TShowGrantsStmt;
      TShowGrantsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          ForValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowIndexStmt = ^TShowIndexStmt;
      TShowIndexStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          FromTableValue: TOffset;
          FromDatabaseValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowMasterStatusStmt = ^TShowMasterStatusStmt;
      TShowMasterStatusStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowOpenTablesStmt = ^TShowOpenTablesStmt;
      TShowOpenTablesStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          FromDatabaseValue: TOffset;
          LikeValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowPluginsStmt = ^TShowPluginsStmt;
      TShowPluginsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowPrivilegesStmt = ^TShowPrivilegesStmt;
      TShowPrivilegesStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowProcedureCodeStmt = ^TShowProcedureCodeStmt;
      TShowProcedureCodeStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowProcedureStatusStmt = ^TShowProcedureStatusStmt;
      TShowProcedureStatusStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          LikeValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowProcessListStmt = ^TShowProcessListStmt;
      TShowProcessListStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowProfileStmt = ^TShowProfileStmt;
      TShowProfileStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          TypeList: TOffset;
          ForQueryValue: TOffset;
          LimitValue: TOffset;
          OffsetValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowProfilesStmt = ^TShowProfilesStmt;
      TShowProfilesStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowRelaylogEventsStmt = ^TShowRelaylogEventsStmt;
      TShowRelaylogEventsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          InValue: TOffset;
          FromValue: TOffset;
          LimitTag: TOffset;
          OffsetToken: TOffset;
          CommaToken: TOffset;
          RowCountToken: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowSlaveHostsStmt = ^TShowSlaveHostsStmt;
      TShowSlaveHostsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowSlaveStatusStmt = ^TShowSlaveStatusStmt;
      TShowSlaveStatusStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowStatusStmt = ^TShowStatusStmt;
      TShowStatusStmt = packed record
      private type
        TNodes = packed record
          ShowTag: TOffset;
          ScopeTag: TOffset;
          StatusTag: TOffset;
          LikeValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowTableStatusStmt = ^TShowTableStatusStmt;
      TShowTableStatusStmt = packed record
      private type
        TNodes = packed record
          ShowTag: TOffset;
          FromValue: TOffset;
          LikeValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowTablesStmt = ^TShowTablesStmt;
      TShowTablesStmt = packed record
      private type
        TNodes = packed record
          ShowTag: TOffset;
          FullTag: TOffset;
          TablesTag: TOffset;
          FromValue: TOffset;
          LikeValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowTriggersStmt = ^TShowTriggersStmt;
      TShowTriggersStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          FromValue: TOffset;
          LikeValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowVariablesStmt = ^TShowVariablesStmt;
      TShowVariablesStmt = packed record
      private type
        TNodes = packed record
          ShowTag: TOffset;
          ScopeTag: TOffset;
          VariablesTag: TOffset;
          LikeValue: TOffset;
          WhereValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShowWarningsStmt = ^TShowWarningsStmt;
      TShowWarningsStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
          Limit: record
            LimitTag: TOffset;
            OffsetToken: TOffset;
            CommaToken: TOffset;
            RowCountToken: TOffset;
          end;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PShutdownStmt = ^TShutdownStmt;
      TShutdownStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PSignalStmt = ^TSignalStmt;
      TSignalStmt = packed record
      private type

        PInformation = ^TInformation;
        TInformation = packed record
        private type
          TNodes = packed record
            Value: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          StmtTag: TOffset;
          Condition: TOffset;
          SetTag: TOffset;
          InformationList: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PSubstringFunc = ^TSubstringFunc;
      TSubstringFunc = packed record
      private type
        TNodes = packed record
          FuncToken: TOffset;
          OpenBracket: TOffset;
          Str: TOffset;
          FromTag: TOffset;
          Pos: TOffset;
          ForTag: TOffset;
          Len: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PSoundsLikeOp = ^TSoundsLikeOp;
      TSoundsLikeOp = packed record
      private type
        TNodes = packed record
          Operand1: TOffset;
          Operand2: TOffset;
          Operator1: TOffset;
          Operator2: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const AOperator1, AOperator2: TOffset; const AOperand1, AOperand2: TOffset): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PStartSlaveStmt = ^TStartSlaveStmt;
      TStartSlaveStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PStartTransactionStmt = ^TStartTransactionStmt;
      TStartTransactionStmt = packed record
      private type
        TNodes = packed record
          StartTransactionTag: TOffset;
          RealOnlyTag: TOffset;
          ReadWriteTag: TOffset;
          WithConsistentSnapshotTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PStopSlaveStmt = ^TStopSlaveStmt;
      TStopSlaveStmt = packed record
      private type
        TNodes = packed record
          StmtTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PSubArea = ^TSubArea;
      TSubArea = packed record
      private type
        TNodes = packed record
          OpenBracket: TOffset;
          AreaNode: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PSubPartition = ^TSubPartition;
      TSubPartition = packed record
      private type
        TNodes = packed record
          SubPartitionTag: TOffset;
          NameIdent: TOffset;
          EngineValue: TOffset;
          CommentValue: TOffset;
          DataDirectoryValue: TOffset;
          IndexDirectoryValue: TOffset;
          MaxRowsValue: TOffset;
          MinRowsValue: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PTableReference = ^TTableReference;
      TTableReference = packed record
      private type
        TNodes = packed record
          FirstTable: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const AFirstTable: TOffset; const AJoinCount: Integer; const AJoins: array of TOffset): TOffset; static;
        function GetJoinCount(): Integer;
        function GetFirstTable(): PChild;
      public
        property FirstTable: PChild read GetFirstTable;
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        property JoinCount: Integer read GetJoinCount;
      end;

      PTag = ^TTag;
      TTag = packed record
      private type
        TNodes = packed record
          KeywordToken1: TOffset;
          KeywordToken2: TOffset;
          KeywordToken3: TOffset;
          KeywordToken4: TOffset;
        end;
      private
        Heritage: TRange;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PTruncateStmt = ^TTruncateStmt;
      TTruncateStmt = packed record
      private type
        TNodes = packed record
          TruncateTag: TOffset;
          TableTag: TOffset;
          TableIdent: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PTrimFunc = ^TTrimFunc;
      TTrimFunc = packed record
      private type
        TNodes = packed record
          FuncToken: TOffset;
          OpenBracket: TOffset;
          DirectionTag: TOffset;
          RemoveStr: TOffset;
          FromTag: TOffset;
          Str: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PUnaryOp = ^TUnaryOp;
      TUnaryOp = packed record
      private type
        TNodes = packed record
          Operand: TOffset;
          Operator: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const AOperator, AOperand: TOffset): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PUnknownStmt = ^TUnknownStmt;
      TUnknownStmt = packed record
      private
        Heritage: TStmt;
      private
        class function Create(const AParser: TMySQLParser; const ATokenCount: Integer; const ATokens: array of TOffset): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PUnlockStmt = ^TUnlockStmt;
      TUnlockStmt = packed record
      private type
        TNodes = packed record
          UnlockTablesTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PUpdateStmt = ^TUpdateStmt;
      TUpdateStmt = packed record
      private type
        TNodes = packed record
          UpdateTag: TOffset;
          PriorityTag: TOffset;
          TableReferenceList: TOffset;
          SetValue: TOffset;
          WhereValue: TOffset;
          OrderByValue: TOffset;
          LimitValue: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PUser = ^TUser;
      TUser = packed record
      private type
        TNodes = packed record
          NameToken: TOffset;
          AtToken: TOffset;
          HostToken: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PUseStmt = ^TUseStmt;
      TUseStmt = packed record
      private type
        TNodes = packed record
          StmtToken: TOffset;
          DbNameNode: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PValue = ^TValue;
      TValue = packed record
      private type
        TNodes = packed record
          IdentTag: TOffset;
          AssignToken: TOffset;
          ValueToken: TOffset;
        end;
      private
        Heritage: TRange;
      private
        Nodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PVariable = ^TVariable;
      TVariable = packed record
      private type
        TNodes = packed record
          At1Token: TOffset;
          At2Token: TOffset;
          ScopeTag: TOffset;
          ScopeDotToken: TOffset;
          Ident: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PWeightStringFunc = ^TWeightStringFunc;
      TWeightStringFunc = packed record
      private type

        PLevel = ^TLevel;
        TLevel = packed record
        private type
          TNodes = packed record
            CountInt: TOffset;
            DirectionTag: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          FuncToken: TOffset;
          OpenBracket: TOffset;
          Str: TOffset;
          AsTag: TOffset;
          DataType: TOffset;
          LevelTag: TOffset;
          LevelList: TOffset;
          CloseBracket: TOffset;
        end;
      private
        Heritage: TRange;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
      end;

      PWhileStmt = ^TWhileStmt;
      TWhileStmt = packed record
      private type
        TNodes = packed record
          BeginLabelToken: TOffset;
          WhileTag: TOffset;
          SearchConditionExpr: TOffset;
          DoTag: TOffset;
          StmtList: TOffset;
          EndTag: TOffset;
          EndLabelToken: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

      PXAStmt = ^TXAStmt;
      TXAStmt = packed record
      private type

        PID = ^TID;
        TID = packed record
        private type
          TNodes = packed record
            GTrId: TOffset;
            Comma1: TOffset;
            BQual: TOffset;
            Comma2: TOffset;
            FormatId: TOffset;
          end;
        private
          Heritage: TRange;
        private
          FNodes: TNodes;
          class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
        public
          property Parser: TMySQLParser read Heritage.Heritage.Heritage.FParser;
        end;

        TNodes = packed record
          XATag: TOffset;
          ActionTag: TOffset;
          Ident: TOffset;
          RestTag: TOffset;
        end;
      private
        Heritage: TStmt;
      private
        FNodes: TNodes;
        class function Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset; static;
      public
        property Parser: TMySQLParser read Heritage.Heritage.Heritage.Heritage.FParser;
      end;

  protected
    kiACCOUNT,
    kiACTION,
    kiADD,
    kiAFTER,
    kiALGORITHM,
    kiALL,
    kiALTER,
    kiANALYZE,
    kiAND,
    kiAS,
    kiASC,
    kiASCII,
    kiAT,
    kiAUTO_INCREMENT,
    kiAUTHORS,
    kiAVG_ROW_LENGTH,
    kiBEFORE,
    kiBEGIN,
    kiBETWEEN,
    kiBINARY,
    kiBINLOG,
    kiBLOCK,
    kiBOTH,
    kiBTREE,
    kiBY,
    kiCACHE,
    kiCALL,
    kiCASCADE,
    kiCASCADED,
    kiCASE,
    kiCATALOG_NAME,
    kiCHANGE,
    kiCHANGED,
    kiCHAIN,
    kiCHARACTER,
    kiCHARSET,
    kiCHECK,
    kiCHECKSUM,
    kiCLASS_ORIGIN,
    kiCLIENT,
    kiCLOSE,
    kiCOALESCE,
    kiCODE,
    kiCOLLATE,
    kiCOLLATION,
    kiCOLUMN,
    kiCOLUMN_FORMAT,
    kiCOLUMN_NAME,
    kiCOLUMNS,
    kiCOMMENT,
    kiCOMMIT,
    kiCOMMITTED,
    kiCOMPACT,
    kiCOMPLETION,
    kiCOMPRESSED,
    kiCONCURRENT,
    kiCONDITION,
    kiCONNECTION,
    kiCONSISTENT,
    kiCONSTRAINT,
    kiCONSTRAINT_CATALOG,
    kiCONSTRAINT_NAME,
    kiCONSTRAINT_SCHEMA,
    kiCONTAINS,
    kiCONTEXT,
    kiCONTINUE,
    kiCONTRIBUTORS,
    kiCONVERT,
    kiCOPY,
    kiCPU,
    kiCREATE,
    kiCROSS,
    kiCURRENT,
    kiCURRENT_DATE,
    kiCURRENT_TIME,
    kiCURRENT_TIMESTAMP,
    kiCURRENT_USER,
    kiCURSOR,
    kiCURSOR_NAME,
    kiDATA,
    kiDATABASE,
    kiDATABASES,
    kiDAY,
    kiDAY_HOUR,
    kiDAY_MINUTE,
    kiDAY_SECOND,
    kiDEALLOCATE,
    kiDECLARE,
    kiDEFAULT,
    kiDEFINER,
    kiDELAY_KEY_WRITE,
    kiDELAYED,
    kiDELETE,
    kiDESC,
    kiDESCRIBE,
    kiDETERMINISTIC,
    kiDIAGNOSTICS,
    kiDIRECTORY,
    kiDISABLE,
    kiDISCARD,
    kiDISTINCT,
    kiDISTINCTROW,
    kiDIV,
    kiDO,
    kiDROP,
    kiDUMPFILE,
    kiDUPLICATE,
    kiDYNAMIC,
    kiEACH,
    kiELSE,
    kiELSEIF,
    kiENABLE,
    kiENCLOSED,
    kiEND,
    kiENDS,
    kiENGINE,
    kiENGINES,
    kiERRORS,
    kiESCAPE,
    kiESCAPED,
    kiEVENT,
    kiEVENTS,
    kiEVERY,
    kiEXCHANGE,
    kiEXCLUSIVE,
    kiEXECUTE,
    kiEXISTS,
    kiEXPIRE,
    kiEXPLAIN,
    kiEXIT,
    kiEXTENDED,
    kiFALSE,
    kiFAST,
    kiFAULTS,
    kiFETCH,
    kiFLUSH,
    kiFIELDS,
    kiFILE,
    kiFIRST,
    kiFIXED,
    kiFOR,
    kiFORCE,
    kiFORMAT,
    kiFOREIGN,
    kiFOUND,
    kiFROM,
    kiFULL,
    kiFULLTEXT,
    kiFUNCTION,
    kiGET,
    kiGLOBAL,
    kiGRANT,
    kiGRANTS,
    kiGROUP,
    kiHANDLER,
    kiHASH,
    kiHAVING,
    kiHELP,
    kiHIGH_PRIORITY,
    kiHOST,
    kiHOSTS,
    kiHOUR,
    kiHOUR_MINUTE,
    kiHOUR_SECOND,
    kiIDENTIFIED,
    kiIF,
    kiIGNORE,
    kiIMPORT,
    kiIN,
    kiINDEX,
    kiINDEXES,
    kiINFILE,
    kiINNER,
    kiINNODB,
    kiINOUT,
    kiINPLACE,
    kiINSTANCE,
    kiINSERT,
    kiINSERT_METHOD,
    kiINTERVAL,
    kiINTO,
    kiINVOKER,
    kiIO,
    kiIPC,
    kiIS,
    kiISOLATION,
    kiITERATE,
    kiJOIN,
    kiJSON,
    kiKEY,
    kiKEY_BLOCK_SIZE,
    kiKEYS,
    kiKILL,
    kiLANGUAGE,
    kiLAST,
    kiLEADING,
    kiLEAVE,
    kiLEFT,
    kiLESS,
    kiLEVEL,
    kiLIKE,
    kiLIMIT,
    kiLINEAR,
    kiLINES,
    kiLIST,
    kiLOAD,
    kiLOCAL,
    kiLOCALTIME,
    kiLOCALTIMESTAMP,
    kiLOCK,
    kiLOGS,
    kiLOOP,
    kiLOW_PRIORITY,
    kiMASTER,
    kiMATCH,
    kiMAX_QUERIES_PER_HOUR,
    kiMAX_ROWS,
    kiMAX_CONNECTIONS_PER_HOUR,
    kiMAX_UPDATES_PER_HOUR,
    kiMAX_USER_CONNECTIONS,
    kiMAXVALUE,
    kiMEDIUM,
    kiMEMORY,
    kiMERGE,
    kiMESSAGE_TEXT,
    kiMICROSECOND,
    kiMIGRATE,
    kiMIN_ROWS,
    kiMINUTE,
    kiMINUTE_SECOND,
    kiMOD,
    kiMODE,
    kiMODIFIES,
    kiMODIFY,
    kiMONTH,
    kiMUTEX,
    kiMYSQL_ERRNO,
    kiNAME,
    kiNAMES,
    kiNATIONAL,
    kiNATURAL,
    kiNEVER,
    kiNEXT,
    kiNO,
    kiNONE,
    kiNOT,
    kiNULL,
    kiNO_WRITE_TO_BINLOG,
    kiNUMBER,
    kiOFFSET,
    kiOJ,
    kiON,
    kiONE,
    kiONLY,
    kiOPEN,
    kiOPTIMIZE,
    kiOPTION,
    kiOPTIONALLY,
    kiOPTIONS,
    kiOR,
    kiORDER,
    kiOUT,
    kiOUTER,
    kiOUTFILE,
    kiOWNER,
    kiPACK_KEYS,
    kiPAGE,
    kiPAGE_CHECKSUM,
    kiPARSER,
    kiPARTIAL,
    kiPARTITION,
    kiPARTITIONING,
    kiPARTITIONS,
    kiPASSWORD,
    kiPHASE,
    kiQUERY,
    kiPLUGINS,
    kiPORT,
    kiPREPARE,
    kiPRESERVE,
    kiPRIMARY,
    kiPRIVILEGES,
    kiPROCEDURE,
    kiPROCESS,
    kiPROCESSLIST,
    kiPROFILE,
    kiPROFILES,
    kiPROXY,
    kiPURGE,
    kiQUARTER,
    kiQUICK,
    kiRANGE,
    kiREAD,
    kiREADS,
    kiREBUILD,
    kiRECOVER,
    kiREDUNDANT,
    kiREFERENCES,
    kiREGEXP,
    kiRELAYLOG,
    kiRELEASE,
    kiRELOAD,
    kiREMOVE,
    kiRENAME,
    kiREORGANIZE,
    kiREPAIR,
    kiREPEAT,
    kiREPEATABLE,
    kiREPLACE,
    kiREPLICATION,
    kiREQUIRE,
    kiRESET,
    kiRESIGNAL,
    kiRESTRICT,
    kiRESUME,
    kiRETURN,
    kiRETURNED_SQLSTATE,
    kiRETURNS,
    kiREVERSE,
    kiREVOKE,
    kiRIGHT,
    kiRLIKE,
    kiROLLBACK,
    kiROLLUP,
    kiROTATE,
    kiROUTINE,
    kiROW,
    kiROW_COUNT,
    kiROW_FORMAT,
    kiROWS,
    kiSAVEPOINT,
    kiSCHEDULE,
    kiSCHEMA,
    kiSCHEMA_NAME,
    kiSECOND,
    kiSECURITY,
    kiSELECT,
    kiSEPARATOR,
    kiSERIALIZABLE,
    kiSERVER,
    kiSESSION,
    kiSET,
    kiSHARE,
    kiSHARED,
    kiSHOW,
    kiSHUTDOWN,
    kiSIGNAL,
    kiSIMPLE,
    kiSLAVE,
    kiSNAPSHOT,
    kiSOCKET,
    kiSONAME,
    kiSOUNDS,
    kiSOURCE,
    kiSPATIAL,
    kiSQL,
    kiSQL_BIG_RESULT,
    kiSQL_BUFFER_RESULT,
    kiSQL_CACHE,
    kiSQL_CALC_FOUND_ROWS,
    kiSQL_NO_CACHE,
    kiSQL_SMALL_RESULT,
    kiSQLEXCEPTION,
    kiSQLSTATE,
    kiSQLWARNINGS,
    kiSTACKED,
    kiSTARTING,
    kiSTART,
    kiSTARTS,
    kiSTATS_AUTO_RECALC,
    kiSTATS_PERSISTENT,
    kiSTATUS,
    kiSTOP,
    kiSTORAGE,
    kiSTRAIGHT_JOIN,
    kiSUBCLASS_ORIGIN,
    kiSUBPARTITION,
    kiSUBPARTITIONS,
    kiSUPER,
    kiSUSPEND,
    kiSWAPS,
    kiSWITCHES,
    kiTABLE,
    kiTABLE_NAME,
    kiTABLES,
    kiTABLESPACE,
    kiTEMPORARY,
    kiTEMPTABLE,
    kiTERMINATED,
    kiTHAN,
    kiTHEN,
    kiTO,
    kiTRADITIONAL,
    kiTRAILING,
    kiTRANSACTION,
    kiTRIGGER,
    kiTRIGGERS,
    kiTRUE,
    kiTRUNCATE,
    kiTYPE,
    kiUNCOMMITTED,
    kiUNDEFINED,
    kiUNDO,
    kiUNICODE,
    kiUNION,
    kiUNIQUE,
    kiUNKNOWN,
    kiUNLOCK,
    kiUNSIGNED,
    kiUNTIL,
    kiUPDATE,
    kiUPGRADE,
    kiUSAGE,
    kiUSE,
    kiUSE_FRM,
    kiUSER,
    kiUSING,
    kiVALUE,
    kiVALUES,
    kiVARIABLES,
    kiVIEW,
    kiWARNINGS,
    kiWEEK,
    kiWHEN,
    kiWHERE,
    kiWHILE,
    kiWRAPPER,
    kiWRITE,
    kiWITH,
    kiWORK,
    kiXA,
    kiXID,
    kiXML,
    kiXOR,
    kiYEAR,
    kiYEAR_MONTH,
    kiZEROFILL: Integer;

  private type
    TDelimiterDevider = (ddNone, ddSpace, ddReturn);
  private
    Commands: TFormatHandle;
    FCurrentToken: TOffset; // Cache for speeding
    FPreviousToken: TOffset;
    FInPL_SQL: Integer;
    MySQLVersions: array of Integer;
    OperatorTypeByKeywordIndex: array of TOperatorType;
    function GetError(): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
    function GetErrorMessage(): string; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function GetErrorMessage(const AErrorCode: Integer): string; overload;
    function GetFunctions(): string;
    function GetKeywords(): string;
    function GetNextToken(Index: Integer): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
    function GetParsedToken(const Index: Integer): TOffset;
    function GetInPL_SQL(): Boolean; {$IFNDEF Debug} inline; {$ENDIF}
    function GetRoot(): PRoot; {$IFNDEF Debug} inline; {$ENDIF}
    function GetText(const Offset: TOffset): PChar; {$IFNDEF Debug} inline; {$ENDIF}
    procedure SaveToDebugHTMLFile(const Filename: string);
    procedure SaveToFormatedSQLFile(const Filename: string);
    procedure SaveToSQLFile(const Filename: string);
    procedure SetFunctions(AFunctions: string);
    procedure SetKeywords(AKeywords: string);
    property CurrentToken: TOffset read FCurrentToken;
    property Error: Boolean read GetError;
    property InPL_SQL: Boolean read GetInPL_SQL;
    property NextToken[Index: Integer]: TOffset read GetNextToken;
    property PreviousToken: TOffset read FPreviousToken;

  protected
    FAnsiQuotes: Boolean;
    FErrorCode: Integer;
    FErrorLine: Integer;
    FErrorToken: TOffset;
    FunctionList: TWordList;
    TokenIndex: Integer;
    KeywordList: TWordList;
    FMySQLVersion: Integer;
    ParsedNodes: packed record
      Mem: PAnsiChar;
      UsedSize: Integer;
      MemSize: Integer;
    end;
    ParseText: string;
    ParsePosition: record
      Text: PChar;
      Length: Integer;
    end;
    FRoot: TOffset;
    ReplaceTexts: record
      Mem: PChar;
      UsedLength: Integer;
      MemSize: Integer;
    end;
    InCreateFunctionStmt: Boolean;
    InCreateProcedureStmt: Boolean;
    TokenBuffer: record
      Count: Integer;
      Tokens: array [0 .. 50 - 1] of TOffset;
    end;

    function ApplyCurrentToken(): TOffset; overload;
    function ApplyCurrentToken(const AUsageType: TUsageType; const ATokenType: TTokenType = ttUnknown): TOffset; overload;
    procedure BeginPL_SQL(); {$IFNDEF Debug} inline; {$ENDIF}
    function ChildPtr(const ANode: TOffset): PChild; {$IFNDEF Debug} inline; {$ENDIF}
    function EndOfStmt(const Token: PToken): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function EndOfStmt(const Token: TOffset): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    procedure EndPL_SQL(); {$IFNDEF Debug} inline; {$ENDIF}
    procedure FormatAnalyzeStmt(const Nodes: TAnalyzeStmt.TNodes);
    procedure FormatAlterDatabaseStmt(const Nodes: TAlterDatabaseStmt.TNodes);
    procedure FormatAlterEventStmt(const Nodes: TAlterEventStmt.TNodes);
    procedure FormatAlterInstanceStmt(const Nodes: TAlterInstanceStmt.TNodes);
    procedure FormatAlterRoutineStmt(const Nodes: TAlterRoutineStmt.TNodes);
    procedure FormatAlterServerStmt(const Nodes: TAlterServerStmt.TNodes);
    procedure FormatAlterTableStmt(const Nodes: TAlterTableStmt.TNodes);
    procedure FormatAlterTableStmtAlterColumn(const Nodes: TAlterTableStmt.TAlterColumn.TNodes);
    procedure FormatAlterTableStmtConvertTo(const Nodes: TAlterTableStmt.TConvertTo.TNodes);
    procedure FormatAlterTableStmtDropObject(const Nodes: TAlterTableStmt.TDropObject.TNodes);
    procedure FormatCreateTableStmtColumn(const Nodes: TCreateTableStmt.TColumn.TNodes);
    procedure FormatCreateTableStmtKey(const Nodes: TCreateTableStmt.TKey.TNodes);
    procedure FormatCreateTableStmtKeyColumn(const Nodes: TCreateTableStmt.TKeyColumn.TNodes);
    procedure FormatComments(const Token: PToken; const BeforeStmt: Boolean = False);
    procedure FormatDataType(const Nodes: TDataType.TNodes);
    procedure FormatDbIdent(const Nodes: TDbIdent.TNodes);
    procedure FormatIntervalOp(const Nodes: TIntervalOp.TNodes);
    procedure FormatList(const Nodes: TList.TNodes); overload; {$IFNDEF Debug} inline; {$ENDIF}
    procedure FormatList(const Nodes: TList.TNodes; const DelimiterDevider: TDelimiterDevider); overload;
    procedure FormatList(const Node: TOffset; const DelimiterDevider: TDelimiterDevider); overload; {$IFNDEF Debug} inline; {$ENDIF}
    procedure FormatNode(const Node: PNode); overload;
    procedure FormatNode(const Node: TOffset); overload; {$IFNDEF Debug} inline; {$ENDIF}
    procedure FormatRoot(const Node: PNode);
    procedure FormatSchedule(const Nodes: TSchedule.TNodes);
    procedure FormatShutdownStmt(const Nodes: TShutdownStmt.TNodes);
    procedure FormatTag(const Nodes: TTag.TNodes);
    procedure FormatToken(const Token: PToken);
    procedure FormatValue(const Nodes: TValue.TNodes);
    function IsChild(const ANode: PNode): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function IsChild(const ANode: TOffset): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function IsRange(const ANode: PNode): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function IsRoot(const ANode: PNode): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function IsStmt(const ANode: PNode): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function IsStmt(const ANode: TOffset): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function IsToken(const ANode: PNode): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function IsToken(const ANode: TOffset): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    function NewNode(const ANodeType: TNodeType): TOffset;
    function NewText(const AText: string): TOffset;
    function NodePtr(const ANode: TOffset): PNode; {$IFNDEF Debug} inline; {$ENDIF}
    function NodeSize(const NodeType: TNodeType): Integer;
    function ParseRoot(): TOffset; overload;
    function ParseAnalyzeStmt(): TOffset;
    function ParseAlias(): TOffset;
    function ParseAlterDatabaseStmt(): TOffset;
    function ParseAlterEventStmt(): TOffset;
    function ParseAlterInstanceStmt(): TOffset;
    function ParseAlterRoutineStmt(const ARoutineType: TRoutineType): TOffset;
    function ParseAlterServerStmt(): TOffset;
    function ParseAlterTableStmt(): TOffset;
    function ParseAlterTableStmtAlterColumn(): TOffset;
    function ParseAlterTableStmtConvertTo(): TOffset;
    function ParseAlterTableStmtDropItem(): TOffset;
    function ParseAlterTableStmtExchangePartition(): TOffset;
    function ParseAlterTableStmtReorganizePartition(): TOffset;
    function ParseAlterTableStmtUnion(): TOffset;
    function ParseAlterStmt(): TOffset;
    function ParseAlterViewStmt(): TOffset;
    function ParseBeginStmt(): TOffset;
    function ParseCallStmt(): TOffset;
    function ParseCaseOp(): TOffset;
    function ParseCaseOpBranch(): TOffset;
    function ParseCaseStmt(): TOffset;
    function ParseCaseStmtBranch(): TOffset;
    function ParseCastFunc(): TOffset;
    function ParseCharFunc(): TOffset;
    function ParseCheckStmt(): TOffset;
    function ParseCheckStmtOption(): TOffset;
    function ParseChecksumStmt(): TOffset;
    function ParseCloseStmt(): TOffset;
    function ParseCommitStmt(): TOffset;
    function ParseCompoundStmt(): TOffset;
    function ParseConvertFunc(): TOffset;
    function ParseColumnIdent(): TOffset;
    function ParseCreateDatabaseStmt(): TOffset;
    function ParseCreateEventStmt(): TOffset;
    function ParseCreateIndexStmt(): TOffset;
    function ParseCreateRoutineStmt(const ARoutineType: TRoutineType): TOffset;
    function ParseCreateRoutineStmtCharacteristList(): TOffset;
    function ParseCreateServerStmt(): TOffset;
    function ParseCreateServerStmtOptionList(): TOffset;
    function ParseCreateStmt(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
    function ParseCreateTableStmt(): TOffset;
    function ParseCreateTableStmtColumn(const Add: TCreateTableStmt.TColumnAdd = caNone): TOffset;
    function ParseCreateTableStmtDefinition(): TOffset; overload;
    function ParseCreateTableStmtDefinition(const AlterTableStmt: Boolean): TOffset; overload;
    function ParseCreateTableStmtForeignKey(const Add: Boolean = False): TOffset;
    function ParseCreateTableStmtKey(const AlterTableStmt: Boolean): TOffset;
    function ParseCreateTableStmtKeyColumn(): TOffset;
    function ParseCreateTableStmtPartition(): TOffset; overload;
    function ParseCreateTableStmtPartition(const Add: Boolean): TOffset; overload;
    function ParseCreateTableStmtPartitionIdent(): TOffset;
    function ParseCreateTableStmtDefinitionPartitionNames(): TOffset;
    function ParseCreateTableStmtDefinitionPartitionValues(): TOffset;
    function ParseCreateTriggerStmt(): TOffset;
    function ParseCreateUserStmt(const Alter: Boolean): TOffset;
    function ParseCreateViewStmt(): TOffset;
    function ParseCurrentTimestamp(): TOffset;
    function ParseDatabaseIdent(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
    function ParseDataType(): TOffset;
    function ParseDbIdent(const ADbIdentType: TDbIdentType): TOffset;
    function ParseDefinerValue(): TOffset;
    function ParseDeallocatePrepareStmt(): TOffset;
    function ParseDeclareStmt(): TOffset;
    function ParseDeclareConditionStmt(): TOffset;
    function ParseDeclareCursorStmt(): TOffset;
    function ParseDeclareHandlerStmt(): TOffset;
    function ParseDeclareHandlerStmtCondition(): TOffset;
    function ParseDeleteStmt(): TOffset;
    function ParseDoStmt(): TOffset;
    function ParseDropDatabaseStmt(): TOffset;
    function ParseDropEventStmt(): TOffset;
    function ParseDropIndexStmt(): TOffset;
    function ParseDropRoutineStmt(const ARoutineType: TRoutineType): TOffset;
    function ParseDropServerStmt(): TOffset;
    function ParseDropTableStmt(): TOffset;
    function ParseDropTriggerStmt(): TOffset;
    function ParseDropUserStmt(): TOffset;
    function ParseDropViewStmt(): TOffset;
    function ParseEventIdent(): TOffset;
    function ParseExecuteStmt(): TOffset;
    function ParseExistsFunc(): TOffset;
    function ParseExplainStmt(): TOffset;
    function ParseExpr(): TOffset;
    function ParseExtractFunc(): TOffset;
    function ParseFetchStmt(): TOffset;
    function ParseFlushStmt(): TOffset;
    function ParseFlushStmtOption(): TOffset;
    function ParseForeignKeyIdent(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
    function ParseFunctionCall(): TOffset;
    function ParseFunctionIdent(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
    function ParseFunctionParam(): TOffset;
    function ParseFunctionReturns(): TOffset;
    function ParseGetDiagnosticsStmt(): TOffset;
    function ParseGetDiagnosticsStmtStmtInfo(): TOffset;
    function ParseGetDiagnosticsStmtConditionInfo(): TOffset;
    function ParseGrantStmt(): TOffset;
    function ParseGrantStmtPrivileg(): TOffset;
    function ParseGrantStmtUserSpecification(): TOffset;
    function ParseGroupConcatFunc(): TOffset;
    function ParseGroupConcatFuncExpr(): TOffset;
    function ParseHelpStmt(): TOffset;
    function ParseIdent(): TOffset;
    function ParseIfStmt(): TOffset;
    function ParseIfStmtBranch(): TOffset;
    function ParseIndexHint(): TOffset;
    function ParseInsertStmt(const Replace: Boolean = False): TOffset;
    function ParseInsertStmtSetItemsList(): TOffset;
    function ParseInsertStmtValuesList(): TOffset;
    function ParseInteger(): TOffset;
    function ParseIntervalOp(): TOffset;
    function ParseIntervalOpList(): TIntervalList;
    function ParseIntervalOpListItem(): TOffset;
    function ParseIterateStmt(): TOffset;
    function ParseKeyIdent(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
    function ParseKeyword(): TOffset;
    function ParseKillStmt(): TOffset;
    function ParseLeaveStmt(): TOffset;
    function ParseList(const Brackets: Boolean; const ParseItem: TParseFunction = nil; const DelimterType: TTokenType = ttComma): TOffset; overload;
    function ParseLoadDataStmt(): TOffset;
    function ParseLoadStmt(): TOffset;
    function ParseLoadXMLStmt(): TOffset;
    function ParseLockStmt(): TOffset;
    function ParseLockStmtItem(): TOffset;
    function ParseLoopStmt(): TOffset;
    function ParsePositionFunc(): TOffset;
    function ParsePrepareStmt(): TOffset;
    function ParsePurgeStmt(): TOffset;
    function ParseProcedureIdent(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
    function ParseOpenStmt(): TOffset;
    function ParseOptimizeStmt(): TOffset;
    function ParsePL_SQLStmt(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
    function ParseProcedureParam(): TOffset;
    function ParseReleaseStmt(): TOffset;
    function ParseRenameStmt(): TOffset;
    function ParseRenameStmtTablePair(): TOffset;
    function ParseRenameStmtUserPair(): TOffset;
    function ParseRepairStmt(): TOffset;
    function ParseRepeatStmt(): TOffset;
    function ParseResetStmt(): TOffset;
    function ParseReturnStmt(): TOffset;
    function ParseResetStmtOption(): TOffset;
    function ParseRevokeStmt(): TOffset;
    function ParseRollbackStmt(): TOffset;
    function ParseSavepointIdent(): TOffset;
    function ParseSavepointStmt(): TOffset;
    function ParseSchedule(): TOffset;
    function ParseSecretIdent(): TOffset;
    function ParseShowAuthorsStmt(): TOffset;
    function ParseShowBinaryLogsStmt(): TOffset;
    function ParseShowBinlogEventsStmt(): TOffset;
    function ParseShowCharacterSetStmt(): TOffset;
    function ParseShowCollationStmt(): TOffset;
    function ParseShowContributorsStmt(): TOffset;
    function ParseShowCountErrorsStmt(): TOffset;
    function ParseShowCountWarningsStmt(): TOffset;
    function ParseShowCreateDatabaseStmt(): TOffset;
    function ParseShowCreateEventStmt(): TOffset;
    function ParseShowCreateFunctionStmt(): TOffset;
    function ParseShowCreateProcedureStmt(): TOffset;
    function ParseShowCreateTableStmt(): TOffset;
    function ParseShowCreateTriggerStmt(): TOffset;
    function ParseShowCreateViewStmt(): TOffset;
    function ParseShowDatabasesStmt(): TOffset;
    function ParseShowEngineStmt(): TOffset;
    function ParseShowEnginesStmt(): TOffset;
    function ParseShowErrorsStmt(): TOffset;
    function ParseShowEventsStmt(): TOffset;
    function ParseShowFunctionCodeStmt(): TOffset;
    function ParseShowFunctionStatusStmt(): TOffset;
    function ParseShowGrantsStmt(): TOffset;
    function ParseShowIndexStmt(): TOffset;
    function ParseShowMasterStatusStmt(): TOffset;
    function ParseShowOpenTablesStmt(): TOffset;
    function ParseShowPluginsStmt(): TOffset;
    function ParseShowPrivilegesStmt(): TOffset;
    function ParseShowProcedureCodeStmt(): TOffset;
    function ParseShowProcedureStatusStmt(): TOffset;
    function ParseShowProcessListStmt(): TOffset;
    function ParseShowProfileStmt(): TOffset;
    function ParseShowProfileStmtType(): TOffset;
    function ParseShowProfilesStmt(): TOffset;
    function ParseShowRelaylogEventsStmt(): TOffset;
    function ParseShowSlaveHostsStmt(): TOffset;
    function ParseShowSlaveStatusStmt(): TOffset;
    function ParseShowStatusStmt(): TOffset;
    function ParseShowTableStatusStmt(): TOffset;
    function ParseShowTablesStmt(): TOffset;
    function ParseShowTriggersStmt(): TOffset;
    function ParseShowVariablesStmt(): TOffset;
    function ParseShowWarningsStmt(): TOffset;
    function ParseShutdownStmt(): TOffset;
    function ParseSignalStmt(): TOffset;
    function ParseSignalStmtInformation(): TOffset;
    function ParseSelectStmt(): TOffset;
    function ParseSelectStmtColumn(): TOffset;
    function ParseSelectStmtGroup(): TOffset;
    function ParseSelectStmtGroups(): TOffset;
    function ParseSelectStmtInto(): TOffset;
    function ParseSelectStmtOrder(): TOffset;
    function ParseSetNamesStmt(): TOffset;
    function ParseSetPasswordStmt(): TOffset;
    function ParseSetStmt(): TOffset;
    function ParseSetStmtAssignment(): TOffset;
    function ParseSetTransactionStmt(): TOffset;
    function ParseStartSlaveStmt(): TOffset;
    function ParseStartTransactionStmt(): TOffset;
    function ParseStopSlaveStmt(): TOffset;
    function ParseString(): TOffset;
    function ParseSubArea(const ParseNode: TParseFunction): TOffset;
    function ParseSubPartition(): TOffset;
    function ParseSubstringFunc(): TOffset;
    function ParseStmt(): TOffset;
    function ParseTableIdent(): TOffset; {$IFNDEF Debug} inline; {$ENDIF}
    function ParseTableReference(): TOffset;
    function ParseTableReferenceInner(): TOffset;
    function ParseTag(const KeywordIndex1: TWordList.TIndex; const KeywordIndex2: TWordList.TIndex = -1; const KeywordIndex3: TWordList.TIndex = -1; const KeywordIndex4: TWordList.TIndex = -1): TOffset;
    function ParseToken(): TOffset;
    function ParseSetTransactionStmtCharacterisic(): TOffset;
    function ParseTrimFunc(): TOffset;
    function ParseTruncateTableStmt(): TOffset;
    function ParseUnknownStmt(): TOffset;
    function ParseUnlockStmt(): TOffset;
    function ParseUpdateStmt(): TOffset;
    function ParseUpdatePair(): TOffset;
    function ParseUserIdent(): TOffset;
    function ParseUseStmt(): TOffset;
    function ParseValue(const KeywordIndex: TWordList.TIndex; const Assign: TValueAssign; const Brackets: Boolean; const ParseItem: TParseFunction): TOffset; overload;
    function ParseValue(const KeywordIndex: TWordList.TIndex; const Assign: TValueAssign; const OptionIndices: TWordList.TIndices): TOffset; overload;
    function ParseValue(const KeywordIndex: TWordList.TIndex; const Assign: TValueAssign; const ParseValueNode: TParseFunction): TOffset; overload;
    function ParseValue(const KeywordIndices: TWordList.TIndices; const Assign: TValueAssign; const Brackets: Boolean; const ParseItem: TParseFunction): TOffset; overload;
    function ParseValue(const KeywordIndices: TWordList.TIndices; const Assign: TValueAssign; const OptionIndices: TWordList.TIndices): TOffset; overload;
    function ParseValue(const KeywordIndices: TWordList.TIndices; const Assign: TValueAssign; const ParseValueNode: TParseFunction): TOffset; overload;
    function ParseValue(const KeywordIndices: TWordList.TIndices; const Assign: TValueAssign; const ValueKeywordIndex1: TWordList.TIndex; const ValueKeywordIndex2: TWordList.TIndex = -1): TOffset; overload;
    function ParseVariable(): TOffset;
    function ParseWeightStringFunc(): TOffset;
    function ParseWeightStringFuncLevel(): TOffset;
    function ParseWhileStmt(): TOffset;
    function ParseXAStmt(): TOffset;
    function RangeNodePtr(const ANode: TOffset): PRange; {$IFNDEF Debug} inline; {$ENDIF}
    procedure SetError(const AErrorCode: Integer; const AErrorToken: TOffset = 0);
    function StmtPtr(const Node: TOffset): PStmt; {$IFNDEF Debug} inline; {$ENDIF}
    function TokenPtr(const Token: TOffset): PToken; {$IFNDEF Debug} inline; {$ENDIF}
    property ErrorCode: Integer read FErrorCode;
    property ErrorMessage: string read GetErrorMessage;

  public
    ttIdents: set of TTokenType;
    ttStrings: set of TTokenType;
    procedure Clear();
    constructor Create(const AMySQLVersion: Integer = 0);
    destructor Destroy(); override;
    function FormatSQL(out SQL: string): Boolean;
    function LoadFromFile(const Filename: string): Boolean;
    function ParseSQL(const Text: PChar; const Length: Integer): Boolean; overload;
    function ParseSQL(const Text: string): Boolean; overload; {$IFNDEF Debug} inline; {$ENDIF}
    procedure SaveToFile(const Filename: string; const FileType: TFileType = ftSQL);
    property AnsiQuotes: Boolean read FAnsiQuotes write FAnsiQuotes;
    property Functions: string read GetFunctions write SetFunctions;
    property Keywords: string read GetKeywords write SetKeywords;
    property MySQLVersion: Integer read FMySQLVersion;
    property Root: PRoot read GetRoot;
  end;

implementation {***************************************************************}

uses
  Windows,
  SysUtils, StrUtils, RTLConsts, Math,
  fspUtils;

resourcestring
  SUnknownError = 'Unknown Error';
  SKeywordNotFound = 'Keyword "%s" not found';
  SUnknownOperatorPrecedence = 'Unknown operator precedence for operator "%s"';
  STooManyTokensInExpr = 'Too many tokens (%d) in Expr';
  SUnknownNodeType = 'Unknown node type';
  SOutOfMemory = 'Out of memory (%d)';

function WordIndices(const Index0: TMySQLParser.TWordList.TIndex;
  const Index1: TMySQLParser.TWordList.TIndex = -1;
  const Index2: TMySQLParser.TWordList.TIndex = -1;
  const Index3: TMySQLParser.TWordList.TIndex = -1;
  const Index4: TMySQLParser.TWordList.TIndex = -1;
  const Index5: TMySQLParser.TWordList.TIndex = -1): TMySQLParser.TWordList.TIndices;
begin
  Result[0] := Index0;
  Result[1] := Index1;
  Result[2] := Index2;
  Result[3] := Index3;
  Result[4] := Index4;
  Result[5] := Index5;
end;

{ TMySQLParser.TStringBuffer **************************************************}

procedure TMySQLParser.TStringBuffer.Clear();
begin
  Buffer.Write := Buffer.Mem;
end;

constructor TMySQLParser.TStringBuffer.Create(const InitialLength: Integer);
begin
  Buffer.Mem := nil;
  Buffer.MemSize := 0;
  Buffer.Write := nil;

  Reallocate(InitialLength);
end;

procedure TMySQLParser.TStringBuffer.Delete(const Start: Integer; const Length: Integer);
begin
  MoveMemory(@Buffer.Mem[Start], @Buffer.Mem[Start + Length], Size - Length);
  Buffer.Write := Pointer(Integer(Buffer.Write) - Length);
end;

destructor TMySQLParser.TStringBuffer.Destroy();
begin
  FreeMem(Buffer.Mem);

  inherited;
end;

function TMySQLParser.TStringBuffer.GetData(): Pointer;
begin
  Result := Pointer(Buffer.Mem);
end;

function TMySQLParser.TStringBuffer.GetLength(): Integer;
begin
  Result := (Integer(Buffer.Write) - Integer(Buffer.Mem)) div SizeOf(Buffer.Mem[0]);
end;

function TMySQLParser.TStringBuffer.GetSize(): Integer;
begin
  Result := Integer(Buffer.Write) - Integer(Buffer.Mem);
end;

function TMySQLParser.TStringBuffer.GetText(): PChar;
begin
  Result := Buffer.Mem;
end;

function TMySQLParser.TStringBuffer.Read(): string;
begin
  SetString(Result, PChar(Buffer.Mem), Size div SizeOf(Result[1]));
end;

procedure TMySQLParser.TStringBuffer.Reallocate(const NeededLength: Integer);
var
  Index: Integer;
begin
  if (Buffer.MemSize = 0) then
  begin
    Buffer.MemSize := NeededLength * SizeOf(Buffer.Write[0]);
    GetMem(Buffer.Mem, Buffer.MemSize);
    Buffer.Write := Buffer.Mem;
  end
  else if (Size + NeededLength * SizeOf(Buffer.Mem[0]) > Buffer.MemSize) then
  begin
    Index := Size div SizeOf(Buffer.Write[0]);
    Inc(Buffer.MemSize, 2 * (Size + NeededLength * SizeOf(Buffer.Mem[0]) - Buffer.MemSize));
    ReallocMem(Buffer.Mem, Buffer.MemSize);
    Buffer.Write := @Buffer.Mem[Index];
  end;
end;

procedure TMySQLParser.TStringBuffer.Write(const Text: PChar; const Length: Integer);
begin
  if (Length > 0) then
  begin
    Reallocate(Length);

    Move(Text^, Buffer.Write^, Length * SizeOf(Buffer.Mem[0]));
    Buffer.Write := @Buffer.Write[Length];
  end;
end;

procedure TMySQLParser.TStringBuffer.Write(const Text: string);
begin
  Write(PChar(Text), System.Length(Text));
end;

procedure TMySQLParser.TStringBuffer.Write(const Char: Char);
begin
  Reallocate(1);
  Move(Char, Buffer.Write^, SizeOf(Char));
  Buffer.Write := @Buffer.Write[1];
end;

{ TMySQLParser.TWordList ******************************************************}

procedure TMySQLParser.TWordList.Clear();
begin
  FText := '';

  FCount := 0;
  SetLength(FIndex, 0);

  SetLength(Parser.OperatorTypeByKeywordIndex, 0);
end;

constructor TMySQLParser.TWordList.Create(const ASQLParser: TMySQLParser; const AText: string = '');
begin
  FParser := ASQLParser;

  FCount := 0;
  SetLength(FIndex, 0);

  Text := AText;
end;

destructor TMySQLParser.TWordList.Destroy();
begin
  Clear();

  inherited;
end;

function TMySQLParser.TWordList.GetText(): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Length(FIndex) - 1 do
    if (I < Length(FIndex) - 1) then
      Result := Result + StrPas(FIndex[I]) + ','
    else
      Result := Result + StrPas(FIndex[I]);
end;

function TMySQLParser.TWordList.GetWord(Index: TWordList.TIndex): string;
begin
  Result := StrPas(FIndex[Index]);
end;

function TMySQLParser.TWordList.IndexOf(const Word: PChar; const Length: Integer): Integer;
var
  Comp: Integer;
  Left: Integer;
  I: Integer;
  Mid: Integer;
  Right: Integer;
  UpcaseWord: array [0..100] of Char;
begin
  Result := -1;

  for I := 0 to Length - 1 do
    UpcaseWord[I] := Upcase(Word[I]);

  if (Length <= System.Length(FFirst) - 2) then
  begin
    Left := FFirst[Length];
    Right := FFirst[Length + 1] - 1;
    while (Left <= Right) do
    begin
      Mid := (Right - Left) div 2 + Left;
      Comp := StrLComp(FIndex[Mid], @UpcaseWord, Length);
      if (Comp < 0) then
        Left := Mid + 1
      else if (Comp = 0) then
        begin Result := Mid; break; end
      else
        Right := Mid - 1;
    end;
  end;
end;

function TMySQLParser.TWordList.IndexOf(const Word: string): Integer;
begin
  Result := IndexOf(PChar(Word), Length(Word));
end;

procedure TMySQLParser.TWordList.SetText(AText: string);
var
  Counts: array of Integer;
  Words: array of array of PChar;

  function InsertIndex(const Word: PChar; const Len: Integer; out Index: Integer): Boolean;
  var
    Comp: Integer;
    Left: Integer;
    Mid: Integer;
    Right: Integer;
  begin
    Result := True;

    if ((Counts[Len] = 0) or (StrLComp(Word, Words[Len][Counts[Len] - 1], Len) > 0)) then
      Index := Counts[Len]
    else
    begin
      Left := 0;
      Right := Counts[Len] - 1;
      while (Left <= Right) do
      begin
        Mid := (Right - Left) div 2 + Left;
        Comp := StrLComp(Words[Len][Mid], Word, Len);
        if (Comp < 0) then
          begin Left := Mid + 1;  Index := Mid + 1; end
        else if (Comp = 0) then
          begin Result := False; Index := Mid; break; end
        else
          begin Right := Mid - 1; Index := Mid; end;
      end;
    end;
  end;

  procedure Add(const Word: PChar; const Len: Integer);
  var
    Index: Integer;
  begin
    if (InsertIndex(Word, Len, Index)) then
    begin
      Move(Words[Len][Index], Words[Len][Index + 1], (Counts[Len] - Index) * SizeOf(Words[Len][0]));
      Words[Len][Index] := Word;
      Inc(Counts[Len]);
    end;
  end;

var
  I: Integer;
  Index: Integer;
  J: Integer;
  Len: Integer;
  MaxLen: Integer;
  OldIndex: Integer;
begin
  Clear();

  if (AText <> '') then
  begin
    FText := UpperCase(ReplaceStr(AText, ',', #0)) + #0;

    OldIndex := 1; Index := 1; MaxLen := 0; FCount := 0;
    while (Index < Length(FText)) do
    begin
      while (FText[Index] <> #0) do Inc(Index);
      Len := Index - OldIndex;
      if (Len > MaxLen) then MaxLen := Len;
      Inc(FCount);
      Inc(Index); // Set over #0
      OldIndex := Index;
    end;

    SetLength(Words, MaxLen + 1);
    SetLength(Counts, MaxLen + 1);
    for I := 1 to MaxLen do
    begin
      Counts[I] := 0;
      SetLength(Words[I], FCount + 1);
      for J := 0 to FCount do
        Words[I][J] := #0;
    end;

    OldIndex := 1; Index := 1;
    while (Index < Length(FText)) do
    begin
      while (FText[Index] <> #0) do Inc(Index);
      Len := Index - OldIndex;
      Add(@FText[OldIndex], Len);
      Inc(Index); // Step over #0
      OldIndex := Index;
    end;

    FCount := 0;
    SetLength(FFirst, MaxLen + 1);
    for I := 1 to MaxLen do
    begin
      FFirst[I] := FCount;
      Inc(FCount, Counts[I]);
    end;

    SetLength(FIndex, FCount);
    Index := 0;
    for I := 1 to MaxLen do
      for J := 0 to Counts[I] - 1 do
      begin
        FIndex[Index] := Words[I][J];
        Inc(Index);
      end;

    // Clear helpers
    for I := 1 to MaxLen do
      SetLength(Words[I], 0);
    SetLength(Counts, 0);
    SetLength(Words, 0);
  end;
end;

{ TMySQLParser.TFormatHandle **************************************************}

constructor TMySQLParser.TFormatHandle.Create();
var
  S: string;
begin
  inherited Create(1024);

  Indent := 0;
  S := StringOfChar(' ', System.Length(IndentSpaces));
  Move(S[1], IndentSpaces, SizeOf(IndentSpaces));
end;

procedure TMySQLParser.TFormatHandle.DecreaseIndent();
begin
  Assert(Indent >= IndentSize);

  if (Indent >= IndentSize) then
    Dec(Indent, IndentSize);
end;

destructor TMySQLParser.TFormatHandle.Destroy();
begin
  inherited;
end;

procedure TMySQLParser.TFormatHandle.IncreaseIndent();
begin
  Inc(Indent, IndentSize);
end;

procedure TMySQLParser.TFormatHandle.WriteIndent();
begin
  Write(@IndentSpaces[0], Indent);
end;

procedure TMySQLParser.TFormatHandle.WriteReturn();
begin
  Write(#13#10);
  if (Indent > 0) then
    Write(@IndentSpaces[0], Indent);
end;

procedure TMySQLParser.TFormatHandle.WriteSpace();
begin
  Write(' ');
end;

{ TMySQLParser.TNode **********************************************************}

class function TMySQLParser.TNode.Create(const AParser: TMySQLParser; const ANodeType: TNodeType): TOffset;
begin
  Result := AParser.NewNode(ANodeType);

  with PNode(AParser.NodePtr(Result))^ do
  begin
    FNodeType := ANodeType;
    FParser := AParser;
  end;
end;

function TMySQLParser.TNode.GetOffset(): TOffset;
begin
  Result := @Self - Parser.ParsedNodes.Mem;
end;

{ TMySQLParser.TChild *********************************************************}

class function TMySQLParser.TChild.Create(const AParser: TMySQLParser; const ANodeType: TNodeType): TOffset;
begin
  Result := TNode.Create(AParser, ANodeType);

  with PChild(AParser.NodePtr(Result))^ do
  begin
    FParentNode := 0;
  end;
end;

function TMySQLParser.TChild.GetFFirstToken(): TOffset;
begin
  if (NodeType = ntToken) then
    Result := @Self - Parser.ParsedNodes.Mem
  else
  begin
    Assert(Parser.IsRange(@Self));
    Result := TMySQLParser.PRange(@Self).FFirstToken;
  end;
end;

function TMySQLParser.TChild.GetFirstToken(): PToken;
begin
  if (NodeType = ntToken) then
    Result := @Self
  else
  begin
    Assert(Parser.IsRange(@Self));
    Result := PRange(@Self).FirstToken;
  end;
end;

function TMySQLParser.TChild.GetFLastToken(): TOffset;
begin
  if (NodeType = ntToken) then
    Result := PNode(@Self)^.Offset
  else
  begin
    Assert(Parser.IsRange(@Self));
    Result := PRange(@Self)^.FLastToken;
  end;
end;

function TMySQLParser.TChild.GetLastToken(): PToken;
begin
  if (NodeType = ntToken) then
    Result := @Self
  else
  begin
    Assert(Parser.IsRange(@Self));

    Result := PRange(@Self)^.LastToken;
  end;
end;

function TMySQLParser.TChild.GetNextSibling(): PChild;
var
  Child: PChild;
  Token: PToken;
begin
  Assert(Parser.IsChild(@Self));

  Result := nil;
  if (PChild(@Self)^.ParentNode^.NodeType = ntList) then
  begin
    Token := PChild(@Self)^.LastToken^.NextToken;

    if (Assigned(Token) and (Token^.TokenType = PList(PChild(@Self)^.ParentNode)^.DelimiterType)) then
    begin
      Token := Token^.NextToken;

      if (Assigned(Token)) then
      begin
        Child := PChild(Token);

        while (Assigned(Child) and (Child^.ParentNode <> PChild(@Self)^.ParentNode)) do
          Child := PChild(Child^.ParentNode);

        Result := Child;
      end;
    end;
  end;
end;

function TMySQLParser.TChild.GetParentNode(): PNode;
begin
  Assert(FParentNode < Parser.ParsedNodes.UsedSize);

  Result := Parser.NodePtr(FParentNode);
end;

{ TMySQLParser.TToken *********************************************************}

class function TMySQLParser.TToken.Create(const AParser: TMySQLParser;
  const ASQL: PChar; const ALength: Integer;
  const AErrorCode: Integer; const AErrorPos: PChar;
  const ATokenType: fspTypes.TTokenType; const AOperatorType: TOperatorType;
  const AKeywordIndex: TWordList.TIndex; const AUsageType: TUsageType): TOffset;
begin
  Result := TChild.Create(AParser, ntToken);

  with PToken(AParser.NodePtr(Result))^ do
  begin
    FErrorCode := AErrorCode;
    FErrorPos := AErrorPos;
    {$IFDEF Debug}
    FIndex := 0;
    {$ENDIF}
    FKeywordIndex := AKeywordIndex;
    FOperatorType := AOperatorType;
    FLength := ALength;
    FNewSQL := 0;
    FSQL := ASQL;
    FTokenType := ATokenType;
    FUsageType := AUsageType;
  end;
end;

function TMySQLParser.TToken.GetAsString(): string;
begin
  case (TokenType) of
    ttLineComment:
      if (Copy(Text, 1, 1) = '#') then
        Result := Trim(Copy(Text, Length - 1, 1))
      else if (Copy(Text, 1, 2) = '--') then
        Result := Trim(Copy(Text, 3, Length - 2))
      else
        raise Exception.Create(SUnknownError);
    ttMultiLineComment:
      if ((Copy(Text, 1, 2) = '/*') and (Copy(Text, Length - 1, 2) = '*/')) then
        Result := Trim(Copy(Text, 3, Length - 4))
      else
        raise Exception.Create(SUnknownError);
    ttBeginLabel:
      if (Copy(Text, Length, 1) = ':') then
        Result := Trim(Copy(Text, 1, Length - 1))
      else
        Result := Text;
    ttBindVariable:
      if (Copy(Text, 1, 1) = ':') then
        Result := Trim(Copy(Text, 2, Length - 1))
      else
        Result := Text;
    ttString:
      Result := SQLUnescape(Text);
    ttDQIdent:
      Result := SQLUnescape(Text);
    ttDBIdent:
      if ((Copy(Text, 1, 1) = '[') and (Copy(Text, Length, 1) = ']')) then
        Result := Trim(Copy(Text, 1, Length - 2))
      else
        Result := Text;
    ttMySQLIdent:
      Result := SQLUnescape(Text);
    ttMySQLCodeStart:
      Result := Copy(Text, 1, Length - 3);
    ttCSString:
      Result := Copy(Text, 1, Length - 1);
    else
      Result := Text;
  end;
end;

function TMySQLParser.TToken.GetDbIdentType(): TDbIdentType;
begin
  if ((OperatorType = otDot)
    or not Assigned(Heritage.ParentNode)
    or (Heritage.ParentNode^.NodeType <> ntDbIdent)) then
    Result := ditUnknown
  else if (PDbIdent(Heritage.ParentNode)^.Nodes.DatabaseIdent = Offset) then
    Result := ditDatabase
  else if (PDbIdent(Heritage.ParentNode)^.Nodes.TableIdent = Offset) then
    Result := ditTable
  else
    Result := PDbIdent(Heritage.ParentNode)^.DbIdentType;
end;

function TMySQLParser.TToken.GetGeneration(): Integer;
var
  Node: PNode;
begin
  Result := 0;
  Node := ParentNode;
  while (Parser.IsChild(Node)) do
  begin
    Inc(Result);
    Node := PChild(Node)^.ParentNode;
  end;
end;

{$IFNDEF Debug}
function TMySQLParser.TToken.GetIndex(): Integer;
var
  Token: PToken;
begin
  Token := Parser.Root^.FirstToken;
  Result := 0;
  while (Assigned(Token) and (Token <> @Self)) do
  begin
    Inc(Result);
    Token := Token^.NextToken;
  end;
end;
{$ENDIF}

function TMySQLParser.TToken.GetIsUsed(): Boolean;
var
  I: Integer;
begin
  Result := not (TokenType in [ttSpace, ttReturn, ttLineComment, ttMultiLineComment, ttMySQLCodeStart, ttMySQLCodeEnd]);

  for I := 0 to System.Length(Parser.MySQLVersions) - 1 do
    Result := Result and (Parser.MySQLVersion >= Parser.MySQLVersions[I]);
end;

function TMySQLParser.TToken.GetNextToken(): PToken;
var
  Offset: TOffset;
begin
  Offset := PNode(@Self)^.Offset;
  repeat
    repeat
      Inc(Offset, Parser.NodeSize(Parser.NodePtr(Offset)^.NodeType));
    until ((Offset = Parser.ParsedNodes.UsedSize) or (Parser.NodePtr(Offset)^.NodeType = ntToken));
    if (Offset = Parser.ParsedNodes.UsedSize) then
      Result := nil
    else
      Result := PToken(Parser.NodePtr(Offset));
  until (not Assigned(Result) or Result^.IsUsed);
end;

function TMySQLParser.TToken.GetNextTokenAll(): PToken;
var
  Offset: TOffset;
begin
  Offset := PNode(@Self)^.Offset;
  repeat
    repeat
      Inc(Offset, Parser.NodeSize(Parser.NodePtr(Offset)^.NodeType));
    until ((Offset = Parser.ParsedNodes.UsedSize) or (Parser.NodePtr(Offset)^.NodeType = ntToken));
    if (Offset = Parser.ParsedNodes.UsedSize) then
      Result := nil
    else
      Result := PToken(Parser.NodePtr(Offset));
  until (not Assigned(Result) or Parser.IsToken(Offset));
end;

function TMySQLParser.TToken.GetOffset(): TOffset;
begin
  Result := Heritage.Heritage.GetOffset();
end;

function TMySQLParser.TToken.GetParentNode(): PNode;
begin
  Result := Heritage.GetParentNode();
end;

function TMySQLParser.TToken.GetSQL(): PChar;
begin
  if (FNewSQL > 0) then
    Result := Parser.GetText(FNewSQL)
  else
    Result := FSQL;
end;

function TMySQLParser.TToken.GetText(): string;
begin
  if (FNewSQL = 0) then
    SetString(Result, FSQL, FLength)
  else
    SetString(Result, Parser.GetText(FNewSQL), FLength);
end;

procedure TMySQLParser.TToken.SetText(AText: string);
begin
  FNewSQL := Parser.NewText(AText);
  FLength := System.Length(AText);
end;

{ TMySQLParser.TRange *********************************************************}

class function TMySQLParser.TRange.Create(const AParser: TMySQLParser; const ANodeType: TNodeType): TOffset;
begin
  Result := TChild.Create(AParser, ANodeType);

  with PRange(AParser.NodePtr(Result))^ do
  begin
    FFirstToken := 0;
    FLastToken := 0;
  end;
end;

function TMySQLParser.TRange.GetFirstToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FFirstToken));
end;

function TMySQLParser.TRange.GetLastToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FLastToken));
end;

function TMySQLParser.TRange.GetOffset(): TOffset;
begin
  Result := Heritage.Heritage.Offset;
end;

function TMySQLParser.TRange.GetParentNode(): PNode;
begin
  Result := PNode(Parser.NodePtr(FParentNode));
end;

procedure TMySQLParser.TRange.AddChild(const AChild: TOffset);
var
  Child: PChild;
begin
  Assert(AChild < Parser.ParsedNodes.UsedSize);

  if (AChild > 0) then
  begin
    Child := Parser.ChildPtr(AChild);
    Child^.FParentNode := Offset;

    if ((FFirstToken = 0) or (0 < Child^.FFirstToken) and (Child^.FFirstToken < FFirstToken)) then
      FFirstToken := Child^.FFirstToken;
    if ((FLastToken = 0) or (0 < Child^.FLastToken) and (Child^.FLastToken > FLastToken)) then
      FLastToken := Child^.FLastToken;
  end;
end;

{ TMySQLParser.TRoot **********************************************************}

procedure TMySQLParser.TRoot.AddStmt(const AStmt: TOffset);
var
  Child: PChild;
begin
  Assert(Parser.IsStmt(AStmt) and (0 < AStmt) and (AStmt < Parser.ParsedNodes.UsedSize));

  if (AStmt > 0) then
  begin
    Child := Parser.ChildPtr(AStmt);

    Child^.FParentNode := Offset;

    if ((FFirstStmt = 0) or (AStmt < FFirstStmt)) then
      FFirstStmt := AStmt;
    if ((FLastStmt = 0) or (AStmt > FLastStmt)) then
      FLastStmt := AStmt;

    if ((FFirstToken = 0) or (Child^.FFirstToken < FFirstToken)) then
      FFirstToken := Child^.FFirstToken;
    if ((FLastToken = 0) or (Child^.FLastToken > FLastToken)) then
      FLastToken := Child^.FLastToken;
  end;
end;

class function TMySQLParser.TRoot.Create(const AParser: TMySQLParser;
  const AFirstTokenAll, ALastTokenAll: TOffset;
  const StmtCount: Integer; const Stmts: array of TOffset): TOffset;
var
  I: Integer;
begin
  Result := TNode.Create(AParser, ntRoot);

  with PRoot(AParser.NodePtr(Result))^ do
  begin
    if (StmtCount = 0) then
    begin
      FFirstStmt := 0;
      FFirstToken := 0;
      FFirstTokenAll := 0;
      FLastStmt := 0;
      FLastToken := 0;
      FLastTokenAll := 0;
    end
    else
    begin
      FFirstStmt := Stmts[0];
      FFirstToken := AParser.StmtPtr(Stmts[0])^.FFirstToken;
      FFirstTokenAll := AFirstTokenAll;
      FLastStmt := Stmts[StmtCount - 1];
      FLastToken := AParser.StmtPtr(Stmts[StmtCount - 1])^.FLastToken;
      FLastTokenAll := ALastTokenAll;

      for I := 0 to StmtCount - 1 do
        AddStmt(Stmts[I]);
    end;
  end;
end;

function TMySQLParser.TRoot.GetFirstStmt(): PStmt;
begin
  Result := PStmt(Parser.NodePtr(FFirstStmt));
end;

function TMySQLParser.TRoot.GetFirstToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FFirstToken));
end;

function TMySQLParser.TRoot.GetFirstTokenAll(): PToken;
begin
  Result := PToken(Parser.NodePtr(FFirstTokenAll));
end;

function TMySQLParser.TRoot.GetLastStmt(): PStmt;
begin
  Result := PStmt(Parser.NodePtr(FLastStmt));
end;

function TMySQLParser.TRoot.GetLastToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FLastToken));
end;

function TMySQLParser.TRoot.GetLastTokenAll(): PToken;
begin
  Result := PToken(Parser.NodePtr(FLastTokenAll));
end;

function TMySQLParser.TRoot.GetOffset(): TOffset;
begin
  Result := @Self - Parser.ParsedNodes.Mem;
end;

{ TMySQLParser.TStmt **********************************************************}

class function TMySQLParser.TStmt.Create(const AParser: TMySQLParser; const AStmtType: TStmtType): TOffset;
begin
  Result := TRange.Create(AParser, NodeTypeByStmtType[AStmtType]);

  with PStmt(AParser.NodePtr(Result))^ do
  begin
    FStmtType := AStmtType;
    FErrorCode := PE_Success;
    FErrorToken := 0;
    FFirstTokenAll := 0;
    FLastTokenAll := 0;
  end;
end;

function TMySQLParser.TStmt.GetErrorMessage(): string;
begin
  case (FErrorCode) of
    PE_UnexpectedChar:
      Result := 'Unexpected character near ''' + LeftStr(Parser.TokenPtr(FErrorToken)^.ErrorPos, 8) + ''''
        + ' in line ' + IntToStr(Parser.FErrorLine);
    PE_UnexpectedToken:
      Result := 'Unexpected character near ''' + LeftStr(Parser.TokenPtr(FErrorToken)^.Text, 8) + ''''
        + ' in line ' + IntToStr(Parser.FErrorLine);
    PE_ExtraToken:
      Result := 'Unexpected character near ''' + LeftStr(Parser.TokenPtr(FErrorToken)^.Text, 8) + ''''
        + ' in line ' + IntToStr(Parser.FErrorLine);
    else Result := Parser.GetErrorMessage(FErrorCode);
  end;
end;

function TMySQLParser.TStmt.GetErrorToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FErrorToken));
end;

function TMySQLParser.TStmt.GetFirstToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FFirstToken));
end;

function TMySQLParser.TStmt.GetFirstTokenAll(): PToken;
begin
  Result := PToken(Parser.NodePtr(FFirstTokenAll));
end;

function TMySQLParser.TStmt.GetLastToken(): PToken;
begin
  Result := PToken(Parser.NodePtr(FLastToken));
end;

function TMySQLParser.TStmt.GetLastTokenAll(): PToken;
begin
  Result := PToken(Parser.NodePtr(FLastTokenAll));
end;

function TMySQLParser.TStmt.GetNextStmt(): PStmt;
var
  Token: PToken;
  Child: PChild;
begin
  if (Heritage.FParentNode <> Parser.FRoot) then
    Result := nil
  else
  begin
    Token := Parser.TokenPtr(FLastTokenAll);
    while (Assigned(Token) and (Token^.TokenType <> ttDelimiter)) do
      Token := Token^.NextToken;
    while (Assigned(Token) and (Token^.TokenType = ttDelimiter)) do
      Token := Token^.NextToken;

    Child := PChild(Token);
    while (Assigned(Child) and (Child^.FParentNode <> Parser.FRoot)) do
      Child := PChild(Child^.ParentNode);

    if (not Assigned(Child)) then
      Result := nil
    else
      Result := PStmt(Child);
  end;
end;

function TMySQLParser.TStmt.GetText(): string;
var
  StringBuffer: TStringBuffer;
  Token: PToken;
begin
  StringBuffer := TStringBuffer.Create(1024);

  Token := Parser.TokenPtr(FFirstTokenAll);
  while (Assigned(Token)) do
  begin
    StringBuffer.Write(Token^.SQL, Token^.Length);

    if (Token = Parser.TokenPtr(FLastTokenAll)) then
      Token := nil
    else
      Token := Token^.NextTokenAll;
  end;

  Result := StringBuffer.Read();

  StringBuffer.Free();
end;

function TMySQLParser.TStmt.GetParentNode(): PNode;
begin
  Result := PNode(Heritage.ParentNode);
end;

{ TMySQLParser.TAnalyzeStmt ***************************************************}

class function TMySQLParser.TAnalyzeStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stAnalyze);

  with PAnalyzeStmt(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.NoWriteToBinlogTag);
    Heritage.Heritage.AddChild(ANodes.TableTag);
    Heritage.Heritage.AddChild(ANodes.TablesList);
  end;
end;

{ TMySQLParser.TAlterDatabase *************************************************}

class function TMySQLParser.TAlterDatabaseStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stAlterDatabase);

  with PAlterDatabaseStmt(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IdentTag);
    Heritage.Heritage.AddChild(ANodes.CharacterSetValue);
    Heritage.Heritage.AddChild(ANodes.CollateValue);
    Heritage.Heritage.AddChild(ANodes.UpgradeDataDirectoryNameTag);
  end;
end;

{ TMySQLParser.TAlterEvent ****************************************************}

class function TMySQLParser.TAlterEventStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stAlterEvent);

  with PAlterEventStmt(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.AlterTag);
    Heritage.Heritage.AddChild(ANodes.DefinerNode);
    Heritage.Heritage.AddChild(ANodes.EventTag);
    Heritage.Heritage.AddChild(ANodes.EventIdent);
    Heritage.Heritage.AddChild(ANodes.OnSchedule.Tag);
    Heritage.Heritage.AddChild(ANodes.OnSchedule.Value);
    Heritage.Heritage.AddChild(ANodes.OnCompletitionTag);
    Heritage.Heritage.AddChild(ANodes.RenameValue);
    Heritage.Heritage.AddChild(ANodes.EnableTag);
    Heritage.Heritage.AddChild(ANodes.CommentValue);
    Heritage.Heritage.AddChild(ANodes.DoTag);
    Heritage.Heritage.AddChild(ANodes.Body);
  end;
end;

{ TMySQLParser.TAlterRoutine **************************************************}

class function TMySQLParser.TAlterInstanceStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stAlterInstance);

  with PAlterInstanceStmt(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.RotateTag);
  end;
end;

{ TMySQLParser.TAlterRoutine **************************************************}

class function TMySQLParser.TAlterRoutineStmt.Create(const AParser: TMySQLParser; const ARoutineType: TRoutineType; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stAlterRoutine);

  with PAlterRoutineStmt(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;
    FRoutineType := ARoutineType;

    Heritage.Heritage.AddChild(ANodes.AlterTag);
    Heritage.Heritage.AddChild(ANodes.IdentNode);
    Heritage.Heritage.AddChild(ANodes.CharacteristicList);
  end;
end;

{ TMySQLParser.TAlterServerStmt ***********************************************}

class function TMySQLParser.TAlterServerStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stAlterServer);

  with PAlterServerStmt(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IdentNode);
    Heritage.Heritage.AddChild(ANodes.Options.Tag);
    Heritage.Heritage.AddChild(ANodes.Options.List);
  end;
end;

{ TMySQLParser.TAlterTableStmt.TAlterColumn ***********************************}

class function TMySQLParser.TAlterTableStmt.TAlterColumn.Create(const AParser: TMySQLParser; const ANodes: TAlterColumn.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntAlterTableStmtAlterColumn);

  with PAlterColumn(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.AddChild(ANodes.AlterTag);
    Heritage.AddChild(ANodes.ColumnIdent);
    Heritage.AddChild(ANodes.SetDefaultValue);
    Heritage.AddChild(ANodes.DropDefaultTag);
  end;
end;

{ TMySQLParser.TAlterTableStmt.TConvertTo *************************************}

class function TMySQLParser.TAlterTableStmt.TConvertTo.Create(const AParser: TMySQLParser; const ANodes: TConvertTo.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntAlterTableStmtConvertTo);

  with PConvertTo(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.AddChild(ANodes.ConvertToTag);
    Heritage.AddChild(ANodes.CharacterSetValue);
    Heritage.AddChild(ANodes.CollateValue);
  end;
end;

{ TMySQLParser.TAlterTableStmt.TDropObject ************************************}

class function TMySQLParser.TAlterTableStmt.TDropObject.Create(const AParser: TMySQLParser; const ANodes: TDropObject.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntAlterTableStmtDropObject);

  with PDropObject(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.AddChild(ANodes.DropTag);
    Heritage.AddChild(ANodes.ItemTypeTag);
    Heritage.AddChild(ANodes.Ident);
  end;
end;

{ TMySQLParser.TAlterTableStmt.TExchangePartition *****************************}

class function TMySQLParser.TAlterTableStmt.TExchangePartition.Create(const AParser: TMySQLParser; const ANodes: TExchangePartition.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntAlterTableStmtExchangePartition);

  with PExchangePartition(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.ExchangePartitionTag);
    Heritage.AddChild(ANodes.PartitionIdent);
    Heritage.AddChild(ANodes.WithTableTag);
    Heritage.AddChild(ANodes.TableIdent);
  end;
end;

{ TMySQLParser.TAlterTableStmt.TReorganizePartition ***************************}

class function TMySQLParser.TAlterTableStmt.TReorganizePartition.Create(const AParser: TMySQLParser; const ANodes: TReorganizePartition.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntAlterTableStmtReorganizePartition);

  with PReorganizePartition(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.ReorganizePartitionTag);
    Heritage.AddChild(ANodes.PartitionIdentList);
    Heritage.AddChild(ANodes.IntoTag);
    Heritage.AddChild(ANodes.PartitionList);
  end;
end;

{ TMySQLParser.TAlterTableStmt ************************************************}

class function TMySQLParser.TAlterTableStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stAlterTable);

  with PAlterTableStmt(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.AlterTag);
    Heritage.Heritage.AddChild(ANodes.IgnoreTag);
    Heritage.Heritage.AddChild(ANodes.TableTag);
    Heritage.Heritage.AddChild(ANodes.IdentNode);
    Heritage.Heritage.AddChild(ANodes.SpecificationList);
    Heritage.Heritage.AddChild(ANodes.AlgorithmValue);
    Heritage.Heritage.AddChild(ANodes.ConvertToCharacterSetNode);
    Heritage.Heritage.AddChild(ANodes.ConvertToCharacterSetNode);
    Heritage.Heritage.AddChild(ANodes.DiscardTablespaceTag);
    Heritage.Heritage.AddChild(ANodes.EnableKeys);
    Heritage.Heritage.AddChild(ANodes.ForceTag);
    Heritage.Heritage.AddChild(ANodes.ImportTablespaceTag);
    Heritage.Heritage.AddChild(ANodes.LockValue);
    Heritage.Heritage.AddChild(ANodes.OrderByValue);
    Heritage.Heritage.AddChild(ANodes.RenameNode);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.AutoIncrementValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.AvgRowLengthValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.CharacterSetValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.CollateValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.CommentValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.ConnectionValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.DataDirectoryValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.DelayKeyWriteValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.EngineValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.IndexDirectoryValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.InsertMethodValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.KeyBlockSizeValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.MaxRowsValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.MinRowsValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.PackKeysValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.PageChecksum);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.PasswordValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.RowFormatValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.StatsAutoRecalcValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.StatsPersistentValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.UnionList);
  end;
end;

{ TMySQLParser.TAlterViewStmt *************************************************}

class function TMySQLParser.TAlterViewStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stAlterView);

  with PAlterViewStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.AlterTag);
    Heritage.Heritage.AddChild(ANodes.AlgorithmValue);
    Heritage.Heritage.AddChild(ANodes.DefinerNode);
    Heritage.Heritage.AddChild(ANodes.SQLSecurityTag);
    Heritage.Heritage.AddChild(ANodes.ViewTag);
    Heritage.Heritage.AddChild(ANodes.IdentNode);
    Heritage.Heritage.AddChild(ANodes.Columns);
    Heritage.Heritage.AddChild(ANodes.AsTag);
    Heritage.Heritage.AddChild(ANodes.SelectStmt);
    Heritage.Heritage.AddChild(ANodes.OptionTag);
  end;
end;

{ TMySQLParser.TBeginStmt *****************************************************}

class function TMySQLParser.TBeginStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stBegin);

  with PBeginStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.BeginTag);
  end;
end;

{ TMySQLParser.TBinaryOp ******************************************************}

class function TMySQLParser.TBinaryOp.Create(const AParser: TMySQLParser; const AOperator, AOperand1, AOperand2: TOffset): TOffset;
begin
  Result := TRange.Create(AParser, ntBinaryOp);

  with PBinaryOp(AParser.NodePtr(Result))^ do
  begin
    FNodes.OperatorToken := AOperator;
    FNodes.Operand1 := AOperand1;
    FNodes.Operand2 := AOperand2;

    Heritage.AddChild(AOperator);
    Heritage.AddChild(AOperand1);
    Heritage.AddChild(AOperand2);
  end;
end;

function TMySQLParser.TBinaryOp.GetOperand1(): PChild;
begin
  Result := Parser.ChildPtr(FNodes.Operand1);
end;

function TMySQLParser.TBinaryOp.GetOperand2(): PChild;
begin
  Result := Parser.ChildPtr(FNodes.Operand2);
end;

function TMySQLParser.TBinaryOp.GetOperator(): PChild;
begin
  Result := Parser.ChildPtr(FNodes.OperatorToken);
end;

{ TMySQLParser.TBetweenOp *****************************************************}

class function TMySQLParser.TBetweenOp.Create(const AParser: TMySQLParser; const AOperator1, AOperator2, AExpr, AMin, AMax: TOffset): TOffset;
begin
  Result := TRange.Create(AParser, ntBetweenOp);

  with PBetweenOp(AParser.NodePtr(Result))^ do
  begin
    FNodes.Operator1 := AOperator1;
    FNodes.Operator2 := AOperator2;
    FNodes.Expr := AExpr;
    FNodes.Min := AMin;
    FNodes.Max := AMax;

    Heritage.AddChild(AOperator1);
    Heritage.AddChild(AOperator2);
    Heritage.AddChild(AExpr);
    Heritage.AddChild(AMin);
    Heritage.AddChild(AMax);
  end;
end;

{ TMySQLParser.TCallStmt ******************************************************}

class function TMySQLParser.TCallStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCall);

  with PCallStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CallTag);
    Heritage.Heritage.AddChild(ANodes.ProcedureIdent);
    Heritage.Heritage.AddChild(ANodes.ParamList);
  end;
end;

{ TMySQLParser.TCaseOp.TBranch ************************************************}

class function TMySQLParser.TCaseOp.TBranch.Create(const AParser: TMySQLParser; const ANodes: TBranch.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCaseOpBranch);

  with PBranch(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.WhenTag);
    Heritage.AddChild(ANodes.CondExpr);
    Heritage.AddChild(ANodes.ThenTag);
    Heritage.AddChild(ANodes.ResultExpr);
  end;
end;

{ TMySQLParser.TCaseOp ********************************************************}

class function TMySQLParser.TCaseOp.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCaseOp);

  with PCaseOp(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.CaseTag);
    Heritage.AddChild(ANodes.CompareExpr);
    Heritage.AddChild(ANodes.BranchList);
    Heritage.AddChild(ANodes.ElseTag);
    Heritage.AddChild(ANodes.ElseExpr);
    Heritage.AddChild(ANodes.EndTag);
  end;
end;

{ TMySQLParser.TCaseStmt.TBranch **********************************************}

class function TMySQLParser.TCaseStmt.TBranch.Create(const AParser: TMySQLParser; const ANodes: TBranch.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCaseStmtBranch);

  with PBranch(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Tag);
    Heritage.AddChild(ANodes.ConditionExpr);
    Heritage.AddChild(ANodes.ThenTag);
    Heritage.AddChild(ANodes.StmtList);
  end;
end;

{ TMySQLParser.TCaseStmt ******************************************************}

class function TMySQLParser.TCaseStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCase);

  with PCaseStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.BranchList);
    Heritage.Heritage.AddChild(ANodes.EndTag);
  end;
end;

{ TMySQLParser.TCastFunc ******************************************************}

class function TMySQLParser.TCastFunc.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCastFunc);

  with PCastFunc(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.FuncToken);
    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.Expr);
    Heritage.AddChild(ANodes.AsTag);
    Heritage.AddChild(ANodes.DataType);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TCharFunc ******************************************************}

class function TMySQLParser.TCharFunc.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCharFunc);

  with PCharFunc(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.FuncToken);
    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.ValueList);
    Heritage.AddChild(ANodes.UsingTag);
    Heritage.AddChild(ANodes.CharsetIdent);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TCheckStmt *****************************************************}

class function TMySQLParser.TCheckStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCheck);

  with PCheckStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.TablesList);
    Heritage.Heritage.AddChild(ANodes.OptionList);
  end;
end;

{ TMySQLParser.TCheckStmt.TOption *********************************************}

class function TMySQLParser.TCheckStmt.TOption.Create(const AParser: TMySQLParser; const ANodes: TOption.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCheckStmtOption);

  with POption(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.OptionTag);
  end;
end;

{ TMySQLParser.TChecksumStmt **************************************************}

class function TMySQLParser.TChecksumStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stChecksum);

  with PChecksumStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.TablesList);
    Heritage.Heritage.AddChild(ANodes.OptionTag);
  end;
end;

{ TMySQLParser.TCloseStmt *****************************************************}

class function TMySQLParser.TCloseStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stClose);

  with PCloseStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CloseTag);
    Heritage.Heritage.AddChild(ANodes.CursorIdent);
  end;
end;

{ TMySQLParser.TCommitStmt ****************************************************}

class function TMySQLParser.TCommitStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCommit);

  with PCommitStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CommitTag);
    Heritage.Heritage.AddChild(ANodes.ChainTag);
    Heritage.Heritage.AddChild(ANodes.ReleaseTag);
  end;
end;

{ TMySQLParser.TCompoundStmt **************************************************}

class function TMySQLParser.TCompoundStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCompound);

  with PCompoundStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.BeginLabelToken);
    Heritage.Heritage.AddChild(ANodes.BeginTag);
    Heritage.Heritage.AddChild(ANodes.StmtList);
    Heritage.Heritage.AddChild(ANodes.EndTag);
    Heritage.Heritage.AddChild(ANodes.EndLabelToken);
  end;
end;

{ TMySQLParser.TConvertFunc ******************************************************}

class function TMySQLParser.TConvertFunc.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntConvertFunc);

  with PConvertFunc(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.FuncToken);
    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.Expr);
    Heritage.AddChild(ANodes.Comma);
    Heritage.AddChild(ANodes.DataType);
    Heritage.AddChild(ANodes.UsingTag);
    Heritage.AddChild(ANodes.CharsetIdent);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TCreateDatabaseStmt ********************************************}

class function TMySQLParser.TCreateDatabaseStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCreateDatabase);

  with PCreateDatabaseStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CreateTag);
    Heritage.Heritage.AddChild(ANodes.DatabaseTag);
    Heritage.Heritage.AddChild(ANodes.IfNotExistsTag);
    Heritage.Heritage.AddChild(ANodes.DatabaseIdent);
    Heritage.Heritage.AddChild(ANodes.CharacterSetValue);
    Heritage.Heritage.AddChild(ANodes.CollateValue);
  end;
end;

{ TMySQLParser.TCreateEventStmt ***********************************************}

class function TMySQLParser.TCreateEventStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCreateEvent);

  with PCreateEventStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CreateTag);
    Heritage.Heritage.AddChild(ANodes.DefinerNode);
    Heritage.Heritage.AddChild(ANodes.EventTag);
    Heritage.Heritage.AddChild(ANodes.IfNotExistsTag);
    Heritage.Heritage.AddChild(ANodes.EventIdent);
    Heritage.Heritage.AddChild(ANodes.OnScheduleValue);
    Heritage.Heritage.AddChild(ANodes.OnCompletitionTag);
    Heritage.Heritage.AddChild(ANodes.EnableTag);
    Heritage.Heritage.AddChild(ANodes.CommentValue);
    Heritage.Heritage.AddChild(ANodes.DoTag);
    Heritage.Heritage.AddChild(ANodes.Body);
  end;
end;

{ TMySQLParser.TCreateIndexStmt ***********************************************}

class function TMySQLParser.TCreateIndexStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCreateIndex);

  with PCreateIndexStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CreateTag);
    Heritage.Heritage.AddChild(ANodes.IndexTag);
    Heritage.Heritage.AddChild(ANodes.IndexIdent);
    Heritage.Heritage.AddChild(ANodes.OnTag);
    Heritage.Heritage.AddChild(ANodes.TableIdent);
    Heritage.Heritage.AddChild(ANodes.IndexTypeValue);
    Heritage.Heritage.AddChild(ANodes.KeyColumnList);
    Heritage.Heritage.AddChild(ANodes.AlgorithmValue);
    Heritage.Heritage.AddChild(ANodes.CommentValue);
    Heritage.Heritage.AddChild(ANodes.KeyBlockSizeValue);
    Heritage.Heritage.AddChild(ANodes.LockValue);
    Heritage.Heritage.AddChild(ANodes.ParserValue);
  end;
end;

{ TMySQLParser.TCreateRoutineStmt *********************************************}

class function TMySQLParser.TCreateRoutineStmt.Create(const AParser: TMySQLParser; const ARoutineType: TRoutineType; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCreateRoutine);

  with PCreateRoutineStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;
    FRoutineType := ARoutineType;

    Heritage.Heritage.AddChild(ANodes.CreateTag);
    Heritage.Heritage.AddChild(ANodes.DefinerNode);
    Heritage.Heritage.AddChild(ANodes.RoutineTag);
    Heritage.Heritage.AddChild(ANodes.IdentNode);
    Heritage.Heritage.AddChild(ANodes.ParameterList);
    Heritage.Heritage.AddChild(ANodes.Returns);
    Heritage.Heritage.AddChild(ANodes.CharacteristicList);
    Heritage.Heritage.AddChild(ANodes.Body);
  end;
end;

{ TMySQLParser.TCreateServerStmt **********************************************}

class function TMySQLParser.TCreateServerStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCreateServer);

  with PCreateServerStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CreateTag);
    Heritage.Heritage.AddChild(ANodes.ServerTag);
    Heritage.Heritage.AddChild(ANodes.ServerIdent);
    Heritage.Heritage.AddChild(ANodes.ForeignDataWrapperValue);
    Heritage.Heritage.AddChild(ANodes.Options.Tag);
    Heritage.Heritage.AddChild(ANodes.Options.List);
  end;
end;

{ TMySQLParser.TCreateTableStmt ***********************************************}

class function TMySQLParser.TCreateTableStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCreateTable);

  with PCreateTableStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CreateTag);
    Heritage.Heritage.AddChild(ANodes.TemporaryTag);
    Heritage.Heritage.AddChild(ANodes.TableTag);
    Heritage.Heritage.AddChild(ANodes.IfNotExistsTag);
    Heritage.Heritage.AddChild(ANodes.TableIdent);
    Heritage.Heritage.AddChild(ANodes.OpenBracketToken);
    Heritage.Heritage.AddChild(ANodes.DefinitionList);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.AutoIncrementValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.AvgRowLengthValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.CharacterSetValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.ChecksumValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.CollateValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.CommentValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.ConnectionValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.DataDirectoryValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.DelayKeyWriteValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.EngineValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.IndexDirectoryValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.InsertMethodValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.KeyBlockSizeValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.MaxRowsValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.MinRowsValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.PackKeysValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.PageChecksum);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.PasswordValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.RowFormatValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.StatsAutoRecalcValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.StatsPersistentValue);
    Heritage.Heritage.AddChild(ANodes.TableOptionsNodes.UnionList);
    Heritage.Heritage.AddChild(ANodes.TableOptionList);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.PartitionByTag);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.PartitionKindTag);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.PartitionAlgorithmValue);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.PartitionExpr);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.PartitionColumnsTag);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.PartitionColumnList);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.PartitionsValue);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.SubPartitionByTag);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.SubPartitionKindTag);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.SubPartitionAlgorithmValue);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.SubPartitionExprList);
    Heritage.Heritage.AddChild(ANodes.PartitionOption.SubPartitionsValue);
    Heritage.Heritage.AddChild(ANodes.PartitionDefinitionList);
    Heritage.Heritage.AddChild(ANodes.LikeTag);
    Heritage.Heritage.AddChild(ANodes.LikeTableIdent);
    Heritage.Heritage.AddChild(ANodes.CloseBracketToken);
    Heritage.Heritage.AddChild(ANodes.IgnoreReplaceTag);
    Heritage.Heritage.AddChild(ANodes.AsTag);
    Heritage.Heritage.AddChild(ANodes.SelectStmt);
  end;
end;

{ TMySQLParser.TCreateTableStmt.TColumn ***************************************}

class function TMySQLParser.TCreateTableStmt.TColumn.Create(const AParser: TMySQLParser; const ANodes: TColumn.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCreateTableStmtColumn);

  with PColumn(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.AddChild(ANodes.AddTag);
    Heritage.AddChild(ANodes.ColumnTag);
    Heritage.AddChild(ANodes.OldNameIdent);
    Heritage.AddChild(ANodes.NameIdent);
    Heritage.AddChild(ANodes.DataTypeNode);
    Heritage.AddChild(ANodes.BinaryTag);
    Heritage.AddChild(ANodes.Null);
    Heritage.AddChild(ANodes.DefaultValue);
    Heritage.AddChild(ANodes.OnUpdateTag);
    Heritage.AddChild(ANodes.AutoIncrementTag);
    Heritage.AddChild(ANodes.KeyTag);
    Heritage.AddChild(ANodes.CommentValue);
    Heritage.AddChild(ANodes.ColumnFormat);
    Heritage.AddChild(ANodes.Position);
  end;
end;

{ TMySQLParser.TCreateTableStmt.TForeignKey ***********************************}

class function TMySQLParser.TCreateTableStmt.TForeignKey.Create(const AParser: TMySQLParser; const ANodes: TForeignKey.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCreateTableStmtForeignKey);

  with PForeignKey(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.AddTag);
    Heritage.AddChild(ANodes.ConstraintTag);
    Heritage.AddChild(ANodes.SymbolIdent);
    Heritage.AddChild(ANodes.ForeignKeyTag);
    Heritage.AddChild(ANodes.NameIdent);
    Heritage.AddChild(ANodes.ColumnNameList);
    Heritage.AddChild(ANodes.ReferencesTag);
    Heritage.AddChild(ANodes.ParentTableIdent);
    Heritage.AddChild(ANodes.IndicesList);
    Heritage.AddChild(ANodes.MatchValue);
    Heritage.AddChild(ANodes.OnDeleteValue);
    Heritage.AddChild(ANodes.OnUpdateValue);
  end;
end;

{ TMySQLParser.TCreateTableStmt.TKey ******************************************}

class function TMySQLParser.TCreateTableStmt.TKey.Create(const AParser: TMySQLParser; const ANodes: TKey.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCreateTableStmtKey);

  with PKey(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.AddChild(ANodes.AddTag);
    Heritage.AddChild(ANodes.ConstraintTag);
    Heritage.AddChild(ANodes.SymbolIdent);
    Heritage.AddChild(ANodes.KeyTag);
    Heritage.AddChild(ANodes.KeyIdent);
    Heritage.AddChild(ANodes.ColumnIdentList);
    Heritage.AddChild(ANodes.KeyBlockSizeValue);
    Heritage.AddChild(ANodes.IndexTypeTag);
    Heritage.AddChild(ANodes.ParserValue);
    Heritage.AddChild(ANodes.CommentValue);
  end;
end;

{ TMySQLParser.TCreateTableStmt.TKeyColumn ************************************}

class function TMySQLParser.TCreateTableStmt.TKeyColumn.Create(const AParser: TMySQLParser; const ANodes: TKeyColumn.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCreateTableStmtKeyColumn);

  with PKeyColumn(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.AddChild(ANodes.IdentTag);
    Heritage.AddChild(ANodes.OpenBracketToken);
    Heritage.AddChild(ANodes.LengthToken);
    Heritage.AddChild(ANodes.CloseBracketToken);
    Heritage.AddChild(ANodes.SortTag);
  end;
end;

{ TMySQLParser.TCreateTableStmt.TPartition ************************************}

class function TMySQLParser.TCreateTableStmt.TPartition.Create(const AParser: TMySQLParser; const ANodes: TPartition.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCreateTableStmtPartition);

  with PPartition(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.AddTag);
    Heritage.AddChild(ANodes.PartitionTag);
    Heritage.AddChild(ANodes.NameIdent);
    Heritage.AddChild(ANodes.ValuesNode);
    Heritage.AddChild(ANodes.EngineValue);
    Heritage.AddChild(ANodes.CommentValue);
    Heritage.AddChild(ANodes.DataDirectoryValue);
    Heritage.AddChild(ANodes.IndexDirectoryValue);
    Heritage.AddChild(ANodes.MaxRowsValue);
    Heritage.AddChild(ANodes.MinRowsValue);
    Heritage.AddChild(ANodes.SubPartitionList);
  end;
end;

{ TMySQLParser.TCreateTableStmt.TPartitionValues ******************************}

class function TMySQLParser.TCreateTableStmt.TPartitionValues.Create(const AParser: TMySQLParser; const ANodes: TPartitionValues.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCreateTableStmtPartitionValues);

  with PPartitionValues(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.ValuesTag);
    Heritage.AddChild(ANodes.DescriptionValue);
  end;
end;

{ TMySQLParser.TCreateTriggerStmt *********************************************}

class function TMySQLParser.TCreateTriggerStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCreateTrigger);

  with PCreateTriggerStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CreateTag);
    Heritage.Heritage.AddChild(ANodes.DefinerNode);
    Heritage.Heritage.AddChild(ANodes.TriggerTag);
    Heritage.Heritage.AddChild(ANodes.TriggerIdent);
    Heritage.Heritage.AddChild(ANodes.ActionValue);
    Heritage.Heritage.AddChild(ANodes.OnTag);
    Heritage.Heritage.AddChild(ANodes.TableIdentNode);
    Heritage.Heritage.AddChild(ANodes.ForEachRowTag);
    Heritage.Heritage.AddChild(ANodes.Body);
  end;
end;

{ TMySQLParser.TCreateUserStmt ************************************************}

class function TMySQLParser.TCreateUserStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCreateUser);

  with PCreateUserStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CreateTag);
    Heritage.Heritage.AddChild(ANodes.IfTag);
    Heritage.Heritage.AddChild(ANodes.UserSpecifications);
    Heritage.Heritage.AddChild(ANodes.WithTag);
    Heritage.Heritage.AddChild(ANodes.ResourcesList);
    Heritage.Heritage.AddChild(ANodes.PasswordOption);
    Heritage.Heritage.AddChild(ANodes.PasswordDays);
    Heritage.Heritage.AddChild(ANodes.DayTag);
    Heritage.Heritage.AddChild(ANodes.AccountTag);
  end;
end;

{ TMySQLParser.TCreateViewStmt ************************************************}

class function TMySQLParser.TCreateViewStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stCreateView);

  with PCreateViewStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.CreateTag);
    Heritage.Heritage.AddChild(ANodes.OrReplaceTag);
    Heritage.Heritage.AddChild(ANodes.AlgorithmValue);
    Heritage.Heritage.AddChild(ANodes.DefinerNode);
    Heritage.Heritage.AddChild(ANodes.SQLSecurityTag);
    Heritage.Heritage.AddChild(ANodes.ViewTag);
    Heritage.Heritage.AddChild(ANodes.IdentNode);
    Heritage.Heritage.AddChild(ANodes.Columns);
    Heritage.Heritage.AddChild(ANodes.AsTag);
    Heritage.Heritage.AddChild(ANodes.SelectStmt);
    Heritage.Heritage.AddChild(ANodes.OptionTag);
  end;
end;

{ TMySQLParser.TCurrentTimestamp **********************************************}

class function TMySQLParser.TCurrentTimestamp.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntCurrentTimestamp);

  with PCurrentTimestamp(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.CurrentTimestampTag);
    Heritage.AddChild(ANodes.OpenBracketToken);
    Heritage.AddChild(ANodes.LengthInteger);
    Heritage.AddChild(ANodes.CloseBracketToken);
  end;
end;

{ TMySQLParser.TDataType ******************************************************}

class function TMySQLParser.TDataType.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntDataType);

  with PDataType(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.AddChild(ANodes.NationalTag);
    Heritage.AddChild(ANodes.IdentToken);
    Heritage.AddChild(ANodes.OpenBracketToken);
    Heritage.AddChild(ANodes.LengthToken);
    Heritage.AddChild(ANodes.CommaToken);
    Heritage.AddChild(ANodes.DecimalsToken);
    Heritage.AddChild(ANodes.CloseBracketToken);
    Heritage.AddChild(ANodes.ItemsList);
    Heritage.AddChild(ANodes.UnsignedTag);
    Heritage.AddChild(ANodes.ZerofillTag);
    Heritage.AddChild(ANodes.CharacterSetValue);
    Heritage.AddChild(ANodes.CollateValue);
    Heritage.AddChild(ANodes.BinaryTag);
    Heritage.AddChild(ANodes.ASCIITag);
    Heritage.AddChild(ANodes.UnicodeTag);
  end;
end;

{ TMySQLParser.TDbIdent *******************************************************}

class function TMySQLParser.TDbIdent.Create(const AParser: TMySQLParser;
  const ADbIdentType: TDbIdentType; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntDbIdent);

  with PDbIdent(AParser.NodePtr(Result))^ do
  begin
    FDbIdentType := ADbIdentType;

    Nodes := ANodes;

    Heritage.AddChild(ANodes.Ident);
    Heritage.AddChild(ANodes.DatabaseDot);
    Heritage.AddChild(ANodes.DatabaseIdent);
    Heritage.AddChild(ANodes.TableDot);
    Heritage.AddChild(ANodes.TableIdent);
  end;
end;

class function TMySQLParser.TDbIdent.Create(const AParser: TMySQLParser; const ADbIdentType: TDbIdentType;
  const AIdent, ADatabaseDot, ADatabaseIdent, ATableDot, ATableIdent: TOffset): TOffset;
var
  Nodes: TNodes;
begin
  Nodes.Ident := AIdent;
  Nodes.DatabaseDot := ADatabaseDot;
  Nodes.DatabaseIdent := ADatabaseIdent;
  Nodes.TableDot := ATableDot;
  Nodes.TableIdent := ATableIdent;

  Result := Create(AParser, ADbIdentType, Nodes);
end;

function TMySQLParser.TDbIdent.GetDatabaseIdent(): PToken;
begin
  Result := Parser.TokenPtr(Nodes.DatabaseIdent);
end;

function TMySQLParser.TDbIdent.GetIdent(): PToken;
begin
  Result := Parser.TokenPtr(Nodes.Ident);
end;

function TMySQLParser.TDbIdent.GetParentNode(): PNode;
begin
  Result := Heritage.GetParentNode();
end;

function TMySQLParser.TDbIdent.GetTableIdent(): PToken;
begin
  Result := Parser.TokenPtr(Nodes.TableIdent);
end;

{ TMySQLParser.TDeallocatePrepareStmt *****************************************}

class function TMySQLParser.TDeallocatePrepareStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDeallocatePrepare);

  with PDeallocatePrepareStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.StmtIdent);
  end;
end;

{ TMySQLParser.TDeclareStmt ***************************************************}

class function TMySQLParser.TDeclareStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDeclare);

  with PDeclareStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IdentList);
    Heritage.Heritage.AddChild(ANodes.TypeNode);
    Heritage.Heritage.AddChild(ANodes.DefaultValue);
    Heritage.Heritage.AddChild(ANodes.CursorForTag);
    Heritage.Heritage.AddChild(ANodes.SelectStmt);
  end;
end;

{ TMySQLParser.TDeclareConditionStmt ******************************************}

class function TMySQLParser.TDeclareConditionStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDeclareCondition);

  with PDeclareConditionStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.Ident);
    Heritage.Heritage.AddChild(ANodes.ConditionTag);
    Heritage.Heritage.AddChild(ANodes.ForTag);
    Heritage.Heritage.AddChild(ANodes.ErrorCode);
    Heritage.Heritage.AddChild(ANodes.SQLStateTag);
    Heritage.Heritage.AddChild(ANodes.ErrorString);
  end;
end;

{ TMySQLParser.TDeclareCursorStmt *********************************************}

class function TMySQLParser.TDeclareCursorStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDeclareCursor);

  with PDeclareCursorStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.Ident);
    Heritage.Heritage.AddChild(ANodes.CursorTag);
    Heritage.Heritage.AddChild(ANodes.ForTag);
    Heritage.Heritage.AddChild(ANodes.SelectStmt);
  end;
end;

{ TMySQLParser.TDeclareHandlerStmt *********************************************}

class function TMySQLParser.TDeclareHandlerStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDeclareHandler);

  with PDeclareHandlerStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.ActionTag);
    Heritage.Heritage.AddChild(ANodes.HandlerTag);
    Heritage.Heritage.AddChild(ANodes.ForTag);
    Heritage.Heritage.AddChild(ANodes.ConditionsExpr);
    Heritage.Heritage.AddChild(ANodes.Stmt);
  end;
end;

{ TMySQLParser.TDeclareHandlerStmtCondition *********************************************}

class function TMySQLParser.TDeclareHandlerStmt.TCondition.Create(const AParser: TMySQLParser; const ANodes: TCondition.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntDeclareHandlerStmtCondition);

  with PCondition(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.ErrorCode);
    Heritage.AddChild(ANodes.SQLStateTag);
    Heritage.AddChild(ANodes.ConditionIdent);
    Heritage.AddChild(ANodes.SQLWarningsTag);
    Heritage.AddChild(ANodes.NotFoundTag);
    Heritage.AddChild(ANodes.SQLExceptionTag);
  end;
end;

{ TMySQLParser.TDeleteStmt ****************************************************}

class function TMySQLParser.TDeleteStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDelete);

  with PDeleteStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.DeleteTag);
    Heritage.Heritage.AddChild(ANodes.LowPriorityTag);
    Heritage.Heritage.AddChild(ANodes.QuickTag);
    Heritage.Heritage.AddChild(ANodes.IgnoreTag);
    Heritage.Heritage.AddChild(ANodes.FromTag);
    Heritage.Heritage.AddChild(ANodes.TableList);
    Heritage.Heritage.AddChild(ANodes.PartitionTag);
    Heritage.Heritage.AddChild(ANodes.PartitionList);
    Heritage.Heritage.AddChild(ANodes.UsingValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
    Heritage.Heritage.AddChild(ANodes.OrderByValue);
    Heritage.Heritage.AddChild(ANodes.LimitValue);
  end;
end;

{ TMySQLParser.TDoStmt ********************************************************}

class function TMySQLParser.TDoStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDo);

  with PDoStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.DoTag);
    Heritage.Heritage.AddChild(ANodes.ExprList);
  end;
end;

{ TMySQLParser.TDropDatabaseStmt **********************************************}

class function TMySQLParser.TDropDatabaseStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDropDatabase);

  with PDropDatabaseStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IfExistsTag);
    Heritage.Heritage.AddChild(ANodes.DatabaseIdent);
  end;
end;

{ TMySQLParser.TDropEventStmt *************************************************}

class function TMySQLParser.TDropEventStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDropEvent);

  with PDropEventStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IfExistsTag);
    Heritage.Heritage.AddChild(ANodes.EventIdent);
  end;
end;

{ TMySQLParser.TDropIndexStmt *************************************************}

class function TMySQLParser.TDropIndexStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDropIndex);

  with PDropIndexStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IndexIdent);
    Heritage.Heritage.AddChild(ANodes.OnTag);
    Heritage.Heritage.AddChild(ANodes.TableIdent);
    Heritage.Heritage.AddChild(ANodes.AlgorithmValue);
    Heritage.Heritage.AddChild(ANodes.LockValue);
  end;
end;

{ TMySQLParser.TDropRoutineStmt ***********************************************}

class function TMySQLParser.TDropRoutineStmt.Create(const AParser: TMySQLParser; const ARoutineType: TRoutineType; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDropRoutine);

  with PDropRoutineStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;
    FRoutineType := ARoutineType;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IfExistsTag);
    Heritage.Heritage.AddChild(ANodes.RoutineIdent);
  end;
end;

{ TMySQLParser.TDropServerStmt ************************************************}

class function TMySQLParser.TDropServerStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDropServer);

  with PDropServerStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IfExistsTag);
    Heritage.Heritage.AddChild(ANodes.ServerIdent);
  end;
end;

{ TMySQLParser.TDropTableStmt *************************************************}

class function TMySQLParser.TDropTableStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDropTable);

  with PDropTableStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IfExistsTag);
    Heritage.Heritage.AddChild(ANodes.TableIdentList);
    Heritage.Heritage.AddChild(ANodes.RestrictCascadeTag);
  end;
end;

{ TMySQLParser.TDropTriggerStmt ***********************************************}

class function TMySQLParser.TDropTriggerStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDropTrigger);

  with PDropTriggerStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IfExistsTag);
    Heritage.Heritage.AddChild(ANodes.TriggerIdent);
  end;
end;

{ TMySQLParser.TDropUserStmt **************************************************}

class function TMySQLParser.TDropUserStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDropUser);

  with PDropUserStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IfExistsTag);
    Heritage.Heritage.AddChild(ANodes.UserList);
  end;
end;

{ TMySQLParser.TDropViewStmt **************************************************}

class function TMySQLParser.TDropViewStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stDropView);

  with PDropViewStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.IfExistsTag);
    Heritage.Heritage.AddChild(ANodes.ViewIdentList);
    Heritage.Heritage.AddChild(ANodes.RestrictCascadeTag);
  end;
end;

{ TMySQLParser.TExecuteStmt ***************************************************}

class function TMySQLParser.TExecuteStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stExecute);

  with PExecuteStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.StmtVariable);
    Heritage.Heritage.AddChild(ANodes.UsingTag);
    Heritage.Heritage.AddChild(ANodes.VariableIdents);
  end;
end;

{ TMySQLParser.TExistsFunc ****************************************************}

class function TMySQLParser.TExistsFunc.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntExistsFunc);

  with PExistsFunc(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.FuncToken);
    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.SubQuery);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TExplainStmt *****************************************************}

class function TMySQLParser.TExplainStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stExplain);

  with PExplainStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.TableIdent);
    Heritage.Heritage.AddChild(ANodes.ColumnIdent);
    Heritage.Heritage.AddChild(ANodes.ExplainType);
    Heritage.Heritage.AddChild(ANodes.AssignToken);
    Heritage.Heritage.AddChild(ANodes.FormatKeyword);
  end;
end;

{ TMySQLParser.TExtractFunc ******************************************************}

class function TMySQLParser.TExtractFunc.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntExtractFunc);

  with PExtractFunc(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.FuncToken);
    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.UnitTag);
    Heritage.AddChild(ANodes.FromTag);
    Heritage.AddChild(ANodes.DateExpr);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TFetchStmt *****************************************************}

class function TMySQLParser.TFetchStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stFetch);

  with PFetchStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.FromTag);
    Heritage.Heritage.AddChild(ANodes.CursorIdent);
    Heritage.Heritage.AddChild(ANodes.IntoTag);
    Heritage.Heritage.AddChild(ANodes.VariableList);
  end;
end;

{ TMySQLParser.TFlushStmt *****************************************************}

class function TMySQLParser.TFlushStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stFlush);

  with PFlushStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.NoWriteToBinLogTag);
    Heritage.Heritage.AddChild(ANodes.OptionList);
  end;
end;

{ TMySQLParser.TFlushStmtOption ***********************************************}

class function TMySQLParser.TFlushStmt.TOption.Create(const AParser: TMySQLParser; const ANodes: TOption.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntFlushStmtOption);

  with POption(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.OptionTag);
    Heritage.AddChild(ANodes.TablesList);
  end;
end;

{ TMySQLParser.TFunctionCall **************************************************}

class function TMySQLParser.TFunctionCall.Create(const AParser: TMySQLParser; const AIdent, AArgumentsList: TOffset): TOffset;
var
  Nodes: TNodes;
begin
  Nodes.Ident := AIdent;
  Nodes.ArgumentsList := AArgumentsList;

  Result := Create(AParser, Nodes);
end;

class function TMySQLParser.TFunctionCall.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntFunctionCall);

  with PFunctionCall(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Ident);
    Heritage.AddChild(ANodes.ArgumentsList);
  end;
end;

function TMySQLParser.TFunctionCall.GetArguments(): PChild;
begin
  Result := Parser.ChildPtr(FNodes.ArgumentsList);
end;

function TMySQLParser.TFunctionCall.GetIdent(): PChild;
begin
  Result := Parser.ChildPtr(FNodes.Ident);
end;

{ TMySQLParser.TFunctionReturns ***********************************************}

class function TMySQLParser.TFunctionReturns.Create(const AParser: TMySQLParser; const ANodes: TFunctionReturns.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntFunctionReturns);

  with PFunctionReturns(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.ReturnsTag);
    Heritage.AddChild(ANodes.DataTypeNode);
    Heritage.AddChild(ANodes.CharsetValue);
  end;
end;

{ TMySQLParser.TGetDiagnosticsStmt ********************************************}

class function TMySQLParser.TGetDiagnosticsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stGetDiagnostics);

  with PGetDiagnosticsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TGetDiagnosticsStmt.TStmtInfo **********************************}

class function TMySQLParser.TGetDiagnosticsStmt.TStmtInfo.Create(const AParser: TMySQLParser; const ANodes: TStmtInfo.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntGetDiagnosticsStmtStmtInfo);

  with PStmtInfo(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Target);
    Heritage.AddChild(ANodes.EqualOp);
    Heritage.AddChild(ANodes.ItemTag);
  end;
end;

{ TMySQLParser.TGetDiagnosticsStmt.TConditionalInfo ***************************}

class function TMySQLParser.TGetDiagnosticsStmt.TConditionalInfo.Create(const AParser: TMySQLParser; const ANodes: TConditionalInfo.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntGetDiagnosticsStmtStmtInfo);

  with PConditionalInfo(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Target);
    Heritage.AddChild(ANodes.EqualOp);
    Heritage.AddChild(ANodes.ItemTag);
  end;
end;

{ TMySQLParser.TGrantStmt *****************************************************}

class function TMySQLParser.TGrantStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stGrant);

  with PGrantStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.PrivilegesList);
    Heritage.Heritage.AddChild(ANodes.OnTag);
    Heritage.Heritage.AddChild(ANodes.OnUser);
    Heritage.Heritage.AddChild(ANodes.ObjectValue);
    Heritage.Heritage.AddChild(ANodes.ToTag);
    Heritage.Heritage.AddChild(ANodes.UserSpecifications);
    Heritage.Heritage.AddChild(ANodes.RequireTag);
    Heritage.Heritage.AddChild(ANodes.WithTag);
    Heritage.Heritage.AddChild(ANodes.ResourcesList);
  end;
end;

{ TMySQLParser.TGrantStmt.TPrivileg *******************************************}

class function TMySQLParser.TGrantStmt.TPrivileg.Create(const AParser: TMySQLParser; const ANodes: TPrivileg.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntGrantStmtPrivileg);

  with PPrivileg(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.PrivilegTag);
    Heritage.AddChild(ANodes.ColumnList);
  end;
end;

{ TMySQLParser.TGrantStmt.TUserSpecification **********************************}

class function TMySQLParser.TGrantStmt.TUserSpecification.Create(const AParser: TMySQLParser; const ANodes: TUserSpecification.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntGrantStmtUserSpecification);

  with PUserSpecification(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.UserIdent);
    Heritage.AddChild(ANodes.IdentifiedToken);
    Heritage.AddChild(ANodes.PluginIdent);
    Heritage.AddChild(ANodes.AsToken);
    Heritage.AddChild(ANodes.AuthString);
  end;
end;

{ TMySQLParser.TGroupConcatFunc ***********************************************}

class function TMySQLParser.TGroupConcatFunc.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntGroupConcatFunc);

  with PGroupConcatFunc(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.FuncToken);
    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.DistinctTag);
    Heritage.AddChild(ANodes.ExprList);
    Heritage.AddChild(ANodes.OrderByTag);
    Heritage.AddChild(ANodes.OrderByExprList);
    Heritage.AddChild(ANodes.SeparatorValue);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TGroupConcatFunc.TExpr *****************************************}

class function TMySQLParser.TGroupConcatFunc.TExpr.Create(const AParser: TMySQLParser; const ANodes: TExpr.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntGroupConcatFuncExpr);

  with PExpr(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Expr);
    Heritage.AddChild(ANodes.Direction);
  end;
end;

{ TMySQLParser.THelpStmt ******************************************************}

class function TMySQLParser.THelpStmt.Create(const AParser: TMySQLParser; const ANodes: THelpStmt.TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stHelp);

  with PHelpStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.HelpString);
  end;
end;

{ TMySQLParser.TIfStmt.TBranch ************************************************}

class function TMySQLParser.TIfStmt.TBranch.Create(const AParser: TMySQLParser; const ANodes: TBranch.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntIfStmtBranch);

  with PBranch(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Tag);
    Heritage.AddChild(ANodes.ConditionExpr);
    Heritage.AddChild(ANodes.ThenTag);
    Heritage.AddChild(ANodes.StmtList);
  end;
end;

{ TMySQLParser.TIfStmt ********************************************************}

class function TMySQLParser.TIfStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stIf);

  with PIfStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.BranchList);
    Heritage.Heritage.AddChild(ANodes.EndTag);
  end;
end;

{ TMySQLParser.TIgnoreLines ***************************************************}

class function TMySQLParser.TIgnoreLines.Create(const AParser: TMySQLParser; const ANodes: TIgnoreLines.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntIgnoreLines);

  with PIgnoreLines(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.IgnoreTag);
    Heritage.AddChild(ANodes.NumberToken);
    Heritage.AddChild(ANodes.LinesTag);
  end;
end;

{ TMySQLParser.TInOp **********************************************************}

class function TMySQLParser.TInOp.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntInOp);

  with PInOp(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Operand);
    Heritage.AddChild(ANodes.NotToken);
    Heritage.AddChild(ANodes.InToken);
    Heritage.AddChild(ANodes.List);
  end;
end;

{ TMySQLParser.TInsertStmt ****************************************************}

class function TMySQLParser.TInsertStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stInsert);

  with PInsertStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.InsertTag);
    Heritage.Heritage.AddChild(ANodes.PriorityTag);
    Heritage.Heritage.AddChild(ANodes.IgnoreTag);
    Heritage.Heritage.AddChild(ANodes.IntoTag);
    Heritage.Heritage.AddChild(ANodes.TableIdent);
    Heritage.Heritage.AddChild(ANodes.PartitionTag);
    Heritage.Heritage.AddChild(ANodes.PartitionList);
    Heritage.Heritage.AddChild(ANodes.ColumnList);
    Heritage.Heritage.AddChild(ANodes.ValuesTag);
    Heritage.Heritage.AddChild(ANodes.ValuesList);
    Heritage.Heritage.AddChild(ANodes.SetTag);
    Heritage.Heritage.AddChild(ANodes.SetList);
    Heritage.Heritage.AddChild(ANodes.SelectStmt);
    Heritage.Heritage.AddChild(ANodes.OnDuplicateKeyUpdateTag);
    Heritage.Heritage.AddChild(ANodes.UpdateList);
  end;
end;

{ TMySQLParser.TInsertStmt ****************************************************}

class function TMySQLParser.TInsertStmt.TSetItem.Create(const AParser: TMySQLParser; const ANodes: TSetItem.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntInsertStmtSetItem);

  with PSetItem(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.FieldToken);
    Heritage.AddChild(ANodes.AssignToken);
    Heritage.AddChild(ANodes.ValueNode);
  end;
end;

{ TMySQLParser.TInterval ******************************************************}

class function TMySQLParser.TIntervalOp.Create(const AParser: TMySQLParser; const ANodes: TIntervalOp.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntIntervalOp);

  with PIntervalOp(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.AddChild(ANodes.QuantityExp);
    Heritage.AddChild(ANodes.UnitTag);
  end;
end;

{ TMySQLParser.TIntervalListItem **********************************************}

class function TMySQLParser.TIntervalOp.TListItem.Create(const AParser: TMySQLParser; const ANodes: TListItem.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntIntervalListItem);

  with PListItem(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.PlusToken);
    Heritage.AddChild(ANodes.IntervalTag);
    Heritage.AddChild(ANodes.Interval);
  end;
end;

{ TMySQLParser.TIterateStmt ***************************************************}

class function TMySQLParser.TIterateStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stIterate);

  with PIterateStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.IterateToken);
    Heritage.Heritage.AddChild(ANodes.LabelToken);
  end;
end;

{ TMySQLParser.TKillStmt *****************************************************}

class function TMySQLParser.TKillStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stKill);

  with PKillStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.ProcessIdToken);
  end;
end;

{ TMySQLParser.TLeaveStmt *****************************************************}

class function TMySQLParser.TLeaveStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stLeave);

  with PLeaveStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.LabelToken);
  end;
end;

{ TMySQLParser.TLikeOp ********************************************************}

class function TMySQLParser.TLikeOp.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntLikeOp);

  with PLikeOp(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Operand1);
    Heritage.AddChild(ANodes.NotToken);
    Heritage.AddChild(ANodes.LikeToken);
    Heritage.AddChild(ANodes.Operand2);
    Heritage.AddChild(ANodes.EscapeToken);
    Heritage.AddChild(ANodes.EscapeCharToken);
  end;
end;

{ TMySQLParser.TList **********************************************************}

class function TMySQLParser.TList.Create(const AParser: TMySQLParser; const ANodes: TNodes; const AChildrenCount: Integer; const AChildren: array of TOffset): TOffset;
var
  I: Integer;
begin
  Result := TRange.Create(AParser, ntList);

  with PList(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;
    if (AChildrenCount > 0) then
      Nodes.FirstChild := AChildren[0];

    Heritage.AddChild(ANodes.OpenBracket);
    for I := 0 to AChildrenCount - 1 do
      Heritage.AddChild(AChildren[I]);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

function TMySQLParser.TList.GetCount(): Integer;
var
  Child: PChild;
begin
  Result := 0;

  Child := FirstChild;
  while (Assigned(Child)) do
  begin
    Inc(Result);
    Child := Child^.NextSibling;
  end;
end;

function TMySQLParser.TList.GetFirstChild(): PChild;
begin
  Result := PChild(Parser.NodePtr(Nodes.FirstChild));
end;

{ TMySQLParser.TLoadDataStmt **************************************************}

class function TMySQLParser.TLoadDataStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stLoadData);

  with PLoadDataStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.LoadDataTag);
    Heritage.Heritage.AddChild(ANodes.PriorityTag);
    Heritage.Heritage.AddChild(ANodes.InfileTag);
    Heritage.Heritage.AddChild(ANodes.FilenameString);
    Heritage.Heritage.AddChild(ANodes.ReplaceIgnoreTag);
    Heritage.Heritage.AddChild(ANodes.IntoTableValue);
    Heritage.Heritage.AddChild(ANodes.PartitionValue);
    Heritage.Heritage.AddChild(ANodes.CharacterSetValue);
    Heritage.Heritage.AddChild(ANodes.ColumnsTag);
    Heritage.Heritage.AddChild(ANodes.ColumnsTerminatedByValue);
    Heritage.Heritage.AddChild(ANodes.EnclosedByValue);
    Heritage.Heritage.AddChild(ANodes.EscapedByValue);
    Heritage.Heritage.AddChild(ANodes.LinesTag);
    Heritage.Heritage.AddChild(ANodes.StartingByValue);
    Heritage.Heritage.AddChild(ANodes.LinesTerminatedByValue);
    Heritage.Heritage.AddChild(ANodes.IgnoreLines);
    Heritage.Heritage.AddChild(ANodes.ColumnList);
    Heritage.Heritage.AddChild(ANodes.SetList);
  end;
end;

{ TMySQLParser.TLoadXMLStmt ***************************************************}

class function TMySQLParser.TLoadXMLStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stLoadXML);

  with PLoadXMLStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

  end;
end;

{ TMySQLParser.TLockStmt.TItem ************************************************}

class function TMySQLParser.TLockStmt.TItem.Create(const AParser: TMySQLParser; const ANodes: TItem.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntLockStmtItem);

  with PItem(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.TableIdent);
    Heritage.AddChild(ANodes.AsTag);
    Heritage.AddChild(ANodes.AliasIdent);
    Heritage.AddChild(ANodes.TypeTag);
  end;
end;

{ TMySQLParser.TLockStmt ******************************************************}

class function TMySQLParser.TLockStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stLock);

  with PLockStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.LockTablesTag);
    Heritage.Heritage.AddChild(ANodes.ItemList);
  end;
end;

{ TMySQLParser.TLoopStmt ******************************************************}

class function TMySQLParser.TLoopStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stLoop);

  with PLoopStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.BeginLabelToken);
    Heritage.Heritage.AddChild(ANodes.BeginTag);
    Heritage.Heritage.AddChild(ANodes.StmtList);
    Heritage.Heritage.AddChild(ANodes.EndTag);
    Heritage.Heritage.AddChild(ANodes.EndLabelToken);
  end;
end;

{ TMySQLParser.TPositionFunc ******************************************************}

class function TMySQLParser.TPositionFunc.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntPositionFunc);

  with PPositionFunc(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.FuncToken);
    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.SubStr);
    Heritage.AddChild(ANodes.InTag);
    Heritage.AddChild(ANodes.Str);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TPrepareStmt ***************************************************}

class function TMySQLParser.TPrepareStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stPrepare);

  with PPrepareStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.StmtIdent);
    Heritage.Heritage.AddChild(ANodes.FromTag);
    Heritage.Heritage.AddChild(ANodes.StmtVariable);
  end;
end;

{ TMySQLParser.TPurgeStmt ***************************************************}

class function TMySQLParser.TPurgeStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stPurge);

  with PPurgeStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.TypeTag);
    Heritage.Heritage.AddChild(ANodes.LogsTag);
    Heritage.Heritage.AddChild(ANodes.Value);
  end;
end;

{ TMySQLParser.TOpenStmt ******************************************************}

class function TMySQLParser.TOpenStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stOpen);

  with POpenStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.CursorIdent);
  end;
end;

{ TMySQLParser.TOptimizeStmt **************************************************}

class function TMySQLParser.TOptimizeStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stOptimize);

  with POptimizeStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.OptionTag);
    Heritage.Heritage.AddChild(ANodes.TableTag);
    Heritage.Heritage.AddChild(ANodes.TablesList);
  end;
end;

{ TMySQLParser.TRenameTableStmt ***********************************************}

class function TMySQLParser.TRenameStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stRename);

  with PRenameStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.RenameTag);
    Heritage.Heritage.AddChild(ANodes.RenameList);
  end;
end;

{ TMySQLParser.TRenameStmt.TPair **********************************************}

class function TMySQLParser.TRenameStmt.TPair.Create(const AParser: TMySQLParser; const ANodes: TPair.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntRenameStmtPair);

  with PPair(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.OrgNode);
    Heritage.AddChild(ANodes.ToTag);
    Heritage.AddChild(ANodes.NewNode);
  end;
end;

{ TMySQLParser.TRegExpOp ******************************************************}

class function TMySQLParser.TRegExpOp.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntRegExpOp);

  with PRegExpOp(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Operand1);
    Heritage.AddChild(ANodes.NotToken);
    Heritage.AddChild(ANodes.RegExpToken);
    Heritage.AddChild(ANodes.Operand2);
  end;
end;

{ TMySQLParser.TReleaseStmt ***************************************************}

class function TMySQLParser.TReleaseStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stRelease);

  with PReleaseStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.ReleaseTag);
    Heritage.Heritage.AddChild(ANodes.Ident);
  end;
end;

{ TMySQLParser.TRepairStmt ****************************************************}

class function TMySQLParser.TRepairStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stRepair);

  with PRepairStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.OptionTag);
    Heritage.Heritage.AddChild(ANodes.TableTag);
    Heritage.Heritage.AddChild(ANodes.TablesList);
  end;
end;

{ TMySQLParser.TRepeatStmt ****************************************************}

class function TMySQLParser.TRepeatStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stRepeat);

  with PRepeatStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.BeginLabelToken);
    Heritage.Heritage.AddChild(ANodes.RepeatTag);
    Heritage.Heritage.AddChild(ANodes.StmtList);
    Heritage.Heritage.AddChild(ANodes.UntilTag);
    Heritage.Heritage.AddChild(ANodes.SearchConditionExpr);
    Heritage.Heritage.AddChild(ANodes.EndTag);
    Heritage.Heritage.AddChild(ANodes.EndLabelToken);
  end;
end;

{ TMySQLParser.TRevokeStmt ****************************************************}

class function TMySQLParser.TRevokeStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stRevoke);

  with PRevokeStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.PrivilegesList);
    Heritage.Heritage.AddChild(ANodes.CommaToken);
    Heritage.Heritage.AddChild(ANodes.GrantOptionTag);
    Heritage.Heritage.AddChild(ANodes.OnTag);
    Heritage.Heritage.AddChild(ANodes.OnUser);
    Heritage.Heritage.AddChild(ANodes.ObjectValue);
    Heritage.Heritage.AddChild(ANodes.FromTag);
    Heritage.Heritage.AddChild(ANodes.UserIdentList);
  end;
end;

{ TMySQLParser.TResetStmt *****************************************************}

class function TMySQLParser.TResetStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stReset);

  with PResetStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.OptionList);
  end;
end;

{ TMySQLParser.TResetStmt.TOption *********************************************}

class function TMySQLParser.TResetStmt.TOption.Create(const AParser: TMySQLParser; const ANodes: TOption.TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stReset);

  with POption(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.OptionTag);
  end;
end;

{ TMySQLParser.TReturnStmt ****************************************************}

class function TMySQLParser.TReturnStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stReturn);

  with PReturnStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.Expr);
  end;
end;

{ TMySQLParser.TRollbackStmt **************************************************}

class function TMySQLParser.TRollbackStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stRollback);

  with PRollbackStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.RollbackTag);
    Heritage.Heritage.AddChild(ANodes.ToValue);
    Heritage.Heritage.AddChild(ANodes.ChainTag);
    Heritage.Heritage.AddChild(ANodes.ReleaseTag);
  end;
end;

{ TMySQLParser.TRoutineParam **************************************************}

class function TMySQLParser.TRoutineParam.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntRoutineParam);

  with PRoutineParam(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.DirektionTag);
    Heritage.AddChild(ANodes.IdentToken);
    Heritage.AddChild(ANodes.DataTypeNode);
  end;
end;

{ TMySQLParser.TSavepointStmt *************************************************}

class function TMySQLParser.TSavepointStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stSavepoint);

  with PSavepointStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.SavepointTag);
    Heritage.Heritage.AddChild(ANodes.Ident);
  end;
end;

{ TMySQLParser.TSecretIdent ***************************************************}

class function TMySQLParser.TSecretIdent.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSecretIdent);

  with PSecretIdent(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.ItemToken);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TSelectStmt.TColumn ********************************************}

class function TMySQLParser.TSelectStmt.TColumn.Create(const AParser: TMySQLParser; const ANodes: TColumn.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSelectStmtColumn);

  with PColumn(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.ExprNode);
    Heritage.AddChild(ANodes.AsToken);
    Heritage.AddChild(ANodes.AliasIdent);
  end;
end;

{ TMySQLParser.TSelectStmt.TTableFactor.TIndexHint ****************************}

class function TMySQLParser.TSelectStmt.TTableFactor.TIndexHint.Create(const AParser: TMySQLParser; const ANodes: TIndexHint.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSelectStmtTableFactorIndexHint);

  with PIndexHint(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.KindTag);
    Heritage.AddChild(ANodes.ForValue);
    Heritage.AddChild(ANodes.IndexList);
  end;
end;

{ TMySQLParser.TSelectStmt.TTableFactor ***************************************}

class function TMySQLParser.TSelectStmt.TTableFactor.Create(const AParser: TMySQLParser; const ANodes: TTableFactor.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSelectStmtTableFactor);

  with PTableFactor(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.TableIdent);
    Heritage.AddChild(ANodes.PartitionTag);
    Heritage.AddChild(ANodes.Partitions);
    Heritage.AddChild(ANodes.AsToken);
    Heritage.AddChild(ANodes.AliasToken);
    Heritage.AddChild(ANodes.IndexHintList);
    Heritage.AddChild(ANodes.SelectStmt);
  end;
end;

{ TMySQLParser.TSelectStmt.TTableFactorOj *************************************}

class function TMySQLParser.TSelectStmt.TTableReferenceOj.Create(const AParser: TMySQLParser; const ANodes: TTableReferenceOj.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSelectStmtTableFactorOj);

  with PTableReferenceOj(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.OpenBracketToken);
    Heritage.AddChild(ANodes.OjTag);
    Heritage.AddChild(ANodes.TableReference);
    Heritage.AddChild(ANodes.CloseBracketToken);
  end;
end;

{ TMySQLParser.TSelectStmt.TTableFactorReferences *****************************}

class function TMySQLParser.TSelectStmt.TTableFactorReferences.Create(const AParser: TMySQLParser; const ANodes: TTableFactorReferences.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSelectStmtTableFactorReferences);

  with PTableFactorReferences(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.ReferenceList);
  end;
end;

{ TMySQLParser.TSelectStmt.TTableFactorSelect *********************************}

class function TMySQLParser.TSelectStmt.TTableFactorSelect.Create(const AParser: TMySQLParser; const ANodes: TTableFactorSelect.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSelectStmtTableFactorSelect);

  with PTableFactorSelect(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.SelectStmt);
  end;
end;

{ TMySQLParser.TSelectStmt.TTableReferenceJoin ********************************}

class function TMySQLParser.TSelectStmt.TTableReferenceJoin.Create(const AParser: TMySQLParser; const AJoinType: TJoinType; const ANodes: TTableReferenceJoin.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSelectStmtTableJoin);

  with PTableReferenceJoin(AParser.NodePtr(Result))^ do
  begin
    FJoinType := AJoinType;

    FNodes := ANodes;

    Heritage.AddChild(ANodes.JoinTag);
    Heritage.AddChild(ANodes.RightTable);
    Heritage.AddChild(ANodes.OnTag);
    Heritage.AddChild(ANodes.Condition);
  end;
end;

{ TMySQLParser.TSelectStmt.TGroup *********************************************}

class function TMySQLParser.TSelectStmt.TGroup.Create(const AParser: TMySQLParser; const ANodes: TGroup.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSelectStmtGroup);

  with PGroup(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Expr);
    Heritage.AddChild(ANodes.Direction);
  end;
end;

{ TMySQLParser.TSelectStmt.TGroups ********************************************}

class function TMySQLParser.TSelectStmt.TGroups.Create(const AParser: TMySQLParser; const ANodes: TGroups.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSelectStmtGroups);

  with PGroups(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.ColumnList);
    Heritage.AddChild(ANodes.WithRollupTag);
  end;
end;

{ TMySQLParser.TSelectStmt.TInto **********************************************}

class function TMySQLParser.TSelectStmt.TInto.Create(const AParser: TMySQLParser; const ANodes: TInto.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSelectStmtInto);

  with PInto(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.IntoTag);
    Heritage.AddChild(ANodes.OutfileValue);
    Heritage.AddChild(ANodes.DumpfileTag);
    Heritage.AddChild(ANodes.Filename);
    Heritage.AddChild(ANodes.CharacterSetValue);
    Heritage.AddChild(ANodes.Variable);
    Heritage.AddChild(ANodes.FieldsTerminatedByValue);
    Heritage.AddChild(ANodes.OptionalEnclosedByValue);
    Heritage.AddChild(ANodes.LinesTerminatedByValue);
  end;
end;

{ TMySQLParser.TSelectStmt.TOrder *********************************************}

class function TMySQLParser.TSelectStmt.TOrder.Create(const AParser: TMySQLParser; const ANodes: TOrder.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSelectStmtOrder);

  with POrder(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Expr);
    Heritage.AddChild(ANodes.DirectionTag);
  end;
end;

{ TMySQLParser.TSelectStmt ****************************************************}

class function TMySQLParser.TSelectStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stSelect);

  with PSelectStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.SelectTag);
    Heritage.Heritage.AddChild(ANodes.DistinctTag);
    Heritage.Heritage.AddChild(ANodes.ColumnsList);
    Heritage.Heritage.AddChild(ANodes.From.Tag);
    Heritage.Heritage.AddChild(ANodes.Into1);
    Heritage.Heritage.AddChild(ANodes.From.Expr);
    Heritage.Heritage.AddChild(ANodes.Where.Tag);
    Heritage.Heritage.AddChild(ANodes.Where.Expr);
    Heritage.Heritage.AddChild(ANodes.GroupBy.Tag);
    Heritage.Heritage.AddChild(ANodes.GroupBy.Expr);
    Heritage.Heritage.AddChild(ANodes.Having.Tag);
    Heritage.Heritage.AddChild(ANodes.Having.Expr);
    Heritage.Heritage.AddChild(ANodes.OrderBy.Tag);
    Heritage.Heritage.AddChild(ANodes.OrderBy.Expr);
    Heritage.Heritage.AddChild(ANodes.Limit.LimitTag);
    Heritage.Heritage.AddChild(ANodes.Limit.OffsetTag);
    Heritage.Heritage.AddChild(ANodes.Limit.OffsetToken);
    Heritage.Heritage.AddChild(ANodes.Limit.CommaToken);
    Heritage.Heritage.AddChild(ANodes.Limit.RowCountToken);
    Heritage.Heritage.AddChild(ANodes.Proc.Tag);
    Heritage.Heritage.AddChild(ANodes.Proc.Ident);
    Heritage.Heritage.AddChild(ANodes.Proc.ParamList);
    Heritage.Heritage.AddChild(ANodes.Into2);
    Heritage.Heritage.AddChild(ANodes.ForUpdatesTag);
    Heritage.Heritage.AddChild(ANodes.LockInShareMode);
    Heritage.Heritage.AddChild(ANodes.Union.Tag);
    Heritage.Heritage.AddChild(ANodes.Union.SelectStmt);
  end;
end;

{ TMySQLParser.TSchedule ******************************************************}

class function TMySQLParser.TSchedule.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
var
  I: Integer;
begin
  Result := TRange.Create(AParser, ntSchedule);

  with PSchedule(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.AddChild(ANodes.At.Tag);
    Heritage.AddChild(ANodes.At.Timestamp);
    for I := 0 to Length(ANodes.At.IntervalList) - 1 do
      Heritage.AddChild(ANodes.At.IntervalList[0]);
    Heritage.AddChild(ANodes.Every.Tag);
    Heritage.AddChild(ANodes.Every.Interval);
    Heritage.AddChild(ANodes.Starts.Tag);
    Heritage.AddChild(ANodes.Starts.Timestamp);
    for I := 0 to Length(ANodes.Starts.IntervalList) - 1 do
      Heritage.AddChild(ANodes.Starts.IntervalList[0]);
    Heritage.AddChild(ANodes.Ends.Tag);
    Heritage.AddChild(ANodes.Ends.Timestamp);
    for I := 0 to Length(ANodes.Ends.IntervalList) - 1 do
      Heritage.AddChild(ANodes.Ends.IntervalList[0]);
  end;
end;

{ TMySQLParser.TSetStmt.TAssignment *******************************************}

class function TMySQLParser.TSetStmt.TAssignment.Create(const AParser: TMySQLParser; const ANodes: TAssignment.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSetStmtAssignment);

  with PAssignment(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.ScopeTag);
    Heritage.AddChild(ANodes.Variable);
    Heritage.AddChild(ANodes.AssignToken);
    Heritage.AddChild(ANodes.ValueExpr);
  end;
end;

{ TMySQLParser.TSetStmt *******************************************************}

class function TMySQLParser.TSetStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stSet);

  with PSetStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.SetTag);
    Heritage.Heritage.AddChild(ANodes.ScopeTag);
    Heritage.Heritage.AddChild(ANodes.AssignmentList);
  end;
end;

{ TMySQLParser.TSetNamesStmt ***********************************************}

class function TMySQLParser.TSetNamesStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stSetNames);

  with PSetNamesStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.ConstValue);
  end;
end;

{ TMySQLParser.TSetPasswordStmt ***********************************************}

class function TMySQLParser.TSetPasswordStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stSetPassword);

  with PSetPasswordStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.ForValue);
    Heritage.Heritage.AddChild(ANodes.AssignToken);
    Heritage.Heritage.AddChild(ANodes.PasswordExpr);
  end;
end;

{ TMySQLParser.TSetTransactionStmt.TCharacteristic ****************************}

class function TMySQLParser.TSetTransactionStmt.TCharacteristic.Create(const AParser: TMySQLParser; const ANodes: TCharacteristic.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntTransactionStmtCharacteristic);

  with PCharacteristic(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.KindTag);
    Heritage.AddChild(ANodes.Value);
  end;
end;

{ TMySQLParser.TSetTransactionStmt ********************************************}

class function TMySQLParser.TSetTransactionStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stSetTransaction);

  with PSetTransactionStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.SetTag);
    Heritage.Heritage.AddChild(ANodes.ScopeTag);
    Heritage.Heritage.AddChild(ANodes.TransactionTag);
    Heritage.Heritage.AddChild(ANodes.CharacteristicList);
  end;
end;

{ TMySQLParser.TShowAuthorsStmt ***********************************************}

class function TMySQLParser.TShowAuthorsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowAuthors);

  with PShowAuthorsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowBinaryLogsStmt ********************************************}

class function TMySQLParser.TShowBinaryLogsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowBinaryLogs);

  with PShowBinaryLogsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowBinlogEventsStmt ******************************************}

class function TMySQLParser.TShowBinlogEventsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowBinlogEvents);

  with PShowBinlogEventsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.InValue);
    Heritage.Heritage.AddChild(ANodes.FromValue);
    Heritage.Heritage.AddChild(ANodes.LimitTag);
    Heritage.Heritage.AddChild(ANodes.OffsetToken);
    Heritage.Heritage.AddChild(ANodes.CommaToken);
    Heritage.Heritage.AddChild(ANodes.RowCountToken);
  end;
end;

{ TMySQLParser.TShowCharacterSetStmt ******************************************}

class function TMySQLParser.TShowCharacterSetStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowCharacterSet);

  with PShowCharacterSetStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.LikeValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowCollationStmt *********************************************}

class function TMySQLParser.TShowCollationStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowCollation);

  with PShowCollationStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.LikeValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowContributorsStmt ******************************************}

class function TMySQLParser.TShowContributorsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowContributors);

  with PShowContributorsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowCountErrorsStmt *******************************************}

class function TMySQLParser.TShowCountErrorsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowCountErrors);

  with PShowCountErrorsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.CountFunctionCall);
  end;
end;

{ TMySQLParser.TShowCountWarningsStmt *****************************************}

class function TMySQLParser.TShowCountWarningsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowCountWarnings);

  with PShowCountWarningsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.CountFunctionCall);
  end;
end;

{ TMySQLParser.TShowCreateDatabaseStmt ****************************************}

class function TMySQLParser.TShowCreateDatabaseStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowCreateDatabase);

  with PShowCreateDatabaseStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowCreateEventStmt *******************************************}

class function TMySQLParser.TShowCreateEventStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowCreateEvent);

  with PShowCreateEventStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowCreateFunctionStmt ****************************************}

class function TMySQLParser.TShowCreateFunctionStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowCreateFunction);

  with PShowCreateFunctionStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowCreateProcedureStmt ***************************************}

class function TMySQLParser.TShowCreateProcedureStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowCreateProcedure);

  with PShowCreateProcedureStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.Ident);
  end;
end;

{ TMySQLParser.TShowCreateTableStmt *******************************************}

class function TMySQLParser.TShowCreateTableStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowCreateTable);

  with PShowCreateTableStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowCreateTriggerStmt *****************************************}

class function TMySQLParser.TShowCreateTriggerStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowCreateTrigger);

  with PShowCreateTriggerStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowCreateViewStmt ********************************************}

class function TMySQLParser.TShowCreateViewStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowCreateView);

  with PShowCreateViewStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowDatabasesStmt *********************************************}

class function TMySQLParser.TShowDatabasesStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowDatabases);

  with PShowDatabasesStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.LikeValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowEngineStmt ************************************************}

class function TMySQLParser.TShowEngineStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowEngine);

  with PShowEngineStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.Ident);
    Heritage.Heritage.AddChild(ANodes.KindTag);
  end;
end;

{ TMySQLParser.TShowEnginesStmt ***********************************************}

class function TMySQLParser.TShowEnginesStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowEngines);

  with PShowEnginesStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowErrorsStmt ************************************************}

class function TMySQLParser.TShowErrorsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowErrors);

  with PShowErrorsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.Limit.LimitTag);
    Heritage.Heritage.AddChild(ANodes.Limit.OffsetToken);
    Heritage.Heritage.AddChild(ANodes.Limit.CommaToken);
    Heritage.Heritage.AddChild(ANodes.Limit.RowCountToken);
  end;
end;

{ TMySQLParser.TShowEventsStmt ************************************************}

class function TMySQLParser.TShowEventsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowEvents);

  with PShowEventsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.FromValue);
    Heritage.Heritage.AddChild(ANodes.LikeValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowFunctionCodeStmt ******************************************}

class function TMySQLParser.TShowFunctionCodeStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowFunctionCode);

  with PShowFunctionCodeStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowFunctionStatusStmt ****************************************}

class function TMySQLParser.TShowFunctionStatusStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowFunctionStatus);

  with PShowFunctionStatusStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowGrantsStmt ************************************************}

class function TMySQLParser.TShowGrantsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowGrants);

  with PShowGrantsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.ForValue);
  end;
end;

{ TMySQLParser.TShowIndexStmt *************************************************}

class function TMySQLParser.TShowIndexStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowIndex);

  with PShowIndexStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.FromTableValue);
    Heritage.Heritage.AddChild(ANodes.FromDatabaseValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowMasterStatusStmt ******************************************}

class function TMySQLParser.TShowMasterStatusStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowMasterStatus);

  with PShowMasterStatusStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowOpenTablesStmt ********************************************}

class function TMySQLParser.TShowOpenTablesStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowOpenTables);

  with PShowOpenTablesStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.FromDatabaseValue);
    Heritage.Heritage.AddChild(ANodes.LikeValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowPluginsStmt ***********************************************}

class function TMySQLParser.TShowPluginsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowPlugins);

  with PShowPluginsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowPrivilegesStmt ********************************************}

class function TMySQLParser.TShowPrivilegesStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowPrivileges);

  with PShowPrivilegesStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowProcedureCodeStmt *****************************************}

class function TMySQLParser.TShowProcedureCodeStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowProcedureCode);

  with PShowProcedureCodeStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowProcedureStatusStmt ***************************************}

class function TMySQLParser.TShowProcedureStatusStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowProcedureStatus);

  with PShowProcedureStatusStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.LikeValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowProcessListStmt *******************************************}

class function TMySQLParser.TShowProcessListStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowProcessList);

  with PShowProcessListStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowProfileStmt ***********************************************}

class function TMySQLParser.TShowProfileStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowProfile);

  with PShowProfileStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.TypeList);
    Heritage.Heritage.AddChild(ANodes.ForQueryValue);
    Heritage.Heritage.AddChild(ANodes.LimitValue);
    Heritage.Heritage.AddChild(ANodes.OffsetValue);
  end;
end;

{ TMySQLParser.TShowProfilesStmt **********************************************}

class function TMySQLParser.TShowProfilesStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowProfiles);

  with PShowProfilesStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowRelaylogEventsStmt ****************************************}

class function TMySQLParser.TShowRelaylogEventsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowRelaylogEvents);

  with PShowRelaylogEventsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.InValue);
    Heritage.Heritage.AddChild(ANodes.FromValue);
    Heritage.Heritage.AddChild(ANodes.LimitTag);
    Heritage.Heritage.AddChild(ANodes.OffsetToken);
    Heritage.Heritage.AddChild(ANodes.CommaToken);
    Heritage.Heritage.AddChild(ANodes.RowCountToken);
  end;
end;

{ TMySQLParser.TShowSlaveHostsStmt ********************************************}

class function TMySQLParser.TShowSlaveHostsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowSlaveHosts);

  with PShowSlaveHostsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowSlaveStatusStmt *******************************************}

class function TMySQLParser.TShowSlaveStatusStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowSlaveStatus);

  with PShowSlaveStatusStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TShowStatusStmt ************************************************}

class function TMySQLParser.TShowStatusStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowStatus);

  with PShowStatusStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.ShowTag);
    Heritage.Heritage.AddChild(ANodes.ScopeTag);
    Heritage.Heritage.AddChild(ANodes.StatusTag);
    Heritage.Heritage.AddChild(ANodes.LikeValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowTableStatusStmt *******************************************}

class function TMySQLParser.TShowTableStatusStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowTableStatus);

  with PShowTableStatusStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.ShowTag);
    Heritage.Heritage.AddChild(ANodes.FromValue);
    Heritage.Heritage.AddChild(ANodes.LikeValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowTablesStmt ************************************************}

class function TMySQLParser.TShowTablesStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowTables);

  with PShowTablesStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.ShowTag);
    Heritage.Heritage.AddChild(ANodes.FullTag);
    Heritage.Heritage.AddChild(ANodes.TablesTag);
    Heritage.Heritage.AddChild(ANodes.FromValue);
    Heritage.Heritage.AddChild(ANodes.LikeValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowTriggersStmt **********************************************}

class function TMySQLParser.TShowTriggersStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowTriggers);

  with PShowTriggersStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.FromValue);
    Heritage.Heritage.AddChild(ANodes.LikeValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowVariablesStmt **********************************************}

class function TMySQLParser.TShowVariablesStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowVariables);

  with PShowVariablesStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.ShowTag);
    Heritage.Heritage.AddChild(ANodes.ScopeTag);
    Heritage.Heritage.AddChild(ANodes.VariablesTag);
    Heritage.Heritage.AddChild(ANodes.LikeValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
  end;
end;

{ TMySQLParser.TShowWarningsStmt **********************************************}

class function TMySQLParser.TShowWarningsStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShowWarnings);

  with PShowWarningsStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.Limit.LimitTag);
    Heritage.Heritage.AddChild(ANodes.Limit.OffsetToken);
    Heritage.Heritage.AddChild(ANodes.Limit.CommaToken);
    Heritage.Heritage.AddChild(ANodes.Limit.RowCountToken);
  end;
end;

{ TMySQLParser.TShutdownStmt **************************************************}

class function TMySQLParser.TShutdownStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stShutdown);

  with PShutdownStmt(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TSignalStmt ****************************************************}

class function TMySQLParser.TSignalStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stSignal);

  with PSignalStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
    Heritage.Heritage.AddChild(ANodes.Condition);
    Heritage.Heritage.AddChild(ANodes.SetTag);
    Heritage.Heritage.AddChild(ANodes.InformationList);
  end;
end;

{ TMySQLParser.TSignalStmt.TInformation ***************************************}

class function TMySQLParser.TSignalStmt.TInformation.Create(const AParser: TMySQLParser; const ANodes: TInformation.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSignalStmtInformation);

  with PInformation(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.Value);
  end;
end;

{ TMySQLParser.TSubstringFunc ******************************************************}

class function TMySQLParser.TSubstringFunc.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSubstringFunc);

  with PSubstringFunc(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.FuncToken);
    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.Str);
    Heritage.AddChild(ANodes.FromTag);
    Heritage.AddChild(ANodes.Pos);
    Heritage.AddChild(ANodes.ForTag);
    Heritage.AddChild(ANodes.Len);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TSoundsLikeOp **************************************************}

class function TMySQLParser.TSoundsLikeOp.Create(const AParser: TMySQLParser; const AOperator1, AOperator2: TOffset; const AOperand1, AOperand2: TOffset): TOffset;
begin
  Result := TRange.Create(AParser, ntSoundsLikeOp);

  with PSoundsLikeOp(AParser.NodePtr(Result))^ do
  begin
    FNodes.Operator1 := AOperator1;
    FNodes.Operator2 := AOperator2;
    FNodes.Operand1 := AOperand1;
    FNodes.Operand2 := AOperand2;

    Heritage.AddChild(AOperator1);
    Heritage.AddChild(AOperator2);
    Heritage.AddChild(AOperand1);
    Heritage.AddChild(AOperand2);
  end;
end;

{ TMySQLParser.TStartSlaveStmt ******************************************}

class function TMySQLParser.TStartSlaveStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stStartSlave);

  with PStartSlaveStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TStartTransactionStmt ******************************************}

class function TMySQLParser.TStartTransactionStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stStartTransaction);

  with PStartTransactionStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StartTransactionTag);
    Heritage.Heritage.AddChild(ANodes.RealOnlyTag);
    Heritage.Heritage.AddChild(ANodes.ReadWriteTag);
    Heritage.Heritage.AddChild(ANodes.WithConsistentSnapshotTag);
  end;
end;

{ TMySQLParser.TStopSlaveStmt ******************************************}

class function TMySQLParser.TStopSlaveStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stStopSlave);

  with PStopSlaveStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtTag);
  end;
end;

{ TMySQLParser.TSubArea *******************************************************}

class function TMySQLParser.TSubArea.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSubArea);

  with PSubArea(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.AreaNode);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TSubPartition **************************************************}

class function TMySQLParser.TSubPartition.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntSubPartition);

  with PSubPartition(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.SubPartitionTag);
    Heritage.AddChild(ANodes.NameIdent);
    Heritage.AddChild(ANodes.EngineValue);
    Heritage.AddChild(ANodes.CommentValue);
    Heritage.AddChild(ANodes.DataDirectoryValue);
    Heritage.AddChild(ANodes.IndexDirectoryValue);
    Heritage.AddChild(ANodes.MaxRowsValue);
    Heritage.AddChild(ANodes.MinRowsValue);
  end;
end;

{ TMySQLParser.TTableReference ************************************************}

class function TMySQLParser.TTableReference.Create(const AParser: TMySQLParser; const AFirstTable: TOffset; const AJoinCount: Integer; const AJoins: array of TOffset): TOffset;
var
  I: Integer;
begin
  Result := TRange.Create(AParser, ntTableReference);

  with PTableReference(AParser.NodePtr(Result))^ do
  begin
    FNodes.FirstTable := AFirstTable;

    Heritage.AddChild(AFirstTable);
    for I := 0 to AJoinCount - 1 do
      Heritage.AddChild(AJoins[I]);
  end;
end;

function TMySQLParser.TTableReference.GetJoinCount(): Integer;
var
  Child: PChild;
begin
  Result := 0;

  Child := Parser.ChildPtr(FNodes.FirstTable);
  while (Assigned(Child)) do
  begin
    Inc(Result);
    Child := Child^.NextSibling;
  end;
end;

function TMySQLParser.TTableReference.GetFirstTable(): PChild;
begin
  Result := PChild(Parser.NodePtr(FNodes.FirstTable));
end;

{ TMySQLParser.TTag ***********************************************************}

class function TMySQLParser.TTag.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntTag);

  with PTag(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.AddChild(ANodes.KeywordToken1);
    Heritage.AddChild(ANodes.KeywordToken2);
    Heritage.AddChild(ANodes.KeywordToken3);
    Heritage.AddChild(ANodes.KeywordToken4);
  end;
end;

{ TMySQLParser.TTruncateStmt **************************************************}

class function TMySQLParser.TTruncateStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stTruncate);

  with PTruncateStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.TruncateTag);
    Heritage.Heritage.AddChild(ANodes.TableTag);
    Heritage.Heritage.AddChild(ANodes.TableIdent);
  end;
end;

{ TMySQLParser.TTrimFunc ****************************************************}

class function TMySQLParser.TTrimFunc.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntTrimFunc);

  with PTrimFunc(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.FuncToken);
    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.DirectionTag);
    Heritage.AddChild(ANodes.RemoveStr);
    Heritage.AddChild(ANodes.FromTag);
    Heritage.AddChild(ANodes.Str);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TUnaryOp *******************************************************}

class function TMySQLParser.TUnaryOp.Create(const AParser: TMySQLParser; const AOperator, AOperand: TOffset): TOffset;
begin
  Result := TRange.Create(AParser, ntUnaryOp);

  with PUnaryOp(AParser.NodePtr(Result))^ do
  begin
    FNodes.Operator := AOperator;
    FNodes.Operand := AOperand;

    Heritage.AddChild(AOperator);
    Heritage.AddChild(AOperand);
  end;
end;

{ TMySQLParser.TUnknownStmt ***************************************************}

class function TMySQLParser.TUnknownStmt.Create(const AParser: TMySQLParser; const ATokenCount: Integer; const ATokens: array of TOffset): TOffset;
var
  I: Integer;
begin
  Result := TStmt.Create(AParser, stUnknown);

  with PUnknownStmt(AParser.NodePtr(Result))^ do
  begin
    for I := 0 to ATokenCount - 1 do
      Heritage.Heritage.AddChild(TOffset(ATokens[I]));
  end;
end;

{ TMySQLParser.TUnlockStmt ****************************************************}

class function TMySQLParser.TUnlockStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stUnlock);

  with PUnlockStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.UnlockTablesTag);
  end;
end;

{ TMySQLParser.TUpdateStmt ****************************************************}

class function TMySQLParser.TUpdateStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stUpdate);

  with PUpdateStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.UpdateTag);
    Heritage.Heritage.AddChild(ANodes.PriorityTag);
    Heritage.Heritage.AddChild(ANodes.TableReferenceList);
    Heritage.Heritage.AddChild(ANodes.SetValue);
    Heritage.Heritage.AddChild(ANodes.WhereValue);
    Heritage.Heritage.AddChild(ANodes.OrderByValue);
    Heritage.Heritage.AddChild(ANodes.LimitValue);
  end;
end;

{ TMySQLParser.TUser **********************************************************}

class function TMySQLParser.TUser.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntUser);

  with PUser(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.NameToken);
    Heritage.AddChild(ANodes.AtToken);
    Heritage.AddChild(ANodes.HostToken);
  end;
end;

{ TMySQLParser.TUseStmt *******************************************************}

class function TMySQLParser.TUseStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stUse);

  with PUseStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.StmtToken);
    Heritage.Heritage.AddChild(ANodes.DbNameNode);
  end;
end;

{ TMySQLParser.TValue *********************************************************}

class function TMySQLParser.TValue.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntValue);

  with PValue(AParser.NodePtr(Result))^ do
  begin
    Nodes := ANodes;

    Heritage.AddChild(ANodes.IdentTag);
    Heritage.AddChild(ANodes.AssignToken);
    Heritage.AddChild(ANodes.ValueToken);
  end;
end;

{ TMySQLParser.TVariable ******************************************************}

class function TMySQLParser.TVariable.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntVariable);

  with PVariable(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.At1Token);
    Heritage.AddChild(ANodes.At2Token);
    Heritage.AddChild(ANodes.ScopeTag);
    Heritage.AddChild(ANodes.ScopeDotToken);
    Heritage.AddChild(ANodes.Ident);
  end;
end;

{ TMySQLParser.TWeightStringFunc **********************************************}

class function TMySQLParser.TWeightStringFunc.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntWeightStringFunc);

  with PWeightStringFunc(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.FuncToken);
    Heritage.AddChild(ANodes.OpenBracket);
    Heritage.AddChild(ANodes.Str);
    Heritage.AddChild(ANodes.AsTag);
    Heritage.AddChild(ANodes.DataType);
    Heritage.AddChild(ANodes.LevelTag);
    Heritage.AddChild(ANodes.LevelList);
    Heritage.AddChild(ANodes.CloseBracket);
  end;
end;

{ TMySQLParser.TWeightStringFunc.TLevel ***************************************}

class function TMySQLParser.TWeightStringFunc.TLevel.Create(const AParser: TMySQLParser; const ANodes: TLevel.TNodes): TOffset;
begin
  Result := TRange.Create(AParser, ntWeightStringFuncLevel);

  with TWeightStringFunc.PLevel(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.CountInt);
    Heritage.AddChild(ANodes.DirectionTag);
  end;
end;

{ TMySQLParser.TWhileStmt *****************************************************}

class function TMySQLParser.TWhileStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stWhile);

  with PWhileStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.BeginLabelToken);
    Heritage.Heritage.AddChild(ANodes.WhileTag);
    Heritage.Heritage.AddChild(ANodes.SearchConditionExpr);
    Heritage.Heritage.AddChild(ANodes.DoTag);
    Heritage.Heritage.AddChild(ANodes.StmtList);
    Heritage.Heritage.AddChild(ANodes.EndTag);
    Heritage.Heritage.AddChild(ANodes.EndLabelToken);
  end;
end;

{ TMySQLParser.TXAStmt ********************************************************}

class function TMySQLParser.TXAStmt.Create(const AParser: TMySQLParser; const ANodes: TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stXA);

  with PXAStmt(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.Heritage.AddChild(ANodes.XATag);
    Heritage.Heritage.AddChild(ANodes.ActionTag);
    Heritage.Heritage.AddChild(ANodes.Ident);
    Heritage.Heritage.AddChild(ANodes.RestTag);
  end;
end;

{ TMySQLParser.TXAStmt.TID ****************************************************}

class function TMySQLParser.TXAStmt.TID.Create(const AParser: TMySQLParser; const ANodes: TID.TNodes): TOffset;
begin
  Result := TStmt.Create(AParser, stXA);

  with PID(AParser.NodePtr(Result))^ do
  begin
    FNodes := ANodes;

    Heritage.AddChild(ANodes.GTrId);
    Heritage.AddChild(ANodes.Comma1);
    Heritage.AddChild(ANodes.BQual);
    Heritage.AddChild(ANodes.Comma2);
    Heritage.AddChild(ANodes.FormatId);
  end;
end;

{ TMySQLParser ****************************************************************}

function TMySQLParser.ApplyCurrentToken(): TOffset;
begin
  Result := ApplyCurrentToken(utUnknown);
end;

function TMySQLParser.ApplyCurrentToken(const AUsageType: TUsageType; const ATokenType: fspTypes.TTokenType = fspTypes.ttUnknown): TOffset;
begin
  Result := CurrentToken;

  if (Result > 0) then
  begin
    if (AUsageType <> utUnknown) then
      TokenPtr(Result)^.FUsageType := AUsageType;
    if (ATokenType <> ttUnknown) then
      TokenPtr(Result)^.FTokenType := ATokenType;

    Dec(TokenBuffer.Count);
    Move(TokenBuffer.Tokens[1], TokenBuffer.Tokens[0], TokenBuffer.Count * SizeOf(TokenBuffer.Tokens[0]));

    FPreviousToken := FCurrentToken;
    FCurrentToken := GetParsedToken(0); // Cache for speeding
  end;
end;

procedure TMySQLParser.BeginPL_SQL();
begin
  Inc(FInPL_SQL);
end;

function TMySQLParser.ChildPtr(const ANode: TOffset): PChild;
begin
  if (not IsChild(NodePtr(ANode))) then
    Result := nil
  else
    Result := @ParsedNodes.Mem[ANode];
end;

procedure TMySQLParser.Clear();
begin
  FErrorCode := PE_Success;
  FErrorLine := 1;
  FErrorToken := 0;
  {$IFDEF Debug} TokenIndex := 0; {$ENDIF}
  FInPL_SQL := 0;
  if (Assigned(ParsedNodes.Mem)) then begin FreeMem(ParsedNodes.Mem); ParsedNodes.Mem := nil; end;
  ParsedNodes.UsedSize := 0;
  ParsedNodes.MemSize := 0;
  ParseText := '';
  ParsePosition.Text := nil;
  ParsePosition.Length := 0;
  FRoot := 0;
  if (Assigned(ReplaceTexts.Mem)) then begin FreeMem(ReplaceTexts.Mem); ReplaceTexts.Mem := nil; end;
  InCreateFunctionStmt := False;
  InCreateProcedureStmt := False;
  SetLength(MySQLVersions, 0);
  TokenBuffer.Count := 0;
end;

constructor TMySQLParser.Create(const AMySQLVersion: Integer = 0);
begin
  inherited Create();

  SetLength(MySQLVersions, 0);

  Commands := nil;
  FAnsiQuotes := False;
  FunctionList := TWordList.Create(Self);
  TokenIndex := 0;
  KeywordList := TWordList.Create(Self);
  FMySQLVersion := AMySQLVersion;
  ParsedNodes.Mem := nil;
  ParsedNodes.UsedSize := 0;
  ParsedNodes.MemSize := 0;
  ReplaceTexts.Mem := nil;
  TokenBuffer.Count := 0;

  Functions := MySQLFunctions;
  Keywords := MySQLKeywords;
end;

destructor TMySQLParser.Destroy();
begin
  Clear();

  FunctionList.Free();
  KeywordList.Free();

  inherited;
end;

function TMySQLParser.EndOfStmt(const Token: PToken): Boolean;
begin
  Result := Token^.TokenType = ttDelimiter;
end;

function TMySQLParser.EndOfStmt(const Token: TOffset): Boolean;
begin
  Result := (Token = 0) or (TokenPtr(Token)^.TokenType = ttDelimiter);
end;

procedure TMySQLParser.EndPL_SQL();
begin
  Assert(FInPL_SQL > 0);

  if (FInPL_SQL > 0) then
    Dec(FInPL_SQL);
end;

procedure TMySQLParser.FormatAnalyzeStmt(const Nodes: TAnalyzeStmt.TNodes);
begin
  FormatNode(Nodes.StmtTag);

  if (Nodes.NoWriteToBinlogTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.NoWriteToBinlogTag);
  end;

  Commands.WriteSpace();
  FormatNode(Nodes.TableTag);

  Commands.WriteSpace();
  FormatNode(Nodes.TablesList);
end;

procedure TMySQLParser.FormatAlterDatabaseStmt(const Nodes: TAlterDatabaseStmt.TNodes);
begin
  FormatNode(Nodes.StmtTag);

  if (Nodes.IdentTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.IdentTag);
  end;

  if (Nodes.UpgradeDataDirectoryNameTag = 0) then
  begin
    if (Nodes.CharacterSetValue > 0) then
    begin
      Commands.WriteSpace();
      FormatNode(Nodes.CharacterSetValue);
    end;

    if (Nodes.CollateValue > 0) then
    begin
      Commands.WriteSpace();
      FormatNode(Nodes.CollateValue);
    end;
  end
  else
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.UpgradeDataDirectoryNameTag);
  end;
end;

procedure TMySQLParser.FormatAlterEventStmt(const Nodes: TAlterEventStmt.TNodes);
begin
  FormatNode(Nodes.AlterTag);

  if (Nodes.DefinerNode > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.DefinerNode);
  end;

  Commands.WriteSpace();
  FormatNode(Nodes.EventTag);

  Commands.WriteSpace();
  FormatNode(Nodes.EventIdent);

  if (Nodes.OnSchedule.Tag > 0) then
  begin
    Assert(Nodes.OnSchedule.Value > 0);

    Commands.IncreaseIndent();
    Commands.WriteReturn();
    FormatNode(Nodes.OnSchedule.Tag);
    Commands.IncreaseIndent();
    Commands.WriteReturn();
    FormatNode(Nodes.OnSchedule.Value);
    Commands.DecreaseIndent();
    Commands.DecreaseIndent();
  end;

  if (Nodes.OnCompletitionTag > 0) then
  begin
    Commands.IncreaseIndent();
    Commands.WriteReturn();
    FormatNode(Nodes.OnCompletitionTag);
    Commands.DecreaseIndent();
  end;

  if (Nodes.RenameValue > 0) then
  begin
    Commands.IncreaseIndent();
    Commands.WriteReturn();
    FormatNode(Nodes.RenameValue);
    Commands.DecreaseIndent();
  end;

  if (Nodes.EnableTag > 0) then
  begin
    Commands.IncreaseIndent();
    Commands.WriteReturn();
    FormatNode(Nodes.EnableTag);
    Commands.DecreaseIndent();
  end;

  if (Nodes.CommentValue > 0) then
  begin
    Commands.IncreaseIndent();
    Commands.WriteReturn();
    FormatNode(Nodes.CommentValue);
    Commands.DecreaseIndent();
  end;

  if (Nodes.DoTag > 0) then
  begin
    Assert(Nodes.Body > 0);

    Commands.IncreaseIndent();
    Commands.WriteReturn();
    FormatNode(Nodes.DoTag);
    Commands.IncreaseIndent();
    Commands.WriteReturn();
    FormatNode(Nodes.Body);
    Commands.DecreaseIndent();
    Commands.DecreaseIndent();
  end;
end;

procedure TMySQLParser.FormatAlterInstanceStmt(const Nodes: TAlterInstanceStmt.TNodes);
begin
  FormatNode(Nodes.StmtTag);
  Commands.WriteSpace();
  FormatNode(Nodes.RotateTag);
end;

procedure TMySQLParser.FormatAlterRoutineStmt(const Nodes: TAlterRoutineStmt.TNodes);
var
  List: PList;
  Child: PChild;
  Value: PValue;
  Tag: PTag;
  Token: PToken;
begin
  FormatNode(Nodes.AlterTag);
  Commands.WriteSpace();
  FormatNode(Nodes.IdentNode);

  if (Nodes.CharacteristicList > 0) then
  begin
    Commands.IncreaseIndent();

    List := PList(NodePtr(Nodes.CharacteristicList));

    Child := List^.FirstChild;
    while (Assigned(Child)) do
    begin
      if (Child^.NodeType = ntTag) then
      begin
        Commands.WriteReturn();
        FormatNode(PNode(Child));
      end;

      Child := Child^.NextSibling;
    end;

    Child := List^.FirstChild;
    while (Assigned(Child)) do
    begin
      if (Child^.NodeType = ntValue) then
      begin
        Value := PValue(Child);
        if (NodePtr(Value^.Nodes.IdentTag)^.NodeType = ntTag) then
        begin
          Tag := PTag(NodePtr(Value^.Nodes.IdentTag));
          if (IsToken(Tag^.Nodes.KeywordToken1)) then
          begin
            Token := TokenPtr(Tag^.Nodes.KeywordToken1);
            if (Token^.KeywordIndex = kiCOMMENT) then
            begin
              Commands.WriteReturn();
              FormatNode(PNode(Child));
            end;
          end;
        end;
      end;

      Child := Child^.NextSibling;
    end;

    Commands.DecreaseIndent();
  end;
end;

procedure TMySQLParser.FormatAlterServerStmt(const Nodes: TAlterServerStmt.TNodes);
begin
  FormatNode(Nodes.StmtTag);

  Commands.WriteSpace();
  FormatNode(Nodes.IdentNode);

  Commands.WriteSpace();
  FormatNode(Nodes.Options.Tag);

  Commands.WriteSpace();
  FormatNode(Nodes.Options.List);
end;

procedure TMySQLParser.FormatAlterTableStmt(const Nodes: TAlterTableStmt.TNodes);
begin
  FormatNode(Nodes.AlterTag);

  if (Nodes.IgnoreTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.IgnoreTag);
  end;

  Commands.WriteSpace();
  FormatNode(Nodes.TableTag);

  Commands.WriteSpace();
  FormatNode(Nodes.IdentNode);

  Commands.IncreaseIndent();

  if (Nodes.SpecificationList > 0) then
  begin
    Commands.WriteReturn();
    FormatList(Nodes.SpecificationList, ddReturn);
  end;

  if (Nodes.AlgorithmValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.AlgorithmValue);
  end;

  if (Nodes.ConvertToCharacterSetNode > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.ConvertToCharacterSetNode);
  end;

  if (Nodes.DiscardTablespaceTag > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.DiscardTablespaceTag);
  end;

  if (Nodes.EnableKeys > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.EnableKeys);
  end;

  if (Nodes.ForceTag > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.ForceTag);
  end;

  if (Nodes.ImportTablespaceTag > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.ImportTablespaceTag);
  end;

  if (Nodes.LockValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.LockValue);
  end;

  if (Nodes.OrderByValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.OrderByValue);
  end;

  if (Nodes.RenameNode > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.RenameNode);
  end;

  if (Nodes.TableOptionsNodes.AutoIncrementValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.AutoIncrementValue);
  end;

  if (Nodes.TableOptionsNodes.AvgRowLengthValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.AvgRowLengthValue);
  end;

  if (Nodes.TableOptionsNodes.CharacterSetValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.CharacterSetValue);
  end;

  if (Nodes.TableOptionsNodes.ChecksumValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.ChecksumValue);
  end;

  if (Nodes.TableOptionsNodes.CollateValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.CollateValue);
  end;

  if (Nodes.TableOptionsNodes.CommentValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.CommentValue);
  end;

  if (Nodes.TableOptionsNodes.ConnectionValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.ConnectionValue);
  end;

  if (Nodes.TableOptionsNodes.DataDirectoryValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.DataDirectoryValue);
  end;

  if (Nodes.TableOptionsNodes.DelayKeyWriteValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.DelayKeyWriteValue);
  end;

  if (Nodes.TableOptionsNodes.EngineValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.EngineValue);
  end;

  if (Nodes.TableOptionsNodes.IndexDirectoryValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.IndexDirectoryValue);
  end;

  if (Nodes.TableOptionsNodes.InsertMethodValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.InsertMethodValue);
  end;

  if (Nodes.TableOptionsNodes.KeyBlockSizeValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.KeyBlockSizeValue);
  end;

  if (Nodes.TableOptionsNodes.MaxRowsValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.MaxRowsValue);
  end;

  if (Nodes.TableOptionsNodes.MinRowsValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.MinRowsValue);
  end;

  if (Nodes.TableOptionsNodes.PackKeysValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.PackKeysValue);
  end;

  if (Nodes.TableOptionsNodes.PageChecksum > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.PageChecksum);
  end;

  if (Nodes.TableOptionsNodes.PasswordValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.PasswordValue);
  end;

  if (Nodes.TableOptionsNodes.RowFormatValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.RowFormatValue);
  end;

  if (Nodes.TableOptionsNodes.StatsAutoRecalcValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.StatsAutoRecalcValue);
  end;

  if (Nodes.TableOptionsNodes.StatsPersistentValue > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.StatsPersistentValue);
  end;

  if (Nodes.TableOptionsNodes.UnionList > 0) then
  begin
    Commands.WriteReturn();
    FormatNode(Nodes.TableOptionsNodes.UnionList);
  end;

  Commands.DecreaseIndent();
end;

procedure TMySQLParser.FormatAlterTableStmtAlterColumn(const Nodes: TAlterTableStmt.TAlterColumn.TNodes);
begin
  FormatNode(Nodes.AlterTag);
  Commands.WriteSpace();
  FormatNode(Nodes.ColumnIdent);

  if (Nodes.SetDefaultValue > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.SetDefaultValue);
  end
  else if (Nodes.DropDefaultTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.DropDefaultTag);
  end;
end;

procedure TMySQLParser.FormatAlterTableStmtConvertTo(const Nodes: TAlterTableStmt.TConvertTo.TNodes);
begin
  FormatNode(Nodes.ConvertToTag);

  Commands.WriteSpace();
  FormatNode(Nodes.CharacterSetValue);

  if (Nodes.CollateValue > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.CollateValue);
  end;
end;

procedure TMySQLParser.FormatAlterTableStmtDropObject(const Nodes: TAlterTableStmt.TDropObject.TNodes);
begin
  FormatNode(Nodes.DropTag);
  Commands.WriteSpace();
  FormatNode(Nodes.ItemTypeTag);
  Commands.WriteSpace();
  FormatNode(Nodes.Ident);
end;

procedure TMySQLParser.FormatCreateTableStmtColumn(const Nodes: TCreateTableStmt.TColumn.TNodes);
begin
  FormatNode(Nodes.AddTag);

  if (Nodes.ColumnTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.ColumnTag);
  end;

  if (Nodes.OldNameIdent > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.OldNameIdent);
  end;

  if (Nodes.NameIdent > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.NameIdent);
  end;

  Commands.WriteSpace();
  FormatNode(Nodes.DataTypeNode);

  if (Nodes.BinaryTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.BinaryTag);
  end;

  if (Nodes.Null > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.Null);
  end;

  if (Nodes.DefaultValue > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.DefaultValue);
  end;

  if (Nodes.OnUpdateTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.OnUpdateTag);
  end;

  if (Nodes.AutoIncrementTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.AutoIncrementTag);
  end;

  if (Nodes.KeyTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.KeyTag);
  end;

  if (Nodes.CommentValue > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.CommentValue);
  end;

  if (Nodes.ColumnFormat > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.ColumnFormat);
  end;

  if (Nodes.Position > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.Position);
  end;
end;

procedure TMySQLParser.FormatCreateTableStmtKey(const Nodes: TCreateTableStmt.TKey.TNodes);
begin
  if (Nodes.AddTag > 0) then
  begin
    FormatNode(Nodes.AddTag);
    Commands.WriteSpace();
  end;

  if (Nodes.ConstraintTag > 0) then
  begin
    FormatNode(Nodes.ConstraintTag);
    Commands.WriteSpace();
  end;

  if (Nodes.SymbolIdent > 0) then
  begin
    FormatNode(Nodes.SymbolIdent);
    Commands.WriteSpace();
  end;

  FormatNode(Nodes.KeyTag);

  if (Nodes.KeyIdent > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.KeyIdent);
  end;

  if (Nodes.IndexTypeTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.IndexTypeTag);
  end;

  Commands.WriteSpace();
  FormatList(Nodes.ColumnIdentList, ddNone);

  if (Nodes.KeyBlockSizeValue > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.KeyBlockSizeValue);
  end;

  if (Nodes.IndexTypeTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.IndexTypeTag);
  end;

  if (Nodes.ParserValue > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.ParserValue);
  end;

  if (Nodes.CommentValue > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.CommentValue);
  end;
end;

procedure TMySQLParser.FormatCreateTableStmtKeyColumn(const Nodes: TCreateTableStmt.TKeyColumn.TNodes);
begin
  FormatNode(Nodes.IdentTag);

  if (Nodes.OpenBracketToken > 0) then
  begin
    FormatNode(Nodes.OpenBracketToken);
    FormatNode(Nodes.LengthToken);
    FormatNode(Nodes.CloseBracketToken);
  end;

  if (Nodes.SortTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.SortTag);
  end;
end;

procedure TMySQLParser.FormatComments(const Token: PToken; const BeforeStmt: Boolean = False);
var
  Comment: string;
  I: Integer;
  ReturnFound: Boolean;
  ReturnNeeded: Boolean;
  T: PToken;
begin
  ReturnNeeded := False; ReturnFound := False;
  T := Token;
  while (Assigned(T) and not T^.IsUsed) do
  begin
    case (T^.TokenType) of
      ttReturn:
        ReturnFound := True;
      ttLineComment:
        begin
          if (ReturnNeeded) then
            Commands.WriteReturn()
          else if (not BeforeStmt) then
            if (not ReturnFound) then
              Commands.WriteSpace()
            else
              Commands.WriteReturn();
          Commands.Write(T^.SQL, T^.Length);
          ReturnNeeded := BeforeStmt;
          ReturnFound := False;
        end;
      ttMultiLineComment:
        begin
          Comment := Trim(Token^.AsString);
          if (Pos(#13#10, Comment) = 0) then
          begin
            if (ReturnNeeded) then
              Commands.WriteReturn()
            else if (not BeforeStmt) then
              Commands.WriteIndent();
            Commands.Write('/* ');
            Commands.Write(Token^.AsString);
            Commands.Write(' */');
            Commands.WriteReturn();
          end
          else
          begin
            if (ReturnNeeded) then
              Commands.WriteReturn()
            else if (not BeforeStmt) then
              Commands.WriteIndent();
            Commands.Write('/*');
            Commands.IncreaseIndent();
            Commands.WriteReturn();

            I := Pos(#13#10, Comment);
            while (I > 0) do
            begin
              Commands.Write(Copy(Comment, 1, I - 1));
              Commands.WriteReturn();
              System.Delete(Comment, 1, I + 1);
              I := Pos(#13#10, Comment);
            end;
            Commands.Write(Comment);

            Commands.DecreaseIndent();
            Commands.WriteReturn();
            Commands.Write('*/');
            ReturnNeeded := True;
          end;
          ReturnFound := False;
        end;
      ttMySQLIdent,
      ttBeginLabel:
        Commands.Write(T^.SQL, T^.Length);
    end;

    T := T^.NextTokenAll;
  end;

  if (ReturnNeeded) then
    Commands.WriteReturn();
end;

procedure TMySQLParser.FormatDataType(const Nodes: TDataType.TNodes);
begin
  if (Nodes.NationalTag > 0) then
  begin
    FormatNode(Nodes.NationalTag);
    Commands.WriteSpace();
  end;

  FormatNode(Nodes.IdentToken);
  if (Nodes.OpenBracketToken > 0) then
  begin
    FormatNode(Nodes.OpenBracketToken);
    FormatNode(Nodes.LengthToken);
    FormatNode(Nodes.CommaToken);
    FormatNode(Nodes.CloseBracketToken);
  end
  else if (Nodes.ItemsList > 0) then
    FormatList(Nodes.ItemsList, ddNone);

  if (Nodes.UnsignedTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.UnsignedTag);
  end;

  if (Nodes.ZerofillTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.ZerofillTag);
  end;

  if (Nodes.CharacterSetValue > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.CharacterSetValue);
  end;

  if (Nodes.CollateValue > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.CharacterSetValue);
  end;

  if (Nodes.BinaryTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.BinaryTag);
  end;

  if (Nodes.ASCIITag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.ASCIITag);
  end;

  if (Nodes.UnicodeTag > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.UnicodeTag);
  end;
end;

procedure TMySQLParser.FormatDbIdent(const Nodes: TDbIdent.TNodes);

  procedure FormatQuotes(const Node: TOffset);
  begin
    Assert(IsToken(Node));

    if (AnsiQuotes) then
      TokenPtr(Node)^.FTokenType := ttDQIdent
    else
      TokenPtr(Node)^.FTokenType := ttMySQLIdent;
    FormatNode(Node);
  end;

begin
  if (Nodes.DatabaseIdent > 0) then
  begin
    Assert(Nodes.DatabaseDot > 0);

    FormatQuotes(Nodes.DatabaseIdent);
    FormatNode(Nodes.DatabaseDot);
  end;

  if (Nodes.TableIdent > 0) then
  begin
    FormatQuotes(Nodes.TableIdent);

    if (Nodes.TableDot > 0) then
      FormatNode(Nodes.TableDot);
  end;

  FormatQuotes(Nodes.Ident);
end;

procedure TMySQLParser.FormatIntervalOp(const Nodes: TIntervalOp.TNodes);
begin
  FormatNode(Nodes.QuantityExp);
  Commands.WriteSpace();
  FormatNode(Nodes.UnitTag);
end;

procedure TMySQLParser.FormatList(const Nodes: TList.TNodes);
begin
  case (Nodes.DelimiterType) of
    ttComma: FormatList(Nodes, ddSpace);
    ttDot: FormatList(Nodes, ddNone);
    ttDelimiter: FormatList(Nodes, ddReturn);
    else FormatList(Nodes, ddSpace);
  end;
end;

procedure TMySQLParser.FormatList(const Nodes: TList.TNodes; const DelimiterDevider: TDelimiterDevider);
var
  Child: PChild;
begin
  if (Nodes.OpenBracket > 0) then
    FormatNode(Nodes.OpenBracket);

  Child := ChildPtr(Nodes.FirstChild);
  repeat
    FormatNode(PNode(Child));
    Child := Child^.NextSibling;
    if (Assigned(Child)) then
    begin
      case (Nodes.DelimiterType) of
        ttComma: Commands.Write(',');
        ttDot: Commands.Write('.');
        ttDelimiter: Commands.Write(';');
        else SetError(PE_InvalidNodeValue);
      end;
      case (DelimiterDevider) of
        ddSpace: Commands.WriteSpace();
        ddReturn: Commands.WriteReturn();
      end;
    end;
  until (not Assigned(Child));

  if (Nodes.CloseBracket > 0) then
    FormatNode(Nodes.CloseBracket);
end;

procedure TMySQLParser.FormatList(const Node: TOffset; const DelimiterDevider: TDelimiterDevider);
begin
  Assert(NodePtr(Node)^.NodeType = ntList);

  FormatList(PList(NodePtr(Node))^.Nodes, DelimiterDevider);
end;

procedure TMySQLParser.FormatNode(const Node: PNode);
var
  Token: PToken;
begin
  if (IsStmt(Node)) then
    FormatComments(PStmt(Node)^.FirstTokenAll, True);

  if (Assigned(Node)) then
    case (Node^.NodeType) of
      ntToken: FormatToken(PToken(Node));

      ntAnalyzeStmt: FormatAnalyzeStmt(PAnalyzeStmt(Node)^.Nodes);
      ntAlterDatabaseStmt: FormatAlterDatabaseStmt(PAlterDatabaseStmt(Node)^.Nodes);
      ntAlterEventStmt: FormatAlterEventStmt(PAlterEventStmt(Node)^.Nodes);
      ntAlterInstanceStmt: FormatAlterInstanceStmt(PAlterInstanceStmt(Node)^.Nodes);
      ntAlterRoutineStmt: FormatAlterRoutineStmt(PAlterRoutineStmt(Node)^.Nodes);
      ntAlterServerStmt: FormatAlterServerStmt(PAlterServerStmt(Node)^.Nodes);
      ntAlterTableStmt: FormatAlterTableStmt(PAlterTableStmt(Node)^.Nodes);
      ntAlterTableStmtAlterColumn: FormatAlterTableStmtAlterColumn(TAlterTableStmt.PAlterColumn(Node)^.Nodes);
      ntAlterTableStmtConvertTo: FormatAlterTableStmtConvertTo(TAlterTableStmt.PConvertTo(Node)^.Nodes);
      ntAlterTableStmtDropObject: FormatAlterTableStmtDropObject(TAlterTableStmt.PDropObject(Node)^.Nodes);
        ntAlterTableStmtExchangePartition: raise Exception.Create(SArgumentOutOfRange);
        ntAlterTableStmtReorganizePartition: raise Exception.Create(SArgumentOutOfRange);
        ntAlterViewStmt: raise Exception.Create(SArgumentOutOfRange);
        ntBeginStmt: raise Exception.Create(SArgumentOutOfRange);
        ntBetweenOp: raise Exception.Create(SArgumentOutOfRange);
        ntBinaryOp: raise Exception.Create(SArgumentOutOfRange);
        ntCallStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCaseOp: raise Exception.Create(SArgumentOutOfRange);
        ntCaseOpBranch: raise Exception.Create(SArgumentOutOfRange);
        ntCaseStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCaseStmtBranch: raise Exception.Create(SArgumentOutOfRange);
        ntCastFunc: raise Exception.Create(SArgumentOutOfRange);
        ntCharFunc: raise Exception.Create(SArgumentOutOfRange);
        ntCheckStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCheckStmtOption: raise Exception.Create(SArgumentOutOfRange);
        ntChecksumStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCloseStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCommitStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCompoundStmt: raise Exception.Create(SArgumentOutOfRange);
        ntConvertFunc: raise Exception.Create(SArgumentOutOfRange);
        ntCreateDatabaseStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCreateEventStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCreateIndexStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCreateRoutineStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCreateServerStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCreateTableStmt: raise Exception.Create(SArgumentOutOfRange);
      ntCreateTableStmtColumn: FormatCreateTableStmtColumn(TCreateTableStmt.PColumn(Node)^.Nodes);
        ntCreateTableStmtForeignKey: raise Exception.Create(SArgumentOutOfRange);
      ntCreateTableStmtKey: FormatCreateTableStmtKey(TCreateTableStmt.PKey(Node)^.Nodes);
      ntCreateTableStmtKeyColumn: FormatCreateTableStmtKeyColumn(TCreateTableStmt.PKeyColumn(Node)^.Nodes);
        ntCreateTableStmtPartition: raise Exception.Create(SArgumentOutOfRange);
        ntCreateTableStmtPartitionValues: raise Exception.Create(SArgumentOutOfRange);
        ntCreateTriggerStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCreateUserStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCreateViewStmt: raise Exception.Create(SArgumentOutOfRange);
        ntCurrentTimestamp: raise Exception.Create(SArgumentOutOfRange);
      ntDataType: FormatDataType(PDataType(Node)^.Nodes);
      ntDbIdent: FormatDbIdent(PDbIdent(Node)^.Nodes);
        ntDeallocatePrepareStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDeclareStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDeclareConditionStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDeclareCursorStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDeclareHandlerStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDeclareHandlerStmtCondition: raise Exception.Create(SArgumentOutOfRange);
        ntDeleteStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDoStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDropDatabaseStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDropEventStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDropIndexStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDropRoutineStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDropServerStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDropTableStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDropTriggerStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDropUserStmt: raise Exception.Create(SArgumentOutOfRange);
        ntDropViewStmt: raise Exception.Create(SArgumentOutOfRange);
        ntExecuteStmt: raise Exception.Create(SArgumentOutOfRange);
        ntExistsFunc: raise Exception.Create(SArgumentOutOfRange);
        ntExplainStmt: raise Exception.Create(SArgumentOutOfRange);
        ntExtractFunc: raise Exception.Create(SArgumentOutOfRange);
        ntFetchStmt: raise Exception.Create(SArgumentOutOfRange);
        ntFlushStmt: raise Exception.Create(SArgumentOutOfRange);
        ntFlushStmtOption: raise Exception.Create(SArgumentOutOfRange);
        ntFunctionCall: raise Exception.Create(SArgumentOutOfRange);
        ntFunctionReturns: raise Exception.Create(SArgumentOutOfRange);
        ntGetDiagnosticsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntGetDiagnosticsStmtStmtInfo: raise Exception.Create(SArgumentOutOfRange);
        ntGetDiagnosticsStmtConditionInfo: raise Exception.Create(SArgumentOutOfRange);
        ntGrantStmt: raise Exception.Create(SArgumentOutOfRange);
        ntGrantStmtPrivileg: raise Exception.Create(SArgumentOutOfRange);
        ntGrantStmtUserSpecification: raise Exception.Create(SArgumentOutOfRange);
        ntGroupConcatFunc: raise Exception.Create(SArgumentOutOfRange);
        ntGroupConcatFuncExpr: raise Exception.Create(SArgumentOutOfRange);
        ntHelpStmt: raise Exception.Create(SArgumentOutOfRange);
        ntIfStmt: raise Exception.Create(SArgumentOutOfRange);
        ntIfStmtBranch: raise Exception.Create(SArgumentOutOfRange);
        ntIgnoreLines: raise Exception.Create(SArgumentOutOfRange);
        ntInOp: raise Exception.Create(SArgumentOutOfRange);
        ntInsertStmt: raise Exception.Create(SArgumentOutOfRange);
        ntInsertStmtSetItem: raise Exception.Create(SArgumentOutOfRange);
      ntIntervalOp: FormatIntervalOp(PIntervalOp(Node)^.Nodes);
        ntIntervalListItem: raise Exception.Create(SArgumentOutOfRange);
        ntIterateStmt: raise Exception.Create(SArgumentOutOfRange);
        ntKillStmt: raise Exception.Create(SArgumentOutOfRange);
        ntLeaveStmt: raise Exception.Create(SArgumentOutOfRange);
        ntLikeOp: raise Exception.Create(SArgumentOutOfRange);
      ntList: FormatList(PList(Node)^.Nodes);
        ntLoadDataStmt: raise Exception.Create(SArgumentOutOfRange);
        ntLoadXMLStmt: raise Exception.Create(SArgumentOutOfRange);
        ntLockStmt: raise Exception.Create(SArgumentOutOfRange);
        ntLockStmtItem: raise Exception.Create(SArgumentOutOfRange);
        ntLoopStmt: raise Exception.Create(SArgumentOutOfRange);
        ntPositionFunc: raise Exception.Create(SArgumentOutOfRange);
        ntPrepareStmt: raise Exception.Create(SArgumentOutOfRange);
        ntPurgeStmt: raise Exception.Create(SArgumentOutOfRange);
        ntOj: raise Exception.Create(SArgumentOutOfRange);
        ntOpenStmt: raise Exception.Create(SArgumentOutOfRange);
        ntOptimizeStmt: raise Exception.Create(SArgumentOutOfRange);
        ntRegExpOp: raise Exception.Create(SArgumentOutOfRange);
        ntRenameStmt: raise Exception.Create(SArgumentOutOfRange);
        ntRenameStmtPair: raise Exception.Create(SArgumentOutOfRange);
        ntReleaseStmt: raise Exception.Create(SArgumentOutOfRange);
        ntRepairStmt: raise Exception.Create(SArgumentOutOfRange);
        ntRepeatStmt: raise Exception.Create(SArgumentOutOfRange);
        ntResetStmt: raise Exception.Create(SArgumentOutOfRange);
        ntReturnStmt: raise Exception.Create(SArgumentOutOfRange);
        ntRevokeStmt: raise Exception.Create(SArgumentOutOfRange);
        ntRollbackStmt: raise Exception.Create(SArgumentOutOfRange);
        ntRoutineParam: raise Exception.Create(SArgumentOutOfRange);
        ntSavepointStmt: raise Exception.Create(SArgumentOutOfRange);
      ntSchedule: FormatSchedule(PSchedule(Node)^.Nodes);
        ntSecretIdent: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmt: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtColumn: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtFrom: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtGroup: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtGroups: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtOrder: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtInto: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtTableFactor: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtTableFactorIndexHint: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtTableFactorOj: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtTableFactorReferences: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtTableFactorSelect: raise Exception.Create(SArgumentOutOfRange);
        ntSelectStmtTableJoin: raise Exception.Create(SArgumentOutOfRange);
        ntSetNamesStmt: raise Exception.Create(SArgumentOutOfRange);
        ntSetPasswordStmt: raise Exception.Create(SArgumentOutOfRange);
        ntSetStmt: raise Exception.Create(SArgumentOutOfRange);
        ntSetStmtAssignment: raise Exception.Create(SArgumentOutOfRange);
        ntSetTransactionStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowAuthorsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowBinaryLogsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowBinlogEventsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowCharacterSetStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowCollationStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowContributorsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowCountErrorsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowCountWarningsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowCreateDatabaseStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowCreateEventStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowCreateFunctionStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowCreateProcedureStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowCreateTableStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowCreateTriggerStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowCreateViewStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowDatabasesStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowEngineStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowEnginesStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowErrorsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowEventsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowFunctionCodeStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowFunctionStatusStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowGrantsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowIndexStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowMasterStatusStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowOpenTablesStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowPluginsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowPrivilegesStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowProcedureCodeStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowProcedureStatusStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowProcessListStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowProfileStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowProfilesStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowRelaylogEventsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowSlaveHostsStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowSlaveStatusStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowStatusStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowTableStatusStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowTablesStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowTriggersStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowVariablesStmt: raise Exception.Create(SArgumentOutOfRange);
        ntShowWarningsStmt: raise Exception.Create(SArgumentOutOfRange);
      ntShutdownStmt: FormatShutdownStmt(PShutdownStmt(Node)^.Nodes);
        ntSignalStmt: raise Exception.Create(SArgumentOutOfRange);
        ntSignalStmtInformation: raise Exception.Create(SArgumentOutOfRange);
        ntSoundsLikeOp: raise Exception.Create(SArgumentOutOfRange);
        ntStartSlaveStmt: raise Exception.Create(SArgumentOutOfRange);
        ntStartTransactionStmt: raise Exception.Create(SArgumentOutOfRange);
        ntStopSlaveStmt: raise Exception.Create(SArgumentOutOfRange);
        ntSubArea: raise Exception.Create(SArgumentOutOfRange);
        ntSubPartition: raise Exception.Create(SArgumentOutOfRange);
        ntSubstringFunc: raise Exception.Create(SArgumentOutOfRange);
        ntTableReference: raise Exception.Create(SArgumentOutOfRange);
      ntTag: FormatTag(PTag(Node)^.Nodes);
        ntTransactionStmtCharacteristic: raise Exception.Create(SArgumentOutOfRange);
        ntTrimFunc: raise Exception.Create(SArgumentOutOfRange);
        ntTruncateStmt: raise Exception.Create(SArgumentOutOfRange);
        ntUnaryOp: raise Exception.Create(SArgumentOutOfRange);
        ntUnknownStmt: raise Exception.Create(SArgumentOutOfRange);
        ntUnlockStmt: raise Exception.Create(SArgumentOutOfRange);
        ntUpdateStmt: raise Exception.Create(SArgumentOutOfRange);
        ntUser: raise Exception.Create(SArgumentOutOfRange);
        ntUseStmt: raise Exception.Create(SArgumentOutOfRange);
      ntValue: FormatValue(PValue(Node)^.Nodes);
        ntVariable: raise Exception.Create(SArgumentOutOfRange);
        ntWeightStringFunc: raise Exception.Create(SArgumentOutOfRange);
        ntWeightStringFuncLevel: raise Exception.Create(SArgumentOutOfRange);
        ntWhileStmt: raise Exception.Create(SArgumentOutOfRange);
        ntXAStmt: raise Exception.Create(SArgumentOutOfRange);
        ntXID: raise Exception.Create(SArgumentOutOfRange);
      else raise Exception.Create(SArgumentOutOfRange);
    end;

  if (IsStmt(Node)) then
  begin
    Token := PStmt(Node)^.LastTokenAll^.NextToken;
    if (Assigned(Token) and (Token^.TokenType = ttDelimiter)) then
    begin
      Commands.Write(Token^.SQL, Token^.Length); // Delimiter
      Commands.WriteReturn();
    end;
  end;
end;

procedure TMySQLParser.FormatNode(const Node: TOffset);
begin
  FormatNode(NodePtr(Node));
end;

procedure TMySQLParser.FormatRoot(const Node: PNode);
var
  Stmt: PStmt;
  Token: PToken;
begin
  Token := Root^.FirstTokenAll;

  Stmt := Root^.FirstStmt;
  while (Assigned(Stmt)) do
  begin
    FormatNode(PNode(Stmt));

    Token := Stmt^.LastTokenAll^.NextTokenAll;
    Stmt := Stmt^.NextStmt;
  end;

  while (Assigned(Token) and (Token^.TokenType = ttDelimiter)) do
    Token := Token^.NextTokenAll;

  if (Assigned(Token)) then
    FormatComments(Token, True);
end;

procedure TMySQLParser.FormatSchedule(const Nodes: TSchedule.TNodes);
var
  I: Integer;
begin
  if (Nodes.At.Tag > 0) then
  begin
    FormatNode(Nodes.At.Tag);
    Commands.WriteSpace();
    FormatNode(Nodes.At.Timestamp);

    for I := 0 to Length(Nodes.Starts.IntervalList) - 1 do
      if (Nodes.Starts.IntervalList[I] > 0) then
      begin
        Commands.WriteSpace();
        FormatNode(Nodes.Starts.IntervalList[I]);
      end;
  end
  else if (Nodes.Every.Tag > 0) then
  begin
    FormatNode(Nodes.Every.Tag);
    Commands.WriteSpace();
    FormatNode(Nodes.Every.Interval);

    if (Nodes.Starts.Tag > 0) then
    begin
      Commands.IncreaseIndent();
      Commands.WriteReturn();
      FormatNode(Nodes.Starts.Tag);
      Commands.WriteSpace();
      FormatNode(Nodes.Starts.Timestamp);

      for I := 0 to Length(Nodes.Starts.IntervalList) - 1 do
        if (Nodes.Starts.IntervalList[I] > 0) then
        begin
          Commands.WriteSpace();
          FormatNode(Nodes.Starts.IntervalList[I]);
        end;
      Commands.DecreaseIndent();
    end;

    if (Nodes.Ends.Tag > 0) then
    begin
      Commands.IncreaseIndent();
      Commands.WriteReturn();
      FormatNode(Nodes.Ends.Tag);
      Commands.WriteSpace();
      FormatNode(Nodes.Ends.Timestamp);

      for I := 0 to Length(Nodes.Ends.IntervalList) - 1 do
        if (Nodes.Ends.IntervalList[I] > 0) then
        begin
          Commands.WriteSpace();
          FormatNode(Nodes.Ends.IntervalList[I]);
        end;
      Commands.DecreaseIndent();
    end;
  end
  else
    SetError(PE_InvalidNodeValue);
end;

function TMySQLParser.FormatSQL(out SQL: string): Boolean;
begin
  SQL := '';

  if (Assigned(Root)) then
  begin
    Commands := TFormatHandle.Create();

    FormatRoot(NodePtr(1));

    SQL := Commands.Read();
    Commands.Free(); Commands := nil;
  end;

  Result := not Error;
end;

procedure TMySQLParser.FormatShutdownStmt(const Nodes: TShutdownStmt.TNodes);
begin
  FormatNode(Nodes.StmtTag);
end;

procedure TMySQLParser.FormatTag(const Nodes: TTag.TNodes);
begin
  FormatNode(Nodes.KeywordToken1);

  if (Nodes.KeywordToken2 > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.KeywordToken2);

    if (Nodes.KeywordToken3 > 0) then
    begin
      Commands.WriteSpace();
      FormatNode(Nodes.KeywordToken3);

      if (Nodes.KeywordToken4 > 0) then
      begin
        Commands.WriteSpace();
        FormatNode(Nodes.KeywordToken4);
      end;
    end;
  end;
end;

procedure TMySQLParser.FormatToken(const Token: PToken);
label
  StringL, StringLE;
var
  Dest: PChar;
  Keyword: array [0 .. 30] of Char;
  Length: Integer;
  Source: PChar;
begin
  if (Token^.TokenType = ttMySQLIdent) then
    Commands.Write(SQLEscape(Token^.AsString, '`'))
  else if (Token^.TokenType = ttDQIdent) then
    Commands.Write(SQLEscape(Token^.AsString, '"'))
  else if (Token^.TokenType in [ttString, ttCSString]) then
    Commands.Write(SQLEscape(Token^.AsString, ''''))
  else if (Token^.UsageType = utKeyword) then
  begin
    Source := Token^.SQL;
    Length := Token^.Length;
    Dest := @Keyword[0];
    asm // Convert SQL to upper case
        PUSH ES
        PUSH ESI
        PUSH EDI

        PUSH DS                          // string operations uses ES
        POP ES
        CLD                              // string operations uses forward direction

        MOV ESI,Source
        MOV ECX,Length
        MOV EDI,Dest

      StringL:
        LODSW                            // Get character
        CMP AX,'a'                       // Small character?
        JB StringLE                      // No!
        CMP AX,'z'                       // Small character?
        JA StringLE                      // No!
        AND AX,$FF - $20                 // Upcase character
      StringLE:
        STOSW                            // Put character
        LOOP StringL                     // Further characters!

        POP EDI
        POP ESI
        POP ES
    end;

    Commands.Write(@Keyword[0], Token^.Length);
  end
  else
    Commands.Write(Token^.SQL, Token^.Length);

  FormatComments(Token^.NextTokenAll, False);
end;

procedure TMySQLParser.FormatValue(const Nodes: TValue.TNodes);
begin
  FormatNode(Nodes.IdentTag);

  if (Nodes.AssignToken > 0) then
  begin
    Commands.WriteSpace();
    FormatNode(Nodes.AssignToken);
  end;

  Commands.WriteSpace();
  FormatNode(Nodes.ValueToken);
end;

function TMySQLParser.GetError(): Boolean;
begin
  Result := FErrorCode <> PE_Success;
end;

function TMySQLParser.GetErrorMessage(): string;
begin
  Result := GetErrorMessage(FErrorCode);
end;

function TMySQLParser.GetErrorMessage(const AErrorCode: Integer): string;
begin
  case (AErrorCode) of
    PE_Success: Result := '';
    PE_Unknown: Result := 'Unknown error';
    PE_IncompleteToken: Result := 'Incompleted token';
    PE_UnexpectedChar: Result := 'Unexpected character';
    PE_IncompleteStmt: Result := 'Incompleted statement';
    PE_UnexpectedToken: Result := 'Unexpected token';
    PE_ExtraToken: Result := 'Unexpected token after statement';
    PE_UnkownStmt: Result := 'Unknown statement';
    PE_InvalidNodeValue: Result := 'Invalid node value';
    else Result := '[Unknown error]';
  end;
end;

function TMySQLParser.GetFunctions(): string;
begin
  Result := FunctionList.Text;
end;

function TMySQLParser.GetInPL_SQL(): Boolean;
begin
  Result := FInPL_SQL > 0;
end;

function TMySQLParser.GetKeywords(): string;
begin
  Result := KeywordList.Text;
end;

function TMySQLParser.GetNextToken(Index: Integer): TOffset;
begin
  Assert(Index >= 0);

  Result := GetParsedToken(Index);
end;

function TMySQLParser.GetParsedToken(const Index: Integer): TOffset;
var
  S: string;
  Token: TOffset;
  Version: Integer;
begin
  if (Index > TokenBuffer.Count - 1) then
    repeat
      Token := ParseToken();

      if (Token > 0) then
      begin
        if (TokenPtr(Token)^.TokenType = ttMySQLCodeStart) then
        begin
          S := TokenPtr(Token)^.Text;
          S := Copy(S, 4, Length(S) - 3);
          if (not TryStrToInt(S, Version)) then
            TokenPtr(Token)^.FErrorCode := PE_UnexpectedChar
          else
          begin
            SetLength(MySQLVersions, Length(MySQLVersions) + 1);
            MySQLVersions[Length(MySQLVersions) - 1] := Version;
          end;
        end
        else if (TokenPtr(Token)^.TokenType = ttMySQLCodeEnd) then
        begin
          if (Length(MySQLVersions) > 0) then
            SetLength(MySQLVersions, Length(MySQLVersions) - 1)
          else if (not Error) then
            SetError(PE_UnexpectedToken, Token);
        end;

        if (TokenPtr(Token)^.IsUsed) then
        begin
          {$IFDEF Debug}
          TokenPtr(Token)^.FIndex := TokenIndex; Inc(TokenIndex);
          {$ENDIF}

          if (TokenBuffer.Count = Length(TokenBuffer.Tokens)) then
            raise Exception.Create(SUnknownError);
          TokenBuffer.Tokens[TokenBuffer.Count] := Token;
          Inc(TokenBuffer.Count);
        end;
      end;
    until ((Token = 0) or (TokenBuffer.Count - 1 = Index));

  if (Index >= TokenBuffer.Count) then
    Result := 0
  else
    Result := TokenBuffer.Tokens[Index];
end;

function TMySQLParser.GetRoot(): PRoot;
begin
  Assert(FRoot < ParsedNodes.UsedSize);

  if (FRoot = 0) then
    Result := nil
  else
    Result := PRoot(NodePtr(FRoot));
end;

function TMySQLParser.GetText(const Offset: TOffset): PChar;
begin
  Result := @ReplaceTexts.Mem[Offset];
end;

function TMySQLParser.IsChild(const ANode: PNode): Boolean;
begin
  Result := Assigned(ANode) and not (ANode^.NodeType in [ntUnknown, ntRoot]);
end;

function TMySQLParser.IsChild(const ANode: TOffset): Boolean;
begin
  Result := IsChild(NodePtr(ANode));
end;

function TMySQLParser.IsRange(const ANode: PNode): Boolean;
begin
  Result := Assigned(ANode) and not (ANode^.NodeType in [ntUnknown, ntRoot, ntToken]);
end;

function TMySQLParser.IsRoot(const ANode: PNode): Boolean;
begin
  Result := Assigned(ANode) and (ANode^.NodeType = ntRoot);
end;

function TMySQLParser.IsStmt(const ANode: PNode): Boolean;
begin
  Result := Assigned(ANode) and (ANode^.NodeType in StmtNodeTypes);
end;

function TMySQLParser.IsStmt(const ANode: TOffset): Boolean;
begin
  Result := IsStmt(NodePtr(ANode));
end;

function TMySQLParser.IsToken(const ANode: PNode): Boolean;
begin
  Result := Assigned(ANode) and (ANode^.NodeType = ntToken);
end;

function TMySQLParser.IsToken(const ANode: TOffset): Boolean;
begin
  Result := IsToken(NodePtr(ANode));
end;

function TMySQLParser.LoadFromFile(const Filename: string): Boolean;
var
  BytesPerSector: DWord;
  BytesRead: DWord;
  FileSize: DWord;
  Handle: THandle;
  Len: Integer;
  MemSize: DWord;
  NumberofFreeClusters: DWord;
  SectorsPerCluser: DWord;
  Mem: PAnsiChar;
  TotalNumberOfClusters: DWord;
begin
  FRoot := 0;

  Clear();

  if (not GetDiskFreeSpace(PChar(ExtractFileDrive(Filename)), SectorsPerCluser, BytesPerSector, NumberofFreeClusters, TotalNumberOfClusters)) then
    RaiseLastOSError();

  Handle := CreateFile(PChar(Filename),
                       GENERIC_READ,
                       FILE_SHARE_READ,
                       nil,
                       OPEN_EXISTING, FILE_FLAG_NO_BUFFERING, 0);

  if (Handle = INVALID_HANDLE_VALUE) then
    RaiseLastOSError()
  else
  begin
    FileSize := GetFileSize(Handle, nil);
    if (FileSize = INVALID_FILE_SIZE) then
      RaiseLastOSError()
    else
    begin
      MemSize := ((FileSize div BytesPerSector) + 1) * BytesPerSector;

      GetMem(Mem, MemSize);
      if (not Assigned(Mem)) then
        raise Exception.CreateFmt(SOutOfMemory, [MemSize])
      else
      begin
        Len := 0;
        if (not ReadFile(Handle, Mem^, MemSize, BytesRead, nil)) then
          RaiseLastOSError()
        else if (BytesRead <> FileSize) then
          raise Exception.Create(SUnknownError)
        else if ((BytesRead >= DWord(Length(BOM_UTF8))) and (CompareMem(Mem, BOM_UTF8, StrLen(BOM_UTF8)))) then
        begin
          Len := MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, @Mem[Length(BOM_UTF8)], BytesRead - DWord(Length(BOM_UTF8)), nil, 0);
          SetLength(ParseText, Len);
          MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, @Mem[Length(BOM_UTF8)], BytesRead - DWord(Length(BOM_UTF8)), @ParseText[1], Len);
        end
        else if ((BytesRead >= DWord(Length(BOM_UNICODE_LE))) and (CompareMem(Mem, BOM_UNICODE_LE, StrLen(BOM_UNICODE_LE)))) then
        begin
          Len := (BytesRead - DWord(Length(BOM_UNICODE_LE))) div SizeOf(WideChar);
          SetLength(ParseText, Len);
          MoveMemory(@ParseText[1], @Mem[Length(BOM_UNICODE_LE)], Len * SizeOf(WideChar));
        end
        else
        begin
          Len := MultiByteToWideChar(CP_ACP, MB_ERR_INVALID_CHARS, Mem, BytesRead, nil, 0);
          SetLength(ParseText, Len);
          MultiByteToWideChar(CP_ACP, MB_ERR_INVALID_CHARS, Mem, BytesRead, @ParseText[1], Len);
        end;

        FreeMem(Mem);

        ParsePosition.Text := PChar(ParseText);
        ParsePosition.Length := Len;
        FRoot := ParseRoot();
      end;
    end;

    CloseHandle(Handle);
  end;

  Result := not Error;
end;

function TMySQLParser.NewNode(const ANodeType: TNodeType): TOffset;
var
  Size: Integer;
begin
  Size := NodeSize(ANodeType);

  if (ParsedNodes.UsedSize + Size > ParsedNodes.MemSize) then
  begin
    Inc(ParsedNodes.MemSize, ParsedNodes.MemSize);
    ReallocMem(ParsedNodes.Mem, ParsedNodes.MemSize);
  end;

  Result := ParsedNodes.UsedSize;
  Inc(ParsedNodes.UsedSize, Size);
end;

function TMySQLParser.NewText(const AText: string): TOffset;
begin
  if (Length(AText) = 0) then
    Result := ReplaceTexts.UsedLength
  else
  begin
    if ((ReplaceTexts.UsedLength + Length(AText)) * SizeOf(ReplaceTexts.Mem[0]) >= ReplaceTexts.MemSize) then
    begin
      ReplaceTexts.MemSize := Min(2 * ReplaceTexts.MemSize, (ReplaceTexts.UsedLength + Length(AText)) * SizeOf(ReplaceTexts.Mem[0]) + ReplaceTexts.MemSize);
      ReallocMem(ReplaceTexts.Mem, ReplaceTexts.MemSize);
    end;

    Result := ReplaceTexts.UsedLength;
    Move(AText[1], ReplaceTexts.Mem[ReplaceTexts.UsedLength], Length(AText) * SizeOf(ReplaceTexts.Mem[0]));
    Inc(ReplaceTexts.UsedLength, Length(AText));
  end;
end;

function TMySQLParser.NodePtr(const ANode: TOffset): PNode;
begin
  Assert(ANode < ParsedNodes.UsedSize);

  if (ANode = 0) then
    Result := nil
  else
    Result := @ParsedNodes.Mem[ANode];
end;

function TMySQLParser.NodeSize(const NodeType: TNodeType): Integer;
begin
  case (NodeType) of
    ntRoot: Result := SizeOf(TRoot);
    ntRange: Result := SizeOf(TRange);
    ntToken: Result := SizeOf(TToken);

    ntAnalyzeStmt: Result := SizeOf(TAnalyzeStmt);
    ntAlterDatabaseStmt: Result := SizeOf(TAlterDatabaseStmt);
    ntAlterEventStmt: Result := SizeOf(TAlterEventStmt);
    ntAlterInstanceStmt: Result := SizeOf(TAlterInstanceStmt);
    ntAlterRoutineStmt: Result := SizeOf(TAlterRoutineStmt);
    ntAlterServerStmt: Result := SizeOf(TAlterServerStmt);
    ntAlterTableStmt: Result := SizeOf(TAlterTableStmt);
    ntAlterTableStmtConvertTo: Result := SizeOf(TAlterTableStmt.TConvertTo);
    ntAlterTableStmtDropObject: Result := SizeOf(TAlterTableStmt.TDropObject);
    ntAlterTableStmtExchangePartition: Result := SizeOf(TAlterTableStmt.TExchangePartition);
    ntAlterTableStmtReorganizePartition: Result := SizeOf(TAlterTableStmt.TReorganizePartition);
    ntAlterViewStmt: Result := SizeOf(TAlterViewStmt);
    ntBeginStmt: Result := SizeOf(TBeginStmt);
    ntBetweenOp: Result := SizeOf(TBetweenOp);
    ntBinaryOp: Result := SizeOf(TBinaryOp);
    ntCallStmt: Result := SizeOf(TCallStmt);
    ntCaseOp: Result := SizeOf(TCaseOp);
    ntCaseOpBranch: Result := SizeOf(TCaseOp.TBranch);
    ntCaseStmt: Result := SizeOf(TCaseStmt);
    ntCaseStmtBranch: Result := SizeOf(TCaseStmt.TBranch);
    ntCastFunc: Result := SizeOf(TCastFunc);
    ntCharFunc: Result := SizeOf(TCharFunc);
    ntCheckStmt: Result := SizeOf(TCheckStmt);
    ntCheckStmtOption: Result := SizeOf(TCheckStmt.TOption);
    ntChecksumStmt: Result := SizeOf(TChecksumStmt);
    ntCloseStmt: Result := SizeOf(TCloseStmt);
    ntCommitStmt: Result := SizeOf(TCommitStmt);
    ntCompoundStmt: Result := SizeOf(TCompoundStmt);
    ntConvertFunc: Result := SizeOf(TConvertFunc);
    ntCreateDatabaseStmt: Result := SizeOf(TCreateDatabaseStmt);
    ntCreateEventStmt: Result := SizeOf(TCreateEventStmt);
    ntCreateIndexStmt: Result := SizeOf(TCreateIndexStmt);
    ntCreateRoutineStmt: Result := SizeOf(TCreateRoutineStmt);
    ntCreateServerStmt: Result := SizeOf(TCreateServerStmt);
    ntCreateTableStmt: Result := SizeOf(TCreateTableStmt);
    ntCreateTableStmtColumn: Result := SizeOf(TCreateTableStmt.TColumn);
    ntCreateTableStmtForeignKey: Result := SizeOf(TCreateTableStmt.TForeignKey);
    ntCreateTableStmtKey: Result := SizeOf(TCreateTableStmt.TKey);
    ntCreateTableStmtKeyColumn: Result := SizeOf(TCreateTableStmt.TKeyColumn);
    ntCreateTableStmtPartition: Result := SizeOf(TCreateTableStmt.TPartition);
    ntCreateTableStmtPartitionValues: Result := SizeOf(TCreateTableStmt.TPartitionValues);
    ntCreateTriggerStmt: Result := SizeOf(TCreateTriggerStmt);
    ntCreateUserStmt: Result := SizeOf(TCreateUserStmt);
    ntCreateViewStmt: Result := SizeOf(TCreateViewStmt);
    ntCurrentTimestamp: Result := SizeOf(TCurrentTimestamp);
    ntDataType: Result := SizeOf(TDataType);
    ntDbIdent: Result := SizeOf(TDbIdent);
    ntDeallocatePrepareStmt: Result := SizeOf(TDeallocatePrepareStmt);
    ntDeclareStmt: Result := SizeOf(TDeclareStmt);
    ntDeclareConditionStmt: Result := SizeOf(TDeclareConditionStmt);
    ntDeclareCursorStmt: Result := SizeOf(TDeclareCursorStmt);
    ntDeclareHandlerStmt: Result := SizeOf(TDeclareHandlerStmt);
    ntDeclareHandlerStmtCondition: Result := SizeOf(TDeclareHandlerStmt.TCondition);
    ntDeleteStmt: Result := SizeOf(TDeleteStmt);
    ntDoStmt: Result := SizeOf(TDoStmt);
    ntDropDatabaseStmt: Result := SizeOf(TDropDatabaseStmt);
    ntDropEventStmt: Result := SizeOf(TDropEventStmt);
    ntDropIndexStmt: Result := SizeOf(TDropIndexStmt);
    ntDropRoutineStmt: Result := SizeOf(TDropRoutineStmt);
    ntDropServerStmt: Result := SizeOf(TDropServerStmt);
    ntDropTableStmt: Result := SizeOf(TDropTableStmt);
    ntDropTriggerStmt: Result := SizeOf(TDropTriggerStmt);
    ntDropUserStmt: Result := SizeOf(TDropUserStmt);
    ntDropViewStmt: Result := SizeOf(TDropViewStmt);
    ntExecuteStmt: Result := SizeOf(TExecuteStmt);
    ntExplainStmt: Result := SizeOf(TExplainStmt);
    ntExistsFunc: Result := SizeOf(TExistsFunc);
    ntExtractFunc: Result := SizeOf(TExtractFunc);
    ntFetchStmt: Result := SizeOf(TFetchStmt);
    ntFlushStmt: Result := SizeOf(TFlushStmt);
    ntFlushStmtOption: Result := SizeOf(TFlushStmt.TOption);
    ntFunctionCall: Result := SizeOf(TFunctionCall);
    ntFunctionReturns: Result := SizeOf(TFunctionReturns);
    ntIfStmt: Result := SizeOf(TIfStmt);
    ntIfStmtBranch: Result := SizeOf(TIfStmt.TBranch);
    ntGetDiagnosticsStmt: Result := SizeOf(TGetDiagnosticsStmt);
    ntGetDiagnosticsStmtStmtInfo: Result := SizeOf(TGetDiagnosticsStmt.TStmtInfo);
    ntGetDiagnosticsStmtConditionInfo: Result := SizeOf(TGetDiagnosticsStmt.TStmtInfo);
    ntGrantStmt: Result := SizeOf(TGrantStmt);
    ntGrantStmtPrivileg: Result := SizeOf(TGrantStmt.TPrivileg);
    ntGrantStmtUserSpecification: Result := SizeOf(TGrantStmt.TUserSpecification);
    ntGroupConcatFunc: Result := SizeOf(TGroupConcatFunc);
    ntGroupConcatFuncExpr: Result := SizeOf(TGroupConcatFunc.TExpr);
    ntHelpStmt: Result := SizeOf(THelpStmt);
    ntInsertStmtSetItem: Result := SizeOf(TInsertStmt.TSetItem);
    ntIgnoreLines: Result := SizeOf(TIgnoreLines);
    ntInOp: Result := SizeOf(TInOp);
    ntInsertStmt: Result := SizeOf(TInsertStmt);
    ntIntervalOp: Result := SizeOf(TIntervalOp);
    ntIntervalListItem: Result := SizeOf(TIntervalOp.TListItem);
    ntIterateStmt: Result := SizeOf(TIterateStmt);
    ntKillStmt: Result := SizeOf(TKillStmt);
    ntLeaveStmt: Result := SizeOf(TLeaveStmt);
    ntLikeOp: Result := SizeOf(TLikeOp);
    ntList: Result := SizeOf(TList);
    ntLoadDataStmt: Result := SizeOf(TLoadDataStmt);
    ntLoadXMLStmt: Result := SizeOf(TLoadXMLStmt);
    ntLockStmt: Result := SizeOf(TLockStmt);
    ntLockStmtItem: Result := SizeOf(TLockStmt.TItem);
    ntLoopStmt: Result := SizeOf(TLoopStmt);
    ntOpenStmt: Result := SizeOf(TOpenStmt);
    ntOptimizeStmt: Result := SizeOf(TOptimizeStmt);
    ntPositionFunc: Result := SizeOf(TPositionFunc);
    ntPrepareStmt: Result := SizeOf(TPrepareStmt);
    ntPurgeStmt: Result := SizeOf(TPurgeStmt);
    ntRegExpOp: Result := SizeOf(TRegExpOp);
    ntRenameStmt: Result := SizeOf(TRenameStmt);
    ntRenameStmtPair: Result := SizeOf(TRenameStmt.TPair);
    ntReleaseStmt: Result := SizeOf(TReleaseStmt);
    ntRepairStmt: Result := SizeOf(TRepairStmt);
    ntRepeatStmt: Result := SizeOf(TRepeatStmt);
    ntResetStmt: Result := SizeOf(TResetStmt);
    ntReturnStmt: Result := SizeOf(TReturnStmt);
    ntRevokeStmt: Result := SizeOf(TRevokeStmt);
    ntRollbackStmt: Result := SizeOf(TRollbackStmt);
    ntRoutineParam: Result := SizeOf(TRoutineParam);
    ntSavepointStmt: Result := SizeOf(TSavepointStmt);
    ntSchedule: Result := SizeOf(TSchedule);
    ntSecretIdent: Result := SizeOf(TSecretIdent);
    ntSelectStmt: Result := SizeOf(TSelectStmt);
    ntSelectStmtColumn: Result := SizeOf(TSelectStmt.TColumn);
    ntSelectStmtGroup: Result := SizeOf(TSelectStmt.TGroup);
    ntSelectStmtGroups: Result := SizeOf(TSelectStmt.TGroups);
    ntSelectStmtOrder: Result := SizeOf(TSelectStmt.TOrder);
    ntSelectStmtInto: Result := SizeOf(TSelectStmt.TInto);
    ntSelectStmtTableFactor: Result := SizeOf(TSelectStmt.TTableFactor);
    ntSelectStmtTableFactorIndexHint: Result := SizeOf(TSelectStmt.TTableFactor.TIndexHint);
    ntSelectStmtTableFactorOj: Result := SizeOf(TSelectStmt.TTableReferenceOj);
    ntSelectStmtTableFactorReferences: Result := SizeOf(TSelectStmt.TTableFactorReferences);
    ntSelectStmtTableFactorSelect: Result := SizeOf(TSelectStmt.TTableFactorSelect);
    ntSelectStmtTableJoin: Result := SizeOf(TSelectStmt.TTableReferenceJoin);
    ntSetNamesStmt: Result := SizeOf(TSetNamesStmt);
    ntSetPasswordStmt: Result := SizeOf(TSetPasswordStmt);
    ntSetStmt: Result := SizeOf(TSetStmt);
    ntSetStmtAssignment: Result := SizeOf(TSetStmt.TAssignment);
    ntSetTransactionStmt: Result := SizeOf(TSetTransactionStmt);
    ntTransactionStmtCharacteristic: Result := SizeOf(TSetTransactionStmt.TCharacteristic);
    ntTrimFunc: Result := SizeOf(TTrimFunc);
    ntShowAuthorsStmt: Result := SizeOf(TShowAuthorsStmt);
    ntShowBinaryLogsStmt: Result := SizeOf(TShowBinaryLogsStmt);
    ntShowBinlogEventsStmt: Result := SizeOf(TShowBinlogEventsStmt);
    ntShowCharacterSetStmt: Result := SizeOf(TShowCharacterSetStmt);
    ntShowCollationStmt: Result := SizeOf(TShowCollationStmt);
    ntShowContributorsStmt: Result := SizeOf(TShowContributorsStmt);
    ntShowCountErrorsStmt: Result := SizeOf(TShowCountErrorsStmt);
    ntShowCountWarningsStmt: Result := SizeOf(TShowCountWarningsStmt);
    ntShowCreateDatabaseStmt: Result := SizeOf(TShowCreateDatabaseStmt);
    ntShowCreateEventStmt: Result := SizeOf(TShowCreateEventStmt);
    ntShowCreateFunctionStmt: Result := SizeOf(TShowCreateFunctionStmt);
    ntShowCreateProcedureStmt: Result := SizeOf(TShowCreateProcedureStmt);
    ntShowCreateTableStmt: Result := SizeOf(TShowCreateTableStmt);
    ntShowCreateTriggerStmt: Result := SizeOf(TShowCreateTriggerStmt);
    ntShowCreateViewStmt: Result := SizeOf(TShowCreateViewStmt);
    ntShowDatabasesStmt: Result := SizeOf(TShowDatabasesStmt);
    ntShowEngineStmt: Result := SizeOf(TShowEngineStmt);
    ntShowEnginesStmt: Result := SizeOf(TShowEnginesStmt);
    ntShowErrorsStmt: Result := SizeOf(TShowErrorsStmt);
    ntShowEventsStmt: Result := SizeOf(TShowEventsStmt);
    ntShowFunctionCodeStmt: Result := SizeOf(TShowFunctionCodeStmt);
    ntShowFunctionStatusStmt: Result := SizeOf(TShowFunctionStatusStmt);
    ntShowGrantsStmt: Result := SizeOf(TShowGrantsStmt);
    ntShowIndexStmt: Result := SizeOf(TShowIndexStmt);
    ntShowMasterStatusStmt: Result := SizeOf(TShowMasterStatusStmt);
    ntShowOpenTablesStmt: Result := SizeOf(TShowOpenTablesStmt);
    ntShowPluginsStmt: Result := SizeOf(TShowPluginsStmt);
    ntShowPrivilegesStmt: Result := SizeOf(TShowPrivilegesStmt);
    ntShowProcedureCodeStmt: Result := SizeOf(TShowProcedureCodeStmt);
    ntShowProcedureStatusStmt: Result := SizeOf(TShowProcedureStatusStmt);
    ntShowProcessListStmt: Result := SizeOf(TShowProcessListStmt);
    ntShowProfileStmt: Result := SizeOf(TShowProfileStmt);
    ntShowProfilesStmt: Result := SizeOf(TShowProfilesStmt);
    ntShowRelaylogEventsStmt: Result := SizeOf(TShowRelaylogEventsStmt);
    ntShowSlaveHostsStmt: Result := SizeOf(TShowSlaveHostsStmt);
    ntShowSlaveStatusStmt: Result := SizeOf(TShowSlaveStatusStmt);
    ntShowStatusStmt: Result := SizeOf(TShowStatusStmt);
    ntShowTableStatusStmt: Result := SizeOf(TShowTableStatusStmt);
    ntShowTablesStmt: Result := SizeOf(TShowTablesStmt);
    ntShowTriggersStmt: Result := SizeOf(TShowTriggersStmt);
    ntShowVariablesStmt: Result := SizeOf(TShowVariablesStmt);
    ntShowWarningsStmt: Result := SizeOf(TShowWarningsStmt);
    ntShutdownStmt: Result := SizeOf(TShutdownStmt);
    ntSignalStmt: Result := SizeOf(TSignalStmt);
    ntSignalStmtInformation: Result := SizeOf(TSignalStmt.TInformation);
    ntSoundsLikeOp: Result := SizeOf(TSoundsLikeOp);
    ntStartSlaveStmt: Result := SizeOf(TStartSlaveStmt);
    ntStartTransactionStmt: Result := SizeOf(TStartTransactionStmt);
    ntStopSlaveStmt: Result := SizeOf(TStopSlaveStmt);
    ntSubArea: Result := SizeOf(TSubArea);
    ntSubPartition: Result := SizeOf(TSubPartition);
    ntSubstringFunc: Result := SizeOf(TSubstringFunc);
    ntTableReference: Result := SizeOf(TTableReference);
    ntTag: Result := SizeOf(TTag);
    ntTruncateStmt: Result := SizeOf(TTruncateStmt);
    ntUnaryOp: Result := SizeOf(TUnaryOp);
    ntUnknownStmt: Result := SizeOf(TUnknownStmt);
    ntUnlockStmt: Result := SizeOf(TUnlockStmt);
    ntUpdateStmt: Result := SizeOf(TUpdateStmt);
    ntUser: Result := SizeOf(TUser);
    ntUseStmt: Result := SizeOf(TUseStmt);
    ntValue: Result := SizeOf(TValue);
    ntVariable: Result := SizeOf(TVariable);
    ntWeightStringFunc: Result := SizeOf(TWeightStringFunc);
    ntWeightStringFuncLevel: Result := SizeOf(TWeightStringFunc.TLevel);
    ntWhileStmt: Result := SizeOf(TWhileStmt);
    ntXAStmt: Result := SizeOf(TXAStmt);
    else raise Exception.Create(SArgumentOutOfRange);
  end;
end;

function TMySQLParser.ParseRoot(): TOffset;
var
  Stmt: TOffset;
  Stmts: Classes.TList;
begin
  if (AnsiQuotes) then
  begin
    ttIdents := [ttIdent, ttDQIdent];
    UsageTypeByTokenType[ttDQIdent] := utDbIdent;
  end
  else
    ttIdents := [ttIdent, ttMySQLIdent];
  if (AnsiQuotes) then
    ttStrings := [ttIdent, ttString]
  else
  begin
    ttStrings := [ttIdent, ttString, ttDQIdent];
    UsageTypeByTokenType[ttDQIdent] := utConst;
  end;
  ParsedNodes.MemSize := 1024;
  ReallocMem(ParsedNodes.Mem, ParsedNodes.MemSize);
  ParsedNodes.UsedSize := 1; // "0" means "not assigned", so we start with "1"
  ReplaceTexts.MemSize := 1024 * SizeOf(ReplaceTexts.Mem[0]);
  ReallocMem(ReplaceTexts.Mem, ReplaceTexts.MemSize);
  ReplaceTexts.UsedLength := 1; // "0" means "not assigned", so we start with "1"

  FPreviousToken := 0;
  FCurrentToken := GetParsedToken(0); // Cache for speeding

  Stmts := Classes.TList.Create();

  while (CurrentToken > 0) do
  begin
    FErrorCode := PE_Success;
    FErrorToken := 0;
    FErrorLine := 1;

    Stmt := ParseStmt();
    if (Stmt > 0) then
      Stmts.Add(Pointer(Stmt));

    while ((CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType = ttDelimiter)) do
      ApplyCurrentToken();
  end;

  while (CurrentToken > 0) do
    ApplyCurrentToken();

  Result := TRoot.Create(Self, 1, PreviousToken, Stmts.Count, TIntegerArray(Stmts.List));

  Stmts.Free();
end;

function TMySQLParser.ParseAnalyzeStmt(): TOffset;
var
  Nodes: TAnalyzeStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiANALYZE);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiNO_WRITE_TO_BINLOG) then
      Nodes.NoWriteToBinlogTag := ParseTag(kiNO_WRITE_TO_BINLOG)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCAL) then
      Nodes.NoWriteToBinlogTag := ParseTag(kiLOCAL);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiTABLE) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.TableTag := ParseTag(kiTABLE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.TablesList := ParseList(False, ParseTableIdent);
  Result := TAnalyzeStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseAlias(): TOffset;
begin
  if (TokenPtr(CurrentToken)^.TokenType = ttString) then
    Result := ParseString()
  else if (TokenPtr(CurrentToken)^.TokenType in ttIdents) then
    Result := ApplyCurrentToken(utConst)
  else
  begin
    SetError(PE_UnexpectedToken);
    Result := 0;
  end;
end;

function TMySQLParser.ParseAlterDatabaseStmt(): TOffset;
var
  Found: Boolean;
  Nodes: TAlterDatabaseStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(NextToken[1])) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiDATABASE) then
    Nodes.StmtTag := ParseTag(kiALTER, kiDATABASE)
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiSCHEMA) then
    Nodes.StmtTag := ParseTag(kiALTER, kiSCHEMA)
  else
    SetError(PE_UnexpectedToken);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiUPGRADE) then
    begin
      if (not Error and not EndOfStmt(CurrentToken)
        and (TokenPtr(CurrentToken)^.TokenType in ttIdents)
        and (TokenPtr(CurrentToken)^.KeywordIndex <> kiDEFAULT)
        and (TokenPtr(CurrentToken)^.KeywordIndex <> kiCHARACTER)
        and (TokenPtr(CurrentToken)^.KeywordIndex <> kiCOLLATE)) then
        Nodes.IdentTag := ParseDatabaseIdent();

      Found := True;
      while (not Error and Found and not EndOfStmt(CurrentToken)) do
        if ((Nodes.CharacterSetValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARACTER)) then
          Nodes.CharacterSetValue := ParseValue(WordIndices(kiCHARACTER, kiSET), vaAuto, ParseIdent)
        else if ((Nodes.CharacterSetValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARSET)) then
          Nodes.CharacterSetValue := ParseValue(kiCHARSET, vaAuto, ParseIdent)
        else if ((Nodes.CollateValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLLATE)) then
          Nodes.CollateValue := ParseValue(kiCOLLATE, vaAuto, ParseIdent)
        else if ((Nodes.CharacterSetValue = 0) and not EndOfStmt(NextToken[1]) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCHARACTER)) then
          Nodes.CharacterSetValue := ParseValue(WordIndices(kiDEFAULT, kiCHARACTER, kiSET), vaAuto, ParseIdent)
        else if ((Nodes.CollateValue = 0) and not EndOfStmt(NextToken[1]) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCOLLATE)) then
          Nodes.CollateValue := ParseValue(WordIndices(kiDEFAULT, kiCOLLATE), vaAuto, ParseIdent)
        else
          Found := False;
    end
    else
    begin
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
        SetError(PE_UnexpectedToken)
      else
        Nodes.IdentTag := ParseDatabaseIdent();

      Nodes.UpgradeDataDirectoryNameTag := ParseTag(kiUPGRADE, kiDATA, kiDIRECTORY, kiNAME);
    end;

  Result := TAlterDatabaseStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseAlterEventStmt(): TOffset;
var
  Nodes: TAlterEventStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.AlterTag := ParseTag(kiALTER);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFINER)) then
    Nodes.DefinerNode := ParseDefinerValue();

  if (not Error) then
    Nodes.EventTag := ParseTag(kiEVENT);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.EventIdent := ParseEventIdent();

  if (not Error and not EndOfStmt(CurrentToken)
    and (TokenPtr(CurrentToken)^.KeywordIndex = kiON)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSCHEDULE)) then
  begin
    Nodes.OnSchedule.Tag := ParseTag(kiON, kiSCHEDULE);
    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.OnSchedule.Value := ParseSchedule();
  end;

  if (not Error and not EndOfStmt(CurrentToken)
    and (TokenPtr(CurrentToken)^.KeywordIndex = kiON)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCOMPLETION)) then
    if (not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiNOT)) then
      Nodes.OnCompletitionTag := ParseTag(kiON, kiCOMPLETION, kiNOT, kiPRESERVE)
    else
      Nodes.OnCompletitionTag := ParseTag(kiON, kiCOMPLETION, kiPRESERVE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiRENAME)) then
    Nodes.RenameValue := ParseValue(WordIndices(kiRENAME, kiTO), vaNo, ParseEventIdent);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiENABLE) then
      Nodes.EnableTag := ParseTag(kiENABLE)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiDISABLE)
      and (TokenPtr(NextToken[1])^.KeywordIndex = kiON)) then
      Nodes.EnableTag := ParseTag(kiDISABLE, kiON, kiSLAVE)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiDISABLE) then
      Nodes.EnableTag := ParseTag(kiDISABLE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOMMENT)) then
    Nodes.CommentValue := ParseValue(kiCOMMENT, vaNo, ParseString);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDO)) then
  begin
    Nodes.DoTag := ParseTag(kiDO);

    if (not Error) then
      Nodes.Body := ParsePL_SQLStmt();
  end;

  Result := TAlterEventStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseAlterInstanceStmt(): TOffset;
var
  Nodes: TAlterInstanceStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiALTER, kiINSTANCE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiROTATE) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.RotateTag := ParseTag(kiROTATE, kiINNODB, kiMASTER, kiKEY);

  Result := TAlterInstanceStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseAlterRoutineStmt(const ARoutineType: TRoutineType): TOffset;
var
  Nodes: TAlterRoutineStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(NextToken[1])) then
    SetError(PE_IncompleteStmt, NextToken[1])
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiPROCEDURE) then
    Nodes.AlterTag := ParseTag(kiALTER, kiPROCEDURE)
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiFUNCTION) then
    Nodes.AlterTag := ParseTag(kiALTER, kiFUNCTION)
  else
    SetError(PE_UnexpectedToken);

  if (not Error) then
    if (ARoutineType = rtFunction) then
      Nodes.IdentNode := ParseDbIdent(ditFunction)
    else
      Nodes.IdentNode := ParseDbIdent(ditProcedure);

  if (not Error) then
    Nodes.CharacteristicList := ParseCreateRoutineStmtCharacteristList();

  Result := TAlterRoutineStmt.Create(Self, ARoutineType, Nodes);
end;

function TMySQLParser.ParseAlterServerStmt(): TOffset;
var
  Nodes: TAlterServerStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiALTER, kiSERVER);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.IdentNode := ParseDbIdent(ditServer);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiOPTIONS) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.Options.Tag := ParseTag(kiOPTIONS);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Options.List := ParseCreateServerStmtOptionList();

  Result := TAlterServerStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseAlterTableStmt(): TOffset;
var
  DelimiterExpected: Boolean;
  DelimiterFound: Boolean;
  ListNodes: TList.TNodes;
  Nodes: TAlterTableStmt.TNodes;
  Specifications: Classes.TList;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Specifications := Classes.TList.Create();

  Nodes.AlterTag := ParseTag(kiALTER);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIGNORE)) then
    Nodes.IgnoreTag := ParseTag(kiIGNORE);

  if (not Error) then
    Nodes.TableTag := ParseTag(kiTABLE);

  if (not Error) then
    Nodes.IdentNode := ParseTableIdent();


  DelimiterFound := False; DelimiterExpected := False;
  while (not Error and (DelimiterFound or not DelimiterExpected) and not EndOfStmt(CurrentToken)) do
  begin
    DelimiterExpected := True;

    if (TokenPtr(CurrentToken)^.KeywordIndex = kiADD) then
      Specifications.Add(Pointer(ParseCreateTableStmtDefinition(True)))
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiALTER) then
      Specifications.Add(Pointer(ParseAlterTableStmtAlterColumn()))
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCHANGE) then
      Specifications.Add(Pointer(ParseCreateTableStmtColumn(caChange)))
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiDROP) then
      Specifications.Add(Pointer(ParseAlterTableStmtDropItem()))
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiMODIFY) then
      Specifications.Add(Pointer(ParseCreateTableStmtColumn(caModify)))


    else if ((Nodes.AlgorithmValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiALGORITHM)) then
    begin
      Nodes.AlgorithmValue := ParseValue(kiALGORITHM, vaAuto, WordIndices(kiDEFAULT, kiINPLACE, kiCOPY));
      Specifications.Add(Pointer(Nodes.AlgorithmValue));
    end
    else if ((Nodes.ConvertToCharacterSetNode = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCONVERT)) then
    begin
      Nodes.ConvertToCharacterSetNode := ParseAlterTableStmtConvertTo();
      Specifications.Add(Pointer(Nodes.ConvertToCharacterSetNode));
    end
    else if ((Nodes.EnableKeys = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDISABLE)) then
    begin
      Nodes.EnableKeys := ParseTag(kiDISABLE, kiKEYS);
      Specifications.Add(Pointer(Nodes.EnableKeys));
    end
    else if ((Nodes.DiscardTablespaceTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDISCARD)) then
    begin
      Nodes.DiscardTablespaceTag := ParseTag(kiDISCARD, kiTABLESPACE);
      Specifications.Add(Pointer(Nodes.DiscardTablespaceTag));
    end
    else if ((Nodes.EnableKeys = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiENABLE)) then
    begin
      Nodes.EnableKeys := ParseTag(kiENABLE, kiKEYS);
      Specifications.Add(Pointer(Nodes.EnableKeys));
    end
    else if ((Nodes.ForceTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFORCE)) then
    begin
      Nodes.ForceTag := ParseTag(kiFORCE);
      Specifications.Add(Pointer(Nodes.ForceTag));
    end
    else if ((Nodes.ImportTablespaceTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIMPORT)) then
    begin
      Nodes.ImportTablespaceTag := ParseTag(kiDISCARD, kiTABLESPACE);
      Specifications.Add(Pointer(Nodes.ImportTablespaceTag));
    end
    else if ((Nodes.LockValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCK)) then
    begin
      Nodes.LockValue := ParseValue(kiLOCK, vaAuto, WordIndices(kiDEFAULT, kiNONE, kiSHARED, kiEXCLUSIVE));
      Specifications.Add(Pointer(Nodes.LockValue));
    end
    else if ((Nodes.OrderByValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiORDER)) then
    begin
      Nodes.OrderByValue := ParseValue(WordIndices(kiORDER, kiBY), vaNo, ParseCreateTableStmtKeyColumn);
      Specifications.Add(Pointer(Nodes.OrderByValue));
    end
    else if ((Nodes.RenameNode = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiRENAME)) then
    begin
      if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiTO)) then
        Nodes.RenameNode := ParseValue(WordIndices(kiRENAME, kiTO), vaNo, ParseTableIdent)
      else if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiAS)) then
        Nodes.RenameNode := ParseValue(WordIndices(kiRENAME, kiAS), vaNo, ParseTableIdent)
      else
        Nodes.RenameNode := ParseValue(kiRENAME, vaNo, ParseTableIdent);
      Specifications.Add(Pointer(Nodes.RenameNode));
    end


    else if ((Nodes.TableOptionsNodes.AutoIncrementValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAUTO_INCREMENT)) then
    begin
      Nodes.TableOptionsNodes.AutoIncrementValue := ParseValue(kiAUTO_INCREMENT, vaAuto, ParseInteger);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.AutoIncrementValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.AvgRowLengthValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAVG_ROW_LENGTH)) then
    begin
      Nodes.TableOptionsNodes.AvgRowLengthValue := ParseValue(kiAVG_ROW_LENGTH, vaAuto, ParseInteger);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.AvgRowLengthValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.CharacterSetValue = 0) and not EndOfStmt(NextToken[2])
      and ((TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT)
        or (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARACTER)
        or (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARSET))) then
    begin
      if ((TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCHARACTER)) then
        Nodes.TableOptionsNodes.CharacterSetValue := ParseValue(WordIndices(kiDEFAULT, kiCHARACTER, kiSET), vaAuto, ParseIdent)
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCHARSET)) then
        Nodes.TableOptionsNodes.CharacterSetValue := ParseValue(WordIndices(kiDEFAULT, kiCHARSET), vaAuto, ParseIdent)
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCHARACTER)) then
        Nodes.TableOptionsNodes.CharacterSetValue := ParseValue(WordIndices(kiCHARACTER, kiSET), vaAuto, ParseIdent)
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCHARSET)) then
        Nodes.TableOptionsNodes.CharacterSetValue := ParseValue(WordIndices(kiCHARSET), vaAuto, ParseIdent);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.CharacterSetValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.ChecksumValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHECKSUM)) then
    begin
      Nodes.TableOptionsNodes.AutoIncrementValue := ParseValue(kiCHECKSUM, vaAuto, ParseInteger);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.AutoIncrementValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.CollateValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLLATE)) then
    begin
      Nodes.TableOptionsNodes.CollateValue := ParseValue(WordIndices(kiCOLLATE), vaAuto, ParseIdent);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.CollateValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.CharacterSetValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCHARACTER)) then
    begin
      Nodes.TableOptionsNodes.CharacterSetValue := ParseValue(WordIndices(kiDEFAULT, kiCHARACTER, kiSET), vaAuto, ParseIdent);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.CharacterSetValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.CollateValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCOLLATE)) then
    begin
      Nodes.TableOptionsNodes.CollateValue := ParseValue(WordIndices(kiDEFAULT, kiCOLLATE), vaAuto, ParseIdent);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.CollateValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.CommentValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOMMENT)) then
    begin
      Nodes.TableOptionsNodes.CommentValue := ParseValue(kiCOMMENT, vaAuto, ParseString);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.CommentValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.ConnectionValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCONNECTION)) then
    begin
      Nodes.TableOptionsNodes.ConnectionValue := ParseValue(kiCONNECTION, vaAuto, ParseString);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.ConnectionValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.DataDirectoryValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDATA)) then
    begin
      Nodes.TableOptionsNodes.DataDirectoryValue := ParseValue(WordIndices(kiDATA, kiDIRECTORY), vaAuto, ParseString);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.DataDirectoryValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.DelayKeyWriteValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDELAY_KEY_WRITE)) then
    begin
      Nodes.TableOptionsNodes.DelayKeyWriteValue := ParseValue(kiDELAY_KEY_WRITE, vaAuto, ParseInteger);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.DelayKeyWriteValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.EngineValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiENGINE)) then
    begin
      Nodes.TableOptionsNodes.EngineValue := ParseValue(kiENGINE, vaAuto, ParseIdent);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.EngineValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.IndexDirectoryValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiINDEX)) then
    begin
      Nodes.TableOptionsNodes.IndexDirectoryValue := ParseValue(WordIndices(kiINDEX, kiDIRECTORY), vaAuto, ParseString);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.IndexDirectoryValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.InsertMethodValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiINSERT_METHOD)) then
    begin
      Nodes.TableOptionsNodes.InsertMethodValue := ParseValue(kiINSERT_METHOD, vaAuto, WordIndices(kiNO, kiFIRST, kiLAST));
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.InsertMethodValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.KeyBlockSizeValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiKEY_BLOCK_SIZE)) then
    begin
      Nodes.TableOptionsNodes.KeyBlockSizeValue := ParseValue(kiKEY_BLOCK_SIZE, vaAuto, ParseInteger);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.KeyBlockSizeValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.MaxRowsValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_ROWS)) then
    begin
      Nodes.TableOptionsNodes.MaxRowsValue := ParseValue(kiMAX_ROWS, vaAuto, ParseInteger);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.MaxRowsValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.MinRowsValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiMIN_ROWS)) then
    begin
      Nodes.TableOptionsNodes.MinRowsValue := ParseValue(kiMIN_ROWS, vaAuto, ParseInteger);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.MinRowsValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.PackKeysValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPACK_KEYS)) then
    begin
      Nodes.TableOptionsNodes.PackKeysValue := ParseValue(kiPACK_KEYS, vaAuto, ParseExpr);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.PackKeysValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.PageChecksum = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPAGE_CHECKSUM)) then
    begin
      Nodes.TableOptionsNodes.PageChecksum := ParseValue(kiPAGE_CHECKSUM, vaAuto, ParseInteger);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.PageChecksum));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.PasswordValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPASSWORD)) then
    begin
      Nodes.TableOptionsNodes.PasswordValue := ParseValue(kiPASSWORD, vaAuto, ParseString);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.PasswordValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.RowFormatValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiROW_FORMAT)) then
    begin
      Nodes.TableOptionsNodes.RowFormatValue := ParseValue(kiROW_FORMAT, vaAuto, WordIndices(kiDEFAULT, kiDYNAMIC, kiFIXED, kiCOMPRESSED, kiREDUNDANT, kiCOMPACT));
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.RowFormatValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.StatsAutoRecalcValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSTATS_AUTO_RECALC)) then
    begin
      if (EndOfStmt(NextToken[1])) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(NextToken[1])^.TokenType = ttInteger) then
        Nodes.TableOptionsNodes.StatsAutoRecalcValue := ParseValue(kiSTATS_AUTO_RECALC, vaAuto, ParseInteger)
      else
        Nodes.TableOptionsNodes.StatsAutoRecalcValue := ParseValue(kiSTATS_AUTO_RECALC, vaAuto, WordIndices(kiDEFAULT));
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.StatsAutoRecalcValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.StatsPersistentValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSTATS_PERSISTENT)) then
    begin
      if (EndOfStmt(NextToken[1])) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(NextToken[1])^.TokenType = ttInteger) then
        Nodes.TableOptionsNodes.StatsPersistentValue := ParseValue(kiSTATS_PERSISTENT, vaAuto, ParseInteger)
      else
        Nodes.TableOptionsNodes.StatsPersistentValue := ParseValue(kiSTATS_PERSISTENT, vaAuto, WordIndices(kiDEFAULT));
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.StatsPersistentValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.EngineValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiTYPE)) then
    begin
      Nodes.TableOptionsNodes.EngineValue := ParseValue(kiTYPE, vaAuto, ParseIdent);
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.EngineValue));
      DelimiterExpected := False;
    end
    else if ((Nodes.TableOptionsNodes.UnionList = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUNION)) then
    begin
      Nodes.TableOptionsNodes.UnionList := ParseAlterTableStmtUnion();
      Specifications.Add(Pointer(Nodes.TableOptionsNodes.UnionList));
      DelimiterExpected := False;
    end


    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiANALYZE)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiCHECK)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiOPTIMIZE)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiREBUILD)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiREPAIR)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiTRUNCATE)) then
    begin
      Specifications.Add(Pointer(ParseValue(TokenPtr(CurrentToken)^.KeywordIndex, vaNo, ParseCreateTableStmtDefinitionPartitionNames)));
      break;
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCOALESCE) then
    begin
      Specifications.Add(Pointer(ParseValue(kiCOALESCE, vaNo, ParseInteger)));
      break;
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiEXCHANGE) then
    begin
      Specifications.Add(Pointer(ParseAlterTableStmtExchangePartition()));
      break;
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiREMOVE) then
    begin
      Specifications.Add(Pointer(ParseTag(kiREMOVE, kiPARTITIONING)));
      break;
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiREORGANIZE) then
    begin
      Specifications.Add(Pointer(ParseAlterTableStmtReorganizePartition()));
      break;
    end;

    if (not Error) then
      if (DelimiterExpected and not EndOfStmt(CurrentToken) and not (TokenPtr(CurrentToken)^.TokenType in [ttComma, ttDelimiter])) then
        SetError(PE_UnexpectedToken)
      else
      begin
        DelimiterFound := not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttComma);
        if (DelimiterFound) then
          Specifications.Add(Pointer(ApplyCurrentToken()));
      end;
  end;

  FillChar(ListNodes, SizeOf(ListNodes), 0);
  ListNodes.DelimiterType := ttComma;
  Nodes.SpecificationList := TList.Create(Self, ListNodes, Specifications.Count, TIntegerArray(Specifications.List));
  Result := TAlterTableStmt.Create(Self, Nodes);

  Specifications.Free();
end;

function TMySQLParser.ParseAlterTableStmtAlterColumn(): TOffset;
var
  Nodes: TAlterTableStmt.TAlterColumn.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCOLUMN)) then
    Nodes.AlterTag := ParseTag(kiALTER, kiCOLUMN)
  else
    Nodes.AlterTag := ParseTag(kiALTER);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.ColumnIdent := ParseColumnIdent();

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiSET) then
      Nodes.SetDefaultValue := ParseValue(WordIndices(kiSET, kiDEFAULT), vaNo, ParseString)
    else
      Nodes.DropDefaultTag := ParseTag(kiDROP);

  Result := TAlterTableStmt.TAlterColumn.Create(Self, Nodes);
end;

function TMySQLParser.ParseAlterTableStmtConvertTo(): TOffset;
var
  Nodes: TAlterTableStmt.TConvertTo.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.ConvertToTag := ParseTag(kiCONVERT, kiTO);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiCHARACTER) then
      Nodes.CharacterSetValue := ParseValue(WordIndices(kiCHARACTER, kiSET), vaNo, ParseIdent)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiCHARSET) then
      Nodes.CharacterSetValue := ParseValue(WordIndices(kiCHARSET), vaNo, ParseIdent)
    else
      SetError(PE_UnexpectedToken);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLLATE)) then
    Nodes.CollateValue := ParseValue(kiCOLLATE, vaNo, ParseIdent);

  Result := TAlterTableStmt.TConvertTo.Create(Self, Nodes);
end;

function TMySQLParser.ParseAlterTableStmtDropItem(): TOffset;
var
  Nodes: TAlterTableStmt.TDropObject.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not Error) then
    Nodes.DropTag := ParseTag(kiDROP);

  if (not Error) then
  begin
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiPARTITION) then
    begin
      Nodes.ItemTypeTag := ParseTag(kiPARTITION);

      if (not Error) then
        Nodes.Ident := ParseList(False, ParseCreateTableStmtPartitionIdent);
    end
    else
    begin
      if (TokenPtr(CurrentToken)^.KeywordIndex = kiPRIMARY) then
        Nodes.ItemTypeTag := ParseTag(kiPRIMARY, kiKEY)
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiINDEX)
        or (TokenPtr(CurrentToken)^.KeywordIndex = kiKEY)) then
      begin
        Nodes.ItemTypeTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);
        if (not Error) then
          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else
            Nodes.Ident := ParseDbIdent(ditKey);
      end
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFOREIGN) then
      begin
        Nodes.ItemTypeTag := ParseTag(kiFOREIGN, kiKEY);

        if (not Error) then
          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else
            Nodes.Ident := ParseForeignKeyIdent();
      end
      else
      begin
        if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLUMN)) then
          Nodes.ItemTypeTag := ParseTag(kiCOLUMN);

        if (not Error) then
          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
            SetError(PE_UnexpectedToken)
          else
            Nodes.Ident := ParseColumnIdent();
      end;
    end;
  end;

  Result := TAlterTableStmt.TDropObject.Create(Self, Nodes);
end;

function TMySQLParser.ParseAlterTableStmtExchangePartition(): TOffset;
var
  Nodes: TAlterTableStmt.TExchangePartition.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.ExchangePartitionTag := ParseTag(kiEXCHANGE, kiPARTITION);

  if (not Error) then
    Nodes.PartitionIdent := ParseCreateTableStmtPartitionIdent();

  if (not Error) then
    Nodes.WithTableTag := ParseTag(kiWITH, kiTABLE);

  if (not Error) then
    Nodes.TableIdent := ParseTableIdent();

  Result := TAlterTableStmt.TExchangePartition.Create(Self, Nodes);
end;

function TMySQLParser.ParseAlterTableStmtReorganizePartition(): TOffset;
var
  Nodes: TAlterTableStmt.TReorganizePartition.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.ReorganizePartitionTag := ParseTag(kiREORGANIZE, kiPARTITION);

  if (not Error) then
    Nodes.PartitionIdentList := ParseList(False, ParseCreateTableStmtPartitionIdent);

  if (not Error) then
    Nodes.IntoTag := ParseTag(kiINTO);

  if (not Error) then
    Nodes.PartitionList := ParseList(True, ParseCreateTableStmtPartition);

  Result := TAlterTableStmt.TReorganizePartition.Create(Self, Nodes);
end;

function TMySQLParser.ParseAlterTableStmtUnion(): TOffset;
var
  Nodes: TValue.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IdentTag := ParseTag(kiUNION);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.OperatorType = otEqual)) then
  begin
    TokenPtr(CurrentToken)^.FOperatorType := otAssign;
    Nodes.AssignToken := ApplyCurrentToken();
  end;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ValueToken := ParseList(True, ParseTableIdent);

  Result := TValue.Create(Self, Nodes);
end;

function TMySQLParser.ParseAlterStmt(): TOffset;
var
  Index: Integer;
begin
  Assert(TokenPtr(CurrentToken)^.KeywordIndex = kiALTER);

  Result := 0;
  Index := 1;

  if (not Error and not EndOfStmt(NextToken[Index]) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiALGORITHM)) then
  begin
    Inc(Index);
    if (EndOfStmt(NextToken[Index])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.OperatorType <> otEqual) then
      SetError(PE_UnexpectedToken, NextToken[Index])
    else
    begin
      Inc(Index);

      if (EndOfStmt(NextToken[Index])) then
        SetError(PE_IncompleteStmt)
      else if ((TokenPtr(NextToken[Index])^.KeywordIndex <> kiUNDEFINED)
        and (TokenPtr(NextToken[Index])^.KeywordIndex <> kiMERGE)
        and (TokenPtr(NextToken[Index])^.KeywordIndex <> kiTEMPTABLE)) then
        SetError(PE_UnexpectedToken, NextToken[Index])
      else
        Inc(Index);
    end;
  end;

  if (not Error and not EndOfStmt(NextToken[Index]) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiDEFINER)) then
  begin
    Inc(Index);
    if (EndOfStmt(NextToken[Index])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.OperatorType <> otEqual) then
      SetError(PE_UnexpectedToken, NextToken[Index])
    else
    begin
      Inc(Index);

      if (EndOfStmt(NextToken[Index])) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiCURRENT_USER) then
        if (((NextToken[Index + 1] = 0) or (TokenPtr(NextToken[Index + 1])^.TokenType <> ttOpenBracket))
          and ((NextToken[Index + 2] = 0) or (TokenPtr(NextToken[Index + 2])^.TokenType <> ttCloseBracket))) then
          Inc(Index)
        else
          Inc(Index, 3)
      else
      begin
        Inc(Index); // Username

        if (not Error and not EndOfStmt(NextToken[Index]) and (TokenPtr(NextToken[Index])^.TokenType = ttAt)) then
        begin
          Inc(Index); // @
          if (not Error and not EndOfStmt(NextToken[Index])) then
            Inc(Index); // Servername
        end;
      end;
    end;
  end;

  if (not Error and not EndOfStmt(NextToken[Index]) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiSQL)) then
  begin
    Inc(Index);
    if (EndOfStmt(NextToken[Index])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex <> kiSECURITY) then
      SetError(PE_UnexpectedToken, NextToken[Index])
    else
    begin
      Inc(Index);
      if (EndOfStmt(NextToken[Index])) then
        SetError(PE_IncompleteStmt)
      else if ((TokenPtr(NextToken[Index])^.KeywordIndex <> kiDEFINER)
        and (TokenPtr(NextToken[Index])^.KeywordIndex <> kiINVOKER)) then
        SetError(PE_UnexpectedToken, NextToken[Index])
      else
        Inc(Index);
    end;
  end;

  if (not Error) then
    if (EndOfStmt(NextToken[Index])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiDATABASE) then
      Result := ParseAlterDatabaseStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiEVENT) then
      Result := ParseAlterEventStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiFUNCTION) then
      Result := ParseAlterRoutineStmt(rtFunction)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiPROCEDURE) then
      Result := ParseAlterRoutineStmt(rtProcedure)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiSERVER) then
      Result := ParseAlterServerStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiTABLE) then
      Result := ParseAlterTableStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiUSER) then
      Result := ParseCreateUserStmt(True)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiVIEW) then
      Result := ParseAlterViewStmt()
    else
      SetError(PE_UnexpectedToken, NextToken[Index]);
end;

function TMySQLParser.ParseAlterViewStmt(): TOffset;
var
  Nodes: TAlterViewStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.AlterTag := ParseTag(kiALTER);

  if (not Error and (TokenPtr(CurrentToken)^.KeywordIndex = kiALGORITHM)) then
    Nodes.AlgorithmValue := ParseValue(kiALGORITHM, vaYes, ParseKeyword);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFINER)) then
    Nodes.DefinerNode := ParseDefinerValue();

  if (not Error and (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL)) then
    if (EndOfStmt(NextToken[2])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[2])^.KeywordIndex = kiDEFINER) then
      Nodes.SQLSecurityTag := ParseTag(kiSQL, kiSECURITY, kiDEFINER)
    else
      Nodes.SQLSecurityTag := ParseTag(kiSQL, kiSECURITY, kiINVOKER);

  if (not Error) then
    Nodes.ViewTag := ParseTag(kiVIEW);

  if (not Error) then
    Nodes.IdentNode := ParseTableIdent();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
    Nodes.Columns := ParseList(True, ParseColumnIdent);

  if (not Error) then
    Nodes.AsTag := ParseTag(kiAS);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiSELECT) then
      SetError(PE_UnexpectedToken)
    else
    begin
      Nodes.SelectStmt := ParseSelectStmt();

      if (not Error and (TokenPtr(CurrentToken)^.KeywordIndex = kiWITH)) then
        if (EndOfStmt(NextToken[1])) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(NextToken[1])^.KeywordIndex = kiCASCADED) then
          Nodes.OptionTag := ParseTag(kiWITH, kiCASCADED, kiCHECK, kiOPTION)
        else if (TokenPtr(NextToken[1])^.KeywordIndex = kiLOCAL) then
          Nodes.OptionTag := ParseTag(kiWITH, kiLOCAL, kiCHECK, kiOPTION)
        else
          Nodes.OptionTag := ParseTag(kiWITH, kiCHECK, kiOPTION);
    end;

  Result := TAlterViewStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseBeginStmt(): TOffset;
var
  Nodes: TBeginStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiWORK)) then
    Nodes.BeginTag := ParseTag(kiBEGIN, kiWORK)
  else
    Nodes.BeginTag := ParseTag(kiBEGIN);

  Result := TBeginStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCallStmt(): TOffset;
var
  Nodes: TCallStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CallTag := ParseTag(kiCALL);

  if (not Error) then
    Nodes.ProcedureIdent := ParseDbIdent(ditProcedure);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
    Nodes.ParamList := ParseList(True, ParseExpr);

  Result := TCallStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCaseOp(): TOffset;
var
  Branches: array of TOffset;
  ListNodes: TList.TNodes;
  Nodes: TCaseOp.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  SetLength(Branches, 0);

  Nodes.CaseTag := ParseTag(kiCASE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiWHEN) then
    begin
      Nodes.CompareExpr := ParseExpr();

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiWHEN) then
          SetError(PE_UnexpectedToken)
        else
          repeat
            SetLength(Branches, Length(Branches) + 1);
            Branches[Length(Branches) - 1] := ParseCaseOpBranch();
          until (Error or EndOfStmt(CurrentToken) or (TokenPtr(CurrentToken)^.KeywordIndex <> kiWHEN));
    end
    else
    begin
      repeat
        SetLength(Branches, Length(Branches) + 1);
        Branches[Length(Branches) - 1] := ParseCaseOpBranch();
      until (Error or EndOfStmt(CurrentToken) or (TokenPtr(CurrentToken)^.KeywordIndex <> kiWHEN));
    end;

  FillChar(ListNodes, SizeOf(ListNodes), 0);
  Nodes.BranchList := TList.Create(Self, ListNodes, Length(Branches), Branches);
  SetLength(Branches, 0);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiELSE)) then
  begin
    Nodes.ElseTag := ParseTag(kiELSE);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.ElseExpr := ParseExpr();
  end;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiEND) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.EndTag := ParseTag(kiEND);

  Result := TCaseOp.Create(Self, Nodes);
end;

function TMySQLParser.ParseCaseOpBranch(): TOffset;
var
  Nodes: TCaseOp.TBranch.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.WhenTag := ParseTag(kiWHEN);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.CondExpr := ParseExpr();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiTHEN) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.ThenTag := ParseTag(kiTHEN);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ResultExpr := ParseExpr();

  Result := TCaseOp.TBranch.Create(Self, Nodes);
end;

function TMySQLParser.ParseCaseStmt(): TOffset;
var
  Branches: array of TOffset;
  ListNodes: TList.TNodes;
  Nodes: TCaseStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  SetLength(Branches, 0);

  Nodes.CaseTag := ParseTag(kiCASE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiWHEN)) then
    Nodes.CompareExpr := ParseExpr();

  while (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWHEN)) do
  begin
    SetLength(Branches, Length(Branches) + 1);
    Branches[Length(Branches) - 1] := ParseCaseStmtBranch();
  end;

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiELSE)) then
  begin
    SetLength(Branches, Length(Branches) + 1);
    Branches[Length(Branches) - 1] := ParseCaseStmtBranch();
  end;

  FillChar(ListNodes, SizeOf(ListNodes), 0);
  Nodes.BranchList := TList.Create(Self, ListNodes, Length(Branches), Branches);
  SetLength(Branches, 0);

  if (not Error) then
    Nodes.EndTag := ParseTag(kiEND, kiCASE);

  Result := TCaseStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCaseStmtBranch(): TOffset;
var
  Nodes: TCaseStmt.TBranch.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWHEN)) then
  begin
    Nodes.Tag := ParseTag(kiWHEN);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.ConditionExpr := ParseExpr();

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiTHEN) then
        SetError(PE_UnexpectedToken)
      else
        Nodes.ThenTag := ParseTag(kiTHEN);
  end
  else if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiELSE)) then
    Nodes.Tag := ParseTag(kiELSE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.StmtList := ParseList(False, ParsePL_SQLStmt, ttDelimiter);

  Result := TCaseStmt.TBranch.Create(Self, Nodes);
end;

function TMySQLParser.ParseCastFunc(): TOffset;
var
  Nodes: TCastFunc.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.FuncToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Expr := ParseExpr();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiAS) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.AsTag := ParseTag(kiAS);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.DataType := ParseDataType();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TCastFunc.Create(Self, Nodes);
end;

function TMySQLParser.ParseCharFunc(): TOffset;
var
  Nodes: TCharFunc.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.FuncToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ValueList := ParseList(False, ParseExpr);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUSING)) then
  begin
    Nodes.UsingTag := ParseTag(kiUSING);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
        SetError(PE_UnexpectedToken)
      else
        Nodes.CharsetIdent := ParseIdent();
  end;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TCharFunc.Create(Self, Nodes);
end;

function TMySQLParser.ParseCheckStmt(): TOffset;
var
  Nodes: TCheckStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiCHECK, kiTABLE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.TablesList := ParseList(False, ParseTableIdent);

  if (not Error and not EndOfStmt(CurrentToken)) then
    Nodes.OptionList := ParseList(False, ParseCheckStmtOption);

  Result := TCheckStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCheckStmtOption(): TOffset;
var
  Nodes: TCheckStmt.TOption.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFOR) then
    Nodes.OptionTag := ParseTag(kiFOR, kiUPGRADE)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiQUICK) then
    Nodes.OptionTag := ParseTag(kiQUICK)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFAST) then
    Nodes.OptionTag := ParseTag(kiFAST)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiMEDIUM) then
    Nodes.OptionTag := ParseTag(kiMEDIUM)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiEXTENDED) then
    Nodes.OptionTag := ParseTag(kiEXTENDED)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCHANGED) then
    Nodes.OptionTag := ParseTag(kiCHANGED)
  else
    SetError(PE_UnexpectedToken);

  Result := TCheckStmt.TOption.Create(Self, Nodes);
end;

function TMySQLParser.ParseChecksumStmt(): TOffset;
var
  Nodes: TChecksumStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiCHECKSUM, kiTABLE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.TablesList := ParseList(False, ParseTableIdent);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiQUICK) then
      Nodes.OptionTag := ParseTag(kiQUICK)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiEXTENDED) then
      Nodes.OptionTag := ParseTag(kiEXTENDED)
    else
      SetError(PE_UnexpectedToken);

  Result := TChecksumStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCloseStmt(): TOffset;
var
  Nodes: TCloseStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CloseTag := ParseTag(kiCLOSE);

  if (not Error) then
    Nodes.CursorIdent := ParseDbIdent(ditCursor);

  Result := TCloseStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCommitStmt(): TOffset;
var
  Nodes: TCommitStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiWORK)) then
    Nodes.CommitTag := ParseTag(kiCOMMIT, kiWORK)
  else
    Nodes.CommitTag := ParseTag(kiCOMMIT);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAND)) then
    if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiNO)) then
      Nodes.CommitTag := ParseTag(kiAND, kiNO, kiCHAIN)
    else
      Nodes.CommitTag := ParseTag(kiAND, kiCHAIN);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(NextToken[1])^.KeywordIndex = kiNO) then
      Nodes.CommitTag := ParseTag(kiNO, kiRELEASE)
    else if (TokenPtr(NextToken[1])^.KeywordIndex = kiRELEASE) then
      Nodes.CommitTag := ParseTag(kiRELEASE);

  Result := TCommitStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCompoundStmt(): TOffset;
var
  Nodes: TCompoundStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(CurrentToken)^.TokenType = ttBeginLabel) then
    Nodes.BeginLabelToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiBEGIN) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.BeginTag := ParseTag(kiBEGIN);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiEND) then
      Nodes.StmtList := ParseList(False, ParsePL_SQLStmt, ttDelimiter);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiEND) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.EndTag := ParseTag(kiEND);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttIdent)) then
    if ((Nodes.BeginLabelToken = 0) or (StrIComp(PChar(TokenPtr(CurrentToken)^.AsString), PChar(TokenPtr(Nodes.BeginLabelToken)^.AsString)) <> 0)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.EndLabelToken := ApplyCurrentToken(utLabel, ttEndLabel);

  Result := TCompoundStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseConvertFunc(): TOffset;
var
  Nodes: TConvertFunc.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.FuncToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error) then
    Nodes.Expr := ParseExpr();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType = ttComma) then
    begin
      Nodes.Comma := ApplyCurrentToken();
      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.DataType := ParseDataType();
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUSING) then
    begin
      Nodes.UsingTag := ParseTag(kiUSING);
      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.CharsetIdent := ApplyCurrentToken();
    end
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TConvertFunc.Create(Self, Nodes);
end;

function TMySQLParser.ParseColumnIdent(): TOffset;
begin
  Result := ParseDbIdent(ditColumn);
end;

function TMySQLParser.ParseCreateDatabaseStmt(): TOffset;
var
  Nodes: TCreateDatabaseStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CreateTag := ParseTag(kiCREATE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSCHEMA) then
      Nodes.DatabaseTag := ParseTag(kiSCHEMA)
    else
      Nodes.DatabaseTag := ParseTag(kiDATABASE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    Nodes.IfNotExistsTag := ParseTag(kiIF, kiNOT, kiEXISTS);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.DatabaseIdent := ParseDbIdent(ditDatabase);

  while (not Error and not EndOfStmt(CurrentToken)) do
    if ((Nodes.CharacterSetValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARACTER)) then
      Nodes.CharacterSetValue := ParseValue(WordIndices(kiCHARACTER, kiSET), vaNo, ParseIdent)
    else if ((Nodes.CollateValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLLATE)) then
      Nodes.CollateValue := ParseValue(kiCOLLATE, vaNo, ParseIdent)
    else if ((Nodes.CollateValue = 0) and not EndOfStmt(NextToken[1]) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCHARACTER)) then
      Nodes.CharacterSetValue := ParseValue(WordIndices(kiDEFAULT, kiCHARACTER, kiSET), vaNo, ParseIdent)
    else if ((Nodes.CollateValue = 0) and not EndOfStmt(NextToken[1]) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCOLLATE)) then
      Nodes.CollateValue := ParseValue(WordIndices(kiDEFAULT, kiCOLLATE), vaNo, ParseIdent)
    else
      SetError(PE_UnexpectedToken);

  Result := TCreateDatabaseStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateEventStmt(): TOffset;
var
  Nodes: TCreateEventStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CreateTag := ParseTag(kiCREATE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFINER)) then
    Nodes.DefinerNode := ParseDefinerValue();

  if (not Error) then
    Nodes.EventTag := ParseTag(kiEVENT);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    Nodes.IfNotExistsTag := ParseTag(kiIF, kiNOT, kiEXISTS);

  if (not Error) then
    Nodes.EventIdent := ParseEventIdent();

  if (not Error) then
    Nodes.OnScheduleValue := ParseValue(WordIndices(kiON, kiSCHEDULE), vaNo, ParseSchedule);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiON) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCOMPLETION)) then
    if (not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiNOT)) then
      Nodes.OnCompletitionTag := ParseTag(kiON, kiCOMPLETION, kiNOT, kiPRESERVE)
    else
      Nodes.OnCompletitionTag := ParseTag(kiON, kiCOMPLETION, kiPRESERVE);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiENABLE) then
      Nodes.EnableTag := ParseTag(kiENABLE)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiDISABLE)
      and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiON)) then
      Nodes.EnableTag := ParseTag(kiDISABLE, kiON, kiSLAVE)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiDISABLE) then
      Nodes.EnableTag := ParseTag(kiDISABLE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOMMENT)) then
    Nodes.CommentValue := ParseValue(kiCOMMENT, vaNo, ParseString);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiDO) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.DoTag := ParseTag(kiDO);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Body := ParsePL_SQLStmt();

  Result := TCreateEventStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateIndexStmt(): TOffset;
var
  Found: Boolean;
  Nodes: TCreateIndexStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CreateTag := ParseTag(kiCREATE);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiUNIQUE) then
      Nodes.IndexTag := ParseTag(kiUNIQUE, kiINDEX)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFULLTEXT) then
      Nodes.IndexTag := ParseTag(kiFULLTEXT, kiINDEX)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSPATIAL) then
      Nodes.IndexTag := ParseTag(kiSPATIAL, kiINDEX)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiINDEX) then
      Nodes.IndexTag := ParseTag(kiINDEX)
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    Nodes.IndexIdent := ParseDbIdent(ditKey);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUSING)) then
    Nodes.IndexTypeValue := ParseValue(kiUSING, vaNo, WordIndices(kiBTREE, kiHASH));

  if (not Error) then
  begin
    Nodes.OnTag := ParseTag(kiON);

    if (not Error) then
      Nodes.TableIdent := ParseTableIdent();
  end;

  if (not Error) then
    Nodes.KeyColumnList := ParseList(True, ParseCreateTableStmtKeyColumn);

  Found := True;
  while (not Error and Found and not EndOfStmt(CurrentToken)) do
    if ((Nodes.AlgorithmValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiALGORITHM)) then
      Nodes.AlgorithmValue := ParseValue(kiALGORITHM, vaAuto, WordIndices(kiDEFAULT,kiINPLACE,kiCOPY))
    else if ((Nodes.CommentValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOMMENT)) then
      Nodes.CommentValue := ParseValue(kiCOMMENT, vaAuto, ParseString)
    else if ((Nodes.KeyBlockSizeValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiKEY_BLOCK_SIZE)) then
      Nodes.KeyBlockSizeValue := ParseValue(kiKEY_BLOCK_SIZE, vaAuto, ParseInteger)
    else if ((Nodes.LockValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCK)) then
      Nodes.LockValue := ParseValue(kiLOCK, vaAuto, WordIndices(kiDEFAULT, kiNONE, kiSHARED, kiEXCLUSIVE))
    else if ((Nodes.IndexTypeValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUSING)) then
      Nodes.IndexTypeValue := ParseValue(kiUSING, vaNo, WordIndices(kiBTREE, kiHASH))
    else if ((Nodes.ParserValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWITH)) then
      Nodes.ParserValue := ParseValue(WordIndices(kiWITH, kiPARSER), vaNo, ParseString)
    else
      Found := False;

  Result := TCreateIndexStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateRoutineStmt(const ARoutineType: TRoutineType): TOffset;
var
  Nodes: TCreateRoutineStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CreateTag := ParseTag(kiCREATE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFINER)) then
    Nodes.DefinerNode := ParseDefinerValue();

  if (not Error) then
    if (ARoutineType = rtFunction) then
      Nodes.RoutineTag := ParseTag(kiFUNCTION)
    else
      Nodes.RoutineTag := ParseTag(kiPROCEDURE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else if (ARoutineType = rtFunction) then
      Nodes.IdentNode := ParseDbIdent(ditFunction)
    else
      Nodes.IdentNode := ParseDbIdent(ditProcedure);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (ARoutineType = rtFunction) then
      Nodes.ParameterList := ParseList(True, ParseFunctionParam)
    else
      Nodes.ParameterList := ParseList(True, ParseProcedureParam);

  if (not Error and (ARoutineType = rtFunction)) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiRETURNS) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.Returns := ParseFunctionReturns();

  if (not Error and not EndOfStmt(CurrentToken)) then
    Nodes.CharacteristicList := ParseCreateRoutineStmtCharacteristList();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
    begin
      if (InCreateFunctionStmt) then
        raise Exception.Create(SUnknownError);
      InCreateFunctionStmt := ARoutineType = rtFunction;
      if (InCreateProcedureStmt) then
        raise Exception.Create(SUnknownError);
      InCreateProcedureStmt := ARoutineType = rtProcedure;
      Nodes.Body := ParsePL_SQLStmt();
      InCreateFunctionStmt := False;
      InCreateProcedureStmt := False;
    end;

  Result := TCreateRoutineStmt.Create(Self, ARoutineType, Nodes);
end;

function TMySQLParser.ParseCreateRoutineStmtCharacteristList(): TOffset;
var
  Characteristics: array of TOffset;
  CommentFound: Boolean;
  DeterministicFound: Boolean;
  Found: Boolean;
  LanguageFound: Boolean;
  ListNodes: TList.TNodes;
  SQLSecurityFound: Boolean;
  Characteristic: TOffset;
begin
  SetLength(Characteristics, 0);

  if (not EndOfStmt(CurrentToken)) then
  begin
    CommentFound := False;
    DeterministicFound := False;
    Found := False;
    LanguageFound := False;
    SQLSecurityFound := False;

    repeat
      Characteristic := 0;
      if (TokenPtr(CurrentToken)^.KeywordIndex = kiCOMMENT) then
      begin
        if (CommentFound) then
          SetError(PE_UnexpectedToken)
        else
          Characteristic := ParseValue(kiCOMMENT, vaNo, ParseString);
        CommentFound := True;
      end
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLANGUAGE) then
      begin
        if (LanguageFound) then
          SetError(PE_UnexpectedToken)
        else
          Characteristic := ParseTag(kiLANGUAGE, kiSQL);
        LanguageFound := True;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiNOT)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiDETERMINISTIC)) then
      begin
        if (DeterministicFound) then
          SetError(PE_UnexpectedToken)
        else
          Characteristic := ParseTag(kiNOT, kiDETERMINISTIC);
        DeterministicFound := True;
      end
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiDETERMINISTIC) then
      begin
        if (DeterministicFound) then
          SetError(PE_UnexpectedToken)
        else
          Characteristic := ParseTag(kiDETERMINISTIC);
        DeterministicFound := True;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCONTAINS)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSQL)) then
      begin
        if (Found) then
          SetError(PE_UnexpectedToken)
        else
          Characteristic := ParseTag(kiCONTAINS, kiSQL);
        Found := True;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiNO)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSQL)) then
      begin
        if (Found) then
          SetError(PE_UnexpectedToken)
        else
          Characteristic := ParseTag(kiNO, kiSQL);
        Found := True;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiREADS)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSQL)
        and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiDATA)) then
      begin
        if (Found) then
          SetError(PE_UnexpectedToken)
        else
          Characteristic := ParseTag(kiREADS, kiSQL, kiDATA);
        Found := True;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiMODIFIES)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSQL)
        and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiDATA)) then
      begin
        if (Found) then
          SetError(PE_UnexpectedToken)
        else
          Characteristic := ParseTag(kiMODIFIES, kiSQL, kiDATA);
        Found := True;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiSQL)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSECURITY)
        and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiDEFINER)) then
      begin
        if (SQLSecurityFound) then
          SetError(PE_UnexpectedToken)
        else
        begin
          Characteristic := ParseTag(kiSQL, kiSECURITY, kiDEFINER);
          SQLSecurityFound := True;
        end;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiSQL)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSECURITY)
        and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiINVOKER)) then
      begin
        if (SQLSecurityFound) then
          SetError(PE_UnexpectedToken)
        else
        begin
          Characteristic := ParseTag(kiSQL, kiSECURITY, kiINVOKER);
          SQLSecurityFound := True;
        end;
      end;

      if (Characteristic > 0) then
      begin
        SetLength(Characteristics, Length(Characteristics) + 1);
        Characteristics[Length(Characteristics) - 1] := Characteristic;
      end;
    until (Error or EndOfStmt(CurrentToken) or (Characteristic = 0));
  end;

  if (Length(Characteristics) = 0) then
    Result := 0
  else
  begin
    FillChar(ListNodes, SizeOf(ListNodes), 0);
    Result := TList.Create(Self, ListNodes, Length(Characteristics), Characteristics);
    SetLength(Characteristics, 0);
  end;
end;

function TMySQLParser.ParseCreateServerStmt(): TOffset;
var
  Nodes: TCreateServerStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CreateTag := ParseTag(kiCREATE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiSERVER) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.ServerTag := ParseTag(kiSERVER);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.ServerIdent := ParseDbIdent(ditServer);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiFOREIGN) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.ForeignDataWrapperValue := ParseValue(WordIndices(kiFOREIGN, kiDATA, kiWRAPPER), vaNo, ParseString);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiOPTIONS) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.Options.Tag := ParseTag(kiOPTIONS);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Options.List := ParseCreateServerStmtOptionList();

  Result := TCreateServerStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateServerStmtOptionList(): TOffset;
var
  Children: array [0 .. 13 - 1] of TOffset;
  ChildrenIndex: Integer;
  DatabaseFound: Boolean;
  DelimiterFound: Boolean;
  HostFound: Boolean;
  ListNodes: TList.TNodes;
  OwnerFound: Boolean;
  PasswordFound: Boolean;
  PortFound: Boolean;
  SocketFound: Boolean;
  UserFound: Boolean;
begin
  FillChar(ListNodes, SizeOf(ListNodes), 0);
  ListNodes.DelimiterType := ttComma;

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
    SetError(PE_UnexpectedToken)
  else
    ListNodes.OpenBracket := ApplyCurrentToken();

  ChildrenIndex := 0;
  if (not Error) then
  begin
    DatabaseFound := False;
    HostFound := False;
    OwnerFound := False;
    PasswordFound := False;
    PortFound := False;
    SocketFound := False;
    UserFound := False;
    repeat
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (not HostFound and (TokenPtr(CurrentToken).KeywordIndex = kiHOST)) then
      begin
        Children[ChildrenIndex] := ParseValue(kiHOST, vaNo, ParseString);
        HostFound := True;
      end
      else if (not DatabaseFound and (TokenPtr(CurrentToken).KeywordIndex = kiDATABASE)) then
      begin
        Children[ChildrenIndex] := ParseValue(kiDATABASE, vaNo, ParseString);
        DatabaseFound := True;
      end
      else if (not UserFound and (TokenPtr(CurrentToken).KeywordIndex = kiUSER)) then
      begin
        Children[ChildrenIndex] := ParseValue(kiUSER, vaNo, ParseString);
        UserFound := True;
      end
      else if (not PasswordFound and (TokenPtr(CurrentToken).KeywordIndex = kiPASSWORD)) then
      begin
        Children[ChildrenIndex] := ParseValue(kiPASSWORD, vaNo, ParseString);
        PasswordFound := True;
      end
      else if (not SocketFound and (TokenPtr(CurrentToken).KeywordIndex = kiSOCKET)) then
      begin
        Children[ChildrenIndex] := ParseValue(kiSOCKET, vaNo, ParseString);
        SocketFound := True;
      end
      else if (not OwnerFound and (TokenPtr(CurrentToken).KeywordIndex = kiOWNER)) then
      begin
        Children[ChildrenIndex] := ParseValue(kiOWNER, vaNo, ParseString);
        OwnerFound := True;
      end
      else if (not PortFound and (TokenPtr(CurrentToken).KeywordIndex = kiPORT)) then
      begin
        Children[ChildrenIndex] := ParseValue(kiPort, vaNo, ParseInteger);
        PortFound := True;
      end
      else
        SetError(PE_UnexpectedToken);

      Inc(ChildrenIndex);

      DelimiterFound := not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttComma);
      if (DelimiterFound) then
      begin
        Children[ChildrenIndex] := ApplyCurrentToken(); // Delimiter
        Inc(ChildrenIndex);
      end;
    until (Error or not DelimiterFound);
  end;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      ListNodes.CloseBracket := ApplyCurrentToken();

  Result := TList.Create(Self, ListNodes, ChildrenIndex, Children);
end;

function TMySQLParser.ParseCreateStmt(): TOffset;
var
  Index: Integer;
begin
  Result := 0;

  Index := 1;
  if (not EndOfStmt(NextToken[Index]) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiOR)) then
  begin
    Inc(Index);
    if (EndOfStmt(NextToken[Index])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex <> kiREPLACE) then
      SetError(PE_UnexpectedToken, NextToken[Index])
    else
      Inc(Index);
  end;

  if (not Error and not EndOfStmt(NextToken[Index]) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiALGORITHM)) then
  begin
    Inc(Index);
    if (EndOfStmt(NextToken[Index])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.OperatorType <> otEqual) then
      SetError(PE_UnexpectedToken, NextToken[Index])
    else
    begin
      Inc(Index);

      if (EndOfStmt(NextToken[Index])) then
        SetError(PE_IncompleteStmt)
      else if ((TokenPtr(NextToken[Index])^.KeywordIndex <> kiUNDEFINED)
        and (TokenPtr(NextToken[Index])^.KeywordIndex <> kiMERGE)
        and (TokenPtr(NextToken[Index])^.KeywordIndex <> kiTEMPTABLE)) then
        SetError(PE_UnexpectedToken, NextToken[Index])
      else
        Inc(Index);
    end;
  end;

  if (not Error and not EndOfStmt(NextToken[Index]) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiDEFINER)) then
  begin
    Inc(Index);
    if (EndOfStmt(NextToken[Index])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.OperatorType <> otEqual) then
      SetError(PE_UnexpectedToken, NextToken[Index])
    else
    begin
      Inc(Index);

      if (EndOfStmt(NextToken[Index])) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiCURRENT_USER) then
        if (((NextToken[Index + 1] = 0) or (TokenPtr(NextToken[Index + 1])^.TokenType <> ttOpenBracket))
          and ((NextToken[Index + 2] = 0) or (TokenPtr(NextToken[Index + 2])^.TokenType <> ttCloseBracket))) then
          Inc(Index)
        else
          Inc(Index, 3)
      else
      begin
        Inc(Index); // Username

        if (not Error and not EndOfStmt(NextToken[Index]) and (TokenPtr(NextToken[Index])^.TokenType = ttAt)) then
        begin
          Inc(Index); // @
          if (not Error and not EndOfStmt(NextToken[Index])) then
            Inc(Index); // Servername
        end;
      end;
    end;
  end;

  if (not Error and not EndOfStmt(NextToken[Index])
    and ((TokenPtr(NextToken[Index])^.KeywordIndex = kiUNIQUE) or (TokenPtr(NextToken[Index])^.KeywordIndex = kiFULLTEXT) or (TokenPtr(NextToken[Index])^.KeywordIndex = kiSPATIAL))) then
    Inc(Index);

  if (not Error and not EndOfStmt(NextToken[Index]) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiSQL)) then
  begin
    Inc(Index);
    if (EndOfStmt(NextToken[Index])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex <> kiSECURITY) then
      SetError(PE_UnexpectedToken, NextToken[Index])
    else
    begin
      Inc(Index);
      if (EndOfStmt(NextToken[Index])) then
        SetError(PE_IncompleteStmt)
      else if ((TokenPtr(NextToken[Index])^.KeywordIndex <> kiDEFINER)
        and (TokenPtr(NextToken[Index])^.KeywordIndex <> kiINVOKER)) then
        SetError(PE_UnexpectedToken, NextToken[Index])
      else
        Inc(Index);
    end;
  end;

  if (not Error and not EndOfStmt(NextToken[Index]) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiTEMPORARY)) then
    Inc(Index);

  if (not Error) then
    if (EndOfStmt(NextToken[Index])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiDATABASE) then
      Result := ParseCreateDatabaseStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiEVENT) then
      Result := ParseCreateEventStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiFUNCTION) then
      Result := ParseCreateRoutineStmt(rtFunction)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiINDEX) then
      Result := ParseCreateIndexStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiPROCEDURE) then
      Result := ParseCreateRoutineStmt(rtProcedure)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiSCHEMA) then
      Result := ParseCreateDatabaseStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiSERVER) then
      Result := ParseCreateServerStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiTABLE) then
      Result := ParseCreateTableStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiTRIGGER) then
      Result := ParseCreateTriggerStmt()
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiUSER) then
      Result := ParseCreateUserStmt(False)
    else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiVIEW) then
      Result := ParseCreateViewStmt()
    else
    begin
      SetError(PE_UnexpectedToken, NextToken[Index]);
      Result := ParseUnknownStmt();
    end;
end;

function TMySQLParser.ParseCreateTableStmt(): TOffset;
var
  Found: Boolean;
  Index: Integer;
  ListNodes: TList.TNodes;
  Nodes: TCreateTableStmt.TNodes;
  PartitionType: (ptUnknown, ptHash, ptKey, ptRANGE, ptList);
  TableOptions: Classes.TList;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CreateTag := ParseTag(kiCREATE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiTEMPORARY)) then
    Nodes.TemporaryTag := ParseTag(kiTEMPORARY);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiTABLE) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.TableTag := ParseTag(kiTABLE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    Nodes.IfNotExistsTag := ParseTag(kiIF, kiNOT, kiEXISTS);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.TableIdent := ParseTableIdent();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)
      and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiLIKE)) then
    begin
      Nodes.OpenBracketToken := ApplyCurrentToken();

      Nodes.LikeTag := ParseTag(kiLIKE);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.LikeTableIdent := ParseTableIdent();

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.CloseBracketToken := ApplyCurrentToken();
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
    begin
      Nodes.LikeTag := ParseTag(kiLIKE);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.LikeTableIdent := ParseTableIdent();
    end
    else
    begin
      if (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket) then
        Nodes.DefinitionList := ParseList(True, ParseCreateTableStmtDefinition);

      if (not Error and not EndOfStmt(CurrentToken)) then
      begin
        TableOptions := Classes.TList.Create();

        Found := True;
        while (not Error and Found and not EndOfStmt(CurrentToken)) do
        begin
          if ((Nodes.TableOptionsNodes.AutoIncrementValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAUTO_INCREMENT)) then
          begin
            Nodes.TableOptionsNodes.AutoIncrementValue := ParseValue(kiAUTO_INCREMENT, vaAuto, ParseInteger);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.AutoIncrementValue));
          end
          else if ((Nodes.TableOptionsNodes.AvgRowLengthValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAVG_ROW_LENGTH)) then
          begin
            Nodes.TableOptionsNodes.AvgRowLengthValue := ParseValue(kiAVG_ROW_LENGTH, vaAuto, ParseInteger);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.AvgRowLengthValue));
          end
          else if ((Nodes.TableOptionsNodes.CharacterSetValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARACTER)) then
          begin
            Nodes.TableOptionsNodes.CharacterSetValue := ParseValue(WordIndices(kiCHARACTER, kiSET), vaAuto, ParseIdent);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.CharacterSetValue));
          end
          else if ((Nodes.TableOptionsNodes.CharacterSetValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARSET)) then
          begin
            Nodes.TableOptionsNodes.CharacterSetValue := ParseValue(kiCHARSET, vaAuto, ParseIdent);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.CharacterSetValue));
          end
          else if ((Nodes.TableOptionsNodes.ChecksumValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHECKSUM)) then
          begin
            Nodes.TableOptionsNodes.AutoIncrementValue := ParseValue(kiCHECKSUM, vaAuto, ParseInteger);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.AutoIncrementValue));
          end
          else if ((Nodes.TableOptionsNodes.CollateValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLLATE)) then
          begin
            Nodes.TableOptionsNodes.CollateValue := ParseValue(WordIndices(kiCOLLATE), vaAuto, ParseIdent);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.CollateValue));
          end
          else if ((Nodes.TableOptionsNodes.CharacterSetValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCHARSET)) then
          begin
            Nodes.TableOptionsNodes.CharacterSetValue := ParseValue(WordIndices(kiDEFAULT, kiCHARSET), vaAuto, ParseIdent);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.CharacterSetValue));
          end
          else if ((Nodes.TableOptionsNodes.CharacterSetValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT) and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCHARACTER) and (TokenPtr(NextToken[2])^.KeywordIndex = kiSET)) then
          begin
            Nodes.TableOptionsNodes.CharacterSetValue := ParseValue(WordIndices(kiDEFAULT, kiCHARACTER, kiSET), vaAuto, ParseIdent);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.CharacterSetValue));
          end
          else if ((Nodes.TableOptionsNodes.CollateValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCOLLATE)) then
          begin
            Nodes.TableOptionsNodes.CollateValue := ParseValue(WordIndices(kiDEFAULT, kiCOLLATE), vaAuto, ParseIdent);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.CollateValue));
          end
          else if ((Nodes.TableOptionsNodes.CommentValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOMMENT)) then
          begin
            Nodes.TableOptionsNodes.CommentValue := ParseValue(kiCOMMENT, vaAuto, ParseString);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.CommentValue));
          end
          else if ((Nodes.TableOptionsNodes.ConnectionValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCONNECTION)) then
          begin
            Nodes.TableOptionsNodes.ConnectionValue := ParseValue(kiCONNECTION, vaAuto, ParseString);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.ConnectionValue));
          end
          else if ((Nodes.TableOptionsNodes.DataDirectoryValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDATA)) then
          begin
            Nodes.TableOptionsNodes.DataDirectoryValue := ParseValue(WordIndices(kiDATA, kiDIRECTORY), vaAuto, ParseString);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.DataDirectoryValue));
          end
          else if ((Nodes.TableOptionsNodes.DelayKeyWriteValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDELAY_KEY_WRITE)) then
          begin
            Nodes.TableOptionsNodes.DelayKeyWriteValue := ParseValue(kiDELAY_KEY_WRITE, vaAuto, ParseInteger);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.DelayKeyWriteValue));
          end
          else if ((Nodes.TableOptionsNodes.EngineValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiENGINE)) then
          begin
            Nodes.TableOptionsNodes.EngineValue := ParseValue(kiENGINE, vaAuto, ParseIdent);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.EngineValue));
          end
          else if ((Nodes.TableOptionsNodes.IndexDirectoryValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiINDEX)) then
          begin
            Nodes.TableOptionsNodes.IndexDirectoryValue := ParseValue(WordIndices(kiINDEX, kiDIRECTORY), vaAuto, ParseString);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.IndexDirectoryValue));
          end
          else if ((Nodes.TableOptionsNodes.InsertMethodValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiINSERT_METHOD)) then
          begin
            Nodes.TableOptionsNodes.InsertMethodValue := ParseValue(kiINSERT_METHOD, vaAuto, WordIndices(kiNO, kiFIRST, kiLAST));
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.InsertMethodValue));
          end
          else if ((Nodes.TableOptionsNodes.KeyBlockSizeValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiKEY_BLOCK_SIZE)) then
          begin
            Nodes.TableOptionsNodes.KeyBlockSizeValue := ParseValue(kiKEY_BLOCK_SIZE, vaAuto, ParseInteger);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.KeyBlockSizeValue));
          end
          else if ((Nodes.TableOptionsNodes.MaxRowsValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_ROWS)) then
          begin
            Nodes.TableOptionsNodes.MaxRowsValue := ParseValue(kiMAX_ROWS, vaAuto, ParseInteger);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.MaxRowsValue));
          end
          else if ((Nodes.TableOptionsNodes.MinRowsValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiMIN_ROWS)) then
          begin
            Nodes.TableOptionsNodes.MinRowsValue := ParseValue(kiMIN_ROWS, vaAuto, ParseInteger);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.MinRowsValue));
          end
          else if ((Nodes.TableOptionsNodes.PackKeysValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPACK_KEYS)) then
          begin
            Nodes.TableOptionsNodes.PackKeysValue := ParseValue(kiPACK_KEYS, vaAuto, ParseExpr);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.PackKeysValue));
          end
          else if ((Nodes.TableOptionsNodes.PageChecksum = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPAGE_CHECKSUM)) then
          begin
            Nodes.TableOptionsNodes.PageChecksum := ParseValue(kiPAGE_CHECKSUM, vaAuto, ParseInteger);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.PageChecksum));
          end
          else if ((Nodes.TableOptionsNodes.PasswordValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPASSWORD)) then
          begin
            Nodes.TableOptionsNodes.PasswordValue := ParseValue(kiPASSWORD, vaAuto, ParseString);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.PasswordValue));
          end
          else if ((Nodes.TableOptionsNodes.RowFormatValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiROW_FORMAT)) then
          begin
            Nodes.TableOptionsNodes.RowFormatValue := ParseValue(kiROW_FORMAT, vaAuto, WordIndices(kiDEFAULT, kiDYNAMIC, kiFIXED, kiCOMPRESSED, kiREDUNDANT, kiCOMPACT));
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.RowFormatValue));
          end
          else if ((Nodes.TableOptionsNodes.StatsAutoRecalcValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSTATS_AUTO_RECALC)) then
          begin
            if (EndOfStmt(NextToken[2]) or (TokenPtr(NextToken[1])^.OperatorType <> otEqual)) then
              Index := 1
            else
              Index := 2;
            if (EndOfStmt(NextToken[Index])) then
              SetError(PE_IncompleteStmt)
            else if (TokenPtr(NextToken[Index])^.TokenType = ttInteger) then
              Nodes.TableOptionsNodes.StatsAutoRecalcValue := ParseValue(kiSTATS_AUTO_RECALC, vaAuto, ParseInteger)
            else
              Nodes.TableOptionsNodes.StatsAutoRecalcValue := ParseValue(kiSTATS_AUTO_RECALC, vaAuto, WordIndices(kiDEFAULT));
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.StatsAutoRecalcValue));
          end
          else if ((Nodes.TableOptionsNodes.StatsPersistentValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSTATS_PERSISTENT)) then
          begin
            if (EndOfStmt(NextToken[2]) or (TokenPtr(NextToken[1])^.OperatorType <> otEqual)) then
              Index := 1
            else
              Index := 2;
            if (EndOfStmt(NextToken[Index])) then
              SetError(PE_IncompleteStmt)
            else if (TokenPtr(NextToken[Index])^.TokenType = ttInteger) then
              Nodes.TableOptionsNodes.StatsPersistentValue := ParseValue(kiSTATS_PERSISTENT, vaAuto, ParseInteger)
            else
              Nodes.TableOptionsNodes.StatsPersistentValue := ParseValue(kiSTATS_PERSISTENT, vaAuto, WordIndices(kiDEFAULT));
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.StatsPersistentValue));
          end
          else if ((Nodes.TableOptionsNodes.EngineValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiTYPE)) then
          begin
            Nodes.TableOptionsNodes.EngineValue := ParseValue(kiTYPE, vaAuto, ParseIdent);
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.EngineValue));
          end
          else if ((Nodes.TableOptionsNodes.UnionList = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUNION)) then
          begin
            Nodes.TableOptionsNodes.UnionList := ParseAlterTableStmtUnion();
            TableOptions.Add(Pointer(Nodes.TableOptionsNodes.UnionList));
          end
          else
            Found := False;

          if (Found and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttComma)) then
            TableOptions.Add(Pointer(ApplyCurrentToken()));
        end;

        FillChar(ListNodes, SizeOf(ListNodes), 0);
        Nodes.TableOptionList := TList.Create(Self, ListNodes, TableOptions.Count, TIntegerArray(TableOptions.List));

        TableOptions.Free();
      end;

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPARTITION)) then
      begin
        Nodes.PartitionOption.PartitionByTag := ParseTag(kiPARTITION, kiBY);

        PartitionType := ptUnknown;
        if (not Error) then
          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else if (TokenPtr(CurrentToken)^.KeywordIndex = kiHASH) then
          begin
            Nodes.PartitionOption.PartitionKindTag := ParseTag(kiHASH);
            PartitionType := ptHash;
          end
          else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiLINEAR) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiHASH)) then
          begin
            Nodes.PartitionOption.PartitionKindTag := ParseTag(kiLINEAR, kiHASH);
            PartitionType := ptHash;
          end
          else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiLINEAR) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiKEY)) then
          begin
            Nodes.PartitionOption.PartitionKindTag := ParseTag(kiLINEAR, kiKEY);
            PartitionType := ptKey;
          end
          else if (TokenPtr(CurrentToken)^.KeywordIndex = kiKEY) then
          begin
            Nodes.PartitionOption.PartitionKindTag := ParseTag(kiKEY);
            PartitionType := ptKEY;
          end
          else if (TokenPtr(CurrentToken)^.KeywordIndex = kiRANGE) then
          begin
            Nodes.PartitionOption.PartitionKindTag := ParseTag(kiRANGE);
            PartitionType := ptRange;
          end
          else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIST) then
          begin
            Nodes.PartitionOption.PartitionKindTag := ParseTag(kiLIST);
            PartitionType := ptList;
          end
          else
            SetError(PE_UnexpectedToken);

        if (not Error) then
          if (PartitionType = ptHash) then
          begin
            if (EndOfStmt(CurrentToken)) then
              SetError(PE_IncompleteStmt)
            else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
              SetError(PE_UnexpectedToken)
            else
              Nodes.PartitionOption.PartitionExpr := ParseSubArea(ParseExpr);
          end
          else if (PartitionType = ptKey) then
          begin
            if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiALGORITHM)) then
              Nodes.PartitionOption.PartitionAlgorithmValue := ParseValue(kiALGORITHM, vaAuto, ParseInteger);

            if (not Error) then
              Nodes.PartitionOption.PartitionColumnList := ParseList(True, ParseColumnIdent);
          end
          else if (PartitionType in [ptRange, ptList]) then
          begin
            if (EndOfStmt(CurrentToken)) then
              SetError(PE_IncompleteStmt)
            else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiCOLUMNS) then
              if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
                SetError(PE_UnexpectedToken)
              else
                Nodes.PartitionOption.PartitionExpr := ParseSubArea(ParseExpr)
            else
            begin
              Nodes.PartitionOption.PartitionColumnsTag := ParseTag(kiCOLUMNS);

              if (not Error) then
                if (EndOfStmt(CurrentToken)) then
                  SetError(PE_IncompleteStmt)
                else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
                  SetError(PE_UnexpectedToken)
                else
                  Nodes.PartitionOption.PartitionColumnList := ParseList(True, ParseColumnIdent);
            end;
          end;

        if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPARTITIONS)) then
          Nodes.PartitionOption.PartitionsValue := ParseValue(kiPARTITIONS, vaNo, ParseInteger);

        if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSUBPARTITION)) then
        begin
          Nodes.PartitionOption.SubPartitionByTag := ParseTag(kiSUBPARTITION, kiBY);

          if (not Error) then
            if (EndOfStmt(CurrentToken)) then
              SetError(PE_IncompleteStmt)
            else if (TokenPtr(CurrentToken)^.KeywordIndex = kiHASH) then
              Nodes.PartitionOption.SubPartitionKindTag := ParseTag(kiHASH)
            else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiLINEAR) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiHASH)) then
              Nodes.PartitionOption.SubPartitionKindTag := ParseTag(kiLINEAR, kiHASH)
            else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiLINEAR) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiKEY)) then
              Nodes.PartitionOption.SubPartitionKindTag := ParseTag(kiLINEAR, kiKEY)
            else if (TokenPtr(CurrentToken)^.KeywordIndex = kiKEY) then
              Nodes.PartitionOption.SubPartitionKindTag := ParseTag(kiKEY)
            else
              SetError(PE_UnexpectedToken);

          if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiALGORITHM)) then
            Nodes.PartitionOption.SubPartitionAlgorithmValue := ParseValue(kiALGORITHM, vaAuto, ParseInteger);

          if (not Error) then
            Nodes.PartitionOption.SubPartitionExprList := ParseList(True, ParseExpr);

          if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSUBPARTITIONS)) then
            Nodes.PartitionOption.SubPartitionsValue := ParseValue(kiSUBPARTITIONS, vaNo, ParseInteger);
        end;
      end;

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
        Nodes.PartitionDefinitionList := ParseList(True, ParseCreateTableStmtPartition);

      if (not Error and not EndOfStmt(CurrentToken)) then
        if (TokenPtr(CurrentToken)^.KeywordIndex = kiIGNORE) then
          Nodes.IgnoreReplaceTag := ParseTag(kiIGNORE)
        else if (TokenPtr(CurrentToken)^.KeywordIndex = kiREPLACE) then
          Nodes.IgnoreReplaceTag := ParseTag(kiREPLACE);

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAS)) then
        Nodes.AsTag := ParseTag(kiAS);

      if (not Error) then
        if (EndOfStmt(CurrentToken) and (Nodes.AsTag > 0)) then
          SetError(PE_IncompleteStmt)
        else if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSELECT)) then
          Nodes.SelectStmt := ParseSelectStmt();
    end;

  Result := TCreateTableStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateTableStmtColumn(const Add: TCreateTableStmt.TColumnAdd = caNone): TOffset;
var
  Nodes: TCreateTableStmt.TColumn.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (Add = caAdd) then
      Nodes.AddTag := ParseTag(kiADD)
    else if (Add = caChange) then
      Nodes.AddTag := ParseTag(kiCHANGE)
    else if (Add = caModify) then
      Nodes.AddTag := ParseTag(kiMODIFY);

  if (not Error and (Add <> caNone) and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLUMN)) then
    Nodes.ColumnTag := ParseTag(kiCOLUMN);

  if (not Error and (Add in [caChange, caModify])) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OldNameIdent := ParseColumnIdent();

  if (not Error and (Add in [caNone, caAdd, caChange])) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.NameIdent := ParseColumnIdent();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.DataTypeNode := ParseDataType();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiBINARY)) then
    Nodes.BinaryTag := ParseTag(kiBINARY);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiNOT) then
      Nodes.Null := ParseTag(kiNOT, kiNULL)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiNULL) then
      Nodes.Null := ParseTag(kiNULL);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT)) then
    if (not EndOfStmt(NextToken[1]) and ((TokenPtr(NextToken[1])^.KeywordIndex = kiCURRENT_TIMESTAMP) or (TokenPtr(NextToken[1])^.KeywordIndex = kiLOCALTIME) or (TokenPtr(NextToken[1])^.KeywordIndex = kiLOCALTIMESTAMP))
      and (EndOfStmt(NextToken[2]) or (TokenPtr(NextToken[2])^.TokenType = ttOpenBracket))) then
      Nodes.DefaultValue := ParseValue(kiDEFAULT, vaNo, ParseCurrentTimestamp)
    else
      Nodes.DefaultValue := ParseValue(kiDEFAULT, vaNo, ParseString);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiNOT) then
      Nodes.Null := ParseTag(kiNOT, kiNULL)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiNULL) then
      Nodes.Null := ParseTag(kiNULL);

  if (not Error and not EndOfStmt(NextToken[1])
    and (TokenPtr(CurrentToken)^.KeywordIndex = kiON) and (TokenPtr(NextToken[1])^.KeywordIndex = kiUPDATE)
    and (not EndOfStmt(NextToken[2]) and ((TokenPtr(NextToken[2])^.KeywordIndex = kiCURRENT_TIMESTAMP) or (TokenPtr(NextToken[2])^.KeywordIndex = kiCURRENT_TIME) or (TokenPtr(NextToken[2])^.KeywordIndex = kiCURRENT_DATE)))) then
    if (EndOfStmt(NextToken[3]) or (TokenPtr(NextToken[3])^.TokenType <> ttOpenBracket)) then
      Nodes.OnUpdateTag := ParseTag(kiON, kiUPDATE, TokenPtr(NextToken[2])^.KeywordIndex)
    else
      Nodes.OnUpdateTag := ParseValue(WordIndices(kiON, kiUPDATE), vaNo, ParseFunctionCall);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAUTO_INCREMENT)) then
    Nodes.AutoIncrementTag := ParseTag(kiAUTO_INCREMENT);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if ((TokenPtr(CurrentToken)^.KeywordIndex = kiUNIQUE) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiKEY)) then
      Nodes.KeyTag := ParseTag(kiUNIQUE, kiKEY)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUNIQUE)  then
      Nodes.KeyTag := ParseTag(kiUNIQUE)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiPRIMARY) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiKEY)) then
      Nodes.KeyTag := ParseTag(kiPRIMARY, kiKEY)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiKEY)  then
      Nodes.KeyTag := ParseTag(kiKEY);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAUTO_INCREMENT)) then
    Nodes.AutoIncrementTag := ParseTag(kiAUTO_INCREMENT);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOMMENT)) then
    Nodes.CommentValue := ParseValue(kiCOMMENT, vaNo, ParseString);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLUMN_FORMAT)) then
    Nodes.ColumnFormat := ParseValue(kiCOLUMN_FORMAT, vaNo, WordIndices(kiFIXED, kiDYNAMIC, kiDEFAULT));

  if (not Error and (Add <> caNone) and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiFIRST) then
      Nodes.Position := ParseTag(kiFIRST)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiAFTER) then
      Nodes.Position := ParseValue(kiAFTER, vaNo, ParseColumnIdent);

  Result := TCreateTableStmt.TColumn.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateTableStmtDefinition(): TOffset;
begin
  Result := ParseCreateTableStmtDefinition(False);
end;

function TMySQLParser.ParseCreateTableStmtDefinition(const AlterTableStmt: Boolean): TOffset;
var
  Index: Integer;
  SpecificationType: (stUnknown, stColumn, stKey, stForeignKey, stPartition);
begin
  if (not AlterTableStmt) then
    Index := 0
  else
    Index := 1; // "ADD"

  Result := 0;
  SpecificationType := stUnknown;

  if (EndOfStmt(NextToken[Index])) then
    SetError(PE_IncompleteStmt)
  else if ((TokenPtr(NextToken[Index])^.KeywordIndex = kiKEY)
    or (TokenPtr(NextToken[Index])^.KeywordIndex = kiFULLTEXT)
    or (TokenPtr(NextToken[Index])^.KeywordIndex = kiINDEX)
    or (TokenPtr(NextToken[Index])^.KeywordIndex = kiPRIMARY)
    or (TokenPtr(NextToken[Index])^.KeywordIndex = kiUNIQUE)
    or (TokenPtr(NextToken[Index])^.KeywordIndex = kiSPATIAL)) then
    SpecificationType := stKey
  else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiFOREIGN) then
    SpecificationType := stForeignKey
  else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiCONSTRAINT) then
  begin
    if (not EndOfStmt(NextToken[Index + 1])
      and (TokenPtr(NextToken[Index + 1])^.KeywordIndex <> kiPRIMARY)
      and (TokenPtr(NextToken[Index + 1])^.KeywordIndex <> kiUNIQUE)) then
      Inc(Index); // Symbol identifier
    if (EndOfStmt(NextToken[Index + 1])) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(NextToken[Index + 1])^.KeywordIndex = kiPRIMARY) or (TokenPtr(NextToken[Index + 1])^.KeywordIndex = kiUNIQUE)) then
      SpecificationType := stKey
    else if (TokenPtr(NextToken[Index + 1])^.KeywordIndex = kiFOREIGN) then
      SpecificationType := stForeignKey
    else
      SetError(PE_UnexpectedToken);
  end
  else if (TokenPtr(NextToken[Index])^.KeywordIndex = kiPARTITION) then
    SpecificationType := stPartition
  else
    SpecificationType := stColumn;

  if (not Error) then
    case (SpecificationType) of
      stColumn:
        if (not AlterTableStmt) then
          Result := ParseCreateTableStmtColumn(caNone)
        else
          Result := ParseCreateTableStmtColumn(caAdd);
      stKey: Result := ParseCreateTableStmtKey(AlterTableStmt);
      stForeignKey: Result := ParseCreateTableStmtForeignKey(AlterTableStmt);
      stPartition: Result := ParseCreateTableStmtPartition(AlterTableStmt);
    end;
end;

function TMySQLParser.ParseCreateTableStmtForeignKey(const Add: Boolean = False): TOffset;
var
  Nodes: TCreateTableStmt.TForeignKey.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (Add) then
    Nodes.AddTag := ParseTag(kiADD);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCONSTRAINT)) then
  begin
    Nodes.ConstraintTag := ParseTag(kiCONSTRAINT);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiPRIMARY) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiUNIQUE)) then
      Nodes.SymbolIdent := ParseForeignKeyIdent();
  end;

  if (not Error) then
    Nodes.ForeignKeyTag := ParseTag(kiFOREIGN, kiKEY);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket)) then
    Nodes.NameIdent := ParseDbIdent(ditForeignKey);

  if (not Error) then
    Nodes.ColumnNameList := ParseList(True, ParseCreateTableStmtKeyColumn);

  if (not Error) then
    Nodes.ReferencesTag := ParseTag(kiREFERENCES);

  if (not Error) then
    Nodes.ParentTableIdent := ParseTableIdent();

  if (not Error) then
    Nodes.IndicesList := ParseList(True, ParseCreateTableStmtKeyColumn);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiMATCH)) then
    if (not EndOfStmt(NextToken[1]) and ((TokenPtr(NextToken[1])^.KeywordIndex = kiFULL) or (TokenPtr(NextToken[1])^.KeywordIndex = kiPARTIAL) or (TokenPtr(NextToken[1])^.KeywordIndex = kiSIMPLE))) then
      Nodes.MatchValue := ParseValue(kiMATCH, vaNo, WordIndices(kiFULL, kiPARTIAL, kiSIMPLE));

  if (not Error and not EndOfStmt(CurrentToken)
    and (TokenPtr(CurrentToken)^.KeywordIndex = kiON) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiDELETE)) then
    if (EndOfStmt(NextToken[2])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[2])^.KeywordIndex = kiRESTRICT) then
      Nodes.OnDeleteValue := ParseValue(WordIndices(kiON, kiDELETE), vaNo, kiRESTRICT)
    else if (TokenPtr(NextToken[2])^.KeywordIndex = kiCASCADE) then
      Nodes.OnDeleteValue := ParseValue(WordIndices(kiON, kiDELETE), vaNo, kiCASCADE)
    else if (TokenPtr(NextToken[2])^.KeywordIndex = kiSET) then
      Nodes.OnDeleteValue := ParseValue(WordIndices(kiON, kiDELETE), vaNo, kiSET, kiNULL)
    else if (TokenPtr(NextToken[2])^.KeywordIndex = kiNO) then
      Nodes.OnDeleteValue := ParseValue(WordIndices(kiON, kiDELETE), vaNo, kiNO, kiACTION)
    else
      SetError(PE_UnexpectedToken);

  if (not Error and not EndOfStmt(CurrentToken)
    and (TokenPtr(CurrentToken)^.KeywordIndex = kiON) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiUPDATE)) then
    if (EndOfStmt(NextToken[2])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[2])^.KeywordIndex = kiRESTRICT) then
      Nodes.OnUpdateValue := ParseValue(WordIndices(kiON, kiUPDATE), vaNo, kiRESTRICT)
    else if (TokenPtr(NextToken[2])^.KeywordIndex = kiCASCADE) then
      Nodes.OnUpdateValue := ParseValue(WordIndices(kiON, kiUPDATE), vaNo, kiCASCADE)
    else if (TokenPtr(NextToken[2])^.KeywordIndex = kiSET) then
      Nodes.OnUpdateValue := ParseValue(WordIndices(kiON, kiUPDATE), vaNo, kiSET, kiNULL)
    else if (TokenPtr(NextToken[2])^.KeywordIndex = kiNO) then
      Nodes.OnUpdateValue := ParseValue(WordIndices(kiON, kiUPDATE), vaNo, kiNO, kiACTION)
    else
      SetError(PE_UnexpectedToken);

  Result := TCreateTableStmt.TForeignKey.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateTableStmtKey(const AlterTableStmt: Boolean): TOffset;
var
  Found: Boolean;
  KeyName: Boolean;
  KeyType: Boolean;
  Nodes: TCreateTableStmt.TKey.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (AlterTableStmt) then
    Nodes.AddTag := ParseTag(kiADD);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCONSTRAINT)) then
  begin
    Nodes.ConstraintTag := ParseTag(kiCONSTRAINT);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiPRIMARY) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiUNIQUE)) then
      Nodes.SymbolIdent := ParseString();
  end;

  KeyName := True; KeyType := False;
  if (not Error) then
    if (EndOfStmt(NextToken[1])) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiPRIMARY) and (TokenPtr(NextToken[1])^.KeywordIndex = kiKEY)) then
      begin Nodes.KeyTag := ParseTag(kiPRIMARY, kiKEY); KeyName := False; KeyType := True; end
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiINDEX)) then
      begin Nodes.KeyTag := ParseTag(kiINDEX); KeyType := True; end
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiKEY)) then
      begin Nodes.KeyTag := ParseTag(kiKEY); KeyType := True; end
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiUNIQUE) and (TokenPtr(NextToken[1])^.KeywordIndex = kiINDEX)) then
      begin Nodes.KeyTag := ParseTag(kiUNIQUE, kiINDEX); KeyType := True; end
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiUNIQUE) and (TokenPtr(NextToken[1])^.KeywordIndex = kiKEY)) then
      begin Nodes.KeyTag := ParseTag(kiUNIQUE, kiKEY); KeyType := True; end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUNIQUE) then
      begin Nodes.KeyTag := ParseTag(kiUNIQUE); KeyType := True; end
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiFULLTEXT) and (TokenPtr(NextToken[1])^.KeywordIndex = kiINDEX)) then
      Nodes.KeyTag := ParseTag(kiFULLTEXT, kiINDEX)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiFULLTEXT) and (TokenPtr(NextToken[1])^.KeywordIndex = kiKEY)) then
      Nodes.KeyTag := ParseTag(kiFULLTEXT, kiKEY)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiSPATIAL) and (TokenPtr(NextToken[1])^.KeywordIndex = kiINDEX)) then
      Nodes.KeyTag := ParseTag(kiSPATIAL, kiINDEX)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiSPATIAL) and (TokenPtr(NextToken[1])^.KeywordIndex = kiKEY)) then
      Nodes.KeyTag := ParseTag(kiSPATIAL, kiKEY)
    else
      SetError(PE_UnexpectedToken);

  if (not Error and KeyName) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex <> kiUSING) and (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket)) then
      Nodes.KeyIdent := ParseDbIdent(ditKey);

  if (not Error and KeyType and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUSING)) then
    if (EndOfStmt(NextToken[1])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[1])^.KeywordIndex = kiBTREE) then
      Nodes.IndexTypeTag := ParseValue(kiUSING, vaNo, WordIndices(kiBTREE, kiBTREE))
    else if (TokenPtr(NextToken[1])^.KeywordIndex = kiHASH) then
      Nodes.IndexTypeTag := ParseValue(kiUSING, vaNo, WordIndices(kiBTREE, kiHASH))
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ColumnIdentList := ParseList(True, ParseCreateTableStmtKeyColumn);

  Found := True;
  while (not Error and Found and not EndOfStmt(CurrentToken)) do
    if ((Nodes.CommentValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOMMENT)) then
      Nodes.CommentValue := ParseValue(kiCOMMENT, vaNo, ParseString)
    else if ((Nodes.KeyBlockSizeValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiKEY_BLOCK_SIZE)) then
      Nodes.KeyBlockSizeValue := ParseValue(kiKEY_BLOCK_SIZE, vaAuto, ParseInteger)
    else if ((Nodes.IndexTypeTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUSING)) then
      Nodes.IndexTypeTag := ParseValue(kiUSING, vaNo, WordIndices(kiBTREE, kiHASH))
    else if ((Nodes.ParserValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWITH)) then
      Nodes.ParserValue := ParseValue(WordIndices(kiWITH, kiPARSER), vaNo, ParseString)
    else
      Found := False;

  Result := TCreateTableStmt.TKey.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateTableStmtKeyColumn(): TOffset;
var
  Nodes: TCreateTableStmt.TKeyColumn.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IdentTag := ParseDbIdent(ditColumn);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
  begin
    Nodes.OpenBracketToken := ApplyCurrentToken();

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.TokenType <> ttInteger) then
        SetError(PE_UnexpectedToken)
      else
        Nodes.LengthToken := ParseInteger();

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
        SetError(PE_UnexpectedToken)
      else
        Nodes.CloseBracketToken := ApplyCurrentToken();
  end;

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiASC) then
      Nodes.SortTag := ParseTag(kiASC)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiDESC) then
      Nodes.SortTag := ParseTag(kiDESC);

  Result := TCreateTableStmt.TKeyColumn.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateTableStmtPartition(): TOffset;
begin
  Result := ParseCreateTableStmtPartition(False);
end;

function TMySQLParser.ParseCreateTableStmtPartition(const Add: Boolean): TOffset;
var
  Found: Boolean;
  Nodes: TCreateTableStmt.TPartition.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (Add) then
    Nodes.AddTag := ParseTag(kiADD);

  if (not Error) then
    Nodes.PartitionTag := ParseTag(kiPARTITION);

  if (not Error) then
    Nodes.NameIdent := ParseCreateTableStmtPartitionIdent();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiVALUES)) then
    Nodes.ValuesNode := ParseCreateTableStmtDefinitionPartitionValues();

  Found := True;
  while (not Error and Found and not EndOfStmt(CurrentToken)) do
    if ((Nodes.CommentValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOMMENT)) then
      Nodes.CommentValue := ParseValue(kiCOMMENT, vaAuto, ParseString)
    else if ((Nodes.DataDirectoryValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDATA)) then
      Nodes.DataDirectoryValue := ParseValue(WordIndices(kiDATA, kiDIRECTORY), vaAuto, ParseString)
    else if ((Nodes.EngineValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiENGINE)) then
      Nodes.EngineValue := ParseValue(kiENGINE, vaAuto, ParseIdent)
    else if ((Nodes.IndexDirectoryValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiINDEX)) then
      Nodes.IndexDirectoryValue := ParseValue(WordIndices(kiINDEX, kiDIRECTORY), vaAuto, ParseString)
    else if ((Nodes.MaxRowsValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_ROWS)) then
      Nodes.MaxRowsValue := ParseValue(kiMAX_ROWS, vaAuto, ParseInteger)
    else if ((Nodes.MinRowsValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiMIN_ROWS)) then
      Nodes.MinRowsValue := ParseValue(kiMIN_ROWS, vaAuto, ParseInteger)
    else if ((Nodes.EngineValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSTORAGE)) then
      Nodes.EngineValue := ParseValue(WordIndices(kiSTORAGE, kiENGINE), vaAuto, ParseIdent)
    else if ((Nodes.SubPartitionList = 0) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
      Nodes.SubPartitionList := ParseList(True, ParseSubPartition)
    else
      Found := False;

  Result := TCreateTableStmt.TPartition.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateTableStmtPartitionIdent(): TOffset;
begin
  Result := ParseDbIdent(ditPartition);
end;

function TMySQLParser.ParseCreateTableStmtDefinitionPartitionNames(): TOffset;
begin
  if (EndOfStmt(CurrentToken)) then
  begin
    SetError(PE_IncompleteStmt);
    Result := 0;
  end
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiALL) then
    Result := ParseTag(kiALL)
  else
    Result := ParseList(False, ParseCreateTableStmtPartitionIdent);
end;

function TMySQLParser.ParseCreateTableStmtDefinitionPartitionValues(): TOffset;
var
  Nodes: TCreateTableStmt.TPartitionValues.TNodes;
  ValueNodes: TValue.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.ValuesTag := ParseTag(kiVALUES);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLESS) then
    if (EndOfStmt(NextToken[1])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[1])^.KeywordIndex <> kiTHAN) then
      SetError(PE_UnexpectedToken, NextToken[1])
    else if (EndOfStmt(NextToken[2])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[2])^.TokenType = ttOpenBracket) then
    begin
      FillChar(ValueNodes, SizeOf(ValueNodes), 0);
      ValueNodes.IdentTag := ParseTag(kiLESS, kiTHAN);
      ValueNodes.ValueToken := ParseList(True, ParseExpr);
      Nodes.DescriptionValue := TValue.Create(Self, ValueNodes);
    end
    else
      Nodes.DescriptionValue := ParseValue(WordIndices(kiLESS, kiTHAN), vaNo, kiMAXVALUE)

  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIN) then
  begin
    FillChar(ValueNodes, SizeOf(ValueNodes), 0);
    ValueNodes.IdentTag := ParseTag(kiIN);
    ValueNodes.ValueToken := ParseList(True);
    Nodes.DescriptionValue := TValue.Create(Self, ValueNodes);
  end
  else
    SetError(PE_UnexpectedToken);

  Result := TCreateTableStmt.TPartitionValues.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateTriggerStmt(): TOffset;
var
  Nodes: TCreateTriggerStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CreateTag := ParseTag(kiCREATE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFINER)) then
    Nodes.DefinerNode := ParseDefinerValue();

    Nodes.TriggerTag := ParseTag(kiTRIGGER);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.TriggerIdent := ParseDbIdent(ditTrigger);

  if (not Error) then
    if (EndOfStmt(CurrentToken) or EndOfStmt(NextToken[1])) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(NextToken[1])^.KeywordIndex <> kiINSERT)
      and (TokenPtr(NextToken[1])^.KeywordIndex <> kiUPDATE)
      and (TokenPtr(NextToken[1])^.KeywordIndex <> kiDELETE)) then
      SetError(PE_UnexpectedToken, NextToken[1])
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiBEFORE) then
      Nodes.ActionValue := ParseValue(kiBEFORE, vaNo, ParseKeyword)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiAFTER) then
      Nodes.ActionValue := ParseValue(kiAFTER, vaNo, ParseKeyword)
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiON) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OnTag := ParseTag(kiON);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.TableIdentNode := ParseTableIdent();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiFOR) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.ForEachRowTag := ParseTag(kiFOR, kiEACH, kiROW);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Body := ParsePL_SQLStmt();

  Result := TCreateTriggerStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateUserStmt(const Alter: Boolean): TOffset;
var
  ListNodes: TList.TNodes;
  Nodes: TCreateUserStmt.TNodes;
  Resources: array of TOffset;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CreateTag := ParseTag(kiCREATE, kiUSER);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    if (not Alter) then
      Nodes.IfTag := ParseTag(kiIF, kiNOT, kiEXISTS)
    else
      Nodes.IfTag := ParseTag(kiIF, kiEXISTS);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.UserSpecifications := ParseList(False, ParseGrantStmtUserSpecification);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWITH)) then
  begin
    SetLength(Resources, 0);

    Nodes.WithTag := ParseTag(kiWITH);

    repeat
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_QUERIES_PER_HOUR) then
      begin
        SetLength(Resources, Length(Resources) + 1);
        Resources[Length(Resources) - 1] := ParseValue(kiMAX_QUERIES_PER_HOUR, vaNo, ParseInteger);
      end
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_UPDATES_PER_HOUR) then
      begin
        SetLength(Resources, Length(Resources) + 1);
        Resources[Length(Resources) - 1] := ParseValue(kiMAX_UPDATES_PER_HOUR, vaNo, ParseInteger);
      end
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_CONNECTIONS_PER_HOUR) then
      begin
        SetLength(Resources, Length(Resources) + 1);
        Resources[Length(Resources) - 1] := ParseValue(kiMAX_CONNECTIONS_PER_HOUR, vaNo, ParseInteger);
      end
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_USER_CONNECTIONS) then
      begin
        SetLength(Resources, Length(Resources) + 1);
        Resources[Length(Resources) - 1] := ParseValue(kiMAX_USER_CONNECTIONS, vaNo, ParseInteger);
      end
      else
        SetError(PE_UnexpectedToken);
    until (Error or EndOfStmt(CurrentToken));

    FillChar(ListNodes, SizeOf(ListNodes), 0);
    Nodes.ResourcesList := TList.Create(Self, ListNodes, Length(Resources), Resources);
  end;

  if (not Error) then
    if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPASSWORD)
      and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiEXPIRE)) then
    begin
      if (EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiDEFAULT)) then
        Nodes.PasswordOption := ParseTag(kiPASSWORD, kiEXPIRE, kiDEFAULT)
      else if (EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiNEVER)) then
        Nodes.PasswordOption := ParseTag(kiPASSWORD, kiEXPIRE, kiNEVER)
      else if (EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiINTERVAL)) then
      begin
        Nodes.PasswordOption := ParseTag(kiPASSWORD, kiEXPIRE, kiINTERVAL);
        if (not Error) then
          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else if (TokenPtr(CurrentToken)^.TokenType <> ttInteger) then
            SetError(PE_UnexpectedToken)
          else
            Nodes.PasswordDays := ParseInteger();
        if (not Error) then
          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiDAY) then
            SetError(PE_UnexpectedToken)
          else
            Nodes.DayTag := ParseTag(kiDAY);
      end
      else
        Nodes.PasswordOption := ParseTag(kiPASSWORD, kiEXPIRE);
    end
    else if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiACCOUNT)) then
    begin
      if (EndOfStmt(NextToken[1])) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCK) then
        Nodes.AccountTag := ParseTag(kiACCOUNT, kiLOCK)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUNLOCK) then
        Nodes.AccountTag := ParseTag(kiACCOUNT, kiUNLOCK)
      else
        SetError(PE_UnexpectedToken);
    end;

  Result := TCreateUserStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCreateViewStmt(): TOffset;
var
  Nodes: TCreateViewStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CreateTag := ParseTag(kiCREATE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiOR)) then
    Nodes.OrReplaceTag := ParseTag(kiOR, kiREPLACE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiALGORITHM)) then
    Nodes.AlgorithmValue := ParseValue(kiALGORITHM, vaYes, ParseKeyword);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFINER)) then
    Nodes.DefinerNode := ParseDefinerValue();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL)) then
    Nodes.SQLSecurityTag := ParseValue(WordIndices(kiSQL, kiSECURITY), vaNo, WordIndices(kiDEFINER, kiINVOKER));

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiVIEW) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.ViewTag := ParseTag(kiVIEW);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.IdentNode := ParseTableIdent();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
    Nodes.Columns := ParseList(True, ParseColumnIdent);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiAS) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.AsTag := ParseTag(kiAS);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiSELECT) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.SelectStmt := ParseSelectStmt();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWITH)) then
    if (EndOfStmt(NextToken[1])) then
      SetError(PE_IncompleteStmt, NextToken[1])
    else if (TokenPtr(NextToken[1])^.KeywordIndex = kiCASCADED) then
      Nodes.OptionTag := ParseTag(kiWITH, kiCASCADED, kiCHECK, kiOPTION)
    else if (TokenPtr(NextToken[1])^.KeywordIndex = kiLOCAL) then
      Nodes.OptionTag := ParseTag(kiWITH, kiLOCAL, kiCHECK, kiOPTION)
    else
      Nodes.OptionTag := ParseTag(kiWITH, kiCHECK, kiOPTION);

  Result := TCreateViewStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseCurrentTimestamp(): TOffset;
var
  Nodes: TCurrentTimestamp.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CurrentTimestampTag := ParseTag(kiCURRENT_TIMESTAMP);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
  begin
    Nodes.OpenBracketToken := ApplyCurrentToken();

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.TokenType <> ttInteger) then
        SetError(PE_UnexpectedToken)
      else
        Nodes.LengthInteger := ParseInteger();
    
    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
        SetError(PE_UnexpectedToken)
      else
        Nodes.CloseBracketToken := ApplyCurrentToken();
  end;
  
  Result := TCurrentTimestamp.Create(Self, Nodes);
end;

function TMySQLParser.ParseDatabaseIdent(): TOffset;
begin
  Result := ParseDbIdent(ditDatabase);
end;

function TMySQLParser.ParseDataType(): TOffset;
var
  IdentString: string;
  Nodes: TDataType.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiNATIONAL)) then
    Nodes.NationalTag := ParseTag(kiNATIONAL);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
    SetError(PE_UnexpectedToken)
  else
    Nodes.IdentToken := ApplyCurrentToken();

  if (not Error) then
  begin
    IdentString := UpperCase(TokenPtr(Nodes.IdentToken)^.AsString);

    if ((IdentString <> 'BIGINT')
      and (IdentString <> 'BINARY')
      and (IdentString <> 'BIT')
      and (IdentString <> 'BLOB')
      and (IdentString <> 'BOOL')
      and (IdentString <> 'BOOLEAN')
      and (IdentString <> 'CHAR')
      and (IdentString <> 'DEC')
      and (IdentString <> 'DECIMAL')
      and (IdentString <> 'DATE')
      and (IdentString <> 'DATETIME')
      and (IdentString <> 'DOUBLE')
      and (IdentString <> 'ENUM')
      and (IdentString <> 'FLOAT')
      and (IdentString <> 'GEOMETRY')
      and (IdentString <> 'GEOMETRYCOLLECTION')
      and (IdentString <> 'INT')
      and (IdentString <> 'INT4')
      and (IdentString <> 'INTEGER')
      and (IdentString <> 'JSON')
      and (IdentString <> 'LINESTRING')
      and (IdentString <> 'LONG')
      and (IdentString <> 'LONGBLOB')
      and (IdentString <> 'LONGTEXT')
      and (IdentString <> 'MEDIUMBLOB')
      and (IdentString <> 'MEDIUMINT')
      and (IdentString <> 'MEDIUMTEXT')
      and (IdentString <> 'MULTILINESTRING')
      and (IdentString <> 'MULTIPOINT')
      and (IdentString <> 'MULTIPOLYGON')
      and (IdentString <> 'NUMERIC')
      and (IdentString <> 'NCHAR')
      and (IdentString <> 'NVARCHAR')
      and (IdentString <> 'POINT')
      and (IdentString <> 'POLYGON')
      and (IdentString <> 'REAL')
      and (IdentString <> 'SERIAL')
      and (IdentString <> 'SET')
      and (IdentString <> 'SIGNED')
      and (IdentString <> 'SMALLINT')
      and (IdentString <> 'TEXT')
      and (IdentString <> 'TIME')
      and (IdentString <> 'TIMESTAMP')
      and (IdentString <> 'TINYBLOB')
      and (IdentString <> 'TINYINT')
      and (IdentString <> 'TINYTEXT')
      and (IdentString <> 'UNSIGNED')
      and (IdentString <> 'VARBINARY')
      and (IdentString <> 'VARCHAR')
      and (IdentString <> 'YEAR')) then
      SetError(PE_UnexpectedToken, PreviousToken);

      if (not Error) then
        if ((IdentString = 'BIGINT')
          or (IdentString = 'BINARY')
          or (IdentString = 'BIT')
          or (IdentString = 'CHAR')
          or (IdentString = 'DATETIME')
          or (IdentString = 'DECIMAL')
          or (IdentString = 'DOUBLE')
          or (IdentString = 'FLOAT')
          or (IdentString = 'INT')
          or (IdentString = 'INTEGER')
          or (IdentString = 'LONGTEXT')
          or (IdentString = 'MEDIUMINT')
          or (IdentString = 'MEDIUMTEXT')
          or (IdentString = 'NCHAR')
          or (IdentString = 'NVARCHAR')
          or (IdentString = 'NUMERIC')
          or (IdentString = 'REAL')
          or (IdentString = 'SMALLINT')
          or (IdentString = 'TIME')
          or (IdentString = 'TIMESTAMP')
          or (IdentString = 'TINYINT')
          or (IdentString = 'TINYTEXT')
          or (IdentString = 'TEXT')
          or (IdentString = 'VARBINARY')
          or (IdentString = 'VARCHAR')
          or (IdentString = 'YEAR')) then
        begin
          if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
          begin
            Nodes.OpenBracketToken := ApplyCurrentToken();

            if (EndOfStmt(CurrentToken)) then
              SetError(PE_IncompleteStmt)
            else if (TokenPtr(CurrentToken)^.TokenType <> ttInteger) then
              SetError(PE_UnexpectedToken)
            else
              Nodes.LengthToken := ParseInteger();

            if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttComma)
              and ((IdentString = 'REAL')
              or (IdentString = 'DOUBLE')
              or (IdentString = 'FLOAT')
              or (IdentString = 'DECIMAL')
              or (IdentString = 'NUMERIC'))) then
            begin
              Nodes.CommaToken := ApplyCurrentToken();

              if (EndOfStmt(CurrentToken)) then
                SetError(PE_IncompleteStmt)
              else if (TokenPtr(CurrentToken)^.TokenType <> ttInteger) then
                SetError(PE_UnexpectedToken)
              else
                Nodes.DecimalsToken := ParseInteger();
            end;

            if (not Error) then
              if (EndOfStmt(CurrentToken)) then
                SetError(PE_IncompleteStmt)
              else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
                SetError(PE_UnexpectedToken)
              else
                Nodes.CloseBracketToken := ApplyCurrentToken();

            if (not Error) then
            begin
              if ((Nodes.LengthToken = 0)
                and ((IdentString = 'VARCHAR')
                  or (IdentString = 'VARBINARY'))) then
                if (EndOfStmt(CurrentToken)) then
                  SetError(PE_IncompleteStmt)
                else
                  SetError(PE_UnexpectedToken);
            end;
          end;
        end
        else if ((IdentString = 'ENUM')
          or (IdentString = 'SET')) then
        begin
          if (not Error) then
            Nodes.ItemsList := ParseList(True, ParseString);
        end;

  end;

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUNSIGNED)
    and ((IdentString = 'BIGINT')
      or (IdentString = 'DECIMAL')
      or (IdentString = 'DOUBLE')
      or (IdentString = 'FLOAT')
      or (IdentString = 'INT')
      or (IdentString = 'INTEGER')
      or (IdentString = 'MEDIUMINT')
      or (IdentString = 'NUMERIC')
      or (IdentString = 'REAL')
      or (IdentString = 'SMALLINT')
      or (IdentString = 'TINYINT'))) then
    Nodes.UnsignedTag := ParseTag(kiUNSIGNED);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiZEROFILL)
    and ((IdentString = 'BIGINT')
      or (IdentString = 'DECIMAL')
      or (IdentString = 'DOUBLE')
      or (IdentString = 'FLOAT')
      or (IdentString = 'INT')
      or (IdentString = 'INTEGER')
      or (IdentString = 'MEDIUMINT')
      or (IdentString = 'REAL')
      or (IdentString = 'SMALLINT')
      or (IdentString = 'TINYINT'))) then
    Nodes.ZerofillTag := ParseTag(kiZEROFILL);

  if ((IdentString = 'TEXT')
    or (IdentString = 'LONGTEXT')
    or (IdentString = 'MEDIUMTEXT')
    or (IdentString = 'TINYTEXT')
    or (IdentString = 'TEXT')
    or (IdentString = 'VARCHAR')) then
  begin
    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiBINARY)) then
      Nodes.BinaryTag := ParseTag(kiBINARY);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiASCII)) then
      Nodes.ASCIITag := ParseTag(kiASCII);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUNICODE)) then
      Nodes.BinaryTag := ParseTag(kiUNICODE);
  end;

  if (not Error
    and ((IdentString = 'CHAR')
      or (IdentString = 'ENUM')
      or (IdentString = 'LONGTEXT')
      or (IdentString = 'MEDIUMTEXT')
      or (IdentString = 'SET')
      or (IdentString = 'TEXT')
      or (IdentString = 'TINYTEXT')
      or (IdentString = 'VARCHAR'))) then
    begin
      if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARACTER)) then
        Nodes.CharacterSetValue := ParseValue(WordIndices(kiCHARACTER, kiSET), vaNo, ParseIdent)
      else if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARSET)) then
        Nodes.CharacterSetValue := ParseValue(kiCHARSET, vaNo, ParseIdent);

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLLATE)) then
        Nodes.CollateValue := ParseValue(kiCOLLATE, vaNo, ParseIdent);
    end;

  Result := TDataType.Create(Self, Nodes);
end;

function TMySQLParser.ParseDbIdent(const ADbIdentType: TDbIdentType): TOffset;
var
  Nodes: TDbIdent.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents + ttStrings) and (TokenPtr(CurrentToken)^.OperatorType <> otMulti)) then
    SetError(PE_UnexpectedToken);

  if (not Error) then
  begin
    if (TokenPtr(CurrentToken)^.OperatorType = otMulti) then
      TokenPtr(CurrentToken)^.FTokenType := ttIdent;
    TokenPtr(CurrentToken)^.FOperatorType := otUnknown;
    TokenPtr(CurrentToken)^.FUsageType := utDbIdent;
    Nodes.Ident := ApplyCurrentToken();
  end;

  if (not Error) then
    if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.OperatorType = otDot)) then
    case (ADbIdentType) of
      ditKey,
      ditColumn:
        begin
          Nodes.TableIdent := Nodes.Ident;

          Nodes.TableDot := ApplyCurrentToken();

          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else if (TokenPtr(CurrentToken)^.OperatorType = otMulti) then
          begin
            if (TokenPtr(CurrentToken)^.OperatorType = otMulti) then
              TokenPtr(CurrentToken)^.FTokenType := ttIdent;
            TokenPtr(CurrentToken)^.FOperatorType := otUnknown;
            TokenPtr(CurrentToken)^.FUsageType := utDbIdent;
            Nodes.Ident := ApplyCurrentToken();
          end
          else if (((TokenPtr(CurrentToken)^.TokenType = ttIdent) or AnsiQuotes and (TokenPtr(CurrentToken)^.TokenType = ttDQIdent) or not AnsiQuotes and (TokenPtr(CurrentToken)^.TokenType = ttMySQLIdent))) then
            Nodes.Ident := ApplyCurrentToken()
          else
            SetError(PE_UnexpectedToken);

          if (not Error and not EndOfStmt(CurrentToken)
            and (TokenPtr(CurrentToken)^.OperatorType = otDot)) then
          begin
            Nodes.DatabaseIdent := Nodes.TableIdent;
            Nodes.DatabaseDot := Nodes.TableDot;
            Nodes.TableIdent := Nodes.Ident;

            Nodes.TableDot := ApplyCurrentToken();

            if (EndOfStmt(CurrentToken)) then
              SetError(PE_IncompleteStmt)
            else if (TokenPtr(CurrentToken)^.OperatorType = otMulti) then
            begin
              if (TokenPtr(CurrentToken)^.OperatorType = otMulti) then
                TokenPtr(CurrentToken)^.FTokenType := ttIdent;
              TokenPtr(CurrentToken)^.FOperatorType := otUnknown;
              TokenPtr(CurrentToken)^.FUsageType := utDbIdent;
              Nodes.Ident := ApplyCurrentToken();
            end
            else if (((TokenPtr(CurrentToken)^.TokenType = ttIdent) or AnsiQuotes and (TokenPtr(CurrentToken)^.TokenType = ttDQIdent) or not AnsiQuotes and (TokenPtr(CurrentToken)^.TokenType = ttMySQLIdent))) then
              Nodes.Ident := ApplyCurrentToken()
            else
              SetError(PE_UnexpectedToken);
          end;
        end;
      ditTable,
      ditFunction,
      ditProcedure,
      ditTrigger,
      ditEvent:
        begin
          Nodes.DatabaseIdent := Nodes.Ident;

          Nodes.DatabaseDot := ApplyCurrentToken();
          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else
          begin
            if (TokenPtr(CurrentToken)^.OperatorType = otMulti) then
              TokenPtr(CurrentToken)^.FTokenType := ttIdent;
            TokenPtr(CurrentToken)^.FOperatorType := otUnknown;
            TokenPtr(CurrentToken)^.FUsageType := utDbIdent;
            Nodes.Ident := ApplyCurrentToken();
          end;
        end;
    end;

  Result := TDbIdent.Create(Self, ADbIdentType, Nodes);
end;

function TMySQLParser.ParseDefinerValue(): TOffset;
var
  Nodes: TValue.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IdentTag := ParseTag(kiDEFINER);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.OperatorType = otEqual)) then
      SetError(PE_UnexpectedToken)
    else
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.ValueToken := ParseUserIdent();
    end;

  Result := TValue.Create(Self, Nodes);
end;

function TMySQLParser.ParseDeallocatePrepareStmt(): TOffset;
var
  Nodes: TDeallocatePrepareStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if ((TokenPtr(CurrentToken)^.KeywordIndex <> kiDEALLOCATE)
    and (TokenPtr(CurrentToken)^.KeywordIndex <> kiDROP)) then
    SetError(PE_UnexpectedToken)
  else if (EndOfStmt(NextToken[1])) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(NextToken[1])^.KeywordIndex <> kiPREPARE) then
    SetError(PE_UnexpectedToken, NextToken[1])
  else
    Nodes.StmtTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex, kiPREPARE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.StmtIdent := ParseVariable();

  Result := TDeallocatePrepareStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDeclareStmt(): TOffset;
var
  Nodes: TDeclareStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiDECLARE);

  if (not Error) then
    if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCURSOR)) then
    begin
      Nodes.CursorForTag := ParseTag(kiCURSOR, kiFOR);

      if (not Error) then
        Nodes.SelectStmt := ParseSelectStmt();
    end
    else
    begin
      Nodes.IdentList := ParseList(False, ApplyCurrentToken);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.TypeNode := ParseDataType();

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT)) then
        Nodes.DefaultValue := ParseValue(kiDEFAULT, vaNo, ParseExpr);
    end;

  Result := TDeclareStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDeclareConditionStmt(): TOffset;
var
  Nodes: TDeclareConditionStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiDECLARE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Ident := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ConditionTag := ParseTag(kiCONDITION, kiFOR);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiSQLSTATE) then
      Nodes.ErrorCode := ParseInteger()
    else
    begin
      if (EndOfStmt(NextToken[1]) or (TokenPtr(NextToken[1])^.KeywordIndex <> kiVALUE)) then
        Nodes.SQLStateTag := ParseTag(kiSQLSTATE)
      else
        Nodes.SQLStateTag := ParseTag(kiSQLSTATE, kiVALUE);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.ErrorString := ParseString();
    end;


  Result := TDeclareConditionStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDeclareCursorStmt(): TOffset;
var
  Nodes: TDeclareCursorStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiDECLARE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Ident := ParseDbIdent(ditCursor);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.CursorTag := ParseTag(kiCURSOR);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ForTag := ParseTag(kiFOR);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiSELECT) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.SelectStmt := ParseSelectStmt();

  Result := TDeclareCursorStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDeclareHandlerStmt(): TOffset;
var
  Nodes: TDeclareHandlerStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiDECLARE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCONTINUE) then
      Nodes.ActionTag := ParseTag(kiCONTINUE)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiEXIT) then
      Nodes.ActionTag := ParseTag(kiEXIT)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUNDO) then
      Nodes.ActionTag := ParseTag(kiUNDO)
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiHANDLER) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.HandlerTag := ParseTag(kiHANDLER);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiFOR) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.ForTag := ParseTag(kiFOR);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ConditionsExpr := ParseList(False, ParseDeclareHandlerStmtCondition);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Stmt := ParsePL_SQLStmt();

  Result := TDeclareHandlerStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDeclareHandlerStmtCondition(): TOffset;
var
  Nodes: TDeclareHandlerStmt.TCondition.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.TokenType = ttInteger) then
    Nodes.ErrorCode := ParseInteger()
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiSQLSTATE)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiVALUE)) then
    Nodes.SQLStateTag := ParseValue(WordIndices(kiSQLSTATE, kiVALUE), vaNo, ParseExpr)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSQLSTATE) then
    Nodes.SQLStateTag := ParseValue(kiSQLSTATE, vaNo, ParseExpr)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiNOT)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiFOUND)) then
    Nodes.SQLStateTag := ParseTag(kiNOT, kiFOUND)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSQLWARNINGS) then
    Nodes.SQLWarningsTag := ParseTag(kiSQLWARNINGS)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSQLEXCEPTION) then
    Nodes.SQLWarningsTag := ParseTag(kiSQLEXCEPTION)
  else if (TokenPtr(CurrentToken)^.TokenType in ttIdents) then // Must be in the end, because keywords are in ttIdents
    Nodes.ConditionIdent := ParseVariable()
  else
    SetError(PE_UnexpectedToken);

  Result := TDeclareHandlerStmt.TCondition.Create(Self, Nodes);
end;

function TMySQLParser.ParseDeleteStmt(): TOffset;
var
  Nodes: TDeleteStmt.TNodes;
  TableCount: Integer;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);
  TableCount := 1;

  Nodes.DeleteTag := ParseTag(kiDELETE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLOW_PRIORITY)) then
    Nodes.LowPriorityTag := ParseTag(kiLOW_PRIORITY);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiQUICK)) then
    Nodes.QuickTag := ParseTag(kiQUICK);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIGNORE)) then
    Nodes.IgnoreTag := ParseTag(kiIGNORE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM) then
    begin
      Nodes.FromTag := ParseTag(kiFROM);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
        begin
          Nodes.TableList := ParseList(False, ParseTableIdent);

          if (not Error) then
            TableCount := PList(NodePtr(Nodes.TableList))^.Count;
        end;

      if (not Error and not EndOfStmt(CurrentToken)) then
        if ((TableCount = 1) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPARTITION)) then
        begin
          Nodes.PartitionTag := ParseTag(kiPARTITION);

          if (not Error) then
            Nodes.PartitionList := ParseList(True, ParseCreateTableStmtPartitionIdent);
        end
        else if ((TableCount > 1) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUSING)) then
          Nodes.UsingValue := ParseValue(kiUSING, vaNo, ParseTableReference);
    end
    else
    begin
      Nodes.TableList := ParseList(False, ParseTableIdent);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiFROM) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.FromTag := ParseTag(kiFROM);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.TableList := ParseList(False, ParseTableReference);
    end;

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE)) then
    Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  if (TableCount = 1) then
  begin
    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiORDER)) then
      Nodes.OrderByValue := ParseValue(WordIndices(kiORDER, kiBY), vaNo, False, ParseColumnIdent);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLIMIT)) then
      Nodes.LimitValue := ParseValue(kiLIMIT, vaNo, ParseInteger);
  end;

  Result := TDeleteStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDoStmt(): TOffset;
var
  Nodes: TDoStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.DoTag := ParseTag(kiDO);

  if (not Error) then
    Nodes.ExprList := ParseList(False, ParseExpr);

  Result := TDoStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDropDatabaseStmt(): TOffset;
var
  Nodes: TDropDatabaseStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(NextToken[1])^.KeywordIndex = kiDATABASE) then
    Nodes.StmtTag := ParseTag(kiDROP, kiDATABASE)
  else
    Nodes.StmtTag := ParseTag(kiDROP, kiSCHEMA);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    Nodes.IfExistsTag := ParseTag(kiIF, kiEXISTS);

  if (not Error) then
    Nodes.DatabaseIdent := ParseDbIdent(ditDatabase);

  Result := TDropDatabaseStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDropEventStmt(): TOffset;
var
  Nodes: TDropEventStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiDROP, kiEVENT);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    Nodes.IfExistsTag := ParseTag(kiIF, kiEXISTS);

  if (not Error) then
    Nodes.EventIdent := ParseDbIdent(ditEvent);

  Result := TDropEventStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDropIndexStmt(): TOffset;
var
  Found: Boolean;
  Nodes: TDropIndexStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiDROP, kiINDEX);

  if (not Error) then
    Nodes.IndexIdent := ParseDbIdent(ditKey);

  Found := True;
  while (not Error and Found and not EndOfStmt(CurrentToken)) do
    if ((Nodes.AlgorithmValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiALGORITHM)) then
      Nodes.AlgorithmValue := ParseValue(kiALGORITHM, vaAuto, WordIndices(kiDEFAULT, kiINPLACE, kiCOPY))
    else if ((Nodes.LockValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCK)) then
      Nodes.LockValue := ParseValue(kiLOCK, vaAuto, WordIndices(kiDEFAULT, kiNONE, kiSHARED, kiEXCLUSIVE))
    else
      Found := False;

  Result := TDropIndexStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDropRoutineStmt(const ARoutineType: TRoutineType): TOffset;
var
  Nodes: TDropRoutineStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (ARoutineType = rtFunction) then
    Nodes.StmtTag := ParseTag(kiDROP, kiFUNCTION)
  else
    Nodes.StmtTag := ParseTag(kiDROP, kiPROCEDURE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    Nodes.IfExistsTag := ParseTag(kiIF, kiEXISTS);

  if (not Error) then
    if (ARoutineType = rtFunction) then
      Nodes.RoutineIdent := ParseDbIdent(ditFunction)
    else
      Nodes.RoutineIdent := ParseDbIdent(ditProcedure);

  Result := TDropRoutineStmt.Create(Self, ARoutineType, Nodes);
end;

function TMySQLParser.ParseDropServerStmt(): TOffset;
var
  Nodes: TDropServerStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiDROP, kiSERVER);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    Nodes.IfExistsTag := ParseTag(kiIF, kiEXISTS);

  if (not Error) then
    Nodes.ServerIdent := ParseDbIdent(ditServer);

  Result := TDropServerStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDropTableStmt(): TOffset;
var
  Nodes: TDropTableStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(NextToken[1])^.KeywordIndex <> kiTEMPORARY) then
    Nodes.StmtTag := ParseTag(kiDROP, kiTABLE)
  else
    Nodes.StmtTag := ParseTag(kiDROP, kiTEMPORARY, kiTABLE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    Nodes.IfExistsTag := ParseTag(kiIF, kiEXISTS);

  if (not Error) then
    Nodes.TableIdentList := ParseList(False, ParseTableIdent);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiRESTRICT) then
      Nodes.RestrictCascadeTag := ParseTag(kiRESTRICT)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCASCADE) then
      Nodes.RestrictCascadeTag := ParseTag(kiCASCADE);

  Result := TDropTableStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDropTriggerStmt(): TOffset;
var
  Nodes: TDropTriggerStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiDROP, kiTrigger);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    Nodes.IfExistsTag := ParseTag(kiIF, kiEXISTS);

  if (not Error) then
    Nodes.TriggerIdent := ParseDbIdent(ditTrigger);

  Result := TDropTriggerStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDropUserStmt(): TOffset;
var
  Nodes: TDropUserStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiDROP, kiUSER);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    Nodes.IfExistsTag := ParseTag(kiIF, kiEXISTS);

  if (not Error) then
    Nodes.UserList := ParseList(False, ParseUserIdent);

  Result := TDropUserStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseDropViewStmt(): TOffset;
var
  Nodes: TDropViewStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiDROP, kiVIEW);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)) then
    Nodes.IfExistsTag := ParseTag(kiIF, kiEXISTS);

  if (not Error) then
    Nodes.ViewIdentList := ParseList(False, ParseTableIdent);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiRESTRICT) then
      Nodes.RestrictCascadeTag := ParseTag(kiRESTRICT)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCASCADE) then
      Nodes.RestrictCascadeTag := ParseTag(kiCASCADE);

  Result := TDropViewStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseEventIdent(): TOffset;
begin
  Result := ParseDbIdent(ditEvent);
end;

function TMySQLParser.ParseExecuteStmt(): TOffset;
var
  Nodes: TExecuteStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiEXECUTE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.StmtVariable := ParseVariable();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUSING)) then
  begin
    Nodes.UsingTag := ParseTag(kiUSING);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.VariableIdents := ParseList(False, ParseVariable);
  end;

  Result := TExecuteStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseExistsFunc(): TOffset;
var
  Nodes: TExistsFunc.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.FuncToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiSELECT) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.SubQuery := ParseSelectStmt();

  if (not Error and (Nodes.OpenBracket > 0)) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TExistsFunc.Create(Self, Nodes);
end;

function TMySQLParser.ParseExplainStmt(): TOffset;
var
  Nodes: TExplainStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex <> kiEXTENDED)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiPARTITIONS)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiFORMAT)) then
    begin
      Nodes.TableIdent := ParseTableIdent();

      if (not Error and not EndOfStmt(CurrentToken)) then
        Nodes.ColumnIdent := ParseColumnIdent();
    end
    else
    begin
      if (TokenPtr(CurrentToken)^.KeywordIndex = kiEXTENDED) then
        Nodes.ExplainType := ParseTag(kiEXTENDED)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiPARTITIONS) then
        Nodes.ExplainType := ParseTag(kiPARTITIONS)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFORMAT) then
      begin
        Nodes.ExplainType := ParseTag(kiFORMAT);

        if (not Error) then
          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else if (TokenPtr(CurrentToken)^.OperatorType = otEqual) then
          begin
            TokenPtr(CurrentToken)^.FOperatorType := otAssign;

            Nodes.AssignToken := ApplyCurrentToken();

            if (not Error) then
              if (EndOfStmt(CurrentToken)) then
                SetError(PE_IncompleteStmt)
              else if (TokenPtr(CurrentToken)^.KeywordIndex = kiTRADITIONAL) then
                Nodes.FormatKeyword := ApplyCurrentToken()
              else if (TokenPtr(CurrentToken)^.KeywordIndex = kiJSON) then
                Nodes.FormatKeyword := ApplyCurrentToken()
              else
                SetError(PE_UnexpectedToken);
          end;
      end;
    end;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSELECT) then
      Nodes.ExplainStmt := ParseSelectStmt()
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiDELETE) then
      Nodes.ExplainStmt := ParseDeleteStmt()
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiINSERT) then
      Nodes.ExplainStmt := ParseInsertStmt(False)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiREPLACE) then
      Nodes.ExplainStmt := ParseInsertStmt(True)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUPDATE) then
      Nodes.ExplainStmt := ParseUpdateStmt()
    else
      SetError(PE_UnexpectedToken);

  Result := TExplainStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseExpr(): TOffset;
const
  MaxNodeCount = 200;
var
  ArgumentsList: TOffset;
  CurrentOperatorType: TOperatorType;
  I: Integer;
  DbIdent: TOffset;
  InNodes: TInOp.TNodes;
  LikeNodes: TLikeOp.TNodes;
  Node: TOffset;
  NodeCount: Integer;
  Nodes: array [0 .. MaxNodeCount - 1] of TOffset;
  OperatorPrecedence: Integer;
  OperatorType: TOperatorType;
  PreviousOperatorType: TOperatorType;
  RegExpNodes: TRegExpOp.TNodes;
  RemoveNodes: Integer;
begin
  NodeCount := 0;

  repeat
    Node := CurrentToken;

    if (NodeCount = MaxNodeCount) then
      raise Exception.CreateFmt(STooManyTokensInExpr, [NodeCount])
    else if (EndOfStmt(Node)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(Node)^.TokenType in [ttColon, ttComma, ttCloseBracket]) then
      SetError(PE_UnexpectedToken)
    else if (TokenPtr(Node)^.KeywordIndex = kiINTERVAL) then
      Node := ParseValue(kiINTERVAL, vaNo, ParseIntervalOp)
    else if ((TokenPtr(Node)^.OperatorType = otMinus) and ((NodeCount = 0) or IsToken(Nodes[NodeCount - 1]) and (TokenPtr(Nodes[NodeCount - 1])^.OperatorType <> otUnknown))) then
      TokenPtr(Node)^.FOperatorType := otUnaryMinus
    else if ((TokenPtr(Node)^.OperatorType = otPlus) and ((NodeCount = 0) or IsToken(Nodes[NodeCount - 1]) and (TokenPtr(Nodes[NodeCount - 1])^.OperatorType <> otUnknown))) then
      TokenPtr(Node)^.FOperatorType := otUnaryPlus
    else if ((TokenPtr(Node)^.OperatorType = otNot) and ((NodeCount = 0) or IsToken(Nodes[NodeCount - 1]) and (TokenPtr(Nodes[NodeCount - 1])^.OperatorType <> otUnknown))) then
    begin
      TokenPtr(Node)^.FOperatorType := otUnaryNot;
      TokenPtr(Node)^.FUsageType := utOperator;
    end
    else if (TokenPtr(Node)^.TokenType = ttOpenBracket) then
      if (EndOfStmt(NextToken[1])) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(NextToken[1])^.KeywordIndex = kiSELECT) then
        Node := ParseSubArea(ParseSelectStmt)
      else if ((NodeCount > 0) and IsToken(Nodes[NodeCount - 1]) and (TokenPtr(Nodes[NodeCount - 1])^.OperatorType in [otIn])) then
        Node := ParseList(True, ParseExpr)
      else
        Node := ParseSubArea(ParseExpr)
    else if ((TokenPtr(Node)^.TokenType in ttIdents)
      and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.TokenType = ttOpenBracket)
      and ((TokenPtr(Node)^.KeywordIndex < 0) or (TokenPtr(Node)^.OperatorType = otUnknown) or (FunctionList.IndexOf(TokenPtr(Node)^.Text) >= 0))) then
      if ((NodeCount >= 2)
        and IsToken(Nodes[NodeCount - 1]) and (TokenPtr(Nodes[NodeCount - 1])^.OperatorType = otDot)
        and IsToken(Nodes[NodeCount - 2]) and (TokenPtr(Nodes[NodeCount - 2])^.TokenType in ttIdents)) then
      begin // Db.Func()
        TokenPtr(Nodes[NodeCount - 2])^.FUsageType := utDbIdent;
        TokenPtr(Node)^.FUsageType := utDbIdent;
        DbIdent := TDbIdent.Create(Self, ditFunction, ApplyCurrentToken(), Nodes[NodeCount - 1], Nodes[NodeCount - 2], 0, 0);
        ArgumentsList := ParseList(True, ParseExpr);
        Node := TFunctionCall.Create(Self, DbIdent, ArgumentsList);
        Dec(NodeCount, 2);
      end
      else if (UpperCase(TokenPtr(Node)^.Text) = 'CAST') then
        Node := ParseCastFunc()
      else if (UpperCase(TokenPtr(Node)^.Text) = 'CHAR') then
        Node := ParseCharFunc()
      else if (UpperCase(TokenPtr(Node)^.Text) = 'CONVERT') then
        Node := ParseConvertFunc()
      else if (UpperCase(TokenPtr(Node)^.Text) = 'EXISTS') then
        Node := ParseExistsFunc()
      else if (UpperCase(TokenPtr(Node)^.Text) = 'EXTRACT') then
        Node := ParseExtractFunc()
      else if (UpperCase(TokenPtr(Node)^.Text) = 'GROUP_CONCAT') then
        Node := ParseGroupConcatFunc()
      else if (UpperCase(TokenPtr(Node)^.Text) = 'POSITION') then
        Node := ParsePositionFunc()
      else if (UpperCase(TokenPtr(Node)^.Text) = 'SUBSTR') then
        Node := ParseSubstringFunc()
      else if (UpperCase(TokenPtr(Node)^.Text) = 'SUBSTRING') then
        Node := ParseSubstringFunc()
      else if (UpperCase(TokenPtr(Node)^.Text) = 'TRIM') then
        Node := ParseTrimFunc()
      else if (UpperCase(TokenPtr(Node)^.Text) = 'WEIGHT_STRING') then
        Node := ParseWeightStringFunc()
      else // Func()
        Node := ParseFunctionCall()
    else if (TokenPtr(Node)^.TokenType = ttAt) then
      Node := ParseVariable()
    else if ((TokenPtr(Node)^.OperatorType = otMulti)
      and ((NodeCount = 0) or IsToken(Nodes[NodeCount - 1]) and (TokenPtr(Nodes[NodeCount - 1])^.OperatorType = otDot))) then
    begin
      TokenPtr(CurrentToken)^.FTokenType := ttIdent;
      TokenPtr(CurrentToken)^.FOperatorType := otUnknown;
      TokenPtr(CurrentToken)^.FUsageType := utDbIdent;
    end
    else if (TokenPtr(Node)^.KeywordIndex = kiCASE) then
      Node := ParseCaseOp()
    else if (TokenPtr(Node)^.KeywordIndex = kiDEFAULT) then
      TokenPtr(Node)^.FUsageType := utConst
    else if (TokenPtr(Node)^.KeywordIndex = kiNULL) then
      TokenPtr(Node)^.FUsageType := utConst
    else if (TokenPtr(Node)^.KeywordIndex = kiTRUE) then
      TokenPtr(Node)^.FUsageType := utConst
    else if (TokenPtr(Node)^.KeywordIndex = kiFALSE) then
      TokenPtr(Node)^.FUsageType := utConst
    else if (TokenPtr(Node)^.KeywordIndex = kiUNKNOWN) then
      TokenPtr(Node)^.FUsageType := utConst
    else if (TokenPtr(Node)^.KeywordIndex >= 0) then
    begin
      OperatorType := OperatorTypeByKeywordIndex[TokenPtr(Node)^.KeywordIndex];
      if (OperatorType <> otUnknown) then
      begin
        TokenPtr(Node)^.FTokenType := ttOperator;
        TokenPtr(Node)^.FOperatorType := OperatorType;
        TokenPtr(Node)^.FUsageType := utOperator;
      end;
    end;

    if ((NodeCount = 0) and IsToken(Node) and (TokenPtr(Node)^.OperatorType <> otUnknown) and not (TokenPtr(Node)^.OperatorType in UnaryOperators)) then
      SetError(PE_UnexpectedToken);

    if (Error) then
    begin
      PreviousOperatorType := otUnknown;
      CurrentOperatorType := otUnknown;
    end
    else
    begin
      if (Node = CurrentToken) then
        Nodes[NodeCount] := ApplyCurrentToken()
      else
        Nodes[NodeCount] := Node;
      Inc(NodeCount);

      if (not IsToken(Nodes[NodeCount - 1])) then
        PreviousOperatorType := otUnknown
      else
        PreviousOperatorType := TokenPtr(Nodes[NodeCount - 1])^.OperatorType;
      if (Error or EndOfStmt(CurrentToken)) then
        CurrentOperatorType := otUnknown
      else
        CurrentOperatorType := TokenPtr(CurrentToken)^.OperatorType;
    end;
  until (Error
    or EndOfStmt(CurrentToken)
    or (PreviousOperatorType = otUnknown) and (CurrentOperatorType = otUnknown));

  if (not Error and (NodeCount > 1)) then
    for OperatorPrecedence := 1 to MaxOperatorPrecedence do
    begin
      I := 0;
      while (not Error and (I < NodeCount)) do
        if (not IsToken(Nodes[I]) or (OperatorPrecedenceByOperatorType[TokenPtr(Nodes[I])^.OperatorType] <> OperatorPrecedence)) then
          Inc(I)
        else
          case (TokenPtr(Nodes[I])^.OperatorType) of
            otBinary,
            otInterval,
            otInvertBits,
            otDistinct,
            otNot,
            otUnaryMinus,
            otUnaryNot,
            otUnaryPlus:
              if (I >= NodeCount - 1) then
                SetError(PE_IncompleteStmt)
              else
              begin
                Nodes[I] := TUnaryOp.Create(Self, Nodes[I], Nodes[I + 1]);
                Dec(NodeCount);
                Move(Nodes[I + 2], Nodes[I + 1], (NodeCount - I - 1) * SizeOf(Nodes[0]));
              end;
            otAnd,
            otAssign,
            otAssign2,
            otBitAND,
            otBitOR,
            otBitXOR,
            otCollate,
            otDiv,
            otDivision,
            otEqual,
            otGreater,
            otGreaterEqual,
            otIs,
            otLess,
            otLessEqual,
            otMinus,
            otMod,
            otMulti,
            otNotEqual,
            otNullSaveEqual,
            otOr,
            otPipes,
            otPlus,
            otShiftLeft,
            otShiftRight,
            otXOr:
              if (I = 0) then
                SetError(PE_UnexpectedToken, Nodes[I])
              else if (I >= NodeCount - 1) then
                SetError(PE_IncompleteStmt)
              else if (IsToken(Nodes[I - 1]) and (TokenPtr(Nodes[I - 1])^.TokenType = ttOperator)) then
                SetError(PE_UnexpectedToken, Nodes[I])
              else if (IsToken(Nodes[I + 1]) and (TokenPtr(Nodes[I + 1])^.TokenType = ttOperator)) then
                SetError(PE_UnexpectedToken, Nodes[I + 1])
              else
              begin
                Nodes[I - 1] := TBinaryOp.Create(Self, Nodes[I], Nodes[I - 1], Nodes[I + 1]);
                Dec(NodeCount, 2);
                Move(Nodes[I + 2], Nodes[I], (NodeCount - I) * SizeOf(Nodes[0]));
                Dec(I);
              end;
            otBetween:
              if (I + 3 >= NodeCount) then
                SetError(PE_IncompleteStmt, Nodes[I])
              else if ((NodePtr(Nodes[I + 2])^.NodeType <> ntToken) or (TokenPtr(Nodes[I + 2])^.OperatorType <> otAnd)) then
                SetError(PE_UnexpectedToken, Nodes[I + 2])
              else
              begin
                Nodes[I - 1] := TBetweenOp.Create(Self, Nodes[I], Nodes[I + 2], Nodes[I - 1], Nodes[I + 1], Nodes[I + 3]);
                Dec(NodeCount, 4);
                Move(Nodes[I + 4], Nodes[I], (NodeCount - I) * SizeOf(Nodes[0]));
                Dec(I);
              end;
            otDot:
              if (I = 0) then
                SetError(PE_UnexpectedToken, Nodes[I])
              else if (I >= NodeCount - 1) then
                SetError(PE_IncompleteStmt)
              else if ((NodeCount <= I + 2) or not IsToken(Nodes[I + 2]) or (TokenPtr(Nodes[I + 2])^.OperatorType <> otDot)) then
              begin // Db.Tbl or Tbl.Clmn
                TokenPtr(Nodes[I + 1])^.FUsageType := utDbIdent;
                Nodes[I - 1] := TDbIdent.Create(Self, ditColumn, Nodes[I + 1], 0, 0, Nodes[I], Nodes[I - 1]);
                Dec(NodeCount, 2);
                Move(Nodes[I + 2], Nodes[I], (NodeCount - I) * SizeOf(Nodes[0]));
                Dec(I);
              end
              else
              begin // Db.Tbl.Clmn
                TokenPtr(Nodes[I - 1])^.FUsageType := utDbIdent;
                TokenPtr(Nodes[I + 1])^.FUsageType := utDbIdent;
                TokenPtr(Nodes[I + 3])^.FUsageType := utDbIdent;
                Nodes[I - 1] := TDbIdent.Create(Self, ditColumn, Nodes[I + 3], Nodes[I], Nodes[I - 1], Nodes[I + 2], Nodes[I + 1]);
                Dec(NodeCount, 4);
                Move(Nodes[I + 4], Nodes[I], (NodeCount - I) * SizeOf(Nodes[0]));
                Dec(I);
              end;
            otEscape:
              SetError(PE_UnexpectedToken, Nodes[I]);
            otIn:
              if (NodeCount = I + 1) then
                SetError(PE_IncompleteStmt)
              else if (I = 0) then
                SetError(PE_UnexpectedToken, Nodes[0])
              else
              begin
                FillChar(InNodes, SizeOf(InNodes), 0);
                if (IsToken(Nodes[I - 1]) and (TokenPtr(Nodes[I - 1])^.OperatorType = otNot)) then
                begin
                  InNodes.NotToken := Nodes[I - 1];
                  if (I = 1) then
                    SetError(PE_UnexpectedToken, Nodes[0])
                  else
                    InNodes.Operand := Nodes[I - 2];
                end
                else
                  InNodes.Operand := Nodes[I - 1];
                InNodes.InToken := Nodes[I];
                InNodes.List := Nodes[I + 1];

                RemoveNodes := 2;
                if (InNodes.NotToken = 0) then
                  Dec(I)
                else
                begin
                  Dec(I, 2);
                  Inc(RemoveNodes);
                end;

                Nodes[I] := TInOp.Create(Self, InNodes);
                Dec(NodeCount, RemoveNodes);
                Move(Nodes[I + RemoveNodes + 1], Nodes[I + 1], (NodeCount - 1) * SizeOf(Nodes[0]));
              end;
            otLike:
              if (NodeCount = I + 1) then
                SetError(PE_IncompleteStmt)
              else if (I = 0) then
                SetError(PE_UnexpectedToken, Nodes[0])
              else
              begin
                FillChar(LikeNodes, SizeOf(LikeNodes), 0);
                if (IsToken(Nodes[I - 1]) and (TokenPtr(Nodes[I - 1])^.OperatorType = otNot)) then
                begin
                  LikeNodes.NotToken := Nodes[I - 1];
                  if (I = 1) then
                    SetError(PE_UnexpectedToken, Nodes[0])
                  else
                    LikeNodes.Operand1 := Nodes[I - 2];
                end
                else
                  LikeNodes.Operand1 := Nodes[I - 1];
                LikeNodes.LikeToken := Nodes[I];
                LikeNodes.Operand2 := Nodes[I + 1];
                if ((NodeCount >= I + 3) and IsToken(Nodes[I + 2]) and (TokenPtr(Nodes[I + 2])^.OperatorType = otEscape)) then
                begin
                  if (NodeCount = I + 3) then
                    SetError(PE_IncompleteStmt);
                  LikeNodes.EscapeToken := Nodes[I + 1];
                  LikeNodes.EscapeCharToken := Nodes[I + 2];
                end;

                RemoveNodes := 2;
                if (LikeNodes.NotToken = 0) then
                  Dec(I)
                else
                begin
                  Dec(I, 2);
                  Inc(RemoveNodes);
                end;
                if (LikeNodes.EscapeCharToken > 0) then Inc(RemoveNodes, 2);

                Nodes[I] := TLikeOp.Create(Self, LikeNodes);
                Dec(NodeCount, RemoveNodes);
                Move(Nodes[I + RemoveNodes + 1], Nodes[I + 1], (NodeCount - 1) * SizeOf(Nodes[0]));
              end;
            otRegExp:
              if (NodeCount = I + 1) then
                SetError(PE_IncompleteStmt)
              else if (I = 0) then
                SetError(PE_UnexpectedToken, Nodes[0])
              else
              begin
                FillChar(RegExpNodes, SizeOf(RegExpNodes), 0);
                if (IsToken(Nodes[I - 1]) and (TokenPtr(Nodes[I - 1])^.OperatorType = otNot)) then
                begin
                  RegExpNodes.NotToken := Nodes[I - 1];
                  if (I = 1) then
                    SetError(PE_UnexpectedToken, Nodes[0])
                  else
                    RegExpNodes.Operand1 := Nodes[I - 2];
                end
                else
                  RegExpNodes.Operand1 := Nodes[I - 1];
                RegExpNodes.RegExpToken := Nodes[I];
                RegExpNodes.Operand2 := Nodes[I + 1];

                RemoveNodes := 2;
                if (RegExpNodes.NotToken = 0) then
                  Dec(I)
                else
                begin
                  Dec(I, 2);
                  Inc(RemoveNodes);
                end;

                Nodes[I] := TRegExpOp.Create(Self, RegExpNodes);
                Dec(NodeCount, RemoveNodes);
                Move(Nodes[I + RemoveNodes + 1], Nodes[I + 1], (NodeCount - 1) * SizeOf(Nodes[0]));
              end;
            otSounds:
              if (NodeCount - 1 < I + 2) then
                SetError(PE_IncompleteStmt, Nodes[I])
              else if ((NodePtr(Nodes[I + 1])^.NodeType <> ntToken) or (TokenPtr(Nodes[I + 1])^.OperatorType <> otLike)) then
                SetError(PE_UnexpectedToken, Nodes[I + 1])
              else
              begin
                Nodes[I + 2] := TSoundsLikeOp.Create(Self, Nodes[I], Nodes[I + 1], Nodes[I - 1], Nodes[I + 2]);
                Dec(NodeCount, 3);
                Move(Nodes[I + 2], Nodes[I - 1], (NodeCount - I) * SizeOf(Nodes[0]));
                Dec(I);
              end;
            else
              case (NodePtr(Nodes[I])^.FNodeType) of
                ntToken: SetError(PE_UnexpectedToken, Nodes[I]);
                ntRange: SetError(PE_UnexpectedToken, RangeNodePtr(Nodes[I])^.FFirstToken);
                else raise ERangeError.Create(SArgumentOutOfRange);
              end;
        end;
    end;

  if (not Error and (NodeCount <> 1)) then
    SetError(PE_Unknown);

  if (not Error and IsToken(Nodes[0]) and (TokenPtr(Nodes[0])^.TokenType in ttIdents)) then
    Nodes[0] := TDbIdent.Create(Self, ditColumn, Nodes[0], 0, 0, 0, 0);

  Result := Nodes[0];
end;

function TMySQLParser.ParseExtractFunc(): TOffset;
var
  Nodes: TExtractFunc.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.FuncToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.UnitTag := ParseIdent();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiFROM) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.FromTag := ParseTag(kiFROM);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.DateExpr := ParseExpr();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TExtractFunc.Create(Self, Nodes);
end;

function TMySQLParser.ParseFetchStmt(): TOffset;
var
  Nodes: TFetchStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiFETCH);

  if (not Error) then
    if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiNEXT)
      and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiFROM)) then
      Nodes.FromTag := ParseTag(kiNEXT, kiFROM)
    else if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM)) then
      Nodes.FromTag := ParseTag(kiFROM);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CursorIdent := ParseDbIdent(ditCursor);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiINTO) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.IntoTag := ParseTag(kiINTO);

  if (not Error) then
    Nodes.VariableList := ParseList(False, ParseVariable);

  Result := TFetchStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseFlushStmt(): TOffset;
var
  Nodes: TFlushStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiFLUSH);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiNO_WRITE_TO_BINLOG) then
      Nodes.NoWriteToBinLogTag := ParseTag(kiNO_WRITE_TO_BINLOG)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCAL) then
      Nodes.NoWriteToBinLogTag := ParseTag(kiLOCAL);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.OptionList := ParseList(False, ParseFlushStmtOption);

  Result := TFlushStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseFlushStmtOption(): TOffset;
var
  Nodes: TFlushStmt.TOption.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiPRIVILEGES) then
    Nodes.OptionTag := ParseTag(kiPRIVILEGES)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSTATUS) then
    Nodes.OptionTag := ParseTag(kiSTATUS)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiTABLE)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiTABLES)) then
  begin
    Nodes.OptionTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

    if (not Error and not EndOfStmt(CurrentToken)) then
      Nodes.TablesList := ParseList(False, ParseTableIdent);
  end
  else
    SetError(PE_UnexpectedToken);

  Result := TFlushStmt.TOption.Create(Self, Nodes);
end;

function TMySQLParser.ParseForeignKeyIdent(): TOffset;
begin
  Result := ParseDbIdent(ditForeignKey);
end;

function TMySQLParser.ParseFunctionCall(): TOffset;
var
  Nodes: TFunctionCall.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if ((FunctionList.Count = 0) or (FunctionList.IndexOf(TokenPtr(CurrentToken)^.SQL, TokenPtr(CurrentToken)^.Length) >= 0)) then
    Nodes.Ident := ApplyCurrentToken(utFunction)
  else
    Nodes.Ident := ParseFunctionIdent();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ArgumentsList := ParseList(True, ParseExpr);

  Result := TFunctionCall.Create(Self, Nodes);
end;

function TMySQLParser.ParseFunctionIdent(): TOffset;
begin
  Result := ParseDbIdent(ditFunction);
end;

function TMySQLParser.ParseFunctionParam(): TOffset;
var
  Nodes: TRoutineParam.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
    SetError(PE_UnexpectedToken)
  else
    Nodes.IdentToken := ParseDbIdent(ditParameter);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.DataTypeNode := ParseDataType();

  Result := TRoutineParam.Create(Self, Nodes);
end;

function TMySQLParser.ParseFunctionReturns(): TOffset;
var
  Nodes: TFunctionReturns.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.ReturnsTag := ParseTag(kiRETURNS);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.DataTypeNode := ParseDataType();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARSET)) then
    Nodes.CharsetValue := ParseValue(kiCHARSET, vaNO, ParseIdent);

  Result := TFunctionReturns.Create(Self, Nodes);
end;

function TMySQLParser.ParseGetDiagnosticsStmt(): TOffset;
var
  Nodes: TGetDiagnosticsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiGET);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCURRENT) or (TokenPtr(CurrentToken)^.KeywordIndex = kiSTACKED)) then
      Nodes.ScopeTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiDIAGNOSTICS) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.DiagnosticsTag := ParseTag(kiDIAGNOSTICS);

  if (not Error) then
    if (EndOfStmt(CurrentToken) or (TokenPtr(CurrentToken)^.KeywordIndex <> kiCONDITION)) then
      Nodes.InfoList := ParseList(False, ParseGetDiagnosticsStmtStmtInfo)
    else
    begin
      Nodes.ConditionTag := ParseTag(kiCONDITION);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.ConditionNumber := ParseExpr();

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.InfoList := ParseList(False, ParseGetDiagnosticsStmtConditionInfo)
    end;

  Result := TGetDiagnosticsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseGetDiagnosticsStmtStmtInfo(): TOffset;
var
  Nodes: TGetDiagnosticsStmt.TStmtInfo.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.Target := ParseVariable();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType <> otEqual) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.EqualOp := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiNUMBER)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiROW_COUNT)) then
      Nodes.ItemTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex)
    else
      SetError(PE_UnexpectedToken);

  Result := TGetDiagnosticsStmt.TStmtInfo.Create(Self, Nodes);
end;

function TMySQLParser.ParseGetDiagnosticsStmtConditionInfo(): TOffset;
var
  Nodes: TGetDiagnosticsStmt.TConditionalInfo.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.Target := ParseVariable();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType <> otEqual) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.EqualOp := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCLASS_ORIGIN)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiSUBCLASS_ORIGIN)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiRETURNED_SQLSTATE)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiMESSAGE_TEXT)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiMYSQL_ERRNO)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiCONSTRAINT_CATALOG)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiCONSTRAINT_SCHEMA)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiCONSTRAINT_NAME)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiCATALOG_NAME)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiSCHEMA_NAME)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiTABLE_NAME)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLUMN_NAME)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiCURSOR_NAME)) then
      Nodes.ItemTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex)
    else
      SetError(PE_UnexpectedToken);

  Result := TGetDiagnosticsStmt.TConditionalInfo.Create(Self, Nodes);
end;

function TMySQLParser.ParseGrantStmt(): TOffset;
var
  GrantOptionHandled: Boolean;
  ListNodes: TList.TNodes;
  MaxQueriesPerHourHandled: Boolean;
  MaxUpdatesPerHourHandled: Boolean;
  MaxConnectionsPerHourHandled: Boolean;
  MaxUserConnectionsHandled: Boolean;
  Nodes: TGrantStmt.TNodes;
  Resources: array of TOffset;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiGRANT);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_UnexpectedToken)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiPROXY) then
    begin
      Nodes.PrivilegesList := ParseList(False, ParseGrantStmtPrivileg);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiON) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.OnTag := ParseTag(kiON);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex = kiTABLE) then
          Nodes.ObjectValue := ParseValue(kiTABLE, vaNo, ParseTableIdent)
        else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFUNCTION) then
          Nodes.ObjectValue := ParseValue(kiFUNCTION, vaNo, ParseFunctionIdent)
        else if (TokenPtr(CurrentToken)^.KeywordIndex = kiPROCEDURE) then
          Nodes.ObjectValue := ParseValue(kiPROCEDURE, vaNo, ParseProcedureIdent)
        else
          Nodes.ObjectValue := ParseTableIdent();

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiTO) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.ToTag := ParseTag(kiTO);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.UserSpecifications := ParseList(False, ParseGrantStmtUserSpecification);

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWITH)) then
      begin
        GrantOptionHandled := False;
        MaxQueriesPerHourHandled := False;
        MaxUpdatesPerHourHandled := False;
        MaxConnectionsPerHourHandled := False;
        MaxUserConnectionsHandled := False;

        SetLength(Resources, 0);

        Nodes.WithTag := ParseTag(kiWITH);

        repeat
          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiGRANT) and not GrantOptionHandled) then
          begin
            SetLength(Resources, Length(Resources) + 1);
            Resources[Length(Resources) - 1] := ParseTag(kiGRANT, kiOPTION);
            GrantOptionHandled := True;
          end
          else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_QUERIES_PER_HOUR) and not MaxQueriesPerHourHandled) then
          begin
            SetLength(Resources, Length(Resources) + 1);
            Resources[Length(Resources) - 1] := ParseValue(kiMAX_QUERIES_PER_HOUR, vaNo, ParseInteger);
            MaxQueriesPerHourHandled := False;
          end
          else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_UPDATES_PER_HOUR) and not MaxUpdatesPerHourHandled) then
          begin
            SetLength(Resources, Length(Resources) + 1);
            Resources[Length(Resources) - 1] := ParseValue(kiMAX_UPDATES_PER_HOUR, vaNo, ParseInteger);
            MaxUpdatesPerHourHandled := True;
          end
          else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_CONNECTIONS_PER_HOUR) and not MaxConnectionsPerHourHandled) then
          begin
            SetLength(Resources, Length(Resources) + 1);
            Resources[Length(Resources) - 1] := ParseValue(kiMAX_CONNECTIONS_PER_HOUR, vaNo, ParseInteger);
            MaxConnectionsPerHourHandled := True;
          end
          else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_USER_CONNECTIONS) and not MaxUserConnectionsHandled) then
          begin
            SetLength(Resources, Length(Resources) + 1);
            Resources[Length(Resources) - 1] := ParseValue(kiMAX_USER_CONNECTIONS, vaNo, ParseInteger);
            MaxUserConnectionsHandled := True;
          end
          else
            SetError(PE_UnexpectedToken);
        until (Error or EndOfStmt(CurrentToken));

        FillChar(ListNodes, SizeOf(ListNodes), 0);
        Nodes.ResourcesList := TList.Create(Self, ListNodes, Length(Resources), Resources);
      end;
    end
    else
    begin
      Nodes.PrivilegesList := ParseTag(kiPROXY);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiON) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.OnTag := ParseTag(kiON);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.OnUser := ParseUserIdent();

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiTO) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.ToTag := ParseTag(kiTO);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.UserSpecifications := ParseList(False, ParseGrantStmtUserSpecification);

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWITH)) then
        Nodes.WithTag := ParseTag(kiWITH, kiGRANT, kiOPTION);
    end;

  Result := TGrantStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseGrantStmtPrivileg(): TOffset;
var
  Nodes: TGrantStmt.TPrivileg.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiALL)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiPRIVILEGES)) then
    Nodes.PrivilegTag := ParseTag(kiALL, kiPRIVILEGES)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiALL) then
    Nodes.PrivilegTag := ParseTag(kiALL)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiALTER)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiROUTINE)) then
    Nodes.PrivilegTag := ParseTag(kiALTER, kiROUTINE)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiALTER) then
    Nodes.PrivilegTag := ParseTag(kiALTER)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCREATE)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiROUTINE)) then
    Nodes.PrivilegTag := ParseTag(kiCREATE, kiROUTINE)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCREATE)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiTABLESPACE)) then
    Nodes.PrivilegTag := ParseTag(kiCREATE, kiTABLESPACE)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCREATE)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiTEMPORARY)
    and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiTABLES)) then
    Nodes.PrivilegTag := ParseTag(kiCREATE, kiTEMPORARY, kiTABLES)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCREATE)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiUSER)) then
    Nodes.PrivilegTag := ParseTag(kiCREATE, kiUSER)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCREATE)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiVIEW)) then
    Nodes.PrivilegTag := ParseTag(kiCREATE, kiVIEW)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCREATE) then
    Nodes.PrivilegTag := ParseTag(kiCREATE)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiDELETE) then
    Nodes.PrivilegTag := ParseTag(kiDELETE)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiDROP) then
    Nodes.PrivilegTag := ParseTag(kiDROP)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiEVENT) then
    Nodes.PrivilegTag := ParseTag(kiEVENT)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiEXECUTE) then
    Nodes.PrivilegTag := ParseTag(kiEXECUTE)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFILE) then
    Nodes.PrivilegTag := ParseTag(kiFILE)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiGRANT)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiOPTION)) then
    Nodes.PrivilegTag := ParseTag(kiGRANT, kiOPTION)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiINDEX) then
    Nodes.PrivilegTag := ParseTag(kiINDEX)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiINSERT) then
    Nodes.PrivilegTag := ParseTag(kiINSERT)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiLOCK)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiTABLES)) then
    Nodes.PrivilegTag := ParseTag(kiLOCK, kiTABLES)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiPROCESS) then
    Nodes.PrivilegTag := ParseTag(kiPROCESS)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiPROXY) then
    Nodes.PrivilegTag := ParseTag(kiPROXY)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiREFERENCES) then
    Nodes.PrivilegTag := ParseTag(kiREFERENCES)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiRELOAD) then
    Nodes.PrivilegTag := ParseTag(kiRELOAD)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiREPLICATION)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCLIENT)) then
    Nodes.PrivilegTag := ParseTag(kiREPLICATION, kiCLIENT)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiREPLICATION)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSLAVE)) then
    Nodes.PrivilegTag := ParseTag(kiREPLICATION, kiSLAVE)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSELECT) then
    Nodes.PrivilegTag := ParseTag(kiSELECT)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiSHOW)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiDATABASES)) then
    Nodes.PrivilegTag := ParseTag(kiSHOW, kiDATABASES)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiSHOW)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiVIEW)) then
    Nodes.PrivilegTag := ParseTag(kiSHOW, kiVIEW)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSHUTDOWN) then
    Nodes.PrivilegTag := ParseTag(kiSHUTDOWN)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSUPER) then
    Nodes.PrivilegTag := ParseTag(kiSUPER)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiTRIGGER) then
    Nodes.PrivilegTag := ParseTag(kiTRIGGER)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUPDATE) then
    Nodes.PrivilegTag := ParseTag(kiUPDATE)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUSAGE) then
    Nodes.PrivilegTag := ParseTag(kiUSAGE)
  else
    SetError(PE_UnexpectedToken);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
    Nodes.PrivilegTag := ParseList(True, ParseColumnIdent);

  Result := TGrantStmt.TPrivileg.Create(Self, Nodes);
end;

function TMySQLParser.ParseGrantStmtUserSpecification(): TOffset;
var
  Nodes: TGrantStmt.TUserSpecification.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.UserIdent := ParseUserIdent();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIDENTIFIED)) then
  begin
    if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiBY)) then
    begin
      if (EndOfStmt(NextToken[2]) or (TokenPtr(NextToken[2])^.KeywordIndex <> kiPASSWORD)) then
        Nodes.IdentifiedToken := ParseTag(kiIDENTIFIED, kiBY)
      else
        Nodes.IdentifiedToken := ParseTag(kiIDENTIFIED, kiBY, kiPASSWORD);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType = ttString) then
          Nodes.AuthString := ParseString()
        else if ((TokenPtr(CurrentToken)^.OperatorType = otLess)
          and not EndOfStmt(NextToken[2])
          and (TokenPtr(NextToken[1])^.TokenType = ttIdent)
          and (TokenPtr(NextToken[2])^.OperatorType = otGreater)) then
          Nodes.AuthString := ParseSecretIdent()
        else
          SetError(PE_UnexpectedToken);
    end
    else if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiWITH)) then
    begin
      Nodes.IdentifiedToken := ParseTag(kiIDENTIFIED, kiWITH);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType = ttIdent) then
          Nodes.PluginIdent := ParseIdent()
        else if (TokenPtr(CurrentToken)^.TokenType = ttString) then
          Nodes.PluginIdent := ParseString()
        else
          SetError(PE_UnexpectedToken);

      if (not Error and not EndOfStmt(CurrentToken)) then
        if (TokenPtr(CurrentToken)^.KeywordIndex = kiAS) then
        begin
          Nodes.AsToken := ParseTag(kiAS);

          if (not Error) then
            if (EndOfStmt(CurrentToken)) then
              SetError(PE_IncompleteStmt)
            else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
              SetError(PE_UnexpectedToken)
            else
              Nodes.AuthString := ParseString();
        end
        else if (TokenPtr(CurrentToken)^.KeywordIndex = kiAS) then
        begin
          Nodes.AsToken := ParseTag(kiAS);

          if (not Error) then
            if (EndOfStmt(CurrentToken)) then
              SetError(PE_IncompleteStmt)
            else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
              SetError(PE_UnexpectedToken)
            else
              Nodes.AuthString := ParseString();
        end;
    end;
  end;

  Result := TGrantStmt.TUserSpecification.Create(Self, Nodes);
end;

function TMySQLParser.ParseGroupConcatFunc(): TOffset;
var
  Nodes: TGroupConcatFunc.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.FuncToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error) then
    if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDISTINCT)) then
      Nodes.DistinctTag := ParseTag(kiDISTINCT);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ExprList := ParseList(False, ParseExpr);

  if (not Error) then
    if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiORDER)) then
    begin
      Nodes.OrderByTag := ParseTag(kiORDER, kiBY);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.OrderByExprList := ParseList(False, ParseGroupConcatFuncExpr);
    end;

  if (not Error) then
    if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSEPARATOR)) then
      Nodes.SeparatorValue := ParseValue(kiSEPARATOR, vaNo, ParseString);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TGroupConcatFunc.Create(Self, Nodes);
end;

function TMySQLParser.ParseGroupConcatFuncExpr(): TOffset;
var
  Nodes: TGroupConcatFunc.TExpr.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.Expr := ParseExpr();

  if (not Error and not EndOfStmt(CurrentToken) and ((TokenPtr(CurrentToken)^.KeywordIndex = kiASC) or (TokenPtr(CurrentToken)^.KeywordIndex = kiDESC))) then
    Nodes.Direction := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

  Result := TGroupConcatFunc.TExpr.Create(Self, Nodes);
end;

function TMySQLParser.ParseHelpStmt(): TOffset;
var
  Nodes: THelpStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiHELP);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.HelpString := ParseString();

  Result := THelpStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseIdent(): TOffset;
begin
  Result := 0;
  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
    SetError(PE_UnexpectedToken)
  else
    Result := ApplyCurrentToken();
end;

function TMySQLParser.ParseIfStmt(): TOffset;
var
  Branches: array of TOffset;
  ListNodes: TList.TNodes;
  Nodes: TIfStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  SetLength(Branches, 1);
  Branches[0] := ParseIfStmtBranch();

  while (not Error) do
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiELSEIF) then
    begin
      SetLength(Branches, Length(Branches) + 1);
      Branches[Length(Branches) - 1] := ParseIfStmtBranch();
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiELSE) then
    begin
      SetLength(Branches, Length(Branches) + 1);
      Branches[Length(Branches) - 1] := ParseIfStmtBranch();
      break;
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiEND) then
      break
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    Nodes.EndTag := ParseTag(kiEND, kiIF);

  FillChar(ListNodes, SizeOf(ListNodes), 0);
  Nodes.BranchList := TList.Create(Self, ListNodes, Length(Branches), Branches);
  SetLength(Branches, 0);

  Result := TIfStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseIfStmtBranch(): TOffset;
var
  Nodes: TIfStmt.TBranch.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(CurrentToken)^.KeywordIndex = kiIF) then
  begin
    Nodes.Tag := ParseTag(kiIF);

    if (not Error) then
      Nodes.ConditionExpr := ParseExpr();

    if (not Error) then
      Nodes.ThenTag := ParseTag(kiTHEN);
  end
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiELSEIF) then
  begin
    Nodes.Tag := ParseTag(kiELSEIF);

    if (not Error) then
      Nodes.ConditionExpr := ParseExpr();

    if (not Error) then
      Nodes.ThenTag := ParseTag(kiTHEN);
  end
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiELSE) then
    Nodes.Tag := ParseTag(kiELSE)
  else
    SetError(PE_UnexpectedToken);

  if (not Error) then
    Nodes.StmtList := ParseList(False, ParsePL_SQLStmt, ttDelimiter);

  Result := TIfStmt.TBranch.Create(Self, Nodes);
end;

function TMySQLParser.ParseIndexHint(): TOffset;
var
  Nodes: TSelectStmt.TTableFactor.TIndexHint.TNodes;
  ValueNodes: TValue.TNodes;
  Use: Boolean;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Use := not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUSE);

  if (EndOfStmt(NextToken[1])) then
    SetError(PE_IncompleteStmt)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex <> kiUSE) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiIGNORE) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiFORCE)) then
    SetError(PE_UnexpectedToken)
  else if ((TokenPtr(NextToken[1])^.KeywordIndex <> kiINDEX) and (TokenPtr(NextToken[1])^.KeywordIndex <> kiKEY)) then
    SetError(PE_UnexpectedToken, NextToken[1])
  else
    Nodes.KindTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex, TokenPtr(NextToken[1])^.KeywordIndex);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFOR)) then
  begin
    FillChar(ValueNodes, SizeOf(ValueNodes), 0);

    ValueNodes.IdentTag := ParseTag(kiFOR);

    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiJOIN) then
      ValueNodes.ValueToken := ParseTag(kiJOIN)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiORDER) then
      ValueNodes.ValueToken := ParseTag(kiORDER, kiBY)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiGROUP) then
      ValueNodes.ValueToken := ParseTag(kiGROUP, kiBY)
    else
      SetError(PE_UnexpectedToken);

    Nodes.ForValue := TValue.Create(Self, ValueNodes);
  end;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (Use and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket) and (TokenPtr(NextToken[1])^.TokenType = ttCloseBracket)) then
      Nodes.IndexList := ParseList(True)
    else
      Nodes.IndexList := ParseList(True, ParseKeyIdent);

  Result := TSelectStmt.TTableFactor.TIndexHint.Create(Self, Nodes);
end;

function TMySQLParser.ParseInsertStmt(const Replace: Boolean = False): TOffset;
var
  Nodes: TInsertStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.InsertTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOW_PRIORITY) then
      Nodes.PriorityTag := ParseTag(kiLOW_PRIORITY)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiDELAYED) then
      Nodes.PriorityTag := ParseTag(kiDELAYED)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiHIGH_PRIORITY) then
      Nodes.PriorityTag := ParseTag(kiHIGH_PRIORITY);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIGNORE)) then
    Nodes.IgnoreTag := ParseTag(kiIGNORE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiINTO)) then
    Nodes.IntoTag := ParseTag(kiINTO);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.TableIdent := ParseTableIdent();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPARTITION)) then
  begin
    Nodes.PartitionTag := ParseTag(kiPARTITION);

    if (not Error) then
      Nodes.PartitionList := ParseList(True, ParseCreateTableStmtPartitionIdent);
  end;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSET) then
    begin
      Nodes.SetTag := ParseTag(kiSET);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.ValuesList := ParseList(False, ParseInsertStmtSetItemsList);
    end
    else
    begin
      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
        Nodes.ColumnList := ParseList(True, ParseColumnIdent);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiVALUES) or (TokenPtr(CurrentToken)^.KeywordIndex = kiVALUE)) then
        begin
          Nodes.ValuesTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

          if (not Error) then
            if (EndOfStmt(CurrentToken)) then
              SetError(PE_IncompleteStmt)
            else
              Nodes.ValuesList := ParseList(False, ParseInsertStmtValuesList);
        end
        else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSELECT) then
          Nodes.SelectStmt := ParseSelectStmt()
        else
          SetError(PE_UnexpectedToken);
    end;

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiON)) then
  begin
    Nodes.OnDuplicateKeyUpdateTag := ParseTag(kiON, kiDUPLICATE, kiKEY, kiUPDATE);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.UpdateList := ParseList(False, ParseUpdatePair);
  end;

  Result := TInsertStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseInsertStmtSetItemsList(): TOffset;
var
  Nodes: TInsertStmt.TSetItem.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else
    Nodes.FieldToken := ParseColumnIdent();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType <> otEqual) then
      SetError(PE_UnexpectedToken)
    else
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();
    end;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ValueNode := ParseExpr();

  Result := TInsertStmt.TSetItem.Create(Self, Nodes);
end;

function TMySQLParser.ParseInsertStmtValuesList(): TOffset;
begin
  Result := ParseList(True, ParseExpr);
end;

function TMySQLParser.ParseInteger(): TOffset;
begin
  Result := 0;
  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.TokenType <> ttInteger) then
    SetError(PE_UnexpectedToken)
  else
    Result := ApplyCurrentToken();
end;

function TMySQLParser.ParseIntervalOp(): TOffset;
var
  Nodes: TIntervalOp.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.QuantityExp := ParseExpr();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex <> kiDAY)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiDAY_HOUR)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiDAY_MINUTE)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiDAY_SECOND)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiHOUR)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiHOUR_MINUTE)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiHOUR_SECOND)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiMICROSECOND)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiMINUTE)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiMINUTE_SECOND)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiMONTH)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiQUARTER)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiSECOND)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiWEEK)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiYEAR)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiYEAR_MONTH)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.UnitTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

  Result := TIntervalOp.Create(Self, Nodes);
end;

function TMySQLParser.ParseIntervalOpList(): TIntervalList;
var
  Day: Boolean;
  DayHour: Boolean;
  DayMinute: Boolean;
  DaySecond: Boolean;
  Found: Boolean;
  Hour: Boolean;
  HourMinute: Boolean;
  HourSecond: Boolean;
  I: Integer;
  Index: Integer;
  Minute: Boolean;
  MinuteSecond: Boolean;
  Month: Boolean;
  Quarter: Boolean;
  Second: Boolean;
  Week: Boolean;
  Year: Boolean;
  YearMonth: Boolean;
begin
  for I := 0 to Length(Result) - 1 do
    Result[I] := 0;

  Day := False;
  DayHour := False;
  DayMinute := False;
  DaySecond := False;
  Hour := False;
  HourMinute := False;
  HourSecond := False;
  Minute := False;
  MinuteSecond := False;
  Month := False;
  Quarter := False;
  Second := False;
  Week := False;
  Year := False;
  YearMonth := False;
  Found := True;
  Index := 0;
  while (not Error and Found and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.OperatorType = otPlus)) do
    if (Index = Length(Result)) then
      raise Exception.Create(SArgumentOutOfRange)
    else if (EndOfStmt(NextToken[1])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[1])^.KeywordIndex <> kiINTERVAL) then
      SetError(PE_UnexpectedToken, NextToken[1])
    else if (EndOfStmt(NextToken[3])) then
      SetError(PE_IncompleteStmt)
    else if (not Year and (TokenPtr(NextToken[3])^.KeywordIndex = kiYEAR)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      Year := True;
      Found := True;
    end
    else if (not Quarter and (TokenPtr(NextToken[3])^.KeywordIndex = kiQUARTER)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      Quarter := True;
      Found := True;
    end
    else if (not MONTH and (TokenPtr(NextToken[3])^.KeywordIndex = kiMONTH)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      Month := True;
      Found := True;
    end
    else if (not Day and (TokenPtr(NextToken[3])^.KeywordIndex = kiDAY)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      Day := True;
      Found := True;
    end
    else if (not Hour and (TokenPtr(NextToken[3])^.KeywordIndex = kiHOUR)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      Hour := True;
      Found := True;
    end
    else if (not Minute and (TokenPtr(NextToken[3])^.KeywordIndex = kiMINUTE)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      Minute := True;
      Found := True;
    end
    else if (not Week and (TokenPtr(NextToken[3])^.KeywordIndex = kiWEEK)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      Week := True;
      Found := True;
    end
    else if (not Second and (TokenPtr(NextToken[3])^.KeywordIndex = kiSECOND)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      Second := True;
      Found := True;
    end
    else if (not YearMonth and (TokenPtr(NextToken[3])^.KeywordIndex = kiYEAR_MONTH)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      YearMonth := True;
      Found := True;
    end
    else if (not DayHour and (TokenPtr(NextToken[3])^.KeywordIndex = kiDAY_HOUR)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      DayHour := True;
      Found := True;
    end
    else if (not DayMinute and (TokenPtr(NextToken[3])^.KeywordIndex = kiDAY_MINUTE)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      DayMinute := True;
      Found := True;
    end
    else if (not DaySecond and (TokenPtr(NextToken[3])^.KeywordIndex = kiDAY_SECOND)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      DaySecond := True;
      Found := True;
    end
    else if (not HourMinute and (TokenPtr(NextToken[3])^.KeywordIndex = kiHOUR_MINUTE)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      HourMinute := True;
      Found := True;
    end
    else if (not HourSecond and (TokenPtr(NextToken[3])^.KeywordIndex = kiHOUR_SECOND)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      HourSecond := True;
      Found := True;
    end
    else if (not MinuteSecond and (TokenPtr(NextToken[3])^.KeywordIndex = kiMINUTE_SECOND)) then
    begin
      Result[Index] := ParseIntervalOpListItem();
      Inc(Index);
      MinuteSecond := True;
      Found := True;
    end
    else
      Found := False;
end;

function TMySQLParser.ParseIntervalOpListItem(): TOffset;
var
  Nodes: TIntervalOp.TListItem.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.OperatorType <> otPlus) then
    SetError(PE_UnexpectedToken)
  else
    Nodes.PlusToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiINTERVAL) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.IntervalTag := ParseTag(kiINTERVAL);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Interval := ParseIntervalOp();

  Result := TIntervalOp.TListItem.Create(Self, Nodes);
end;

function TMySQLParser.ParseIterateStmt(): TOffset;
var
  Nodes: TIterateStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IterateToken := ParseTag(kiITERATE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.LabelToken := ApplyCurrentToken(utLabel);

  Result := TIterateStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseKeyIdent(): TOffset;
begin
  Result := ParseDbIdent(ditKey);
end;

function TMySQLParser.ParseKeyword(): TOffset;
begin
  Result := 0;
  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex < 0) then
    SetError(PE_UnexpectedToken)
  else
    Result := ApplyCurrentToken();
end;

function TMySQLParser.ParseKillStmt(): TOffset;
var
  Nodes: TKillStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(NextToken[1])) then
    Nodes.StmtTag := ParseTag(kiKILL)
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiCONNECTION) then
    Nodes.StmtTag := ParseTag(kiKILL, kiCONNECTION)
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiQUERY) then
    Nodes.StmtTag := ParseTag(kiKILL, kiQUERY)
  else
    Nodes.StmtTag := ParseTag(kiKILL);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ProcessIdToken := ParseExpr();

  Result := TKillStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseLeaveStmt(): TOffset;
var
  Nodes: TLeaveStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiLEAVE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.LabelToken := ApplyCurrentToken(utLabel);

  Result := TLeaveStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseList(const Brackets: Boolean; const ParseItem: TParseFunction = nil; const DelimterType: fspTypes.TTokenType = ttComma): TOffset;
var
  ChildrenArray: array [0 .. 100 - 1] of TOffset;
  ChildrenList: Classes.TList;
  DelimiterFound: Boolean;
  I: Integer;
  Index: Integer;
  Nodes: TList.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  ChildrenList := nil;

  if (Brackets) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OpenBracket := ApplyCurrentToken();

  Index := 0;
  if (not Error and Assigned(ParseItem) and (not Brackets or not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket))) then
  begin
    repeat
      if (Index < Length(ChildrenArray)) then
      begin
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          ChildrenArray[Index] := ParseItem();
        if (Index = 0) then
          Nodes.FirstChild := ChildrenArray[Index];
      end
      else
      begin
        if (Index = Length(ChildrenArray)) then
        begin
          ChildrenList := Classes.TList.Create();
          for I := 0 to Length(ChildrenArray) - 1 do
            ChildrenList.Add(Pointer(ChildrenArray[I]));
        end;
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          ChildrenList.Add(Pointer(ParseItem()));
      end;
      Inc(Index);

      DelimiterFound := (CurrentToken > 0) and (TokenPtr(CurrentToken)^.TokenType = DelimterType);
      if (not Error and DelimiterFound) then
      begin
        if (Index < Length(ChildrenArray)) then
          ChildrenArray[Index] := ApplyCurrentToken() // Delimiter
        else
        begin
          if (Index = Length(ChildrenArray)) then
          begin
            ChildrenList := Classes.TList.Create();
            for I := 0 to Length(ChildrenArray) - 1 do
              ChildrenList.Add(Pointer(ChildrenArray[I]));
          end;
          ChildrenList.Add(Pointer(ApplyCurrentToken()));  // Delimiter
        end;
        Inc(Index);
      end;
    until (Error or EndOfStmt(CurrentToken) or not DelimiterFound
      or ((DelimterType = ttDelimiter) and
        ((TokenPtr(CurrentToken)^.KeywordIndex = kiELSE)
          or (TokenPtr(CurrentToken)^.KeywordIndex = kiELSEIF)
          or (TokenPtr(CurrentToken)^.KeywordIndex = kiUNTIL)
          or (TokenPtr(CurrentToken)^.KeywordIndex = kiWHEN)
          or (TokenPtr(CurrentToken)^.KeywordIndex = kiEND))));

    if (not Error and DelimiterFound and EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt);
  end;

  Nodes.DelimiterType := DelimterType;

  if (not Error and Brackets) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  if (not Assigned(ChildrenList)) then
    Result := TList.Create(Self, Nodes, Index, ChildrenArray)
  else
  begin
    Result := TList.Create(Self, Nodes, ChildrenList.Count, TIntegerArray(ChildrenList.List));
    ChildrenList.Free();
  end;
end;

function TMySQLParser.ParseLoadDataStmt(): TOffset;
var
  Nodes: TLoadDataStmt.TNodes;
  IgnoreLinesNodes: TIgnoreLines.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.LoadDataTag := ParseTag(kiLOAD, kiDATA);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOW_PRIORITY) then
      Nodes.PriorityTag := ParseTag(kiLOW_PRIORITY)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCONCURRENT) then
      Nodes.PriorityTag := ParseTag(kiCONCURRENT);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCAL) then
      Nodes.InfileTag := ParseTag(kiLOCAL, kiINFILE)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiINFILE) then
      Nodes.InfileTag := ParseTag(kiINFILE)
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.FilenameString := ParseString();

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiREPLACE) then
      Nodes.ReplaceIgnoreTag := ParseTag(kiREPLACE)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIGNORE) then
      Nodes.ReplaceIgnoreTag := ParseTag(kiIGNORE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.IntoTableValue := ParseValue(WordIndices(kiINTO, kiTABLE), vaNo, ParseTableIdent);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPARTITION)) then
    Nodes.PartitionValue := ParseValue(kiPARTITION, vaNo, True, ParseCreateTableStmtPartitionIdent);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARACTER)) then
    Nodes.CharacterSetValue := ParseValue(WordIndices(kiCHARACTER, kiSET), vaNo, ParseIdent);

  if (not Error and not EndOfStmt(CurrentToken) and ((TokenPtr(CurrentToken)^.KeywordIndex = kiFIELDS) or (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLUMNS)))then
  begin
    Nodes.ColumnsTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiTERMINATED)) then
      Nodes.ColumnsTerminatedByValue := ParseValue(WordIndices(kiTERMINATED, kiBY), vaNo, ParseString);

    if (not Error and not EndOfStmt(CurrentToken)) then
      if (TokenPtr(CurrentToken)^.KeywordIndex = kiOPTIONALLY) then
        Nodes.EnclosedByValue := ParseValue(WordIndices(kiOPTIONALLY, kiENCLOSED, kiBY), vaNo, ParseString)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiENCLOSED) then
        Nodes.EnclosedByValue := ParseValue(WordIndices(kiENCLOSED, kiBY), vaNo, ParseString);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiESCAPED)) then
      Nodes.EscapedByValue := ParseValue(WordIndices(kiESCAPED, kiBY), vaNo, ParseString);
  end;

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLINES)) then
  begin
    Nodes.LinesTag := ParseTag(kiLINES);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSTARTING)) then
      Nodes.StartingByValue := ParseValue(WordIndices(kiSTARTING, kiBY), vaNo, ParseString);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiTERMINATED)) then
      Nodes.LinesTerminatedByValue := ParseValue(WordIndices(kiTERMINATED, kiBY), vaNo, ParseString);
  end;

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIGNORE)) then
  begin
    FillChar(IgnoreLinesNodes, SizeOf(IgnoreLinesNodes), 0);

    IgnoreLinesNodes.IgnoreTag := ParseTag(kiIGNORE);

    if (not Error) then
      IgnoreLinesNodes.NumberToken := ParseInteger;

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLINES) then
        IgnoreLinesNodes.LinesTag := ParseTag(kiLINES)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiROWS) then
        IgnoreLinesNodes.LinesTag := ParseTag(kiROWS)
      else
        SetError(PE_UnexpectedToken);

    Nodes.IgnoreLines := TIgnoreLines.Create(Self, IgnoreLinesNodes);
  end;

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
    Nodes.ColumnList := ParseList(True, ParseColumnIdent);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSET)) then
    Nodes.SetList := ParseValue(kiSET, vaNo, False, ParseUpdatePair);

  Result := TLoadDataStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseLoadStmt(): TOffset;
begin
  Result := 0;
  if (EndOfStmt(NextToken[1])) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiDATA) then
    Result := ParseLoadDataStmt()
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiXML) then
    Result := ParseLoadXMLStmt()
  else
    SetError(PE_UnexpectedToken);
end;

function TMySQLParser.ParseLoadXMLStmt(): TOffset;
var
  Nodes: TLoadXMLStmt.TNodes;
  IgnoreLinesNodes: TIgnoreLines.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.LoadXMLTag := ParseTag(kiLOAD, kiXML);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOW_PRIORITY) then
      Nodes.PriorityTag := ParseTag(kiLOW_PRIORITY)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCONCURRENT) then
      Nodes.PriorityTag := ParseTag(kiCONCURRENT);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCAL)) then
    Nodes.LocalTag := ParseTag(kiLOCAL);

  if (not Error) then
    Nodes.InfileTag := ParseTag(kiINFILE);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiREPLACE) then
      Nodes.ReplaceIgnoreTag := ParseTag(kiREPLACE)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIGNORE) then
      Nodes.ReplaceIgnoreTag := ParseTag(kiIGNORE);

  if (not Error) then
    Nodes.IntoTableValue := ParseValue(WordIndices(kiINTO, kiTABLE), vaNo, ParseTableIdent);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPARTITION)) then
    Nodes.PartitionValue := ParseValue(kiPARTITION, vaNo, True, ParseCreateTableStmtPartitionIdent);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARACTER)) then
    Nodes.CharacterSetValue := ParseValue(WordIndices(kiCHARACTER, kiSET), vaNo, ParseIdent);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiROWS)) then
    Nodes.RowsIdentifiedByValue := ParseValue(WordIndices(kiROWS, kiIDENTIFIED, kiBY), vaNo, ParseString);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIGNORE)) then
  begin
    FillChar(IgnoreLinesNodes, SizeOf(IgnoreLinesNodes), 0);

    IgnoreLinesNodes.IgnoreTag := ParseTag(kiIGNORE);

    if (not Error) then
      IgnoreLinesNodes.NumberToken := ParseInteger;

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLINES) then
        IgnoreLinesNodes.LinesTag := ParseTag(kiLINES)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiROWS) then
        IgnoreLinesNodes.LinesTag := ParseTag(kiROWS)
      else
        SetError(PE_UnexpectedToken);

    Nodes.IgnoreLines := TIgnoreLines.Create(Self, IgnoreLinesNodes);
  end;

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket)) then
    Nodes.ColumnList := ParseList(True, ParseColumnIdent);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSET)) then
    Nodes.SetList := ParseValue(kiSET, vaNo, False, ParseUpdatePair);

  Result := TLoadXMLStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseLockStmt(): TOffset;
var
  Nodes: TLockStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.LockTablesTag := ParseTag(kiLOCK, kiTABLES);

  if (not Error) then
    Nodes.ItemList := ParseList(False, ParseLockStmtItem);

  Result := TLockStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseLockStmtItem(): TOffset;
var
  Nodes: TLockStmt.TItem.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.TableIdent := ParseTableIdent();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAS)) then
    Nodes.AsTag := ParseTag(kiAS);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType in ttIdents) and (TokenPtr(CurrentToken)^.KeywordIndex < 0)) then
    Nodes.AliasIdent := ParseAlias();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiREAD) then
      if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiLOCAL)) then
        Nodes.TypeTag := ParseTag(kiREAD, kiLOCAL)
      else
        Nodes.TypeTag := ParseTag(kiREAD)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOW_PRIORITY) then
      Nodes.TypeTag := ParseTag(kiLOW_PRIORITY, kiWRITE)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWRITE) then
      Nodes.TypeTag := ParseTag(kiWRITE)
    else
      SetError(PE_UnexpectedToken);

  Result := TLockStmt.TItem.Create(Self, Nodes);
end;

function TMySQLParser.ParseLoopStmt(): TOffset;
var
  Nodes: TLoopStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(CurrentToken)^.TokenType = ttBeginLabel) then
    Nodes.BeginLabelToken := ApplyCurrentToken();

  Nodes.BeginTag := ParseTag(kiLOOP);

  if (not Error) then
    Nodes.StmtList := ParseList(False, ParsePL_SQLStmt, ttDelimiter);

  if (not Error) then
    Nodes.EndTag := ParseTag(kiEND, kiLOOP);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttIdent)) then
    if ((Nodes.BeginLabelToken = 0) or (StrIComp(PChar(TokenPtr(CurrentToken)^.AsString), PChar(TokenPtr(Nodes.BeginLabelToken)^.AsString)) <> 0)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.EndLabelToken := ApplyCurrentToken(utLabel, ttEndLabel);

  Result := TLoopStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseProcedureIdent(): TOffset;
begin
  Result := ParseDbIdent(ditProcedure);
end;

function TMySQLParser.ParseOpenStmt(): TOffset;
var
  Nodes: TOpenStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiOPEN);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CursorIdent := ParseDbIdent(ditCursor);

  Result := TOpenStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseOptimizeStmt(): TOffset;
var
  Nodes: TOptimizeStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiOPTIMIZE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiNO_WRITE_TO_BINLOG) then
      Nodes.OptionTag := ParseTag(kiNO_WRITE_TO_BINLOG)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCAL) then
      Nodes.OptionTag := ParseTag(kiLOCAL)
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiTABLE) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.TableTag := ParseTag(kiTABLE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.TablesList := ParseList(False, ParseTableIdent);

  Result := TOptimizeStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParsePositionFunc(): TOffset;
var
  Nodes: TPositionFunc.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.FuncToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.SubStr := ParseString();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiIN) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.InTag := ParseTag(kiIN);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Str := ParseExpr();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TPositionFunc.Create(Self, Nodes);
end;

function TMySQLParser.ParsePL_SQLStmt(): TOffset;
begin
  BeginPL_SQL();
  Result := ParseStmt();
  EndPL_SQL();
end;

function TMySQLParser.ParsePrepareStmt(): TOffset;
var
  Nodes: TPrepareStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiPREPARE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.StmtIdent := ParseIdent();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiFROM) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.FromTag := ParseTag(kiFROM);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.StmtVariable := ParseVariable();

  Result := TPrepareStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParsePurgeStmt(): TOffset;
var
  Nodes: TPurgeStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiPURGE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiBINARY) then
      Nodes.TypeTag := ParseTag(kiBINARY)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiMASTER) then
      Nodes.TypeTag := ParseTag(kiMASTER)
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiLOGS) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.LogsTag := ParseTag(kiLOGS);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiTO) then
      Nodes.Value := ParseValue(kiTO, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiBEFORE) then
      Nodes.Value := ParseValue(kiBEFORE, vaNo, ParseExpr)
    else
      SetError(PE_UnexpectedToken);

  Result := TPurgeStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseProcedureParam(): TOffset;
var
  Nodes: TRoutineParam.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIN) then
    Nodes.DirektionTag := ParseTag(kiIN)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiOUT) then
    Nodes.DirektionTag := ParseTag(kiOUT)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiINOUT) then
    Nodes.DirektionTag := ParseTag(kiINOUT);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.IdentToken := ParseDbIdent(ditParameter);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.DataTypeNode := ParseDataType();

  Result := TRoutineParam.Create(Self, Nodes);
end;

function TMySQLParser.ParseReleaseStmt(): TOffset;
var
  Nodes: TReleaseStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.ReleaseTag := ParseTag(kiRELEASE, kiSAVEPOINT);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Ident := ParseSavepointIdent();

  Result := TReleaseStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseRenameStmt(): TOffset;
var
  Nodes: TRenameStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(NextToken[1])) then
    SetError(PE_IncompleteStmt, NextToken[1])
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiTABLE) then
  begin
    Nodes.RenameTag := ParseTag(kiRENAME, kiTABLE);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.RenameList := ParseList(False, ParseRenameStmtTablePair);
  end
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiUSER) then
  begin
    Nodes.RenameTag := ParseTag(kiRENAME, kiUSER);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.RenameList := ParseList(False, ParseRenameStmtUserPair);
  end
  else
    SetError(PE_UnexpectedToken, NextToken[1]);

  Result := TRenameStmt.Create(Self, Nodes)
end;

function TMySQLParser.ParseRenameStmtTablePair(): TOffset;
var
  Nodes: TRenameStmt.TPair.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.OrgNode := ParseTableIdent();

  if (not Error) then
    Nodes.ToTag := ParseTag(kiTO);

  if (not Error) then
    Nodes.NewNode := ParseTableIdent();

  Result := TRenameStmt.TPair.Create(Self, Nodes);
end;

function TMySQLParser.ParseRenameStmtUserPair(): TOffset;
var
  Nodes: TRenameStmt.TPair.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.OrgNode := ParseUserIdent();

  if (not Error) then
    Nodes.ToTag := ParseTag(kiTO);

  if (not Error) then
    Nodes.NewNode := ParseUserIdent();

  Result := TRenameStmt.TPair.Create(Self, Nodes);
end;

function TMySQLParser.ParseRepairStmt(): TOffset;
var
  Nodes: TRepairStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiREPAIR);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiNO_WRITE_TO_BINLOG) then
      Nodes.OptionTag := ParseTag(kiNO_WRITE_TO_BINLOG)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCAL) then
      Nodes.OptionTag := ParseTag(kiLOCAL)
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiTABLE) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.TableTag := ParseTag(kiTABLE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.TablesList := ParseList(False, ParseTableIdent);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiQUICK) then
      Nodes.OptionTag := ParseTag(kiQUICK)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiEXTENDED) then
      Nodes.OptionTag := ParseTag(kiEXTENDED)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUSE_FRM) then
      Nodes.OptionTag := ParseTag(kiUSE_FRM)
    else
      SetError(PE_UnexpectedToken);

  Result := TRepairStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseRepeatStmt(): TOffset;
var
  Nodes: TRepeatStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(CurrentToken)^.TokenType = ttBeginLabel) then
    Nodes.BeginLabelToken := ApplyCurrentToken();

  Nodes.RepeatTag := ParseTag(kiREPEAT);

  if (not Error) then
    Nodes.StmtList := ParseList(False, ParsePL_SQLStmt, ttDelimiter);

  if (not Error) then
    Nodes.UntilTag := ParseTag(kiUNTIL);

  if (not Error) then
    Nodes.SearchConditionExpr := ParseExpr();

  if (not Error) then
    Nodes.EndTag := ParseTag(kiEND, kiREPEAT);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttIdent)) then
    if ((Nodes.BeginLabelToken = 0) or (StrIComp(PChar(TokenPtr(CurrentToken)^.AsString), PChar(TokenPtr(Nodes.BeginLabelToken)^.AsString)) <> 0)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.EndLabelToken := ApplyCurrentToken(utLabel, ttEndLabel);

  Result := TRepeatStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseRevokeStmt(): TOffset;
var
  Nodes: TRevokeStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiREVOKE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_UnexpectedToken)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex <> kiALL)
      and (TokenPtr(CurrentToken)^.KeywordIndex <> kiPROXY)) then
    begin
      Nodes.PrivilegesList := ParseList(False, ParseGrantStmtPrivileg);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiON) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.OnTag := ParseTag(kiON);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex = kiTABLE) then
          Nodes.ObjectValue := ParseValue(kiTABLE, vaNo, ParseTableIdent)
        else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFUNCTION) then
          Nodes.ObjectValue := ParseValue(kiFUNCTION, vaNo, ParseFunctionIdent)
        else if (TokenPtr(CurrentToken)^.KeywordIndex = kiPROCEDURE) then
          Nodes.ObjectValue := ParseValue(kiFUNCTION, vaNo, ParseProcedureIdent)
        else
          Nodes.ObjectValue := ParseTableIdent();

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiFROM) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.FromTag := ParseTag(kiFROM);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.UserIdentList := ParseList(False, ParseUserIdent);
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiALL) then
    begin
      Nodes.PrivilegesList := ParseTag(kiALL, kiPRIVILEGES);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttComma) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.CommaToken := ApplyCurrentToken();

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.GrantOptionTag := ParseTag(kiGRANT, kiOPTION);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.UserIdentList := ParseList(False, ParseUserIdent);
    end
    else
    begin
      Nodes.PrivilegesList := ParseTag(kiPROXY);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiON) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.OnTag := ParseTag(kiON);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.OnUser := ParseUserIdent();

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiFROM) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.FromTag := ParseTag(kiFROM);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.UserIdentList := ParseList(False, ParseUserIdent);
    end;

  Result := TRevokeStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseResetStmt(): TOffset;
var
  Nodes: TResetStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiRESET);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.OptionList := ParseList(False, ParseResetStmtOption);

  Result := TResetStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseResetStmtOption(): TOffset;
var
  Nodes: TResetStmt.TOption.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(CurrentToken)^.KeywordIndex = kiMASTER) then
    Nodes.OptionTag := ParseTag(kiMASTER)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiQUERY) then
    Nodes.OptionTag := ParseTag(kiQUERY, kiCACHE)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSLAVE) then
    Nodes.OptionTag := ParseTag(kiSLAVE)
  else
    SetError(PE_UnexpectedToken);

  Result := TResetStmt.TOption.Create(Self, Nodes);
end;

function TMySQLParser.ParseReturnStmt(): TOffset;
var
  Nodes: TReturnStmt.TNodes;
begin
  Assert(InCreateFunctionStmt);

  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiRETURN);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Expr := ParseExpr();

  Result := TReturnStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseRollbackStmt(): TOffset;
var
  Nodes: TRollbackStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiWORK)) then
    Nodes.RollbackTag := ParseTag(kiROLLBACK, kiWORK)
  else
    Nodes.RollbackTag := ParseTag(kiROLLBACK);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiTO) then
      if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSAVEPOINT)) then
        Nodes.ToValue := ParseValue(WordIndices(kiTO, kiSAVEPOINT), vaNo, ParseSavepointIdent)
      else
        Nodes.ToValue := ParseValue(kiTO, vaNo, ParseSavepointIdent)
    else
    begin
      if (TokenPtr(CurrentToken)^.KeywordIndex = kiAND) then
        if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiNO)) then
          Nodes.ChainTag := ParseTag(kiAND, kiNO, kiCHAIN)
        else
          Nodes.ChainTag := ParseTag(kiAND, kiCHAIN);

      if (not Error and not EndOfStmt(CurrentToken)) then
        if (TokenPtr(NextToken[1])^.KeywordIndex = kiNO) then
          Nodes.ReleaseTag := ParseTag(kiNO, kiRELEASE)
        else if (TokenPtr(NextToken[1])^.KeywordIndex = kiRELEASE) then
          Nodes.ReleaseTag := ParseTag(kiRELEASE);
    end;

  Result := TRollbackStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseSavepointIdent(): TOffset;
begin
  Result := 0;
  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
    SetError(PE_UnexpectedToken)
  else
    Result := ApplyCurrentToken();
end;

function TMySQLParser.ParseSavepointStmt(): TOffset;
var
  Nodes: TSavepointStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.SavepointTag := ParseTag(kiSAVEPOINT);

  if (not Error) then
    Nodes.Ident := ParseSavepointIdent();

  Result := TSavepointStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseSchedule(): TOffset;
var
  Nodes: TSchedule.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiAT) then
  begin
    Nodes.At.Tag := ParseTag(kiAT);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.At.Timestamp := ParseExpr();

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.OperatorType = otPlus)) then
      Nodes.At.IntervalList := ParseIntervalOpList();
  end
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiEVERY) then
  begin
    Nodes.Every.Tag := ParseTag(kiEVERY);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.Every.Interval := ParseIntervalOp();

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSTARTS)) then
    begin
      Nodes.Starts.Tag := ParseTag(kiSTARTS);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.Starts.Timestamp := ParseExpr();

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.OperatorType = otPlus)) then
        Nodes.Starts.IntervalList := ParseIntervalOpList();
    end;

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiENDS)) then
    begin
      Nodes.Ends.Tag := ParseTag(kiENDS);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
          Nodes.Ends.Timestamp := ParseExpr();

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.OperatorType = otPlus)) then
        Nodes.Ends.IntervalList := ParseIntervalOpList();
    end;
  end;

  Result := TSchedule.Create(Self, Nodes);
end;

function TMySQLParser.ParseSecretIdent(): TOffset;
var
  Nodes: TSecretIdent.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.OperatorType <> otLess) then
    SetError(PE_UnexpectedToken)
  else
    Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error) then
    Nodes.ItemToken := ParseIdent();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType <> otGreater) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TSecretIdent.Create(Self, Nodes);
end;

function TMySQLParser.ParseSelectStmt(): TOffset;
var
  Found: Boolean;
  Nodes: TSelectStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.SelectTag := ParseTag(kiSELECT);

  Found := True;
  while (not Error and Found and not EndOfStmt(CurrentToken)) do
    if ((Nodes.DistinctTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiALL)) then
      Nodes.DistinctTag := ParseTag(kiALL)
    else if ((Nodes.DistinctTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDISTINCT)) then
      Nodes.DistinctTag := ParseTag(kiDISTINCT)
    else if ((Nodes.DistinctTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDISTINCTROW)) then
      Nodes.DistinctTag := ParseTag(kiDISTINCTROW)
    else if ((Nodes.HighPriorityTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiHIGH_PRIORITY)) then
      Nodes.HighPriorityTag := ParseTag(kiHIGH_PRIORITY)
    else if ((Nodes.StraightJoinTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSTRAIGHT_JOIN)) then
      Nodes.StraightJoinTag := ParseTag(kiSTRAIGHT_JOIN)
    else if ((Nodes.SQLSmallResultTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_SMALL_RESULT)) then
      Nodes.SQLSmallResultTag := ParseTag(kiSQL_SMALL_RESULT)
    else if ((Nodes.SQLBigResultTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_BIG_RESULT)) then
      Nodes.SQLBigResultTag := ParseTag(kiSQL_BIG_RESULT)
    else if ((Nodes.SQLBufferResultTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_BUFFER_RESULT)) then
      Nodes.SQLBufferResultTag := ParseTag(kiSQL_BUFFER_RESULT)
    else if ((Nodes.SQLNoCacheTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_CACHE)) then
      Nodes.SQLNoCacheTag := ParseTag(kiSQL_CACHE)
    else if ((Nodes.SQLNoCacheTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_NO_CACHE)) then
      Nodes.SQLNoCacheTag := ParseTag(kiSQL_NO_CACHE)
    else if ((Nodes.SQLCalcFoundRowsTag = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSQL_CALC_FOUND_ROWS)) then
      Nodes.SQLCalcFoundRowsTag := ParseTag(kiSQL_CALC_FOUND_ROWS)
    else
      Found := False;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ColumnsList := ParseList(False, ParseSelectStmtColumn);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiINTO)) then
    Nodes.Into1 := ParseSelectStmtInto();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM)) then
  begin
    Nodes.From.Tag := ParseTag(kiFROM);
    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.From.Expr := ParseList(False, ParseTableReference);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE)) then
    begin
      Nodes.Where.Tag := ParseTag(kiWHERE);
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.Where.Expr := ParseExpr();
    end;

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiGROUP)) then
    begin
      Nodes.GroupBy.Tag := ParseTag(kiGROUP, kiBY);
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.GroupBy.Expr := ParseSelectStmtGroups();
    end;

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiHAVING)) then
    begin
      Nodes.Where.Tag := ParseTag(kiHAVING);
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.Where.Expr := ParseExpr();
    end;

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiORDER)) then
    begin
      Nodes.OrderBy.Tag := ParseTag(kiORDER, kiBY);
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.OrderBy.Expr := ParseList(False, ParseSelectStmtOrder);
    end;

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLIMIT)) then
    begin
      Nodes.Limit.LimitTag := ParseTag(kiLIMIT);

      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
      begin
        Nodes.Limit.RowCountToken := ParseExpr();

        if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttComma)) then
        begin
          Nodes.Limit.CommaToken := ApplyCurrentToken();

          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else
          begin
            Nodes.Limit.OffsetToken := Nodes.Limit.RowCountToken;
            Nodes.Limit.RowCountToken := ParseExpr();
          end;
        end
        else if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiOFFSET)) then
        begin
          Nodes.Limit.OffsetTag := ParseTag(kiOFFSET);

          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else
            Nodes.Limit.OffsetToken := ParseInteger();
        end;
      end;
    end;

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPROCEDURE)) then
    begin
      Nodes.Proc.Tag := ParseTag(kiPROCEDURE);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
        begin
          Nodes.Proc.Ident := ParseDbIdent(ditProcedure);

          if (not Error) then
            if (EndOfStmt(CurrentToken)) then
              SetError(PE_IncompleteStmt)
            else
              Nodes.Proc.ParamList := ParseList(True, ParseExpr);
        end;
    end;

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiINTO)) then
      Nodes.Into2 := ParseSelectStmtInto();

    if (not Error and not EndOfStmt(CurrentToken)) then
      if (TokenPtr(CurrentToken)^.KeywordIndex = kiFOR) then
        Nodes.ForUpdatesTag := ParseTag(kiFOR, kiUPDATE)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCK) then
        Nodes.LockInShareMode := ParseTag(kiLOCK, kiIN, kiSHARE, kiMODE);
  end;

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiUNION)) then
  begin
    if (not Error and not EndOfStmt(NextToken[1]) and ((TokenPtr(NextToken[1])^.KeywordIndex = kiALL) or (TokenPtr(NextToken[1])^.KeywordIndex = kiDISTINCT))) then
      Nodes.Union.Tag := ParseTag(kiUNION, TokenPtr(NextToken[1])^.KeywordIndex)
    else
      Nodes.Union.Tag := ParseTag(kiUNION);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.Union.SelectStmt := ParseSelectStmt();
  end;

  Result := TSelectStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseSelectStmtColumn(): TOffset;
var
  Nodes: TSelectStmt.TColumn.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else
    Nodes.ExprNode := ParseExpr();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAS)) then
    Nodes.AsToken := ParseTag(kiAS);

  if (not Error) then
    if (EndOfStmt(CurrentToken) and (Nodes.AsToken > 0)) then
      SetError(PE_IncompleteStmt)
    else if (not EndOfStmt(CurrentToken)
      and ((Nodes.AsToken > 0)
        or (TokenPtr(CurrentToken)^.TokenType = ttString)
        or (TokenPtr(CurrentToken)^.TokenType = ttMySQLIdent) and not AnsiQuotes
        or (TokenPtr(CurrentToken)^.TokenType = ttDQIdent) and AnsiQuotes
        or (TokenPtr(CurrentToken)^.TokenType = ttDQIdent) and not AnsiQuotes
        or ((TokenPtr(CurrentToken)^.TokenType = ttIdent)
          and (TokenPtr(CurrentToken)^.KeywordIndex <> kiFROM)
          and (TokenPtr(CurrentToken)^.KeywordIndex <> kiWHERE)
          and (TokenPtr(CurrentToken)^.KeywordIndex <> kiGROUP)
          and (TokenPtr(CurrentToken)^.KeywordIndex <> kiHAVING)
          and (TokenPtr(CurrentToken)^.KeywordIndex <> kiORDER)
          and (TokenPtr(CurrentToken)^.KeywordIndex <> kiLIMIT)
          and (TokenPtr(CurrentToken)^.KeywordIndex <> kiPROCEDURE)
          and (TokenPtr(CurrentToken)^.KeywordIndex <> kiINTO)
          and (TokenPtr(CurrentToken)^.KeywordIndex <> kiFOR)))) then
      Nodes.AliasIdent := ParseAlias();

  Result := TSelectStmt.TColumn.Create(Self, Nodes);
end;

function TMySQLParser.ParseSelectStmtGroup(): TOffset;
var
  Nodes: TSelectStmt.TGroup.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.Expr := ParseExpr();

  if (not Error and not EndOfStmt(CurrentToken) and ((TokenPtr(CurrentToken)^.KeywordIndex = kiASC) or (TokenPtr(CurrentToken)^.KeywordIndex = kiDESC))) then
    Nodes.Direction := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

  Result := TSelectStmt.TGroup.Create(Self, Nodes);
end;

function TMySQLParser.ParseSelectStmtGroups(): TOffset;
var
  Nodes: TSelectStmt.TGroups.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.ColumnList := ParseList(False, ParseSelectStmtGroup);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWITH)) then
    Nodes.WithRollupTag := ParseTag(kiWITH, kiROLLUP);

  Result := TSelectStmt.TGroups.Create(Self, Nodes);
end;

function TMySQLParser.ParseSelectStmtInto(): TOffset;
var
  Nodes: TSelectStmt.TInto.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IntoTag := ParseTag(kiINTO);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiOUTFILE) then
  begin
    Nodes.OutfileValue := ParseValue(kiOUTFILE, vaNo, ParseString);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCHARACTER)) then
      Nodes.CharacterSetValue := ParseValue(WordIndices(kiCHARACTER, kiSET), vaNo, ParseIdent);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFIELDS)) then
      Nodes.CharacterSetValue := ParseValue(WordIndices(kiFIELDS, kiTERMINATED, kiBY), vaNo, ParseString);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiOPTIONALLY)) then
      Nodes.CharacterSetValue := ParseValue(WordIndices(kiOPTIONALLY, kiENCLOSED, kiBY), vaNo, ParseString);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLINES)) then
      Nodes.LinesTerminatedByValue := ParseValue(WordIndices(kiLINES, kiTERMINATED, kiBY), vaNo, ParseString);
  end
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiDUMPFILE) then
  begin
    Nodes.DumpfileTag := ParseTag(kiOUTFILE);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.Filename := ParseString();
  end
  else if (TokenPtr(CurrentToken)^.TokenType = ttAt) then
    Nodes.Variable := ParseList(False, ParseVariable)
  else if (InPL_SQL) then
    Nodes.Variable := ParseList(False, ParseVariable)
  else
    SetError(PE_UnexpectedToken);

  Result := TSelectStmt.TInto.Create(Self, Nodes);
end;

function TMySQLParser.ParseSelectStmtOrder(): TOffset;
var
  Nodes: TSelectStmt.TOrder.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.Expr := ParseExpr();

  if (not Error and not EndOfStmt(CurrentToken) and ((TokenPtr(CurrentToken)^.KeywordIndex = kiASC) or (TokenPtr(CurrentToken)^.KeywordIndex = kiDESC))) then
    Nodes.DirectionTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

  Result := TSelectStmt.TOrder.Create(Self, Nodes);
end;

function TMySQLParser.ParseSetNamesStmt(): TOffset;
var
  Nodes: TSetNamesStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(NextToken[1])^.KeywordIndex = kiNAMES) then
    Nodes.StmtTag := ParseTag(kiSET, kiNAMES)
  else if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCHARACTER)) then
    Nodes.StmtTag := ParseTag(kiSET, kiCHARACTER, kiSET)
  else
    raise Exception.Create(SUnknownError);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ConstValue := ApplyCurrentToken();

  Result := TSetNamesStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseSetPasswordStmt(): TOffset;
var
  Nodes: TSetPasswordStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSET, kiPASSWORD);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFOR)) then
    Nodes.ForValue := ParseValue(kiFOR, vaNo, ParseUserIdent);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType <> otEqual) then
      SetError(PE_UnexpectedToken)
    else
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();
    end;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.PasswordExpr := ParseExpr();

  Result := TSetPasswordStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseSetStmt(): TOffset;
var
  Nodes: TSetStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.SetTag := ParseTag(kiSET);

  if (not Error and not EndOfStmt(CurrentToken)
    and ((TokenPtr(CurrentToken)^.KeywordIndex = kiGLOBAL) or (TokenPtr(CurrentToken)^.KeywordIndex = kiSESSION))) then
    Nodes.ScopeTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.AssignmentList := ParseList(False, ParseSetStmtAssignment);

  Result := TSetStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseSetStmtAssignment(): TOffset;
var
  Nodes: TSetStmt.TAssignment.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiGLOBAL) then
      Nodes.ScopeTag := ParseTag(kiGLOBAL)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSESSION) then
      Nodes.ScopeTag := ParseTag(kiSESSION);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Variable := ParseVariable();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType = otEqual) then
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();
    end
    else if (TokenPtr(CurrentToken)^.OperatorType = otAssign2) then
      Nodes.AssignToken := ApplyCurrentToken()
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    Nodes.ValueExpr := ParseExpr();

  Result := TSetStmt.TAssignment.Create(Self, Nodes);
end;

function TMySQLParser.ParseSetTransactionStmt(): TOffset;
var
  Nodes: TSetTransactionStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.SetTag := ParseTag(kiSET);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiGLOBAL) then
      Nodes.ScopeTag := ParseTag(kiGLOBAL)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSESSION) then
      Nodes.ScopeTag := ParseTag(kiSESSION);

  if (not Error) then
    Nodes.TransactionTag := ParseTag(kiTRANSACTION);

  if (not Error) then
    Nodes.CharacteristicList := ParseList(False, ParseSetTransactionStmtCharacterisic);

  Result := TSetTransactionStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseSetTransactionStmtCharacterisic(): TOffset;
var
  Nodes: TSetTransactionStmt.TCharacteristic.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiISOLATION) then
  begin
    Nodes.KindTag := ParseTag(kiISOLATION, kiLEVEL);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiREPEATABLE) then
        Nodes.Value := ParseTag(kiREPEATABLE, kiREAD)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiREAD) then
        if (EndOfStmt(NextToken[1])) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(NextToken[1])^.KeywordIndex = kiCOMMITTED) then
          Nodes.Value := ParseTag(kiREAD, kiCOMMITTED)
        else if (TokenPtr(NextToken[1])^.KeywordIndex = kiUNCOMMITTED) then
          Nodes.Value := ParseTag(kiREAD, kiUNCOMMITTED)
        else
          SetError(PE_UnexpectedToken)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSERIALIZABLE) then
        Nodes.Value := ParseTag(kiSERIALIZABLE)
      else
        SetError(PE_UnexpectedToken);
  end
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiREAD) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(NextToken[1])^.KeywordIndex = kiWRITE) then
      Nodes.KindTag := ParseTag(kiREAD, kiWRITE)
    else if (TokenPtr(NextToken[1])^.KeywordIndex = kiONLY) then
      Nodes.KindTag := ParseTag(kiREAD, kiONLY)
    else
      SetError(PE_UnexpectedToken)
  else
   SetError(PE_UnexpectedToken);

  Result := TSetTransactionStmt.TCharacteristic.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowAuthorsStmt(): TOffset;
var
  Nodes: TShowAuthorsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiAUTHORS);

  Result := TShowAuthorsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowBinaryLogsStmt(): TOffset;
var
  Nodes: TShowBinaryLogsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiBINARY, kiLOGS);

  Result := TShowBinaryLogsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowBinlogEventsStmt(): TOffset;
var
  Nodes: TShowBinlogEventsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiBINLOG, kiEVENTS);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIN)) then
    Nodes.InValue := ParseValue(kiIN, vaNo, ParseString);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM)) then
    Nodes.FromValue := ParseValue(kiFROM, vaNo, ParseInteger);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLIMIT)) then
  begin
    Nodes.LimitTag := ParseTag(kiLIMIT);

    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
    begin
      Nodes.RowCountToken := ParseInteger();

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttComma)) then
      begin
        Nodes.CommaToken := ApplyCurrentToken();

        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
        begin
          Nodes.OffsetToken := Nodes.RowCountToken;
          Nodes.RowCountToken := ParseInteger();
        end;
      end;
    end;
  end;

  Result := TShowBinlogEventsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowCharacterSetStmt(): TOffset;
var
  Nodes: TShowCharacterSetStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiCHARACTER, kiSET);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
      Nodes.LikeValue := ParseValue(kiLIKE, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE) then
      Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowCharacterSetStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowCollationStmt(): TOffset;
var
  Nodes: TShowCollationStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiCOLLATION);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
      Nodes.LikeValue := ParseValue(kiLIKE, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE) then
      Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowCollationStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowContributorsStmt(): TOffset;
var
  Nodes: TShowContributorsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiCONTRIBUTORS);

  Result := TShowContributorsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowCountErrorsStmt(): TOffset;
var
  Nodes: TShowCountErrorsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW);

  if (not Error) then
    if (EndOfStmt(NextToken[3])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
      SetError(PE_UnexpectedToken)
    else if (TokenPtr(NextToken[1])^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken, NextToken[1])
    else if ((TokenPtr(NextToken[2])^.TokenType <> ttOperator) or (TokenPtr(NextToken[2])^.OperatorType <> otMulti)) then
      SetError(PE_UnexpectedToken, NextToken[2])
    else if (TokenPtr(NextToken[3])^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken, NextToken[3])
    else
      Nodes.CountFunctionCall := ParseFunctionCall();

  Result := TShowCountErrorsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowCountWarningsStmt(): TOffset;
var
  Nodes: TShowCountWarningsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW);

  if (not Error) then
    if (EndOfStmt(NextToken[3])) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttIdent) then
      SetError(PE_UnexpectedToken)
    else if (TokenPtr(NextToken[1])^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken, NextToken[1])
    else if ((TokenPtr(NextToken[2])^.TokenType <> ttOperator) or (TokenPtr(NextToken[2])^.OperatorType <> otMulti)) then
      SetError(PE_UnexpectedToken, NextToken[2])
    else if (TokenPtr(NextToken[3])^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken, NextToken[3])
    else
      Nodes.CountFunctionCall := ParseFunctionCall();

  Result := TShowCountWarningsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowCreateDatabaseStmt(): TOffset;
var
  Nodes: TShowCreateDatabaseStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(NextToken[2])^.KeywordIndex = kiSCHEMA) then
    Nodes.StmtTag := ParseTag(kiSHOW, kiCREATE, kiSCHEMA)
  else
    Nodes.StmtTag := ParseTag(kiSHOW, kiCREATE, kiDATABASE);

  if (not Error and not EndOfStmt(NextToken[2])
    and (TokenPtr(CurrentToken)^.KeywordIndex = kiIF)
    and (TokenPtr(NextToken[1])^.KeywordIndex = kiNOT)
    and (TokenPtr(NextToken[2])^.KeywordIndex = kiEXISTS)) then
    Nodes.IfNotExistsTag := ParseTag(kiIF, kiNOT, kiEXISTS);

  if (not Error) then
    Nodes.Ident := ParseDbIdent(ditDatabase);

  Result := TShowCreateDatabaseStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowCreateEventStmt(): TOffset;
var
  Nodes: TShowCreateEventStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiCREATE, kiEVENT);

  if (not Error) then
    Nodes.Ident := ParseDbIdent(ditEvent);

  Result := TShowCreateEventStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowCreateFunctionStmt(): TOffset;
var
  Nodes: TShowCreateFunctionStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiCREATE, kiFUNCTION);

  if (not Error) then
    Nodes.Ident := ParseDbIdent(ditFunction);

  Result := TShowCreateFunctionStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowCreateProcedureStmt(): TOffset;
var
  Nodes: TShowCreateProcedureStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiCREATE, kiPROCEDURE);

  if (not Error) then
    Nodes.Ident := ParseDbIdent(ditProcedure);

  Result := TShowCreateProcedureStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowCreateTableStmt(): TOffset;
var
  Nodes: TShowCreateTableStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiCREATE, kiTABLE);

  if (not Error) then
    Nodes.Ident := ParseTableIdent();

  Result := TShowCreateTableStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowCreateTriggerStmt(): TOffset;
var
  Nodes: TShowCreateTriggerStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiCREATE, kiTRIGGER);

  if (not Error) then
    Nodes.Ident := ParseDbIdent(ditTrigger);

  Result := TShowCreateTriggerStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowCreateViewStmt(): TOffset;
var
  Nodes: TShowCreateViewStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiCREATE, kiVIEW);

  if (not Error) then
    Nodes.Ident := ParseTableIdent();

  Result := TShowCreateViewStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowDatabasesStmt(): TOffset;
var
  Nodes: TShowDatabasesStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiDATABASES);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
      Nodes.LikeValue := ParseValue(kiLIKE, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE) then
      Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowDatabasesStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowEngineStmt(): TOffset;
var
  Nodes: TShowEngineStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiENGINE);

  if (not Error) then
    Nodes.Ident := ParseIdent();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSTATUS) then
      Nodes.KindTag := ParseTag(kiSTATUS)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiMUTEX) then
      Nodes.KindTag := ParseTag(kiMUTEX)
    else
      SetError(PE_UnexpectedToken);

  Result := TShowEngineStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowEnginesStmt(): TOffset;
var
  Nodes: TShowEnginesStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(NextToken[1])^.KeywordIndex = kiSTORAGE) then
    Nodes.StmtTag := ParseTag(kiSHOW, kiSTORAGE, kiENGINES)
  else
    Nodes.StmtTag := ParseTag(kiSHOW, kiENGINES);

  Result := TShowEnginesStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowErrorsStmt(): TOffset;
var
  Nodes: TShowErrorsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiERRORS);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLIMIT)) then
  begin
    Nodes.Limit.LimitTag := ParseTag(kiLIMIT);

    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
    begin
      Nodes.Limit.RowCountToken := ParseInteger();

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttComma)) then
      begin
        Nodes.Limit.CommaToken := ApplyCurrentToken();

        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
        begin
          Nodes.Limit.OffsetToken := Nodes.Limit.RowCountToken;
          Nodes.Limit.RowCountToken := ParseInteger();
        end;
      end;
    end;
  end;

  Result := TShowErrorsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowEventsStmt(): TOffset;
var
  Nodes: TShowEventsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiERRORS);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM) then
      Nodes.FromValue := ParseValue(kiFROM, vaNo, ParseDatabaseIdent)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIN) then
      Nodes.FromValue := ParseValue(kiIN, vaNo, ParseDatabaseIdent);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
      Nodes.LikeValue := ParseValue(kiLIKE, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE) then
      Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowEventsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowFunctionCodeStmt(): TOffset;
var
  Nodes: TShowFunctionCodeStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiFUNCTION, kiCODE);

  Result := TShowFunctionCodeStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowFunctionStatusStmt(): TOffset;
var
  Nodes: TShowFunctionStatusStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiFUNCTION, kiSTATUS);

  Result := TShowFunctionStatusStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowGrantsStmt(): TOffset;
var
  Nodes: TShowGrantsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiGRANTS);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFOR)) then
    Nodes.ForValue := ParseValue(kiFOR, vaNo, ParseUserIdent);

  Result := TShowGrantsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowIndexStmt(): TOffset;
var
  Nodes: TShowIndexStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(NextToken[1])^.KeywordIndex = kiINDEX) then
    Nodes.StmtTag := ParseTag(kiSHOW, kiINDEX)
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiINDEXES) then
    Nodes.StmtTag := ParseTag(kiSHOW, kiINDEXES)
  else if (TokenPtr(NextToken[1])^.KeywordIndex = kiKEYS) then
    Nodes.StmtTag := ParseTag(kiSHOW, kiKEYS)
  else
    SetError(PE_UnexpectedToken);

  if (not Error and EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM) then
    Nodes.FromTableValue := ParseValue(kiFROM, vaNo, ParseTableIdent)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIN) then
    Nodes.FromTableValue := ParseValue(kiIN, vaNo, ParseTableIdent)
  else
    SetError(PE_UnexpectedToken);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM) then
      Nodes.FromDatabaseValue := ParseValue(kiFROM, vaNo, ParseDatabaseIdent)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIN) then
      Nodes.FromDatabaseValue := ParseValue(kiIN, vaNo, ParseDatabaseIdent);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE)) then
    Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowIndexStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowMasterStatusStmt(): TOffset;
var
  Nodes: TShowMasterStatusStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiMASTER, kiSTATUS);

  Result := TShowMasterStatusStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowOpenTablesStmt(): TOffset;
var
  Nodes: TShowOpenTablesStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiOPEN, kiTABLES);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM) then
      Nodes.FromDatabaseValue := ParseValue(kiFROM, vaNo, ParseDatabaseIdent)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIN) then
      Nodes.FromDatabaseValue := ParseValue(kiIN, vaNo, ParseDatabaseIdent);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
      Nodes.LikeValue := ParseValue(kiLIKE, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE) then
      Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowOpenTablesStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowPluginsStmt(): TOffset;
var
  Nodes: TShowPluginsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiPLUGINS);

  Result := TShowPluginsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowPrivilegesStmt(): TOffset;
var
  Nodes: TShowPrivilegesStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiPRIVILEGES);

  Result := TShowPrivilegesStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowProcedureCodeStmt(): TOffset;
var
  Nodes: TShowProcedureCodeStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiPROCEDURE, kiCODE);

  Result := TShowProcedureCodeStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowProcedureStatusStmt(): TOffset;
var
  Nodes: TShowProcedureStatusStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiPROCEDURE, kiSTATUS);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
      Nodes.LikeValue := ParseValue(kiLIKE, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE) then
      Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowProcedureStatusStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowProcessListStmt(): TOffset;
var
  Nodes: TShowProcessListStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(NextToken[1])^.KeywordIndex = kiFULL) then
    Nodes.StmtTag := ParseTag(kiSHOW, kiFULL, kiPROCESSLIST)
  else
    Nodes.StmtTag := ParseTag(kiSHOW, kiPROCESSLIST);

  Result := TShowProcessListStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowProfileStmt(): TOffset;
var
  Nodes: TShowProfileStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiPROFILE);

  if (not Error) then
    Nodes.TypeList := ParseList(False, ParseShowProfileStmtType);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFOR)) then
    Nodes.ForQueryValue := ParseValue(WordIndices(kiFOR, kiQUERY), vaNo, ParseInteger);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLIMIT)) then
  begin
    Nodes.LimitValue := ParseValue(kiLIMIT, vaNo, ParseInteger);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiOFFSET)) then
      Nodes.LimitValue := ParseValue(kiOFFSET, vaNo, ParseInteger);
  end;

  Result := TShowProfileStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowProfilesStmt(): TOffset;
var
  Nodes: TShowProfilesStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiPROFILES);

  Result := TShowProfilesStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowProfileStmtType(): TOffset;
begin
  Result := 0;

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiALL) then
    Result := ParseTag(kiALL)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiBLOCK)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiIO)) then
    Result := ParseTag(kiBLOCK, kiIO)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCONTEXT)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSWITCHES)) then
    Result := ParseTag(kiCONTEXT, kiSWITCHES)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCPU) then
    Result := ParseTag(kiCPU)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIPC) then
    Result := ParseTag(kiIPC)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiMEMORY) then
    Result := ParseTag(kiMEMORY)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiPAGE)
    and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiFAULTS)) then
    Result := ParseTag(kiPAGE, kiFAULTS)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSOURCE) then
    Result := ParseTag(kiSOURCE)
  else
    SetError(PE_UnexpectedToken);
end;

function TMySQLParser.ParseShowRelaylogEventsStmt(): TOffset;
var
  Nodes: TShowRelaylogEventsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiRELAYLOG, kiEVENTS);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiIN)) then
    Nodes.InValue := ParseValue(kiIN, vaNo, ParseString);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM)) then
    Nodes.InValue := ParseValue(kiFROM, vaNo, ParseInteger);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLIMIT)) then
  begin
    Nodes.LimitTag := ParseTag(kiLIMIT);

    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
    begin
      Nodes.RowCountToken := ParseInteger();

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttComma)) then
      begin
        Nodes.CommaToken := ApplyCurrentToken();

        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
        begin
          Nodes.OffsetToken := Nodes.RowCountToken;
          Nodes.RowCountToken := ParseInteger();
        end;
      end;
    end;
  end;

  Result := TShowRelaylogEventsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowSlaveHostsStmt(): TOffset;
var
  Nodes: TShowSlaveHostsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiSLAVE, kiHOSTS);

  Result := TShowSlaveHostsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowSlaveStatusStmt(): TOffset;
var
  Nodes: TShowSlaveStatusStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiSLAVE, kiSTATUS);

  Result := TShowSlaveStatusStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowStatusStmt(): TOffset;
var
  Nodes: TShowStatusStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.ShowTag := ParseTag(kiSHOW);

  if (not Error and not EndOfStmt(CurrentToken) and ((TokenPtr(CurrentToken)^.KeywordIndex = kiGLOBAL) or (TokenPtr(CurrentToken)^.KeywordIndex = kiSESSION))) then
    Nodes.ScopeTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiSTATUS) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.StatusTag := ParseTag(kiSTATUS);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
      Nodes.LikeValue := ParseValue(kiLIKE, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE) then
      Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowStatusStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowTableStatusStmt(): TOffset;
var
  Nodes: TShowTableStatusStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.ShowTag := ParseTag(kiSHOW, kiTABLE, kiSTATUS);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM) then
      Nodes.FromValue := ParseValue(kiFROM, vaNo, ParseDatabaseIdent)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIN) then
      Nodes.FromValue := ParseValue(kiIN, vaNo, ParseDatabaseIdent);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
      Nodes.LikeValue := ParseValue(kiLIKE, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE) then
      Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowTableStatusStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowTablesStmt(): TOffset;
var
  Nodes: TShowTablesStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.ShowTag := ParseTag(kiSHOW);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiFULL)) then
    Nodes.FullTag := ParseTag(kiFULL);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiTABLES) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.TablesTag := ParseTag(kiTABLES);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM) then
      Nodes.FromValue := ParseValue(kiFROM, vaNo, ParseDatabaseIdent)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIN) then
      Nodes.FromValue := ParseValue(kiIN, vaNo, ParseDatabaseIdent);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
      Nodes.LikeValue := ParseValue(kiLIKE, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE) then
      Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowTablesStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowTriggersStmt(): TOffset;
var
  Nodes: TShowTriggersStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiTRIGGERS);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM) then
      Nodes.FromValue := ParseValue(kiFROM, vaNo, ParseDatabaseIdent)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiIN) then
      Nodes.FromValue := ParseValue(kiIN, vaNo, ParseDatabaseIdent);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
      Nodes.LikeValue := ParseValue(kiLIKE, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE) then
      Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowTriggersStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowVariablesStmt(): TOffset;
var
  Nodes: TShowVariablesStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.ShowTag := ParseTag(kiSHOW);

  if (not Error and not EndOfStmt(CurrentToken) and ((TokenPtr(CurrentToken)^.KeywordIndex = kiGLOBAL) or (TokenPtr(CurrentToken)^.KeywordIndex = kiSESSION))) then
    Nodes.ScopeTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiVARIABLES) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.VariablesTag := ParseTag(kiVARIABLES);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLIKE) then
      Nodes.LikeValue := ParseValue(kiLIKE, vaNo, ParseString)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE) then
      Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  Result := TShowVariablesStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShowWarningsStmt(): TOffset;
var
  Nodes: TShowWarningsStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHOW, kiWARNINGS);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLIMIT)) then
  begin
    Nodes.Limit.LimitTag := ParseTag(kiLIMIT);

    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
    begin
      Nodes.Limit.RowCountToken := ParseInteger();

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttComma)) then
      begin
        Nodes.Limit.CommaToken := ApplyCurrentToken();

        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else
        begin
          Nodes.Limit.OffsetToken := Nodes.Limit.RowCountToken;
          Nodes.Limit.RowCountToken := ParseInteger();
        end;
      end;
    end;
  end;

  Result := TShowWarningsStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseShutdownStmt(): TOffset;
var
  Nodes: TShutdownStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSHUTDOWN);

  Result := TShutdownStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseSignalStmt(): TOffset;
var
  Nodes: TSignalStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(CurrentToken)^.KeywordIndex = kiSIGNAL) then
  begin
    Nodes.StmtTag := ParseTag(kiSIGNAL);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiSQLSTATE)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiVALUE)) then
        Nodes.Condition := ParseValue(WordIndices(kiSQLSTATE, kiVALUE), vaNo, ParseExpr)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSQLSTATE) then
        Nodes.Condition := ParseValue(kiSQLSTATE, vaNo, ParseString)
      else
        Nodes.Condition := ParseIdent();
  end
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiRESIGNAL) then
  begin
    Nodes.StmtTag := ParseTag(kiRESIGNAL);

    if (not Error and not EndOfStmt(CurrentToken)) then
      if ((TokenPtr(CurrentToken)^.KeywordIndex = kiSQLSTATE)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiVALUE)) then
        Nodes.Condition := ParseValue(WordIndices(kiSQLSTATE, kiVALUE), vaYes, ParseExpr)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSQLSTATE) then
        Nodes.Condition := ParseValue(kiSQLSTATE, vaNo, ParseString)
      else
        Nodes.Condition := ParseIdent();
  end
  else
    SetError(PE_Unknown);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSET)) then
  begin
    Nodes.SetTag := ParseTag(kiSET);

    if (not Error and not EndOfStmt(CurrentToken)) then
      Nodes.InformationList := ParseList(False, ParseSignalStmtInformation);
  end;

  Result := TSignalStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseSignalStmtInformation(): TOffset;
var
  Nodes: TSignalStmt.TInformation.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCLASS_ORIGIN)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiSUBCLASS_ORIGIN)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiMESSAGE_TEXT)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiMYSQL_ERRNO)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiCONSTRAINT_CATALOG)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiCONSTRAINT_SCHEMA)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiCONSTRAINT_NAME)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiCATALOG_NAME)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiSCHEMA_NAME)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiTABLE_NAME)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiCOLUMN_NAME)
    or (TokenPtr(CurrentToken)^.KeywordIndex = kiCURSOR_NAME)) then
    Nodes.Value := ParseValue(TokenPtr(CurrentToken)^.KeywordIndex, vaYes, ParseExpr)
  else
    SetError(PE_UnexpectedToken);

  Result := TSignalStmt.TInformation.Create(Self, Nodes);
end;

function TMySQLParser.ParseSQL(const Text: PChar; const Length: Integer): Boolean;
begin
  Clear();

  SetString(ParseText, Text, Length);
  ParsePosition.Text := PChar(ParseText);
  ParsePosition.Length := Length;

  FRoot := ParseRoot();

  Result := not Error;
end;

function TMySQLParser.ParseSQL(const Text: string): Boolean;
begin
  Result := ParseSQL(PChar(Text), Length(Text));
end;

function TMySQLParser.ParseStartSlaveStmt(): TOffset;
var
  Nodes: TStartSlaveStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSTART, kiSLAVE);

  Result := TStartSlaveStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseStartTransactionStmt(): TOffset;
var
  Found: Boolean;
  Nodes: TStartTransactionStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StartTransactionTag := ParseTag(kiSTART, kiTRANSACTION);

  Found := True;
  while (not Error and Found and not EndOfStmt(CurrentToken)) do
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiREAD) then
      if (EndOfStmt(NextToken[1])) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiONLY) then
        Nodes.RealOnlyTag := ParseTag(kiREAD, kiONLY)
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWRITE) then
        Nodes.RealOnlyTag := ParseTag(kiREAD, kiWRITE)
      else
        SetError(PE_UnexpectedToken)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiWITH) then
      Nodes.WithConsistentSnapshotTag := ParseTag(kiWITH, kiCONSISTENT, kiSNAPSHOT)
    else
      Found := False;

  Result := TStartTransactionStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseStopSlaveStmt(): TOffset;
var
  Nodes: TStopSlaveStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtTag := ParseTag(kiSTOP, kiSLAVE);

  Result := TStopSlaveStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseStmt(): TOffset;
var
  Continue: Boolean;
  Index: Integer;
  FFirstTokenAll: TOffset;
  FLastTokenAll: TOffset;
  KeywordIndex: TWordList.TIndex; // Cache for speeding
  KeywordIndex1: TWordList.TIndex; // Cache for speeding
  KeywordIndex2: TWordList.TIndex; // Cache for speeding
  KeywordToken: TOffset;
  T: PToken;
  Token: TOffset;
begin
  Result := 0;
  {$IFDEF Debug}
  Continue := False;
  {$ENDIF}

  if (PreviousToken = 0) then
    FFirstTokenAll := 1
  else
  begin
    T := TokenPtr(PreviousToken);
    if (T^.TokenType = ttDelimiter) then
    begin
      repeat
        FFirstTokenAll := T^.Offset;
        T := T^.NextTokenAll;
      until (not Assigned(T) or (T^.TokenType in [ttSpace, ttReturn]));
      if (Assigned(T)) then
        FFirstTokenAll := T^.Offset;
    end
    else
    begin
      repeat
        T := T^.NextTokenAll;
      until (not Assigned(T) or (T^.TokenType in [ttSpace, ttReturn]));
      if (Assigned(T)) then
        T := T^.NextTokenAll;
      if (not Assigned(T) or not Assigned(T^.NextTokenAll)) then
        FFirstTokenAll := 0
      else
        FFirstTokenAll := T^.NextTokenAll^.Offset;
    end;
  end;

  KeywordToken := CurrentToken;
  if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttBeginLabel)) then
    KeywordToken := NextToken[1];

  if (EndOfStmt(KeywordToken)) then
    SetError(PE_IncompleteStmt)
  else
  begin
    KeywordIndex := TokenPtr(KeywordToken)^.KeywordIndex;

    if (KeywordIndex = kiANALYZE) then
      Result := ParseAnalyzeStmt()
    else if (KeywordIndex = kiALTER) then
      Result := ParseAlterStmt()
    else if (KeywordIndex = kiBEGIN) then
      if (not InPL_SQL) then
        Result := ParseBeginStmt()
      else
        Result := ParseCompoundStmt()
    else if (KeywordIndex = kiCALL) then
      Result := ParseCallStmt()
    else if (InPL_SQL and (KeywordIndex = kiCASE)) then
      Result := ParseCaseStmt()
    else if (KeywordIndex = kiCHECK) then
      Result := ParseCheckStmt()
    else if (KeywordIndex = kiCHECKSUM) then
      Result := ParseChecksumStmt()
    else if (InPL_SQL and (KeywordIndex = kiCLOSE)) then
      Result := ParseCloseStmt()
    else if (KeywordIndex = kiCOMMIT) then
      Result := ParseCommitStmt()
    else if (KeywordIndex = kiCREATE) then
      Result := ParseCreateStmt()
    else if (KeywordIndex = kiDEALLOCATE) then
      Result := ParseDeallocatePrepareStmt()
    else if (InPL_SQL and (KeywordIndex = kiDECLARE)) then
      if (not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiCONDITION)) then
        Result := ParseDeclareConditionStmt()
      else if (not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiCURSOR)) then
        Result := ParseDeclareCursorStmt()
      else if (not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiHANDLER)) then
        Result := ParseDeclareHandlerStmt()
      else
        Result := ParseDeclareStmt()
    else if (KeywordIndex = kiDELETE) then
      Result := ParseDeleteStmt()
    else if (KeywordIndex = kiDESC) then
      Result := ParseExplainStmt()
    else if (KeywordIndex = kiDESCRIBE) then
      Result := ParseExplainStmt()
    else if (KeywordIndex = kiDO) then
      Result := ParseDoStmt()
    else if (KeywordIndex = kiDROP) then
    begin
      if (EndOfStmt(NextToken[1])) then
        SetError(PE_IncompleteStmt)
      else
      begin
        KeywordIndex1 := TokenPtr(NextToken[1])^.KeywordIndex;
        if (KeywordIndex1 = kiDATABASE) then
          Result := ParseDropDatabaseStmt()
        else if (KeywordIndex1 = kiEVENT) then
          Result := ParseDropEventStmt()
        else if (KeywordIndex1 = kiFUNCTION) then
          Result := ParseDropRoutineStmt(rtFunction)
        else if (KeywordIndex1 = kiINDEX) then
          Result := ParseDropIndexStmt()
        else if (KeywordIndex1 = kiPREPARE) then
          Result := ParseDeallocatePrepareStmt()
        else if (KeywordIndex1 = kiPROCEDURE) then
          Result := ParseDropRoutineStmt(rtProcedure)
        else if (KeywordIndex1 = kiSCHEMA) then
          Result := ParseDropDatabaseStmt()
        else if (KeywordIndex1 = kiSERVER) then
          Result := ParseDropServerStmt()
        else if (KeywordIndex1 = kiTEMPORARY) then
        begin
          if (EndOfStmt(NextToken[2])) then
            SetError(PE_IncompleteStmt)
          else if (TokenPtr(NextToken[2])^.KeywordIndex <> kiTABLE) then
            SetError(PE_UnexpectedToken, NextToken[2])
          else
            Result := ParseDropTableStmt();
        end
        else if (KeywordIndex1 = kiTABLE) then
          Result := ParseDropTableStmt()
        else if (KeywordIndex1 = kiTRIGGER) then
          Result := ParseDropTriggerStmt()
        else if (KeywordIndex1 = kiUSER) then
          Result := ParseDropUserStmt()
        else if (KeywordIndex1 = kiVIEW) then
          Result := ParseDropViewStmt()
        else
        begin
          SetError(PE_UnkownStmt, NextToken[1]);
          Result := ParseUnknownStmt();
        end;
      end;
    end
    else if (KeywordIndex = kiEXECUTE) then
      Result := ParseExecuteStmt()
    else if (KeywordIndex = kiEXPLAIN) then
      Result := ParseExplainStmt()
    else if (InPL_SQL and (KeywordIndex = kiFETCH)) then
      Result := ParseFetchStmt()
    else if (KeywordIndex = kiFLUSH) then
      Result := ParseFlushStmt()
    else if ((KeywordIndex = kiGET)
      and not EndOfStmt(NextToken[2])
      and ((((TokenPtr(NextToken[1])^.KeywordIndex = kiCURRENT) or (TokenPtr(NextToken[1])^.KeywordIndex = kiSTACKED)) and (TokenPtr(NextToken[2])^.KeywordIndex = kiDIAGNOSTICS)) or (TokenPtr(NextToken[1])^.KeywordIndex = kiDIAGNOSTICS))) then
      Result := ParseGetDiagnosticsStmt()
    else if (KeywordIndex = kiGRANT) then
      Result := ParseGrantStmt()
    else if (KeywordIndex = kiHELP) then
      Result := ParseHelpStmt()
    else if (InPL_SQL and (KeywordIndex = kiIF)) then
      Result := ParseIfStmt()
    else if (KeywordIndex = kiINSERT) then
      Result := ParseInsertStmt()
    else if (InPL_SQL and (KeywordIndex = kiITERATE)) then
      Result := ParseIterateStmt()
    else if (KeywordIndex = kiKILL) then
      Result := ParseKillStmt()
    else if (InPL_SQL and (KeywordIndex = kiLEAVE)) then
      Result := ParseLeaveStmt()
    else if ((KeywordIndex = kiLOAD)) then
      Result := ParseLoadStmt()
    else if ((KeywordIndex = kiLOCK)) then
      Result := ParseLockStmt()
    else if (InPL_SQL and (KeywordIndex = kiLOOP)) then
      Result := ParseLoopStmt()
    else if (KeywordIndex = kiPREPARE) then
      Result := ParsePrepareStmt()
    else if (KeywordIndex = kiPURGE) then
      Result := ParsePurgeStmt()
    else if (InPL_SQL and (KeywordIndex = kiOPEN)) then
      Result := ParseOpenStmt()
    else if (KeywordIndex = kiRENAME) then
      Result := ParseRenameStmt()
    else if (KeywordIndex = kiREPAIR) then
      Result := ParseRepairStmt()
    else if (InPL_SQL and (KeywordIndex = kiREPEAT)) then
      Result := ParseRepeatStmt()
    else if (KeywordIndex = kiRELEASE) then
      Result := ParseReleaseStmt()
    else if (KeywordIndex = kiREPLACE) then
      Result := ParseInsertStmt()
    else if (KeywordIndex = kiRESET) then
      Result := ParseResetStmt()
    else if (InPL_SQL and (KeywordIndex = kiRETURN) and InCreateFunctionStmt) then
      Result := ParseReturnStmt()
    else if (KeywordIndex = kiREVOKE) then
      Result := ParseRevokeStmt()
    else if (KeywordIndex = kiROLLBACK) then
      Result := ParseRollbackStmt()
    else if (KeywordIndex = kiSAVEPOINT) then
      Result := ParseSavepointStmt()
    else if (KeywordIndex = kiSELECT) then
      Result := ParseSelectStmt()
    else if (KeywordIndex = kiSET) then
      if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiNAMES)) then
        Result := ParseSetNamesStmt()
      else if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiCHARACTER)) then
        Result := ParseSetNamesStmt()
      else if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiPASSWORD)) then
        Result := ParseSetPasswordStmt()
      else
      begin
        if (EndOfStmt(NextToken[1]) or (TokenPtr(NextToken[1])^.KeywordIndex <> kiGLOBAL) and (TokenPtr(NextToken[1])^.KeywordIndex <> kiSESSION)) then
          Index := 1
        else
          Index := 2;
        if (not EndOfStmt(NextToken[Index]) and (TokenPtr(NextToken[Index])^.KeywordIndex = kiTRANSACTION)) then
          Result := ParseSetTransactionStmt()
        else
          Result := ParseSetStmt()
      end
    else
    {$IFDEF Debug}
      Continue := True; // This "Hack" is needed to use <Ctrl+LeftClick>
    if (Continue) then  // the Delphi XE2 IDE. But why???
    {$ENDIF}
    if (KeywordIndex = kiSHOW) then
    begin
      KeywordIndex1 := 0; KeywordIndex2 := 0;
      if (not EndOfStmt(NextToken[1])) then
      begin
        KeywordIndex1 := TokenPtr(NextToken[1])^.KeywordIndex;
        if (not EndOfStmt(NextToken[2])) then
          KeywordIndex2 := TokenPtr(NextToken[2])^.KeywordIndex;
      end;
      if ((KeywordIndex1 = kiAUTHORS)) then
        Result := ParseShowAuthorsStmt()
      else if ((KeywordIndex1 = kiBINARY) and (KeywordIndex2 = kiLOGS)) then
        Result := ParseShowBinaryLogsStmt()
      else if ((KeywordIndex1 = kiMASTER) and (KeywordIndex2 = kiLOGS)) then
        Result := ParseShowBinaryLogsStmt()
      else if ((KeywordIndex1 = kiBINLOG) and (KeywordIndex2 = kiEVENTS)) then
        Result := ParseShowBinlogEventsStmt()
      else if ((KeywordIndex1 = kiCHARACTER) and (KeywordIndex2 = kiSET)) then
        Result := ParseShowCharacterSetStmt()
      else if ((KeywordIndex1 = kiCOLLATION)) then
        Result := ParseShowCollationStmt()
      else if ((KeywordIndex1 = kiCONTRIBUTORS)) then
        Result := ParseShowContributorsStmt()
      else if (not EndOfStmt(NextToken[5]) and (TokenPtr(NextToken[5])^.KeywordIndex = kiERRORS)) then
        Result := ParseShowCountErrorsStmt()
      else if (not EndOfStmt(NextToken[5]) and (TokenPtr(NextToken[5])^.KeywordIndex = kiWARNINGS)) then
        Result := ParseShowCountWarningsStmt()
      else if ((KeywordIndex1 = kiCREATE) and (KeywordIndex2 = kiDATABASE)) then
        Result := ParseShowCreateDatabaseStmt()
      else if ((KeywordIndex1 = kiCREATE) and (KeywordIndex2 = kiEVENT)) then
        Result := ParseShowCreateEventStmt()
      else if ((KeywordIndex1 = kiCREATE) and (KeywordIndex2 = kiFUNCTION)) then
        Result := ParseShowCreateFunctionStmt()
      else if ((KeywordIndex1 = kiCREATE) and (KeywordIndex2 = kiPROCEDURE)) then
        Result := ParseShowCreateProcedureStmt()
      else if ((KeywordIndex1 = kiCREATE) and (KeywordIndex2 = kiSCHEMA)) then
        Result := ParseShowCreateDatabaseStmt()
      else if ((KeywordIndex1 = kiCREATE) and (KeywordIndex2 = kiPROCEDURE)) then
        Result := ParseShowCreateProcedureStmt()
      else if ((KeywordIndex1 = kiCREATE) and (KeywordIndex2 = kiTABLE)) then
        Result := ParseShowCreateTableStmt()
      else if ((KeywordIndex1 = kiCREATE) and (KeywordIndex2 = kiTRIGGER)) then
        Result := ParseShowCreateTriggerStmt()
      else if ((KeywordIndex1 = kiCREATE) and (KeywordIndex2 = kiVIEW)) then
        Result := ParseShowCreateViewStmt()
      else if ((KeywordIndex1 = kiDATABASES)) then
        Result := ParseShowDatabasesStmt()
      else if ((KeywordIndex1 = kiENGINE)) then
        Result := ParseShowEngineStmt()
      else if ((KeywordIndex1 = kiENGINES)) then
        Result := ParseShowEnginesStmt()
      else if ((KeywordIndex1 = kiERRORS)) then
        Result := ParseShowErrorsStmt()
      else if ((KeywordIndex1 = kiEVENTS)) then
        Result := ParseShowEventsStmt()
      else if ((KeywordIndex1 = kiFUNCTION) and (KeywordIndex2 = kiCODE)) then
        Result := ParseShowFunctionCodeStmt()
      else if ((KeywordIndex1 = kiFUNCTION) and (KeywordIndex2 = kiSTATUS)) then
        Result := ParseShowFunctionStatusStmt()
      else if ((KeywordIndex1 = kiGRANTS)) then
        Result := ParseShowGrantsStmt()
      else if ((KeywordIndex1 = kiINDEX)) then
        Result := ParseShowIndexStmt()
      else if ((KeywordIndex1 = kiINDEXES)) then
        Result := ParseShowIndexStmt()
      else if ((KeywordIndex1 = kiKEYS)) then
        Result := ParseShowIndexStmt()
      else if ((KeywordIndex1 = kiMASTER) and (KeywordIndex2 = kiSTATUS)) then
        Result := ParseShowMasterStatusStmt()
      else if ((KeywordIndex1 = kiOPEN) and (KeywordIndex2 = kiTABLES)) then
        Result := ParseShowOpenTablesStmt()
      else if ((KeywordIndex1 = kiPLUGINS)) then
        Result := ParseShowPluginsStmt()
      else if ((KeywordIndex1 = kiPRIVILEGES)) then
        Result := ParseShowPrivilegesStmt()
      else if ((KeywordIndex1 = kiPROCEDURE) and (KeywordIndex2 = kiCODE)) then
        Result := ParseShowProcedureCodeStmt()
      else if ((KeywordIndex1 = kiPROCEDURE) and (KeywordIndex2 = kiSTATUS)) then
        Result := ParseShowProcedureStatusStmt()
      else if ((KeywordIndex1 = kiFULL) and (KeywordIndex2 = kiPROCESSLIST)) then
        Result := ParseShowProcessListStmt()
      else if ((KeywordIndex1 = kiPROCESSLIST)) then
        Result := ParseShowProcessListStmt()
      else if ((KeywordIndex1 = kiPROFILE)) then
        Result := ParseShowProfileStmt()
      else if ((KeywordIndex1 = kiPROFILES)) then
        Result := ParseShowProfilesStmt()
      else if ((KeywordIndex1 = kiRELAYLOG) and (KeywordIndex2 = kiEVENTS)) then
        Result := ParseShowRelaylogEventsStmt()
      else if ((KeywordIndex1 = kiSLAVE) and (KeywordIndex2 = kiHOSTS)) then
        Result := ParseShowSlaveHostsStmt()
      else if ((KeywordIndex1 = kiSLAVE) and (KeywordIndex2 = kiSTATUS)) then
        Result := ParseShowSlaveStatusStmt()
      else if ((KeywordIndex1 = kiSTATUS)
        or (KeywordIndex1 = kiGLOBAL) and (KeywordIndex2 = kiSTATUS)
        or (KeywordIndex1 = kiSESSION) and (KeywordIndex2 = kiSTATUS)) then
        Result := ParseShowStatusStmt()
      else if ((KeywordIndex1 = kiTABLE) and (KeywordIndex2 = kiSTATUS)) then
        Result := ParseShowTableStatusStmt()
      else if ((KeywordIndex1 = kiTABLES)) then
        Result := ParseShowTablesStmt()
      else if ((KeywordIndex1 = kiTRIGGERS)) then
        Result := ParseShowTriggersStmt()
      else if ((KeywordIndex1 = kiVARIABLES)
        or (KeywordIndex1 = kiGLOBAL) and (KeywordIndex2 = kiVARIABLES)
        or (KeywordIndex1 = kiSESSION) and (KeywordIndex2 = kiVARIABLES)) then
        Result := ParseShowVariablesStmt()
      else if ((KeywordIndex1 = kiWARNINGS)) then
        Result := ParseShowWarningsStmt()
      else if ((KeywordIndex1 = kiSTORAGE) and (KeywordIndex2 = kiENGINES)) then
        Result := ParseShowEnginesStmt()
      else
      begin
        SetError(PE_UnkownStmt, CurrentToken);
        Result := ParseUnknownStmt();
      end;
    end
    else if (KeywordIndex = kiSHUTDOWN) then
      Result := ParseShutdownStmt()
    else if (KeywordIndex = kiSIGNAL) then
      Result := ParseSignalStmt()
    else if ((KeywordIndex = kiSTART)
      and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSLAVE)) then
      Result := ParseStartSlaveStmt()
    else if (KeywordIndex = kiSTART) then
      Result := ParseStartTransactionStmt()
    else if (KeywordIndex = kiSTOP) then
      Result := ParseStopSlaveStmt()
    else if (KeywordIndex = kiTRUNCATE) then
      Result := ParseTruncateTableStmt()
    else if (KeywordIndex = kiUNLOCK) then
      Result := ParseUnlockStmt()
    else if (KeywordIndex = kiUPDATE) then
      Result := ParseUpdateStmt()
    else if (KeywordIndex = kiUSE) then
      Result := ParseUseStmt()
    else if (InPL_SQL and (KeywordIndex = kiWHILE)) then
      Result := ParseWhileStmt()
    else if (KeywordIndex = kiXA) then
      Result := ParseXAStmt()
    else
    begin
      SetError(PE_UnkownStmt);
      Result := ParseUnknownStmt();
    end;

    if (IsStmt(Result)) then
    begin
      if (not Error and not EndOfStmt(CurrentToken)) then
        SetError(PE_ExtraToken);

      // Add unparsed Tokens to the Stmt
      while (not EndOfStmt(CurrentToken)) do
      begin
        Token := ApplyCurrentToken();
        StmtPtr(Result)^.Heritage.AddChild(Token);
      end;

      Token := StmtPtr(Result)^.FLastToken;
      FLastTokenAll := Token;
      while ((Token > 0) and (TokenPtr(Token)^.TokenType <> ttDelimiter)) do
      begin
        T := TokenPtr(Token)^.NextTokenAll;
        if (not Assigned(T)) then
          Token := 0
        else
          Token := T^.Offset;
        if ((Token > 0) and (TokenPtr(Token)^.TokenType <> ttDelimiter)) then
          FLastTokenAll := Token;
      end;

      StmtPtr(Result)^.FErrorCode := FErrorCode;
      StmtPtr(Result)^.FErrorToken := FErrorToken;
      StmtPtr(Result)^.FFirstTokenAll := FFirstTokenAll;
      StmtPtr(Result)^.FLastTokenAll := FLastTokenAll;
    end;
  end;
end;

function TMySQLParser.ParseString(): TOffset;
begin
  Result := 0;
  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (not (TokenPtr(CurrentToken)^.TokenType in ttStrings) and not ((TokenPtr(CurrentToken)^.TokenType = ttIdent) and (TokenPtr(CurrentToken)^.KeywordIndex < 0))) then
    SetError(PE_UnexpectedToken)
  else
    Result := ApplyCurrentToken();
end;

function TMySQLParser.ParseSubArea(const ParseNode: TParseFunction): TOffset;
var
  Nodes: TSubArea.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
    SetError(PE_UnexpectedToken)
  else
    Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error) then
    Nodes.AreaNode := ParseNode();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TSubArea.Create(Self, Nodes);
end;

function TMySQLParser.ParseSubPartition(): TOffset;
var
  Found: Boolean;
  Nodes: TSubPartition.TNodes;
begin
  if (not Error) then
    Nodes.SubPartitionTag := ParseTag(kiPARTITION);

  if (not Error) then
    Nodes.NameIdent := ParseCreateTableStmtPartitionIdent();

  Found := True;
  while (not Error and Found and not EndOfStmt(CurrentToken)) do
    if ((Nodes.CommentValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCOMMENT)) then
      Nodes.CommentValue := ParseValue(kiCOMMENT, vaAuto, ParseString)
    else if ((Nodes.DataDirectoryValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDATA)) then
      Nodes.DataDirectoryValue := ParseValue(WordIndices(kiDATA, kiDIRECTORY), vaAuto, ParseString)
    else if ((Nodes.EngineValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiENGINE)) then
      Nodes.EngineValue := ParseValue(kiENGINE, vaAuto, ParseIdent)
    else if ((Nodes.IndexDirectoryValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiINDEX)) then
      Nodes.IndexDirectoryValue := ParseValue(WordIndices(kiINDEX, kiDIRECTORY), vaAuto, ParseString)
    else if ((Nodes.MaxRowsValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiMAX_ROWS)) then
      Nodes.MaxRowsValue := ParseValue(kiMAX_ROWS, vaAuto, ParseInteger)
    else if ((Nodes.MinRowsValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiMIN_ROWS)) then
      Nodes.MinRowsValue := ParseValue(kiMIN_ROWS, vaAuto, ParseInteger)
    else if ((Nodes.EngineValue = 0) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSTORAGE)) then
      Nodes.EngineValue := ParseValue(WordIndices(kiSTORAGE, kiENGINE), vaAuto, ParseIdent)
    else
      Found := False;

  Result := TSubPartition.Create(Self, Nodes);
end;

function TMySQLParser.ParseSubstringFunc(): TOffset;
var
  Nodes: TSubstringFunc.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.FuncToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Str := ParseExpr();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiFROM) then
      Nodes.FromTag := ParseTag(kiFROM)
    else if (TokenPtr(CurrentToken)^.TokenType = ttComma) then
      Nodes.FromTag := ApplyCurrentToken()
    else
      SetError(PE_UnexpectedToken);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Pos := ParseExpr();

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiFOR) then
      Nodes.ForTag := ParseTag(kiFOR)
    else if (TokenPtr(CurrentToken)^.TokenType = ttComma) then
      Nodes.ForTag := ApplyCurrentToken();

  if (not Error and (Nodes.ForTag > 0)) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Len := ParseExpr();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TSubstringFunc.Create(Self, Nodes);
end;

function TMySQLParser.ParseTableIdent(): TOffset;
begin
  Result := ParseDbIdent(ditTable);
end;

function TMySQLParser.ParseTableReference(): TOffset;
var
  Nodes: TSelectStmt.TTableReferenceOj.TNodes;
begin
  if (TokenPtr(CurrentToken)^.TokenType <> ttOpenCurlyBracket) then
    Result := ParseTableReferenceInner()
  else
  begin
    FillChar(Nodes, SizeOf(Nodes), 0);

    Nodes.OpenBracketToken := ApplyCurrentToken();

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiOJ) then
        SetError(PE_UnexpectedToken)
      else
        Nodes.OjTag := ParseTag(kiOJ);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.TableReference := ParseTableReferenceInner();

    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracketToken := ApplyCurrentToken();

    Result := TSelectStmt.TTableReferenceOj.Create(Self, Nodes);
  end;
end;

function TMySQLParser.ParseTableReferenceInner(): TOffset;

  function ParseTableFactor(): TOffset;
  var
    Nodes: TSelectStmt.TTableFactor.TNodes;
    ReferencesNodes: TSelectStmt.TTableFactorReferences.TNodes;
    SelectNodes: TSelectStmt.TTableFactorSelect.TNodes;
  begin
    if (TokenPtr(CurrentToken)^.TokenType in ttIdents) then
    begin
      FillChar(Nodes, SizeOf(Nodes), 0);

      Nodes.TableIdent := ParseTableIdent();

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiPARTITION)) then
      begin
        Nodes.PartitionTag := ParseTag(kiPARTITION);

        if (not Error) then
          Nodes.Partitions := ParseList(True, ParseCreateTableStmtPartitionIdent);
      end;

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAS)) then
      begin
        Nodes.AsToken := ParseTag(kiAS);
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents) or (TokenPtr(CurrentToken)^.KeywordIndex >= 0)) then
          SetError(PE_UnexpectedToken);
      end;

      if (not Error and not EndOfStmt(CurrentToken)
        and (TokenPtr(CurrentToken)^.KeywordIndex < 0)
        and (TokenPtr(CurrentToken)^.TokenType in ttIdents + ttStrings)) then
        Nodes.AliasToken := ParseAlias();

      if (not Error and not EndOfStmt(CurrentToken) and ((TokenPtr(CurrentToken)^.KeywordIndex = kiUSE) or (TokenPtr(CurrentToken)^.KeywordIndex = kiIGNORE) or (TokenPtr(CurrentToken)^.KeywordIndex = kiFORCE))) then
        Nodes.IndexHintList := ParseList(False, ParseIndexHint);

      Result := TSelectStmt.TTableFactor.Create(Self, Nodes);
    end
    else if ((TokenPtr(CurrentToken)^.TokenType = ttOpenBracket) and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiSELECT)) then
    begin
      SelectNodes.SelectStmt := ParseSubArea(ParseSelectStmt);

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiAS)) then
        SelectNodes.AsToken := ParseTag(kiAS);

      if (not Error) then
        SelectNodes.AliasToken := ParseAlias();

      Result := TSelectStmt.TTableFactorSelect.Create(Self, SelectNodes);
    end
    else if (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket) then
    begin
      FillChar(ReferencesNodes, SizeOf(ReferencesNodes), 0);

      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        ReferencesNodes.ReferenceList := ParseList(True, ParseTableReference);

      Result := TSelectStmt.TTableFactorReferences.Create(Self, ReferencesNodes);
    end
    else
    begin
      SetError(PE_UnexpectedToken);
      Result := 0;
    end;
  end;

var
  FirstTable: TOffset;
  JoinCount: Integer;
  JoinNodes: TSelectStmt.TTableReferenceJoin.TNodes;
  Joins: array [0 .. 19] of TOffset;
  JoinType: TJoinType;
begin
  JoinCount := 0;
  {$IFDEF Debug} FillChar(Joins, SizeOf(Joins), 0); {$ENDIF}

  FirstTable := ParseTableFactor();

  while (not Error and not EndOfStmt(CurrentToken)
    and ((TokenPtr(CurrentToken)^.KeywordIndex = kiINNER)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiCROSS)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiJOIN)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiSTRAIGHT_JOIN)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiLEFT)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiRIGHT)
      or (TokenPtr(CurrentToken)^.KeywordIndex = kiNATURAL))) do
  begin
    FillChar(JoinNodes, SizeOf(JoinNodes), 0);

    JoinType := jtUnknown;
    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiINNER)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiJOIN)) then
      begin
        JoinNodes.JoinTag := ParseTag(kiINNER, kiJOIN);
        JoinType := jtInner
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiCROSS)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiJOIN)) then
      begin
        JoinNodes.JoinTag := ParseTag(kiCROSS, kiJOIN);
        JoinType := jtCross;
      end
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiJOIN) then
      begin
        JoinNodes.JoinTag := ParseTag(kiJOIN);
        JoinType := jtInner;
      end
      else if (TokenPtr(CurrentToken)^.KeywordIndex = kiSTRAIGHT_JOIN) then
      begin
        JoinNodes.JoinTag := ParseTag(kiSTRAIGHT_JOIN);
        JoinType := jtCross;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiLEFT)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiJOIN)) then
      begin
        JoinNodes.JoinTag := ParseTag(kiLEFT, kiJOIN);
        JoinType := jtLeft;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiLEFT)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiOUTER)
        and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiJOIN)) then
      begin
        JoinNodes.JoinTag := ParseTag(kiLEFT, kiOUTER, kiJOIN);
        JoinType := jtLeft;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiRIGHT)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiJOIN)) then
      begin
        JoinNodes.JoinTag := ParseTag(kiRIGHT, kiJOIN);
        JoinType := jtRight;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiRIGHT)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiOUTER)
        and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiJOIN)) then
      begin
        JoinNodes.JoinTag := ParseTag(kiRIGHT, kiOUTER, kiJOIN);
        JoinType := jtRight;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiNATURAL)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiJOIN)) then
      begin
        JoinNodes.JoinTag := ParseTag(kiNATURAL, kiJOIN);
        JoinType := jtEqui;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiNATURAL)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiLEFT)
        and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiJOIN)) then
      begin
        JoinNodes.JoinTag := ParseTag(kiNATURAL, kiLEFT, kiJOIN);
        JoinType := jtNaturalLeft;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiNATURAL)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiLEFT)
        and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiOUTER)
        and not EndOfStmt(NextToken[3]) and (TokenPtr(NextToken[3])^.KeywordIndex = kiJOIN)) then
      begin
        JoinNodes.JoinTag := ParseTag(kiNATURAL, kiLEFT, kiOUTER, kiJOIN);
        JoinType := jtNaturalLeft;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiNATURAL)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiRIGHT)
        and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiJOIN)) then
      begin
        JoinNodes.JoinTag := ParseTag(kiNATURAL, kiRIGHT, kiJOIN);
        JoinType := jtNaturalRight;
      end
      else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiNATURAL)
        and not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiRIGHT)
        and not EndOfStmt(NextToken[2]) and (TokenPtr(NextToken[2])^.KeywordIndex = kiOUTER)
        and not EndOfStmt(NextToken[3]) and (TokenPtr(NextToken[3])^.KeywordIndex = kiJOIN)) then
      begin
        JoinNodes.JoinTag := ParseTag(kiNATURAL, kiRIGHT, kiOUTER, kiJOIN);
        JoinType := jtNaturalRight;
      end
      else
        raise Exception.Create(SUnknownError);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
      begin
        if (not (JoinType in [jtLeft, jtRight])) then
        begin
          JoinNodes.RightTable := ParseTableFactor();

          if (not Error) then
            if (EndOfStmt(CurrentToken)) then
              SetError(PE_IncompleteStmt)
            else if ((JoinType in [jtStraight]) and (TokenPtr(CurrentToken)^.KeywordIndex = kiON)) then
            begin
              JoinNodes.OnTag := ParseTag(kiON);
              if (not Error) then
                if (EndOfStmt(CurrentToken)) then
                  SetError(PE_IncompleteStmt)
                else if (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket) then
                  JoinNodes.Condition := ParseList(True, ParseExpr)
                else
                  JoinNodes.Condition := ParseExpr();
            end
            else if (JoinType in [jtInner, jtCross]) then
              if (TokenPtr(CurrentToken)^.KeywordIndex = kiON) then
              begin
                JoinNodes.OnTag := ParseTag(kiON);
                if (not Error) then
                  if (EndOfStmt(CurrentToken)) then
                    SetError(PE_IncompleteStmt)
                  else if (TokenPtr(CurrentToken)^.TokenType = ttOpenBracket) then
                    JoinNodes.Condition := ParseList(True, ParseExpr)
                  else
                    JoinNodes.Condition := ParseExpr();
              end
              else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUSING) then
              begin
                JoinNodes.OnTag := ParseTag(kiUSING);
                if (not Error) then
                  if (EndOfStmt(CurrentToken)) then
                    SetError(PE_IncompleteStmt)
                  else
                    JoinNodes.Condition := ParseList(True, ParseColumnIdent);
              end;
        end
        else
        begin
          JoinNodes.RightTable := ParseTableFactor(); // Should be "ParseTableReference", but I don't know to handle it with this parser... :-(

          if (not Error and not EndOfStmt(CurrentToken) and not (JoinType in [jtNaturalLeft, jtNaturalRight])) then
            if (TokenPtr(CurrentToken)^.KeywordIndex = kiON) then
            begin
              JoinNodes.OnTag := ParseTag(kiON);
              if (not Error) then
                if (EndOfStmt(CurrentToken)) then
                  SetError(PE_IncompleteStmt)
                else
                  JoinNodes.Condition := ParseExpr();
            end
            else if (TokenPtr(CurrentToken)^.KeywordIndex = kiUSING) then
            begin
              JoinNodes.OnTag := ParseTag(kiUSING);
              if (not Error) then
                if (EndOfStmt(CurrentToken)) then
                  SetError(PE_IncompleteStmt)
                else
                  JoinNodes.Condition := ParseList(True, ParseColumnIdent);
            end;
        end;

      end;

    Joins[JoinCount] := TSelectStmt.TTableReferenceJoin.Create(Self, JoinType, JoinNodes);
    Inc(JoinCount);
  end;

  Result := TTableReference.Create(Self, FirstTable, JoinCount, Joins);
end;

function TMySQLParser.ParseTag(const KeywordIndex1: TWordList.TIndex; const KeywordIndex2: TWordList.TIndex = -1; const KeywordIndex3: TWordList.TIndex = -1; const KeywordIndex4: TWordList.TIndex = -1): TOffset;
var
  Nodes: TTag.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex <> KeywordIndex1) then
    SetError(PE_UnexpectedToken)
  else
  begin
    TokenPtr(CurrentToken)^.FOperatorType := otUnknown;
    Nodes.KeywordToken1 := ApplyCurrentToken();

    if (KeywordIndex2 >= 0) then
    begin
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.KeywordIndex <> KeywordIndex2) then
        SetError(PE_UnexpectedToken)
      else
      begin
        TokenPtr(CurrentToken)^.FOperatorType := otUnknown;
        Nodes.KeywordToken2 := ApplyCurrentToken();

        if (KeywordIndex3 >= 0) then
        begin
          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else if (TokenPtr(CurrentToken)^.KeywordIndex <> KeywordIndex3) then
            SetError(PE_UnexpectedToken)
          else
          begin
            TokenPtr(CurrentToken)^.FOperatorType := otUnknown;
            Nodes.KeywordToken3 := ApplyCurrentToken();

            if (KeywordIndex4 >= 0) then
            begin
              if (EndOfStmt(CurrentToken)) then
                SetError(PE_IncompleteStmt)
              else if (TokenPtr(CurrentToken)^.KeywordIndex <> KeywordIndex4) then
                SetError(PE_UnexpectedToken)
              else
              begin
                TokenPtr(CurrentToken)^.FOperatorType := otUnknown;
                Nodes.KeywordToken4 := ApplyCurrentToken();
              end;
            end;
          end;
        end;
      end;
    end;
  end;

  Result := TTag.Create(Self, Nodes);
end;

function TMySQLParser.ParseToken(): TOffset;
label
  TwoChars,
  Selection, SelSpace, SelQuotedIdent, SelNotLess, SelNotEqual1, SelNotGreater, SelNot1, SelDoubleQuote, SelComment, SelModulo, SelDolor, SelAmpersand2, SelBitAND, SelSingleQuote, SelOpenBracket, SelCloseBracket, SelMySQLCodeEnd, SelMulti, SelComma, SelDoubleDot, SelDot, SelDotNumber, SelMySQLCode, SelDiv, SelInteger, SelSLComment, SelArrow, SelMinus, SelPlus, SelAssign, SelColon, SelDelimiter, SelNULLSaveEqual, SelLessEqual, SelShiftLeft, SelNotEqual2, SelLess, SelEqual, SelGreaterEqual, SelShiftRight, SelGreater, SelParameter, SelAt, SelUnquotedIdent, SelDBIdent, SelBackslash, SelCloseSquareBracket, SelHat, SelMySQLCharacterSet, SelMySQLIdent, SelBitValueHigh, SelBitValueLow, SelHexValueHigh, SelHexValueLow, SelUnquotedIdentLower, SelOpenCurlyBracket, SelOpenCurlyBracket2, SelPipe, SelBitOR, SelCloseCurlyBracket, SelTilde, SelE,
  BindVariable,
  Colon,
  Comment,
  Intger, IntgerL, IntgerE,
  MLComment, MLCommentL, MLComment2,
  MySQLCharacterSet, MySQLCharacterSetL, MySQLCharacterSetLE, MySQLCharacterSetE, MySQLCharacterSetE2,
  MySQLCondCode, MySQLCondCodeL, MySQLCondCodeE,
  Numeric, NumericL, NumericExp, NumericE, NumericDot, NumericLE,
  IPAddress, IPAddressL, IPAddressLE,
  QuotedIdent, QuotedIdentL, QuotedIdentLE, QuotedIdentE,
  Return, ReturnE,
  Separator,
  UnquotedIdent, UnquotedIdentL, UnquotedIdentLE, UnquotedIdentLabel,
  WhiteSpace, WhiteSpaceL, WhiteSpaceLE,
  IncompleteToken, UnexpectedChar, UnexpectedCharL,
  TrippelChar,
  DoubleChar,
  SingleChar,
  Finish;
const
  Terminators: PChar = #9#10#13#32'#%&()*+,-./;<=>@'; // Characters, terminating a token
  TerminatorsL = 20; // Count of Terminators
var
  DotFound: Boolean;
  EFound: Boolean;
  ErrorCode: Integer;
  ErrorPos: PChar;
  KeywordIndex: TWordList.TIndex;
  Length: Integer;
  OperatorType: TOperatorType;
  SQL: PChar;
  TokenLength: Integer;
  TokenType: fspTypes.TTokenType;
  UsageType: TUsageType;
begin
  if (ParsePosition.Length = 0) then
    Result := 0
  else
  begin
    TokenType := ttUnknown;
    OperatorType := otUnknown;
    ErrorCode := PE_Success;
    SQL := ParsePosition.Text;
    Length := ParsePosition.Length;

    asm
        PUSH ES
        PUSH ESI
        PUSH EDI
        PUSH EBX

        PUSH DS                          // string operations uses ES
        POP ES
        CLD                              // string operations uses forward direction

        MOV ESI,SQL
        MOV ECX,Length

      // ------------------------------

        CMP ECX,1                        // One character in SQL?
        JB IncompleteToken               // No!
        JA TwoChars                      // More!
        MOV EAX,0                        // Hi Char in EAX
        MOV AX,[ESI]                     // One character from SQL to AX
        JMP Selection
      TwoChars:
        MOV EAX,[ESI]                    // Two characters from SQL to AX

      Selection:
        CMP AX,9                         // Tab ?
        JE WhiteSpace                    // Yes!
        CMP AX,10                        // Line feed ?
        JE Return                        // Yes!
        CMP AX,13                        // Carriadge Return ?
        JE Return                        // Yes!
        CMP AX,31                        // Invalid char ?
        JBE UnexpectedChar               // Yes!
      SelSpace:
        CMP AX,' '                       // Space ?
        JE WhiteSpace                    // Yes!
      SelNotLess:
        CMP AX,'!'                       // "!" ?
        JNE SelDoubleQuote               // No!
        CMP EAX,$003C0021                // "!<" ?
        JNE SelNotEqual1                 // No!
        MOV OperatorType,otGreaterEqual
        JMP DoubleChar
      SelNotEqual1:
        CMP EAX,$003D0021                // "!=" ?
        JNE SelNotGreater                // No!
        MOV OperatorType,otNotEqual
        JMP DoubleChar
      SelNotGreater:
        CMP EAX,$003E0021                // "!>" ?
        JNE SelNot1                      // No!
        MOV OperatorType,otLessEqual
        JMP DoubleChar
      SelNot1:
        MOV OperatorType,otUnaryNot
        JMP SingleChar
      SelDoubleQuote:
        CMP AX,'"'                       // Double Quote  ?
        JNE SelComment                   // No!
        MOV TokenType,ttDQIdent
        MOV DX,'"'                       // End Quoter
        JMP QuotedIdent
      SelComment:
        CMP AX,'#'                       // "#" ?
        JE Comment                       // Yes!
      SelDolor:
        CMP AX,'$'                       // "$" ?
        JE UnquotedIdent                 // Yes!
      SelModulo:
        CMP AX,'%'                       // "%" ?
        JNE SelAmpersand2                // No!
        MOV OperatorType,otMOD
        JMP SingleChar
      SelAmpersand2:
        CMP AX,'&'                       // "&" ?
        JNE SelSingleQuote               // No!
        CMP EAX,$00260026                // "&&" ?
        JNE SelBitAND                    // No!
        MOV OperatorType,otAND
        JMP DoubleChar
      SelBitAND:
        MOV OperatorType,otBitAND
        JMP SingleChar
      SelSingleQuote:
        CMP AX,''''                      // Single Quote ?
        JNE SelOpenBracket               // No!
        MOV TokenType,ttString
        MOV DX,''''                      // End Quoter
        JMP QuotedIdent
      SelOpenBracket:
        CMP AX,'('                       // "(" ?
        JNE SelCloseBracket              // No!
        MOV TokenType,ttOpenBracket
        JMP SingleChar
      SelCloseBracket:
        CMP AX,')'                       // ")" ?
        JNE SelMySQLCodeEnd              // No!
        MOV TokenType,ttCloseBracket
        JMP SingleChar
      SelMySQLCodeEnd:
        CMP AX,'*'                       // "*" ?
        JNE SelPlus                      // No!
        CMP EAX,$002F002A                // "*/" ?
        JNE SelMulti                     // No!
        MOV TokenType,ttMySQLCodeEnd
        JMP DoubleChar
      SelMulti:
        MOV OperatorType,otMulti
        JMP SingleChar
      SelPlus:
        CMP AX,'+'                       // "+" ?
        JNE SelComma                     // No!
        MOV OperatorType,otPlus
        JMP SingleChar
      SelComma:
        CMP AX,','                       // "," ?
        JNE SelSLComment                 // No!
        MOV TokenType,ttComma
        JMP SingleChar
      SelSLComment:
        CMP AX,'-'                       // "-" ?
        JNE SelDoubleDot                 // No!
        CMP EAX,$002D002D                // "--" ?
        JNE SelArrow                     // No!
        CMP ECX,3                        // Three characters in SQL?
        JB DoubleChar                    // No!
        CMP WORD PTR [ESI + 4],9         // "--<Tab>" ?
        JE Comment                       // Yes!
        CMP WORD PTR [ESI + 4],10        // "--<LF>" ?
        JE Comment                       // Yes!
        CMP WORD PTR [ESI + 4],13        // "--<CR>" ?
        JE Comment                       // Yes!
        CMP WORD PTR [ESI + 4],' '       // "-- " ?
        JE Comment                       // Yes!
        JE DoubleChar
      SelArrow:
        CMP EAX,$003E002D                // "->" ?
        JNE SelMinus                     // No!
        MOV OperatorType,otArrow
        JMP DoubleChar
      SelMinus:
        MOV OperatorType,otMinus
        JMP SingleChar
      SelDoubleDot:
        CMP AX,'.'                       // "." ?
        JNE SelMySQLCode                 // No!
        CMP EAX,$002E002E                // ".." ?
        JNE SelDotNumber                 // No!
        MOV OperatorType,otDoubleDot
        JMP DoubleChar
      SelDotNumber:
        CMP EAX,$0030002E                // ".0" ?
        JB SelDot                        // Less!
        CMP EAX,$0039002E                // ".9" ?
        JA SelDot                        // Above!
        JMP Numeric
      SelDot:
        MOV TokenType,ttDot
        MOV OperatorType,otDot
        JMP SingleChar
      SelMySQLCode:
        CMP AX,'/'                       // "/" ?
        JNE SelInteger                   // No!
        CMP EAX,$002A002F                // "/*" ?
        JNE SelDiv                       // No!
        CMP ECX,3                        // Three characters in SQL?
        JB MLComment                     // No!
        CMP WORD PTR [ESI + 4],'!'       // "/*!" ?
        JNE MLComment                    // No!
        JMP MySQLCondCode                // MySQL Code!
      SelDiv:
        MOV OperatorType,otDivision
        JMP SingleChar
      SelInteger:
        CMP AX,'9'                       // Digit?
        JBE Numeric                      // Yes!
      SelAssign:
        CMP EAX,$003D003A                // ":=" ?
        JNE SelColon                     // No!
        MOV OperatorType,otAssign2
        JMP DoubleChar
      SelColon:
        CMP AX,':'                      // ":" ?
        JE UnexpectedChar                // Yes!
      SelDelimiter:
        CMP AX,';'                       // ";" ?
        JNE SelNULLSaveEqual             // No!
        MOV TokenType,ttDelimiter
        JMP SingleChar
      SelNULLSaveEqual:
        CMP AX,'<'                       // "<" ?
        JNE SelEqual                     // No!
        CMP EAX,$003D003C                // "<=" ?
        JNE SelShiftLeft                 // No!
        CMP ECX,3                        // Three characters in SQL?
        JB SelLessEqual                  // No!
        CMP WORD PTR [ESI + 4],'>'       // "<=>" ?
        JNE SelLessEqual                 // No!
        MOV OperatorType,otNULLSaveEqual
        JMP TrippelChar
      SelLessEqual:
        MOV OperatorType,otLessEqual     // "<="!
        JMP DoubleChar
      SelShiftLeft:
        CMP EAX,$003C003C                // "<<" ?
        JNE SelNotEqual2                 // No!
        MOV OperatorType,otShiftLeft
        JMP DoubleChar
      SelNotEqual2:
        CMP EAX,$003E003C                // "<>" ?
        JNE SelLess                      // No!
        MOV OperatorType,otNotEqual
        JMP DoubleChar
      SelLess:
        MOV OperatorType,otLess
        JMP SingleChar
      SelEqual:
        CMP AX,'='                       // "=" ?
        JNE SelGreaterEqual              // No!
        MOV OperatorType,otEqual
        JMP SingleChar
      SelGreaterEqual:
        CMP AX,'>'                       // ">" ?
        JNE SelParameter                 // No!
        CMP EAX,$003D003E                // ">=" ?
        JNE SelShiftRight                // No!
        MOV OperatorType,otGreaterEqual
        JMP DoubleChar
      SelShiftRight:
        CMP EAX,$003E003E                // ">>" ?
        JNE SelGreater                   // No!
        MOV OperatorType,otShiftRight
        JMP DoubleChar
      SelGreater:
        MOV OperatorType,otGreater
        JMP SingleChar
      SelParameter:
        CMP AX,'?'                       // "?" ?
        JNE SelAt                        // No!
        MOV OperatorType,otParameter
        JMP SingleChar
      SelAt:
        CMP AX,'@'                       // "@" ?
        JNE SelUnquotedIdent             // No!
        MOV TokenType,ttAt
        JMP SingleChar
      SelUnquotedIdent:
        CMP AX,'Z'                       // Up case character?
        JA SelDBIdent                    // No!
        MOV TokenType,ttIdent
        JMP UnquotedIdent                // Yes!
      SelDBIdent:
        CMP AX,'['                       // "[" ?
        JNE SelBackslash                 // No!
        MOV TokenType,ttDBIdent
        MOV DX,']'                       // End Quoter
        JMP QuotedIdent
      SelBackslash:
        CMP AX,'\'                       // "\" ?
        JNE SelCloseSquareBracket        // No!
        MOV TokenType,ttBackslash
        JMP SingleChar
      SelCloseSquareBracket:
        CMP AX,']'                       // "]" ?
        JE UnexpectedChar                // Yes!
      SelHat:
        CMP AX,'^'                       // "^" ?
        JNE SelMySQLCharacterSet         // No!
        MOV OperatorType,otHat
        JMP SingleChar
      SelMySQLCharacterSet:
        CMP AX,'_'                       // "_" ?
        JE MySQLCharacterSet             // Yes!
      SelMySQLIdent:
        CMP AX,'`'                       // "`" ?
        JNE SelBitValueHigh              // No!
        MOV TokenType,ttMySQLIdent
        MOV DX,'`'                       // End Quoter
        JMP QuotedIdent
      SelBitValueHigh:
        CMP EAX,$00270042                // "B'" ?
        JNE SelBitValueLow               // No!
        ADD ESI,2                        // Step over "B"
        DEC ECX                          // One character handled
        MOV TokenType,ttString
        MOV DX,''''                      // End Quoter
        JMP QuotedIdent
      SelBitValueLow:
        CMP EAX,$00270062                // "b'" ?
        JNE SelHexValueHigh              // No!
        ADD ESI,2                        // Step over "b"
        DEC ECX                          // One character handled
        MOV TokenType,ttString
        MOV DX,''''                      // End Quoter
        JMP QuotedIdent
      SelHexValueHigh:
        CMP EAX,$00270048                // "H'" ?
        JNE SelHexValueLow               // No!
        ADD ESI,2                        // Step over "H"
        DEC ECX                          // One character handled
        MOV TokenType,ttString
        MOV DX,''''                      // End Quoter
        JMP QuotedIdent
      SelHexValueLow:
        CMP EAX,$00270068                // "h'" ?
        JNE SelUnquotedIdentLower        // No!
        ADD ESI,2                        // Step over "h"
        DEC ECX                          // One character handled
        MOV TokenType,ttString
        MOV DX,''''                      // End Quoter
        JMP QuotedIdent
      SelUnquotedIdentLower:
        CMP AX,'z'                       // Low case character?
        JA SelOpenCurlyBracket           // No!
        MOV TokenType,ttIdent
        JMP UnquotedIdent                // Yes!
      SelOpenCurlyBracket:
        CMP AX,'{'                       // "{" ?
        JNE SelPipe                      // No!
        MOV TokenType,ttOpenCurlyBracket
        CMP DWORD PTR [ESI + 2],$004A004F// "{OJ" ?
        JE SelOpenCurlyBracket2          // Yes!
        CMP DWORD PTR [ESI + 2],$006A004F// "{Oj" ?
        JE SelOpenCurlyBracket2          // Yes!
        CMP DWORD PTR [ESI + 2],$004A006F// "{oJ" ?
        JE SelOpenCurlyBracket2          // Yes!
        CMP DWORD PTR [ESI + 2],$006A006F// "{oj" ?
        JE SelOpenCurlyBracket2          // Yes!
        JMP SelPipe
      SelOpenCurlyBracket2:
        CMP ECX,4                        // Four characters in SQL?
        JB SelPipe                       // No!
        PUSH EAX
        MOV AX,WORD PTR [ESI + 6]        // "{OJ " ?
        CALL Separator
        POP EAX
        JZ SingleChar                    // Yes!
      SelPipe:
        CMP AX,'|'                       // "|" ?
        JNE SelCloseCurlyBracket         // No!
        CMP EAX,$007C007C                // "||" ?
        JNE SelBitOR                     // No!
        MOV OperatorType,otPipes
        JMP DoubleChar
      SelBitOR:
        MOV OperatorType,otBitOr
        JMP SingleChar
      SelCloseCurlyBracket:
        CMP AX,'}'                       // "}" ?
        JNE SelTilde                     // No!
        MOV TokenType,ttCloseCurlyBracket
        JMP SingleChar
      SelTilde:
        CMP AX,'~'                       // "~" ?
        JNE SelE                         // No!
        MOV OperatorType,otInvertBits
        JMP SingleChar
      SelE:
        CMP AX,127                       // #127 ?
        JE UnexpectedChar                // No!
        JMP UnquotedIdent

      // ------------------------------

      BindVariable:
        MOV TokenType,ttBindVariable
        JMP UnquotedIdent

      // ------------------------------

      Colon:
        MOV TokenType,ttBindVariable
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled
        CMP ECX,0                        // End of SQL?
        JE Finish                        // Yes!
        MOV AX,[ESI]                     // One Character from SQL to AX
        CMP AX,'A'
        JB Finish
        CMP AX,'Z'
        JBE BindVariable
        CMP AX,'a'
        JB Finish
        CMP AX,'z'
        JBE BindVariable
        JMP UnexpectedChar

      // ------------------------------

      Comment:
        MOV TokenType,ttLineComment
        CMP AX,10                        // End of line?
        JE Finish                        // Yes!
        CMP AX,13                        // End of line?
        JE Finish                        // Yes!
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled
        CMP ECX,0                        // End of SQL?
        JE Finish                        // Yes!
        MOV AX,[ESI]                     // One Character from SQL to AX
        JMP Comment

      // ------------------------------

      MLComment:
        MOV TokenType,ttMultiLineComment
        ADD ESI,4                        // Step over "/*" in SQL
        SUB ECX,2                        // Two characters handled
      MLCommentL:
        CMP ECX,2                        // Two characters left in SQL?
        JAE MLComment2                   // Yes!
        JMP IncompleteToken
      MLComment2:
        MOV EAX,[ESI]                    // Load two character from SQL
        CMP EAX,$002F002A
        JE DoubleChar
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled
        JMP MLCommentL

      // ------------------------------

      MySQLCharacterSet:
        MOV TokenType,ttCSString
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled
        MOV EDX,ESI
      MySQLCharacterSetL:
        MOV AX,[ESI]                     // One Character from SQL to AX
        CMP AX,'0'                       // Digit?
        JB MySQLCharacterSetE            // No!
        CMP AX,'9'
        JBE MySQLCharacterSetLE          // Yes!
        CMP AX,'A'                       // String character?
        JB MySQLCharacterSetE            // No!
        CMP AX,'Z'
        JBE MySQLCharacterSetLE          // Yes!
        CMP AX,'a'                       // String character?
        JB MySQLCharacterSetE            // No!
        CMP AX,'z'
        JBE MySQLCharacterSetLE          // Yes!
      MySQLCharacterSetLE:
        ADD ESI,2                        // Next character in SQL
        LOOP MySQLCharacterSetL
        JMP IncompleteToken              // End of SQL!
      MySQLCharacterSetE:
        CMP ESI,EDX                      // Empty ident?
        JE IncompleteToken               // Yes!
        MOV AX,[ESI]                     // One Character from SQL to AX
        CMP AX,''''                      // "'"?
        JE MySQLCharacterSetE2
        MOV TokenType,ttIdent
        JMP UnquotedIdent
      MySQLCharacterSetE2:
        MOV DX,''''                      // End Quoter
        JMP QuotedIdent

      // ------------------------------

      MySQLCondCode:
        MOV TokenType,ttMySQLCodeStart
        ADD ESI,6                        // Step over "/*!" in SQL
        SUB ECX,3                        // Two characters handled
        MOV EAX,0
        MOV EDX,0
      MySQLCondCodeL:
        CMP ECX,0                        // End of SQL?
        JE MySQLCondCodeE                // Yes!
        MOV AX,[ESI]                     // One Character from SQL to AX
        CMP AX,'0'                       // Digit?
        JB MySQLCondCodeE                // No!
        CMP AX,'9'                       // Digit?
        JA MySQLCondCodeE                // No!
        SUB AX,'0'                       // Str to Int
        PUSH EAX                         // EDX := EDX * 10
        MOV EAX,EDX
        MOV EDX,10
        MUL EDX
        MOV EDX,EAX
        POP EAX
        ADD EDX,EAX                      // EDX := EDX + Digit
        ADD ESI,2                        // Next character in SQL
        LOOP MySQLCondCodeL
      MySQLCondCodeE:
        JMP Finish

      // ------------------------------

      Numeric:
        MOV DotFound,False               // One dot in a numeric value allowed only
        MOV EFound,False                 // One "E" in a numeric value allowed only
        MOV TokenType,ttInteger
      NumericL:
        CMP AX,'.'                       // Dot?
        JE NumericDot                    // Yes!
        CMP AX,'E'                       // "E"?
        JE NumericExp                    // Yes!
        CMP AX,'e'                       // "e"?
        JE NumericExp                    // Yes!
        CMP AX,'0'                       // Digit?
        JB NumericE                      // No!
        CMP AX,'9'
        JA NumericE                      // No!
        JMP NumericLE
      NumericDot:
        MOV TokenType,ttNumeric          // A dot means it's an Numeric token
        CMP EFound,False                 // A 'e' before?
        JNE UnexpectedChar               // Yes!
        CMP DotFound,False               // A dot before?
        JNE IPAddress                    // Yes!
        MOV DotFound,True
        JMP NumericLE
      NumericExp:
        MOV TokenType,ttNumeric          // A 'E' means it's an Numeric token
        CMP EFound,False                 // A 'e' before?
        JNE Finish                       // Yes!
        MOV EFound,True
      NumericLE:
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled
        CMP ECX,0                        // End of SQL?
        JE Finish                        // Yes!
        MOV AX,[ESI]                     // One Character from SQL to AX
        JMP NumericL
      NumericE:
        JMP Finish

      // ------------------------------

      IPAddress:
        MOV TokenType,ttIPAddress        // A dot means it's an Numeric token
      IPAddressL:
        MOV AX,[ESI]                     // One Character from SQL to AX
        CMP AX,'.'                       // Dot?
        JE IPAddressLE                   // Yes!
        CMP AX,'0'                       // Digit?
        JB UnexpectedChar                // No!
        CMP AX,'9'
        JA UnexpectedChar                // No!
      IPAddressLE:
        ADD ESI,2                        // Next character in SQL
        LOOP IPAddressL
        JMP Finish

      // ------------------------------

      QuotedIdent:
        // DX: End Quoter
        ADD ESI,2                        // Step over Start Quoter in SQL
        DEC ECX                          // One character handled
        JZ IncompleteToken               // End of SQL!
      QuotedIdentL:
        MOV AX,[ESI]                     // One Character from SQL to AX
        CMP AX,'\'                       // Escaper?
        JNE QuotedIdentLE                // No!
        CMP ECX,0                        // End of SQL?
        JE IncompleteToken               // Yes!
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled
        MOV AX,[ESI]                     // One Character from SQL to AX
        CMP AX,DX                        // Escaped End Quoter?
        JE QuotedIdent                   // Yes!
      QuotedIdentLE:
        CMP AX,DX                        // End Quoter (unescaped)?
        JE QuotedIdentE                  // Yes!
        ADD ESI,2                        // One character handled
        LOOP QuotedIdentL
        JMP IncompleteToken
      QuotedIdentE:
        ADD ESI,2                        // Step over End Quoter in SQL
        DEC ECX                          // One character handled
        JZ Finish                        // All characters handled!
        MOV AX,[ESI]                     // One Character from SQL to AX
        CMP AX,DX                        // A seconed End Quoter (unescaped)?
        JNZ Finish                       // No!
        ADD ESI,2                        // Step over second End Quoter in SQL
        LOOP QuotedIdentL                // Handle further characters
        JMP Finish

      // ------------------------------

      Return:
        MOV TokenType,ttReturn
        MOV EDX,EAX                      // Remember first character
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled
        JZ Finish                        // End of SQL!
        MOV AX,[ESI]                     // One Character from SQL to AX
        CMP AX,DX                        // Same character like before?
        JE Finish                        // Yes!
        CMP AX,10                        // Line feed?
        JE ReturnE                       // Yes!
        CMP AX,13                        // Carriadge Return?
        JNE Finish                       // No!
      ReturnE:
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled
        JMP Finish

      // ------------------------------

      Separator:
        // AX: Char
        PUSH ECX
        MOV EDI,[Terminators]
        MOV ECX,TerminatorsL
        REPNE SCASW                      // Character = SQL separator?
        POP ECX
        RET
        // ZF, if Char is in Terminators

      // ------------------------------

      UnquotedIdent:
        MOV TokenType,ttIdent
      UnquotedIdentL:
        CALL Separator                   // SQL separator?
        JE Finish                        // Yes!
        CMP AX,32                        // Special character?
        JB UnexpectedChar                // Yes!
        CMP AX,':'                       // ":"?
        JE UnquotedIdentLabel            // Yes!
        ADD ESI,2                        // Next character in SQL
        MOV AX,[ESI]                     // One Character from SQL to AX
        LOOP UnquotedIdentL
        JMP Finish
      UnquotedIdentLabel:
        MOV TokenType,ttBeginLabel
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // Once character ":" handled
        JMP Finish

      // ------------------------------

      WhiteSpace:
        MOV TokenType,ttSpace
      WhiteSpaceL:
        CMP AX,9                         // Tabulator?
        JE WhiteSpaceLE                  // Yes!
        CMP AX,' '                       // Space?
        JNE Finish                       // No!
      WhiteSpaceLE:
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled
        CMP ECX,0                        // End of SQL?
        JE Finish                        // Yes!
        MOV AX,[ESI]                     // One Character from SQL to AX
        JMP WhiteSpaceL

      // ------------------------------

      IncompleteToken:
        MOV TokenType,ttSyntaxError
        MOV ErrorCode,PE_IncompleteToken
        JMP Finish

      UnexpectedChar:
        MOV TokenType,ttSyntaxError
        MOV ErrorCode,PE_UnexpectedChar
        MOV ErrorPos,ESI
      UnexpectedCharL:
        MOV AX,[ESI]                     // One Character from SQL to AX
        CALL Separator                   // Separator in SQL?
        JE Finish                        // Yes!
        ADD ESI,2                        // Next character in SQL
        LOOP UnexpectedCharL
        JMP Finish

      TrippelChar:
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled
      DoubleChar:
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled
      SingleChar:
        ADD ESI,2                        // Next character in SQL
        DEC ECX                          // One character handled

      Finish:
        MOV EAX,Length                   // Calculate TokenLength
        SUB EAX,ECX
        MOV TokenLength,EAX

        POP EBX
        POP EDI
        POP ESI
        POP ES
    end;

    Assert((ErrorCode <> PE_Success) or (TokenLength > 0));

    if (TokenLength = 0) then
      raise Exception.Create(SUnknownError);

    if (TokenType <> ttIdent) then
      KeywordIndex := -1
    else
    begin
      KeywordIndex := KeywordList.IndexOf(SQL, TokenLength);
      if (KeywordIndex >= 0) then
        OperatorType := OperatorTypeByKeywordIndex[KeywordIndex];
    end;

    if (KeywordIndex >= 0) then
      UsageType := utKeyword
    else if (OperatorType = otUnknown) then
      UsageType := UsageTypeByTokenType[TokenType]
    else
      UsageType := utOperator;

    if ((TokenType = ttUnknown) and (OperatorType <> otUnknown)) then
      TokenType := ttOperator;

    Result := TToken.Create(Self, SQL, TokenLength, ErrorCode, ErrorPos, TokenType, OperatorType, KeywordIndex, UsageType);

    ParsePosition.Text := @SQL[TokenLength];
    Dec(ParsePosition.Length, TokenLength);
    if (not Error and (TokenType = ttReturn)) then
      Inc(FErrorLine);

    if (not Error and (ErrorCode <> PE_Success)) then
      SetError(ErrorCode, Result)
    else if (not Error and (AnsiQuotes and (TokenType = ttMySQLIdent))) then
      SetError(PE_UnexpectedToken, Result);
  end;
end;

function TMySQLParser.ParseTrimFunc(): TOffset;
var
  Nodes: TTrimFunc.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.FuncToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiBOTH) then
      Nodes.DirectionTag := ParseTag(kiBOTH)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiLEADING) then
      Nodes.DirectionTag := ParseTag(kiLEADING)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiTRAILING) then
      Nodes.DirectionTag := ParseTag(kiTRAILING);

  if (not Error and (Nodes.DirectionTag > 0) and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType in ttStrings)) then
    Nodes.RemoveStr := ParseExpr();

  if (not Error and ((Nodes.DirectionTag > 0) or (Nodes.RemoveStr > 0))) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiFROM) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.FromTag := ParseTag(kiFROM);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.Str := ParseExpr();

  if (not Error and (Nodes.OpenBracket > 0)) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TTrimFunc.Create(Self, Nodes);
end;

function TMySQLParser.ParseTruncateTableStmt(): TOffset;
var
  Nodes: TTruncateStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.TruncateTag := ParseTag(kiTRUNCATE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiTABLE)) then
    Nodes.TableTag := ParseTag(kiTABLE);

  if (not Error) then
    Nodes.TableIdent := ParseTableIdent();

  Result := TTruncateStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseUnknownStmt(): TOffset;
var
  Tokens: Classes.TList;
begin
  Tokens := Classes.TList.Create();

  while (not EndOfStmt(CurrentToken)) do
    Tokens.Add(Pointer(ApplyCurrentToken()));

  Result := TUnknownStmt.Create(Self, Tokens.Count, TIntegerArray(Tokens.List));

  Tokens.Free();
end;

function TMySQLParser.ParseUnlockStmt(): TOffset;
var
  Nodes: TUnlockStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.UnlockTablesTag := ParseTag(kiUNLOCK, kiTABLES);

  Result := TUnlockStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseUpdateStmt(): TOffset;
var
  Nodes: TUpdateStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.UpdateTag := ParseTag(kiUPDATE);

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiLOW_PRIORITY) then
      Nodes.PriorityTag := ParseTag(kiLOW_PRIORITY)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCONCURRENT) then
      Nodes.PriorityTag := ParseTag(kiCONCURRENT);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.TableReferenceList := ParseList(False, ParseTableReference);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.KeywordIndex <> kiSET) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.SetValue := ParseValue(kiSET, vaNo, False, ParseUpdatePair);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiWHERE)) then
    Nodes.WhereValue := ParseValue(kiWHERE, vaNo, ParseExpr);

  if (not Error and (PList(NodePtr(Nodes.TableReferenceList))^.Count = 1)) then
  begin
    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiORDER)) then
      Nodes.OrderByValue := ParseValue(WordIndices(kiORDER, kiBY), vaNo, False, ParseCreateTableStmtKeyColumn);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiLIMIT)) then
      Nodes.LimitValue := ParseValue(kiLIMIT, vaNo, ParseInteger);
  end;

  Result := TUpdateStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseUpdatePair(): TOffset;
var
  Nodes: TValue.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IdentTag := ParseColumnIdent();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.OperatorType = otEqual)) then
      SetError(PE_UnexpectedToken)
    else
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();
    end;

  if (not Error) then
    if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiDEFAULT)) then
      Nodes.ValueToken := ApplyCurrentToken()
    else
      Nodes.ValueToken := ParseExpr();

  Result := TValue.Create(Self, Nodes);
end;

function TMySQLParser.ParseUserIdent(): TOffset;
var
  Nodes: TUser.TNodes;
begin
  Result := 0;

  if (EndOfStmt(CurrentToken)) then
    SetError(PE_IncompleteStmt)
  else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCURRENT_USER) then
    if (((NextToken[1] = 0) or (TokenPtr(NextToken[1])^.TokenType <> ttOpenBracket))
      and ((NextToken[2] = 0) or (TokenPtr(NextToken[2])^.TokenType <> ttCloseBracket))) then
      Result := ApplyCurrentToken()
    else
      Result := ParseFunctionCall()
  else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents) and (TokenPtr(CurrentToken)^.TokenType <> ttString)) then
    SetError(PE_UnexpectedToken)
  else
  begin
    FillChar(Nodes, SizeOf(Nodes), 0);

    Nodes.NameToken := ApplyCurrentToken(utDbIdent);

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttAt)) then
    begin
      Nodes.AtToken := ApplyCurrentToken();

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if ((TokenPtr(CurrentToken)^.TokenType = ttIPAddress)
          or (TokenPtr(CurrentToken)^.TokenType in ttIdents + ttStrings)) then
          Nodes.HostToken := ApplyCurrentToken(utDbIdent)
        else
          SetError(PE_UnexpectedToken);
    end;

    Result := TUser.Create(Self, Nodes);
  end;
end;

function TMySQLParser.ParseUseStmt(): TOffset;
var
  Nodes: TUseStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.StmtToken := ParseTag(kiUSE);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not (TokenPtr(CurrentToken)^.TokenType in ttIdents)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.DbNameNode := ParseDatabaseIdent();

  Result := TUseStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseValue(const KeywordIndex: TWordList.TIndex; const Assign: TValueAssign; const Brackets: Boolean; const ParseItem: TParseFunction): TOffset;
var
  Nodes: TValue.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IdentTag := ParseTag(KeywordIndex);

  if (not Error and (Assign in [vaYes, vaAuto])) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType = otEqual) then
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();
    end
    else if (Assign = vaYes) then
      SetError(PE_UnexpectedToken);

  if (not Error) then
    Nodes.ValueToken := ParseList(Brackets, ParseItem);

  Result := TValue.Create(Self, Nodes);
end;

function TMySQLParser.ParseValue(const KeywordIndex: TWordList.TIndex; const Assign: TValueAssign; const OptionIndices: TWordList.TIndices): TOffset;
var
  CurrentKeywordIndex: Integer;
  I: Integer;
  Nodes: TValue.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IdentTag := ParseTag(KeywordIndex);

  if (not Error and (Assign in [vaYes, vaAuto])) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType = otEqual) then
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();
    end
    else if (Assign = vaYes) then
      SetError(PE_UnexpectedToken);

  if (not Error) then
  begin
    CurrentKeywordIndex := TokenPtr(CurrentToken)^.KeywordIndex;
    for I := 0 to Length(OptionIndices) - 1 do
      if ((OptionIndices[I] < 0)) then
        break
      else if (OptionIndices[I] = CurrentKeywordIndex) then
      begin
        Nodes.ValueToken := ParseTag(CurrentKeywordIndex);
        break;
      end;
    if (Nodes.ValueToken = 0) then
      SetError(PE_UnexpectedToken);
  end;

  Result := TValue.Create(Self, Nodes);
end;

function TMySQLParser.ParseValue(const KeywordIndex: TWordList.TIndex; const Assign: TValueAssign; const ParseValueNode: TParseFunction): TOffset;
var
  Nodes: TValue.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IdentTag := ParseTag(KeywordIndex);

  if (not Error and (Assign in [vaYes, vaAuto])) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType = otEqual) then
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();
    end
    else if (Assign = vaYes) then
      SetError(PE_UnexpectedToken);

  if (not Error) then
    Nodes.ValueToken := ParseValueNode();

  Result := TValue.Create(Self, Nodes);
end;

function TMySQLParser.ParseValue(const KeywordIndices: TWordList.TIndices; const Assign: TValueAssign; const Brackets: Boolean; const ParseItem: TParseFunction): TOffset;
var
  Nodes: TValue.TNodes;
begin
  Assert(KeywordIndices[4] = -1);

  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IdentTag := ParseTag(KeywordIndices[0], KeywordIndices[1], KeywordIndices[2], KeywordIndices[3]);

  if (not Error and (Assign in [vaYes, vaAuto])) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType = otEqual) then
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();
    end
    else if (Assign = vaYes) then
      SetError(PE_UnexpectedToken);

  if (not Error) then
    Nodes.ValueToken := ParseList(Brackets, ParseItem);

  Result := TValue.Create(Self, Nodes);
end;

function TMySQLParser.ParseValue(const KeywordIndices: TWordList.TIndices; const Assign: TValueAssign; const OptionIndices: TWordList.TIndices): TOffset;
var
  CurrentKeywordIndex: Integer;
  I: Integer;
  Nodes: TValue.TNodes;
begin
  Assert(KeywordIndices[4] = -1);

  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IdentTag := ParseTag(KeywordIndices[0], KeywordIndices[1], KeywordIndices[2], KeywordIndices[3]);

  if (not Error and (Assign in [vaYes, vaAuto])) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType = otEqual) then
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();
    end
    else if (Assign = vaYes) then
      SetError(PE_UnexpectedToken);

  if (not Error) then
  begin
    CurrentKeywordIndex := TokenPtr(CurrentToken)^.KeywordIndex;
    for I := 0 to Length(OptionIndices) - 1 do
      if ((OptionIndices[I] < 0)) then
        break
      else if (OptionIndices[I] = CurrentKeywordIndex) then
      begin
        Nodes.ValueToken := ParseTag(CurrentKeywordIndex);
        break;
      end;
    if (Nodes.ValueToken = 0) then
      SetError(PE_UnexpectedToken);
  end;

  Result := TValue.Create(Self, Nodes);
end;

function TMySQLParser.ParseValue(const KeywordIndices: TWordList.TIndices; const Assign: TValueAssign; const ParseValueNode: TParseFunction): TOffset;
var
  Nodes: TValue.TNodes;
begin
  Assert(KeywordIndices[4] = -1);

  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IdentTag := ParseTag(KeywordIndices[0], KeywordIndices[1], KeywordIndices[2], KeywordIndices[3]);

  if (not Error and (Assign in [vaYes, vaAuto])) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType = otEqual) then
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();
    end
    else if (Assign = vaYes) then
      SetError(PE_UnexpectedToken);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else
      Nodes.ValueToken := ParseValueNode();

  Result := TValue.Create(Self, Nodes);
end;

function TMySQLParser.ParseValue(const KeywordIndices: TWordList.TIndices; const Assign: TValueAssign; const ValueKeywordIndex1: TWordList.TIndex; const ValueKeywordIndex2: TWordList.TIndex = -1): TOffset;
var
  Nodes: TValue.TNodes;
begin
  Assert(KeywordIndices[4] = -1);

  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.IdentTag := ParseTag(KeywordIndices[0], KeywordIndices[1], KeywordIndices[2], KeywordIndices[3]);

  if (not Error and (Assign in [vaYes, vaAuto])) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.OperatorType = otEqual) then
    begin
      TokenPtr(CurrentToken)^.FOperatorType := otAssign;
      Nodes.AssignToken := ApplyCurrentToken();
    end
    else if (Assign = vaYes) then
      SetError(PE_UnexpectedToken);

  if (not Error) then
    Nodes.ValueToken := ParseTag(ValueKeywordIndex1, ValueKeywordIndex2);

  Result := TValue.Create(Self, Nodes);
end;

function TMySQLParser.ParseVariable(): TOffset;
var
  Nodes: TVariable.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttAt)) then
    Nodes.At1Token := ApplyCurrentToken();

  if (not Error and (Nodes.At1Token > 0)
    and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttAt)) then
  begin
    Nodes.At2Token := Nodes.At1Token;
    Nodes.At1Token := ApplyCurrentToken();
  end;

  if (not Error and not EndOfStmt(CurrentToken)
    and (Nodes.At1Token > 0)
    and ((TokenPtr(CurrentToken)^.KeywordIndex = kiGLOBAL) or (TokenPtr(CurrentToken)^.KeywordIndex = kiSESSION) or (TokenPtr(CurrentToken)^.KeywordIndex = kiLOCAL))) then
  begin
    Nodes.ScopeTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else if (TokenPtr(CurrentToken)^.OperatorType <> otDot) then
        SetError(PE_UnexpectedToken)
      else
        Nodes.ScopeDotToken := ApplyCurrentToken();
  end;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.TokenType = ttDot)) then
      Nodes.Ident := ParseList(False, ApplyCurrentToken, ttDot)
    else
      Nodes.Ident := ApplyCurrentToken();

  Result := TVariable.Create(Self, Nodes);
end;

function TMySQLParser.ParseWeightStringFunc(): TOffset;
var
  Nodes: TWeightStringFunc.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.FuncToken := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttOpenBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.OpenBracket := ApplyCurrentToken();

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.Str := ParseString();

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiAS)) then
  begin
    Nodes.AsTag := ParseTag(kiAS);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.DataType := ParseDataType();
  end;

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex <> kiLEVEL)) then
  begin
    Nodes.AsTag := ParseTag(kiLEVEL);

    if (not Error) then
      if (EndOfStmt(CurrentToken)) then
        SetError(PE_IncompleteStmt)
      else
        Nodes.LevelList := ParseList(False, ParseWeightStringFuncLevel);
  end;

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if (TokenPtr(CurrentToken)^.TokenType <> ttCloseBracket) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.CloseBracket := ApplyCurrentToken();

  Result := TWeightStringFunc.Create(Self, Nodes);
end;

function TMySQLParser.ParseWeightStringFuncLevel(): TOffset;
var
  Nodes: TWeightStringFunc.TLevel.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.CountInt := ParseInteger();

  if (not Error and not EndOfStmt(CurrentToken)) then
    if (TokenPtr(CurrentToken)^.KeywordIndex = kiASC) then
      Nodes.DirectionTag := ParseTag(kiASC)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiDESC) then
      Nodes.DirectionTag := ParseTag(kiDESC)
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiREVERSE) then
      Nodes.DirectionTag := ParseTag(kiREVERSE);

  Result := TWeightStringFunc.TLevel.Create(Self, Nodes);
end;

function TMySQLParser.ParseWhileStmt(): TOffset;
var
  Nodes: TWhileStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  if (TokenPtr(CurrentToken)^.TokenType = ttBeginLabel) then
    Nodes.BeginLabelToken := ApplyCurrentToken();

  if (not Error) then
    Nodes.WhileTag := ParseTag(kiWHILE);

  if (not Error) then
    Nodes.SearchConditionExpr := ParseExpr();

  if (not Error) then
    Nodes.DoTag := ParseTag(kiDO);

  if (not Error) then
    Nodes.StmtList := ParseList(False, ParsePL_SQLStmt, ttDelimiter);

  if (not Error) then
    Nodes.EndTag := ParseTag(kiEND, kiWHILE);

  if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttIdent)) then
    if ((Nodes.BeginLabelToken = 0) or (StrIComp(PChar(TokenPtr(CurrentToken)^.AsString), PChar(TokenPtr(Nodes.BeginLabelToken)^.AsString)) <> 0)) then
      SetError(PE_UnexpectedToken)
    else
      Nodes.EndLabelToken := ApplyCurrentToken(utLabel, ttEndLabel);

  Result := TWhileStmt.Create(Self, Nodes);
end;

function TMySQLParser.ParseXAStmt(): TOffset;

  function ParseXID(): TOffset;
  var
    Nodes: TXAStmt.TID.TNodes;
  begin
    FillChar(Nodes, SizeOf(Nodes), 0);

    Nodes.GTrId := ParseString();

    if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttComma)) then
    begin
      Nodes.Comma1 := ApplyCurrentToken();

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
          else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.BQual := ParseString();

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.TokenType = ttComma)) then
      begin
        Nodes.Comma1 := ApplyCurrentToken();

        if (not Error) then
          if (EndOfStmt(CurrentToken)) then
            SetError(PE_IncompleteStmt)
          else if (TokenPtr(CurrentToken)^.TokenType <> ttInteger) then
            SetError(PE_UnexpectedToken)
          else
            Nodes.FormatId := ParseInteger();
      end;
    end;

    Result := TXAStmt.TID.Create(Self, Nodes);
  end;

var
  Nodes: TXAStmt.TNodes;
begin
  FillChar(Nodes, SizeOf(Nodes), 0);

  Nodes.XATag := ParseTag(kiXA);

  if (not Error) then
    if (EndOfStmt(CurrentToken)) then
      SetError(PE_IncompleteStmt)
    else if ((TokenPtr(CurrentToken)^.KeywordIndex = kiBEGIN) or (TokenPtr(CurrentToken)^.KeywordIndex = kiSTART)) then
    begin
      Nodes.ActionTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.Ident := ParseXID();

      if (not Error and not EndOfStmt(CurrentToken) and ((TokenPtr(CurrentToken)^.KeywordIndex = kiJOIN) or (TokenPtr(CurrentToken)^.KeywordIndex = kiRESUME))) then
        Nodes.RestTag := ParseTag(TokenPtr(CurrentToken)^.KeywordIndex);
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiCOMMIT) then
    begin
      Nodes.ActionTag := ParseTag(kiCOMMIT);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.Ident := ParseXID();

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiONE)) then
        Nodes.RestTag := ParseTag(kiONE, kiPHASE);
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiEND) then
    begin
      Nodes.ActionTag := ParseTag(kiEND);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.Ident := ParseXID();

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiSUSPEND)) then
        if (not EndOfStmt(NextToken[1]) and (TokenPtr(NextToken[1])^.KeywordIndex = kiFOR)) then
          Nodes.RestTag := ParseTag(kiSUSPEND, kiFOR, kiMIGRATE)
        else
          Nodes.RestTag := ParseTag(kiSUSPEND);
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiPREPARE) then
    begin
      Nodes.ActionTag := ParseTag(kiPREPARE);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.Ident := ParseXID();
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiRECOVER) then
    begin
      Nodes.ActionTag := ParseTag(kiRECOVER);

      if (not Error and not EndOfStmt(CurrentToken) and (TokenPtr(CurrentToken)^.KeywordIndex = kiCONVERT)) then
        Nodes.RestTag := ParseTag(kiCONVERT, kiXID);
    end
    else if (TokenPtr(CurrentToken)^.KeywordIndex = kiROLLBACK) then
    begin
      Nodes.ActionTag := ParseTag(kiROLLBACK);

      if (not Error) then
        if (EndOfStmt(CurrentToken)) then
          SetError(PE_IncompleteStmt)
        else if (TokenPtr(CurrentToken)^.TokenType <> ttString) then
          SetError(PE_UnexpectedToken)
        else
          Nodes.Ident := ParseXID();
    end
    else
      SetError(PE_UnexpectedToken);

  Result := TXAStmt.Create(Self, Nodes);
end;

function TMySQLParser.RangeNodePtr(const ANode: TOffset): PRange;
begin
  Assert(IsRange(NodePtr(ANode)));

  Result := PRange(NodePtr(ANode));
end;

procedure TMySQLParser.SaveToFile(const Filename: string; const FileType: TFileType = ftSQL);
begin
  if (not Assigned(Root)) then
    raise Exception.Create('Empty Buffer');
  case (FileType) of
    ftSQL:
      SaveToSQLFile(Filename);
    ftFormatedSQL:
      SaveToFormatedSQLFile(Filename);
    ftDebugHTML:
      SaveToDebugHTMLFile(Filename);
  end;
end;

procedure TMySQLParser.SaveToDebugHTMLFile(const Filename: string);
var
  G: Integer;
  GenerationCount: Integer;
  Handle: THandle;
  HTML: string;
  LastTokenIndex: Integer;
  Node: PNode;
  ParentNodes: Classes.TList;
  Size: Cardinal;
  Stmt: PStmt;
  Token: PToken;
  Generation: Integer;
begin
  Handle := CreateFile(PChar(Filename),
                       GENERIC_WRITE,
                       FILE_SHARE_READ,
                       nil,
                       CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);

  if (Handle = INVALID_HANDLE_VALUE) then
    RaiseLastOSError()
  else
  begin
    if (not WriteFile(Handle, PChar(BOM_UNICODE_LE)^, StrLen(BOM_UNICODE_LE), Size, nil)) then
      RaiseLastOSError();

    HTML :=
      '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">' + #13#10 +
      '<html>' + #13#10 +
      '  <head>' + #13#10 +
      '  <meta http-equiv="content-type" content="text/html">' + #13#10 +
      '  <title>Debug - Free SQL Parser</title>' + #13#10 +
      '  <style type="text/css">' + #13#10 +
      '    body {' + #13#10 +
      '      font: 12px Verdana,Arial,Sans-Serif;' + #13#10 +
      '      color: #000;' + #13#10 +
      '    }' + #13#10 +
      '    td {' + #13#10 +
      '      font: 12px Verdana,Arial,Sans-Serif;' + #13#10 +
      '    }' + #13#10 +
      '    a {' + #13#10 +
      '      text-decoration: none;' + #13#10 +
      '    }' + #13#10 +
      '    a:link span { display: none; }' + #13#10 +
      '    a:visited span { display: none; }' + #13#10 +
      '    a:hover span {' + #13#10 +
      '      display: block;' + #13#10 +
      '      position: absolute;' + #13#10 +
      '      margin: 18px 0px 0px 0px;' + #13#10 +
      '      background-color: #FFD;' + #13#10 +
      '      padding: 0px 2px 2px 1px;' + #13#10 +
      '      border: 1px solid #000;' + #13#10 +
      '      color: #000;' + #13#10 +
      '    }' + #13#10 +
      '    .Node {' + #13#10 +
      '      font-size: 11px;' + #13#10 +
      '      text-align: center;' + #13#10 +
      '      background-color: #F0F0F0;' + #13#10 +
      '    }' + #13#10 +
      '    .SQL {' + #13#10 +
      '      font-size: 12px;' + #13#10 +
      '      background-color: #F0F0F0;' + #13#10 +
      '      text-align: center;' + #13#10 +
      '    }' + #13#10 +
      '    .TokenError {' + #13#10 +
      '      font-size: 12px;' + #13#10 +
      '      background-color: #FFC0C0;' + #13#10 +
      '      text-align: center;' + #13#10 +
      '    }' + #13#10 +
      '    .StmtOk {' + #13#10 +
      '      font-size: 12px;' + #13#10 +
      '      background-color: #D0FFD0;' + #13#10 +
      '      text-align: center;' + #13#10 +
      '    }' + #13#10 +
      '    .StmtError {' + #13#10 +
      '      font-size: 12px;' + #13#10 +
      '      background-color: #FFC0C0;' + #13#10 +
      '      text-align: center;' + #13#10 +
      '    }' + #13#10 +
      '    .ErrorMessage {' + #13#10 +
      '      font-size: 12px;' + #13#10 +
      '      color: #E82020;' + #13#10 +
      '      font-weight:bold;' + #13#10 +
      '    }' + #13#10 +
      '  </style>' + #13#10 +
      '  </head>' + #13#10 +
      '  <body>' + #13#10;

    if (not WriteFile(Handle, PChar(HTML)^, Length(HTML) * SizeOf(HTML[1]), Size, nil)) then
      RaiseLastOSError();

    Stmt := Root^.FirstStmt;
    while (Assigned(Stmt)) do
    begin
      HTML := '';

      Token := Stmt^.FirstToken; GenerationCount := 0;
      while (Assigned(Token)) do
      begin
        GenerationCount := Max(GenerationCount, Token^.Generation);
        if (Token = Stmt^.LastToken) then
          Token := nil
        else
          Token := Token^.NextToken;
      end;

      ParentNodes := Classes.TList.Create();
      ParentNodes.Add(Root);

      HTML := HTML
        + '<table cellspacing="2" cellpadding="0" border="0">' + #13#10;

      for Generation := 0 to GenerationCount - 1 do
      begin
        HTML := HTML
          + '<tr>' + #13#10;
        Token := Stmt^.FirstToken;
        LastTokenIndex := Token^.Index - 1;
        while (Assigned(Token)) do
        begin
          Node := Token^.ParentNode; G := Token^.Generation;
          while (IsChild(Node) and (G > Generation)) do
          begin
            Dec(G);
            if (G > Generation) then
              Node := PChild(Node)^.ParentNode;
          end;

          if (IsChild(Node) and (G = Generation) and (ParentNodes.IndexOf(Node) < 1)) then
          begin
            if (PChild(Node)^.FirstToken^.Index - LastTokenIndex - 1 > 0) then
              HTML := HTML
                + '<td colspan="' + IntToStr(PChild(Node)^.FirstToken^.Index - LastTokenIndex - 1) + '"></td>';
            HTML := HTML
              + '<td colspan="' + IntToStr(PChild(Node)^.LastToken^.Index - PChild(Node)^.FirstToken^.Index + 1) + '" class="Node">';
            HTML := HTML
              + '<a href="">'
              + HTMLEscape(NodeTypeToString[Node^.NodeType]);
            HTML := HTML
              + '<span><table cellspacing="2" cellpadding="0">';
            if (Assigned(PChild(Node)^.ParentNode)) then
              HTML := HTML
                + '<tr><td>ParentNode Offset:</td><td>&nbsp;</td><td>' + IntToStr(PChild(Node)^.ParentNode^.Offset) + '</td></tr>';
            HTML := HTML
              + '<tr><td>Offset:</td><td>&nbsp;</td><td>' + IntToStr(Node^.Offset) + '</td></tr>';
            if (IsStmt(Node)) then
              HTML := HTML + '<tr><td>StmtType:</td><td>&nbsp;</td><td>' + StmtTypeToString[PStmt(Node)^.StmtType] + '</td></tr>'
            else
              case (Node^.NodeType) of
                ntAlterRoutineStmt:
                  HTML := HTML
                    + '<tr><td>AlterRoutineType:</td><td>&nbsp;</td><td>' + RoutineTypeToString[PAlterRoutineStmt(Node)^.RoutineType] + '</td></tr>';
                ntBinaryOp:
                  if (IsToken(PNode(PBinaryOp(Node)^.Operator))) then
                    HTML := HTML
                      + '<tr><td>OperatorType:</td><td>&nbsp;</td><td>' + OperatorTypeToString[PToken(PBinaryOp(Node)^.Operator)^.OperatorType] + '</td></tr>';
                ntCreateRoutineStmt:
                  HTML := HTML
                    + '<tr><td>RoutineType:</td><td>&nbsp;</td><td>' + RoutineTypeToString[PCreateRoutineStmt(Node)^.RoutineType] + '</td></tr>';
                ntDropRoutineStmt:
                  HTML := HTML
                    + '<tr><td>RoutineType:</td><td>&nbsp;</td><td>' + RoutineTypeToString[PDropRoutineStmt(Node)^.RoutineType] + '</td></tr>';
                ntDbIdent:
                  HTML := HTML
                    + '<tr><td>DbIdentType:</td><td>&nbsp;</td><td>' + DbIdentTypeToString[PDbIdent(Node)^.DbIdentType] + '</td></tr>';
                ntSelectStmtTableJoin:
                  HTML := HTML
                    + '<tr><td>JoinType:</td><td>&nbsp;</td><td>' + JoinTypeToString[TSelectStmt.PTableReferenceJoin(Node)^.JoinType] + '</td></tr>';
              end;
            HTML := HTML
              + '</table></span>';
            HTML := HTML
              + '</a></td>' + #13#10;

            LastTokenIndex := PChild(Node)^.LastToken^.Index;

            ParentNodes.Add(Node);
            Token := PChild(Node)^.LastToken;
          end;

          if (Token <> Stmt^.LastToken) then
            Token := Token^.NextToken
          else
          begin
            if (Token^.Index - LastTokenIndex > 0) then
              HTML := HTML
                + '<td colspan="' + IntToStr(Token^.Index - LastTokenIndex) + '"></td>';
            Token := nil;
          end;
        end;
        HTML := HTML
          + '</tr>' + #13#10;
      end;

      ParentNodes.Free();


      if (Stmt^.ErrorCode <> PE_Success) then
        HTML := HTML
          + '<tr class="SQL">' + #13#10
      else
        HTML := HTML
          + '<tr class="StmtOk">' + #13#10;

      Token := Stmt^.FirstToken;
      while (Assigned(Token)) do
      begin
        if (Token^.ErrorCode = PE_Success) then
          HTML := HTML
            + '<td>'
        else
          HTML := HTML
            + '<td class="TokenError">';
        HTML := HTML
          + '<a href="">';
        HTML := HTML
          + '<code>' + HTMLEscape(ReplaceStr(Token.Text, ' ', '&nbsp;')) + '</code>';
        HTML := HTML
          + '<span><table cellspacing="2" cellpadding="0">';
        if (Assigned(PChild(Token)^.ParentNode)) then
          HTML := HTML + '<tr><td>ParentNode Offset:</td><td>&nbsp;</td><td>' + IntToStr(PChild(Token)^.ParentNode^.Offset) + '</td></tr>';
        HTML := HTML + '<tr><td>Offset:</td><td>&nbsp;</td><td>' + IntToStr(PNode(Token)^.Offset) + '</td></tr>';
        HTML := HTML + '<tr><td>TokenType:</td><td>&nbsp;</td><td>' + HTMLEscape(TokenTypeToString[Token^.TokenType]) + '</td></tr>';
        if (Token^.KeywordIndex >= 0) then
          HTML := HTML + '<tr><td>KeywordIndex:</td><td>&nbsp;</td><td>ki' + HTMLEscape(KeywordList[Token^.KeywordIndex]) + '</td></tr>';
        if (Token^.OperatorType <> otUnknown) then
          HTML := HTML + '<tr><td>OperatorType:</td><td>&nbsp;</td><td>' + HTMLEscape(OperatorTypeToString[Token^.OperatorType]) + '</td></tr>';
        if (Token^.DbIdentType <> ditUnknown) then
          HTML := HTML + '<tr><td>DbIdentType:</td><td>&nbsp;</td><td>' + HTMLEscape(DbIdentTypeToString[Token^.DbIdentType]) + '</td></tr>';
        if ((Trim(Token^.AsString) <> '') and (Token^.KeywordIndex < 0)) then
          HTML := HTML + '<tr><td>AsString:</td><td>&nbsp;</td><td>' + HTMLEscape(Token^.AsString) + '</td></tr>';
        if (Token^.ErrorCode <> PE_Success) then
          HTML := HTML + '<tr><td>ErrorCode:</td><td>&nbsp;</td><td>' + IntToStr(Token^.ErrorCode) + '</td></tr>';
        if (Token^.UsageType <> utUnknown) then
          HTML := HTML + '<tr><td>UsageType:</td><td>&nbsp;</td><td>' + HTMLEscape(UsageTypeToString[Token^.UsageType]) + '</td></tr>';
        HTML := HTML
          + '</table></span>';
        HTML := HTML
          + '</a></td>' + #13#10;

        if (Token = Stmt^.LastToken) then
          Token := nil
        else
          Token := Token.NextToken;
      end;
      HTML := HTML
        + '</tr>' + #13#10;

      if ((Stmt^.ErrorCode <> PE_Success) and (Stmt^.ErrorCode <> PE_IncompleteStmt) and Assigned(Stmt^.ErrorToken)) then
      begin
        HTML := HTML
          + '<tr>';
        if (Stmt^.ErrorToken^.Index - Stmt^.FirstToken^.Index > 0) then
          HTML := HTML
            + '<td colspan="' + IntToStr(Stmt^.ErrorToken^.Index - Stmt^.FirstToken^.Index) + '"></td>';
        HTML := HTML
          + '<td class="StmtError"><a href="">&uarr;'
          + '<span><table cellspacing="2" cellpadding="0">'
          + '<tr><td>ErrorCode:</td><td>' + IntToStr(Stmt^.ErrorCode) + '</td></tr>'
          + '<tr><td>ErrorMessage:</td><td>' + HTMLEscape(Stmt^.ErrorMessage) + '</td></tr>'
          + '</table></span>'
          + '</a></td>';
        if (Stmt^.ErrorToken^.Index - Stmt^.LastToken^.Index > 0) then
          HTML := HTML
            + '<td colspan="' + IntToStr(Stmt^.LastToken^.Index - Stmt^.ErrorToken^.Index) + '"></td>';
        HTML := HTML
          + '</tr>' + #13#10;
      end;

      HTML := HTML
        + '</table>' + #13#10;

      if (Stmt^.ErrorCode <> PE_Success) then
        HTML := HTML
          + '<div class="ErrorMessage">' + HTMLEscape('Error: ' + Stmt^.ErrorMessage) + '</div>';

//      HTML := HTML
//        + '<br><br>'
//        + '<code>';
//
//      HTML := HTML
//        + 'SELECT';
//
//      HTML := HTML
//        + '</code>';

      Stmt := Stmt^.NextStmt;

      if (Assigned(Stmt)) then
        HTML := HTML
          + '<br><br>' + #13#10;

      if (not WriteFile(Handle, PChar(HTML)^, Length(HTML) * SizeOf(HTML[1]), Size, nil)) then
        RaiseLastOSError();
    end;

    HTML :=
      '    <br>' + #13#10 +
      '    <br>' + #13#10 +
      '  </body>' + #13#10 +
      '</html>';

    if (not WriteFile(Handle, PChar(HTML)^, Length(HTML) * SizeOf(HTML[1]), Size, nil)) then
      RaiseLastOSError();

    if (not CloseHandle(Handle)) then
      RaiseLastOSError();
  end;
end;

procedure TMySQLParser.SaveToFormatedSQLFile(const Filename: string);
var
  Handle: THandle;
  Size: Cardinal;
  SQL: string;
begin
  Handle := CreateFile(PChar(Filename),
                       GENERIC_WRITE,
                       FILE_SHARE_READ,
                       nil,
                       CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);

  if (Handle = INVALID_HANDLE_VALUE) then
    RaiseLastOSError();

  FormatSQL(SQL); // Ignore error messages...

  if (not WriteFile(Handle, PChar(BOM_UNICODE_LE)^, StrLen(BOM_UNICODE_LE), Size, nil)
    or not WriteFile(Handle, PChar(SQL)^, Length(SQL) * SizeOf(SQL[1]), Size, nil)
    or not CloseHandle(Handle)) then
    RaiseLastOSError();
end;

procedure TMySQLParser.SaveToSQLFile(const Filename: string);
var
  Handle: THandle;
  Size: Cardinal;
  StringBuffer: TStringBuffer;
  Token: PToken;
begin
  StringBuffer := TStringBuffer.Create(1024);

  Token := TokenPtr(1);
  while (Assigned(Token)) do
  begin
    StringBuffer.Write(Token^.SQL, Token^.Length);
    Token := Token^.NextTokenAll;
  end;

  Handle := CreateFile(PChar(Filename),
                       GENERIC_WRITE,
                       FILE_SHARE_READ,
                       nil,
                       CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);

  if (Handle = INVALID_HANDLE_VALUE) then
    RaiseLastOSError();

  if (not WriteFile(Handle, PChar(BOM_UNICODE_LE)^, StrLen(BOM_UNICODE_LE), Size, nil)
    or not WriteFile(Handle, StringBuffer.Data^, StringBuffer.Size, Size, nil)
    or not CloseHandle(Handle)) then
    RaiseLastOSError();

  StringBuffer.Free();
end;

procedure TMySQLParser.SetError(const AErrorCode: Integer; const AErrorToken: TOffset = 0);
begin
  Assert(not Error and ((AErrorCode <> PE_IncompleteStmt) or (AErrorToken = 0) or IsToken(AErrorToken)));

  FErrorCode := AErrorCode;

  if (not IsChild(AErrorToken)) then
    FErrorToken := CurrentToken
  else
    FErrorToken := ChildPtr(AErrorToken)^.FFirstToken;
end;

procedure TMySQLParser.SetFunctions(AFunctions: string);
begin
  FunctionList.Text := AFunctions;
end;

procedure TMySQLParser.SetKeywords(AKeywords: string);

  function IndexOf(const Word: string): Integer;
  begin
    Result := KeywordList.IndexOf(PChar(Word), Length(Word));

    if (Result < 0) then
      raise ERangeError.CreateFmt(SKeywordNotFound, [Word]);
  end;

var
  Index: Integer;
begin
  KeywordList.Text := AKeywords;

  if (AKeywords <> '') then
  begin
    kiACCOUNT                  := IndexOf('ACCOUNT');
    kiACTION                   := IndexOf('ACTION');
    kiADD                      := IndexOf('ADD');
    kiAFTER                    := IndexOf('AFTER');
    kiALGORITHM                := IndexOf('ALGORITHM');
    kiALL                      := IndexOf('ALL');
    kiALTER                    := IndexOf('ALTER');
    kiANALYZE                  := IndexOf('ANALYZE');
    kiAND                      := IndexOf('AND');
    kiAS                       := IndexOf('AS');
    kiASC                      := IndexOf('ASC');
    kiASCII                    := IndexOf('ASCII');
    kiAT                       := IndexOf('AT');
    kiAUTO_INCREMENT           := IndexOf('AUTO_INCREMENT');
    kiAUTHORS                  := IndexOf('AUTHORS');
    kiAVG_ROW_LENGTH           := IndexOf('AVG_ROW_LENGTH');
    kiBEFORE                   := IndexOf('BEFORE');
    kiBEGIN                    := IndexOf('BEGIN');
    kiBETWEEN                  := IndexOf('BETWEEN');
    kiBINARY                   := IndexOf('BINARY');
    kiBINLOG                   := IndexOf('BINLOG');
    kiBLOCK                    := IndexOf('BLOCK');
    kiBOTH                     := IndexOf('BOTH');
    kiBTREE                    := IndexOf('BTREE');
    kiBY                       := IndexOf('BY');
    kiCACHE                    := IndexOf('CACHE');
    kiCALL                     := IndexOf('CALL');
    kiCASCADE                  := IndexOf('CASCADE');
    kiCASCADED                 := IndexOf('CASCADED');
    kiCASE                     := IndexOf('CASE');
    kiCATALOG_NAME             := IndexOf('CATALOG_NAME');
    kiCHANGE                   := IndexOf('CHANGE');
    kiCHANGED                  := IndexOf('CHANGED');
    kiCHAIN                    := IndexOf('CHAIN');
    kiCHARACTER                := IndexOf('CHARACTER');
    kiCHARSET                  := IndexOf('CHARSET');
    kiCHECK                    := IndexOf('CHECK');
    kiCHECKSUM                 := IndexOf('CHECKSUM');
    kiCLASS_ORIGIN             := IndexOf('CLASS_ORIGIN');
    kiCLIENT                   := IndexOf('CLIENT');
    kiCLOSE                    := IndexOf('CLOSE');
    kiCOALESCE                 := IndexOf('COALESCE');
    kiCODE                     := IndexOf('CODE');
    kiCOLLATE                  := IndexOf('COLLATE');
    kiCOLLATION                := IndexOf('COLLATION');
    kiCOLUMN                   := IndexOf('COLUMN');
    kiCOLUMN_NAME              := IndexOf('COLUMN_NAME');
    kiCOLUMN_FORMAT            := IndexOf('COLUMN_FORMAT');
    kiCOLUMNS                  := IndexOf('COLUMNS');
    kiCOMMENT                  := IndexOf('COMMENT');
    kiCOMMIT                   := IndexOf('COMMIT');
    kiCOMMITTED                := IndexOf('COMMITTED');
    kiCOMPACT                  := IndexOf('COMPACT');
    kiCOMPLETION               := IndexOf('COMPLETION');
    kiCOMPRESSED               := IndexOf('COMPRESSED');
    kiCONCURRENT               := IndexOf('CONCURRENT');
    kiCONNECTION               := IndexOf('CONNECTION');
    kiCONDITION                := IndexOf('CONDITION');
    kiCONSISTENT               := IndexOf('CONSISTENT');
    kiCONSTRAINT               := IndexOf('CONSTRAINT');
    kiCONSTRAINT_CATALOG       := IndexOf('CONSTRAINT_CATALOG');
    kiCONSTRAINT_NAME          := IndexOf('CONSTRAINT_NAME');
    kiCONSTRAINT_SCHEMA        := IndexOf('CONSTRAINT_SCHEMA');
    kiCONTAINS                 := IndexOf('CONTAINS');
    kiCONTEXT                  := IndexOf('CONTEXT');
    kiCONTINUE                 := IndexOf('CONTINUE');
    kiCONTRIBUTORS             := IndexOf('CONTRIBUTORS');
    kiCONVERT                  := IndexOf('CONVERT');
    kiCOPY                     := IndexOf('COPY');
    kiCPU                      := IndexOf('CPU');
    kiCREATE                   := IndexOf('CREATE');
    kiCROSS                    := IndexOf('CROSS');
    kiCURRENT                  := IndexOf('CURRENT');
    kiCURRENT_DATE             := IndexOf('CURRENT_DATE');
    kiCURRENT_TIME             := IndexOf('CURRENT_TIME');
    kiCURRENT_TIMESTAMP        := IndexOf('CURRENT_TIMESTAMP');
    kiCURRENT_USER             := IndexOf('CURRENT_USER');
    kiCURSOR                   := IndexOf('CURSOR');
    kiCURSOR_NAME              := IndexOf('CURSOR_NAME');
    kiDATA                     := IndexOf('DATA');
    kiDATABASE                 := IndexOf('DATABASE');
    kiDATABASES                := IndexOf('DATABASES');
    kiDAY                      := IndexOf('DAY');
    kiDAY_HOUR                 := IndexOf('DAY_HOUR');
    kiDAY_MINUTE               := IndexOf('DAY_MINUTE');
    kiDAY_SECOND               := IndexOf('DAY_SECOND');
    kiDEALLOCATE               := IndexOf('DEALLOCATE');
    kiDECLARE                  := IndexOf('DECLARE');
    kiDEFAULT                  := IndexOf('DEFAULT');
    kiDEFINER                  := IndexOf('DEFINER');
    kiDELAY_KEY_WRITE          := IndexOf('DELAY_KEY_WRITE');
    kiDELAYED                  := IndexOf('DELAYED');
    kiDELETE                   := IndexOf('DELETE');
    kiDESC                     := IndexOf('DESC');
    kiDESCRIBE                 := IndexOf('DESCRIBE');
    kiDETERMINISTIC            := IndexOf('DETERMINISTIC');
    kiDIAGNOSTICS              := IndexOf('DIAGNOSTICS');
    kiDIRECTORY                := IndexOf('DIRECTORY');
    kiDISABLE                  := IndexOf('DISABLE');
    kiDISCARD                  := IndexOf('DISCARD');
    kiDISTINCT                 := IndexOf('DISTINCT');
    kiDISTINCTROW              := IndexOf('DISTINCTROW');
    kiDIV                      := IndexOf('DIV');
    kiDO                       := IndexOf('DO');
    kiDROP                     := IndexOf('DROP');
    kiDUMPFILE                 := IndexOf('DUMPFILE');
    kiDUPLICATE                := IndexOf('DUPLICATE');
    kiDYNAMIC                  := IndexOf('DYNAMIC');
    kiEACH                     := IndexOf('EACH');
    kiELSE                     := IndexOf('ELSE');
    kiELSEIF                   := IndexOf('ELSEIF');
    kiENABLE                   := IndexOf('ENABLE');
    kiENABLE                   := IndexOf('ENABLE');
    kiENCLOSED                 := IndexOf('ENCLOSED');
    kiEND                      := IndexOf('END');
    kiENDS                     := IndexOf('ENDS');
    kiENGINE                   := IndexOf('ENGINE');
    kiENGINES                  := IndexOf('ENGINES');
    kiEVENT                    := IndexOf('EVENT');
    kiEVENTS                   := IndexOf('EVENTS');
    kiERRORS                   := IndexOf('ERRORS');
    kiESCAPE                   := IndexOf('ESCAPE');
    kiESCAPED                  := IndexOf('ESCAPED');
    kiEVERY                    := IndexOf('EVERY');
    kiEXCHANGE                 := IndexOf('EXCHANGE');
    kiEXCLUSIVE                := IndexOf('EXCLUSIVE');
    kiEXECUTE                  := IndexOf('EXECUTE');
    kiEXISTS                   := IndexOf('EXISTS');
    kiEXPIRE                   := IndexOf('EXPIRE');
    kiEXPLAIN                  := IndexOf('EXPLAIN');
    kiEXIT                     := IndexOf('EXIT');
    kiEXTENDED                 := IndexOf('EXTENDED');
    kiFALSE                    := IndexOf('FALSE');
    kiFAST                     := IndexOf('FAST');
    kiFAULTS                   := IndexOf('FAULTS');
    kiFETCH                    := IndexOf('FETCH');
    kiFLUSH                    := IndexOf('FLUSH');
    kiFIELDS                   := IndexOf('FIELDS');
    kiFILE                     := IndexOf('FILE');
    kiFIRST                    := IndexOf('FIRST');
    kiFIXED                    := IndexOf('FIXED');
    kiFOR                      := IndexOf('FOR');
    kiFORCE                    := IndexOf('FORCE');
    kiFOREIGN                  := IndexOf('FOREIGN');
    kiFORMAT                   := IndexOf('FORMAT');
    kiFOUND                    := IndexOf('FOUND');
    kiFROM                     := IndexOf('FROM');
    kiFULL                     := IndexOf('FULL');
    kiFULLTEXT                 := IndexOf('FULLTEXT');
    kiFUNCTION                 := IndexOf('FUNCTION');
    kiGET                      := IndexOf('GET');
    kiGLOBAL                   := IndexOf('GLOBAL');
    kiGRANT                    := IndexOf('GRANT');
    kiGRANTS                   := IndexOf('GRANTS');
    kiGROUP                    := IndexOf('GROUP');
    kiHANDLER                  := IndexOf('HANDLER');
    kiHASH                     := IndexOf('HASH');
    kiHAVING                   := IndexOf('HAVING');
    kiHELP                     := IndexOf('HELP');
    kiHIGH_PRIORITY            := IndexOf('HIGH_PRIORITY');
    kiHOST                     := IndexOf('HOST');
    kiHOSTS                    := IndexOf('HOSTS');
    kiHOUR                     := IndexOf('HOUR');
    kiHOUR_MINUTE              := IndexOf('HOUR_MINUTE');
    kiHOUR_SECOND              := IndexOf('HOUR_SECOND');
    kiIDENTIFIED               := IndexOf('IDENTIFIED');
    kiIF                       := IndexOf('IF');
    kiIGNORE                   := IndexOf('IGNORE');
    kiIMPORT                   := IndexOf('IMPORT');
    kiIN                       := IndexOf('IN');
    kiINDEX                    := IndexOf('INDEX');
    kiINDEXES                  := IndexOf('INDEXES');
    kiINNER                    := IndexOf('INNER');
    kiINFILE                   := IndexOf('INFILE');
    kiINNODB                   := IndexOf('INNODB');
    kiINOUT                    := IndexOf('INOUT');
    kiINPLACE                  := IndexOf('INPLACE');
    kiINSTANCE                 := IndexOf('INSTANCE');
    kiINSERT                   := IndexOf('INSERT');
    kiINSERT_METHOD            := IndexOf('INSERT_METHOD');
    kiINTERVAL                 := IndexOf('INTERVAL');
    kiINTO                     := IndexOf('INTO');
    kiINVOKER                  := IndexOf('INVOKER');
    kiIO                       := IndexOf('IO');
    kiIPC                      := IndexOf('IPC');
    kiIS                       := IndexOf('IS');
    kiISOLATION                := IndexOf('ISOLATION');
    kiITERATE                  := IndexOf('ITERATE');
    kiJOIN                     := IndexOf('JOIN');
    kiJSON                     := IndexOf('JSON');
    kiKEY                      := IndexOf('KEY');
    kiKEY_BLOCK_SIZE           := IndexOf('KEY_BLOCK_SIZE');
    kiKEYS                     := IndexOf('KEYS');
    kiKILL                     := IndexOf('KILL');
    kiLANGUAGE                 := IndexOf('LANGUAGE');
    kiLAST                     := IndexOf('LAST');
    kiLEADING                  := IndexOf('LEADING');
    kiLEAVE                    := IndexOf('LEAVE');
    kiLEFT                     := IndexOf('LEFT');
    kiLESS                     := IndexOf('LESS');
    kiLEVEL                    := IndexOf('LEVEL');
    kiLIKE                     := IndexOf('LIKE');
    kiLIMIT                    := IndexOf('LIMIT');
    kiLINEAR                   := IndexOf('LINEAR');
    kiLINES                    := IndexOf('LINES');
    kiLIST                     := IndexOf('LIST');
    kiLOGS                     := IndexOf('LOGS');
    kiLOAD                     := IndexOf('LOAD');
    kiLOCAL                    := IndexOf('LOCAL');
    kiLOCALTIME                := IndexOf('LOCALTIME');
    kiLOCALTIMESTAMP           := IndexOf('LOCALTIMESTAMP');
    kiLOCK                     := IndexOf('LOCK');
    kiLOOP                     := IndexOf('LOOP');
    kiLOW_PRIORITY             := IndexOf('LOW_PRIORITY');
    kiMASTER                   := IndexOf('MASTER');
    kiMATCH                    := IndexOf('MATCH');
    kiMAX_CONNECTIONS_PER_HOUR := IndexOf('MAX_CONNECTIONS_PER_HOUR');
    kiMAX_QUERIES_PER_HOUR     := IndexOf('MAX_QUERIES_PER_HOUR');
    kiMAX_ROWS                 := IndexOf('MAX_ROWS');
    kiMAX_UPDATES_PER_HOUR     := IndexOf('MAX_UPDATES_PER_HOUR');
    kiMAX_USER_CONNECTIONS     := IndexOf('MAX_USER_CONNECTIONS');
    kiMAXVALUE                 := IndexOf('MAXVALUE');
    kiMEDIUM                   := IndexOf('MEDIUM');
    kiMEMORY                   := IndexOf('MEMORY');
    kiMERGE                    := IndexOf('MERGE');
    kiMESSAGE_TEXT             := IndexOf('MESSAGE_TEXT');
    kiMICROSECOND              := IndexOf('MICROSECOND');
    kiMIGRATE                  := IndexOf('MIGRATE');
    kiMIN_ROWS                 := IndexOf('MIN_ROWS');
    kiMINUTE                   := IndexOf('MINUTE');
    kiMINUTE_SECOND            := IndexOf('MINUTE_SECOND');
    kiMOD                      := IndexOf('MOD');
    kiMODE                     := IndexOf('MODE');
    kiMODIFIES                 := IndexOf('MODIFIES');
    kiMODIFY                   := IndexOf('MODIFY');
    kiMONTH                    := IndexOf('MONTH');
    kiMUTEX                    := IndexOf('MUTEX');
    kiMYSQL_ERRNO              := IndexOf('MYSQL_ERRNO');
    kiNAME                     := IndexOf('NAME');
    kiNAMES                    := IndexOf('NAMES');
    kiNATIONAL                 := IndexOf('NATIONAL');
    kiNATURAL                  := IndexOf('NATURAL');
    kiNEVER                    := IndexOf('NEVER');
    kiNEXT                     := IndexOf('NEXT');
    kiNO                       := IndexOf('NO');
    kiNONE                     := IndexOf('NONE');
    kiNOT                      := IndexOf('NOT');
    kiNO_WRITE_TO_BINLOG       := IndexOf('NO_WRITE_TO_BINLOG');
    kiNULL                     := IndexOf('NULL');
    kiNUMBER                   := IndexOf('NUMBER');
    kiOFFSET                   := IndexOf('OFFSET');
    kiOJ                       := IndexOf('OJ');
    kiON                       := IndexOf('ON');
    kiONE                      := IndexOf('ONE');
    kiONLY                     := IndexOf('ONLY');
    kiOPEN                     := IndexOf('OPEN');
    kiOPTIMIZE                 := IndexOf('OPTIMIZE');
    kiOPTION                   := IndexOf('OPTION');
    kiOPTIONALLY               := IndexOf('OPTIONALLY');
    kiOPTIONS                  := IndexOf('OPTIONS');
    kiOR                       := IndexOf('OR');
    kiORDER                    := IndexOf('ORDER');
    kiOUT                      := IndexOf('OUT');
    kiOUTER                    := IndexOf('OUTER');
    kiOUTFILE                  := IndexOf('OUTFILE');
    kiOWNER                    := IndexOf('OWNER');
    kiPACK_KEYS                := IndexOf('PACK_KEYS');
    kiPAGE                     := IndexOf('PAGE');
    kiPAGE_CHECKSUM            := IndexOf('PAGE_CHECKSUM');
    kiPARSER                   := IndexOf('PARSER');
    kiPARTIAL                  := IndexOf('PARTIAL');
    kiPARTITION                := IndexOf('PARTITION');
    kiPARTITIONING             := IndexOf('PARTITIONING');
    kiPARTITIONS               := IndexOf('PARTITIONS');
    kiPASSWORD                 := IndexOf('PASSWORD');
    kiPHASE                    := IndexOf('PHASE');
    kiQUERY                    := IndexOf('QUERY');
    kiRECOVER                  := IndexOf('RECOVER');
    kiREDUNDANT                := IndexOf('REDUNDANT');
    kiPLUGINS                  := IndexOf('PLUGINS');
    kiPORT                     := IndexOf('PORT');
    kiPREPARE                  := IndexOf('PREPARE');
    kiPRESERVE                 := IndexOf('PRESERVE');
    kiPRIMARY                  := IndexOf('PRIMARY');
    kiPRIVILEGES               := IndexOf('PRIVILEGES');
    kiPROCEDURE                := IndexOf('PROCEDURE');
    kiPROCESS                  := IndexOf('PROCESS');
    kiPROCESSLIST              := IndexOf('PROCESSLIST');
    kiPROFILE                  := IndexOf('PROFILE');
    kiPROFILES                 := IndexOf('PROFILES');
    kiPROXY                    := IndexOf('PROXY');
    kiPURGE                    := IndexOf('PURGE');
    kiQUARTER                  := IndexOf('QUARTER');
    kiQUICK                    := IndexOf('QUICK');
    kiRANGE                    := IndexOf('RANGE');
    kiREAD                     := IndexOf('READ');
    kiREADS                    := IndexOf('READS');
    kiREBUILD                  := IndexOf('REBUILD');
    kiREFERENCES               := IndexOf('REFERENCES');
    kiREGEXP                   := IndexOf('REGEXP');
    kiRELAYLOG                 := IndexOf('RELAYLOG');
    kiRELEASE                  := IndexOf('RELEASE');
    kiRELOAD                   := IndexOf('RELOAD');
    kiREMOVE                   := IndexOf('REMOVE');
    kiRENAME                   := IndexOf('RENAME');
    kiREORGANIZE               := IndexOf('REORGANIZE');
    kiREPEAT                   := IndexOf('REPEAT');
    kiREPLICATION              := IndexOf('REPLICATION');
    kiREPAIR                   := IndexOf('REPAIR');
    kiREPEATABLE               := IndexOf('REPEATABLE');
    kiREPLACE                  := IndexOf('REPLACE');
    kiREQUIRE                  := IndexOf('REQUIRE');
    kiRESET                    := IndexOf('RESET');
    kiRESIGNAL                 := IndexOf('RESIGNAL');
    kiRESTRICT                 := IndexOf('RESTRICT');
    kiRESUME                   := IndexOf('RESUME');
    kiRETURN                   := IndexOf('RETURN');
    kiRETURNED_SQLSTATE        := IndexOf('RETURNED_SQLSTATE');
    kiRETURNS                  := IndexOf('RETURNS');
    kiREVERSE                  := IndexOf('REVERSE');
    kiREVOKE                   := IndexOf('REVOKE');
    kiRIGHT                    := IndexOf('RIGHT');
    kiRLIKE                    := IndexOf('RLIKE');
    kiROLLBACK                 := IndexOf('ROLLBACK');
    kiROLLUP                   := IndexOf('ROLLUP');
    kiROTATE                   := IndexOf('ROTATE');
    kiROUTINE                  := IndexOf('ROUTINE');
    kiROW                      := IndexOf('ROW');
    kiROW_COUNT                := IndexOf('ROW_COUNT');
    kiROW_FORMAT               := IndexOf('ROW_FORMAT');
    kiROWS                     := IndexOf('ROWS');
    kiSAVEPOINT                := IndexOf('SAVEPOINT');
    kiSCHEDULE                 := IndexOf('SCHEDULE');
    kiSCHEMA                   := IndexOf('SCHEMA');
    kiSCHEMA_NAME              := IndexOf('SCHEMA_NAME');
    kiSECOND                   := IndexOf('SECOND');
    kiSECURITY                 := IndexOf('SECURITY');
    kiSELECT                   := IndexOf('SELECT');
    kiSEPARATOR                := IndexOf('SEPARATOR');
    kiSERIALIZABLE             := IndexOf('SERIALIZABLE');
    kiSERVER                   := IndexOf('SERVER');
    kiSESSION                  := IndexOf('SESSION');
    kiSET                      := IndexOf('SET');
    kiSHARE                    := IndexOf('SHARE');
    kiSHARED                   := IndexOf('SHARED');
    kiSHOW                     := IndexOf('SHOW');
    kiSHUTDOWN                 := IndexOf('SHUTDOWN');
    kiSIGNAL                   := IndexOf('SIGNAL');
    kiSIMPLE                   := IndexOf('SIMPLE');
    kiSLAVE                    := IndexOf('SLAVE');
    kiSNAPSHOT                 := IndexOf('SNAPSHOT');
    kiSOCKET                   := IndexOf('SOCKET');
    kiSONAME                   := IndexOf('SONAME');
    kiSOUNDS                   := IndexOf('SOUNDS');
    kiSOURCE                   := IndexOf('SOURCE');
    kiSPATIAL                  := IndexOf('SPATIAL');
    kiSQL                      := IndexOf('SQL');
    kiSQL_BIG_RESULT           := IndexOf('SQL_BIG_RESULT');
    kiSQL_BUFFER_RESULT        := IndexOf('SQL_BUFFER_RESULT');
    kiSQL_CACHE                := IndexOf('SQL_CACHE');
    kiSQL_CALC_FOUND_ROWS      := IndexOf('SQL_CALC_FOUND_ROWS');
    kiSQL_NO_CACHE             := IndexOf('SQL_NO_CACHE');
    kiSQL_SMALL_RESULT         := IndexOf('SQL_SMALL_RESULT');
    kiSQLEXCEPTION             := IndexOf('SQLEXCEPTION');
    kiSQLSTATE                 := IndexOf('SQLSTATE');
    kiSQLWARNINGS              := IndexOf('SQLWARNINGS');
    kiSTACKED                  := IndexOf('STACKED');
    kiSTARTING                 := IndexOf('STARTING');
    kiSTART                    := IndexOf('START');
    kiSTARTS                   := IndexOf('STARTS');
    kiSTATS_AUTO_RECALC        := IndexOf('STATS_AUTO_RECALC');
    kiSTATS_PERSISTENT         := IndexOf('STATS_PERSISTENT');
    kiSTATUS                   := IndexOf('STATUS');
    kiSTOP                     := IndexOf('STOP');
    kiSTORAGE                  := IndexOf('STORAGE');
    kiSTRAIGHT_JOIN            := IndexOf('STRAIGHT_JOIN');
    kiSUBCLASS_ORIGIN          := IndexOf('SUBCLASS_ORIGIN');
    kiSUBPARTITION             := IndexOf('SUBPARTITION');
    kiSUBPARTITIONS            := IndexOf('SUBPARTITIONS');
    kiSUPER                    := IndexOf('SUPER');
    kiSUSPEND                  := IndexOf('SUSPEND');
    kiSWAPS                    := IndexOf('SWAPS');
    kiSWITCHES                 := IndexOf('SWITCHES');
    kiTABLE                    := IndexOf('TABLE');
    kiTABLE_NAME               := IndexOf('TABLE_NAME');
    kiTABLES                   := IndexOf('TABLES');
    kiTABLESPACE               := IndexOf('TABLESPACE');
    kiTEMPORARY                := IndexOf('TEMPORARY');
    kiTEMPTABLE                := IndexOf('TEMPTABLE');
    kiTERMINATED               := IndexOf('TERMINATED');
    kiTHAN                     := IndexOf('THAN');
    kiTHEN                     := IndexOf('THEN');
    kiTO                       := IndexOf('TO');
    kiTRAILING                 := IndexOf('TRAILING');
    kiTRADITIONAL              := IndexOf('TRADITIONAL');
    kiTRANSACTION              := IndexOf('TRANSACTION');
    kiTRIGGER                  := IndexOf('TRIGGER');
    kiTRIGGERS                 := IndexOf('TRIGGERS');
    kiTRUNCATE                 := IndexOf('TRUNCATE');
    kiTRUE                     := IndexOf('TRUE');
    kiTYPE                     := IndexOf('TYPE');
    kiUNCOMMITTED              := IndexOf('UNCOMMITTED');
    kiUNDEFINED                := IndexOf('UNDEFINED');
    kiUNDO                     := IndexOf('UNDO');
    kiUNICODE                  := IndexOf('UNICODE');
    kiUNION                    := IndexOf('UNION');
    kiUNIQUE                   := IndexOf('UNIQUE');
    kiUNKNOWN                  := IndexOf('UNKNOWN');
    kiUNLOCK                   := IndexOf('UNLOCK');
    kiUNSIGNED                 := IndexOf('UNSIGNED');
    kiUNTIL                    := IndexOf('UNTIL');
    kiUPDATE                   := IndexOf('UPDATE');
    kiUPGRADE                  := IndexOf('UPGRADE');
    kiUSAGE                    := IndexOf('USAGE');
    kiUSE                      := IndexOf('USE');
    kiUSE_FRM                  := IndexOf('USE_FRM');
    kiUSER                     := IndexOf('USER');
    kiUSING                    := IndexOf('USING');
    kiVALUE                    := IndexOf('VALUE');
    kiVALUES                   := IndexOf('VALUES');
    kiVARIABLES                := IndexOf('VARIABLES');
    kiVIEW                     := IndexOf('VIEW');
    kiWARNINGS                 := IndexOf('WARNINGS');
    kiWEEK                     := IndexOf('WEEK');
    kiWHEN                     := IndexOf('WHEN');
    kiWHERE                    := IndexOf('WHERE');
    kiWHILE                    := IndexOf('WHILE');
    kiWRAPPER                  := IndexOf('WRAPPER');
    kiWITH                     := IndexOf('WITH');
    kiWORK                     := IndexOf('WORK');
    kiWRITE                    := IndexOf('WRITE');
    kiXA                       := IndexOf('XA');
    kiXID                      := IndexOf('XID');
    kiXML                      := IndexOf('XML');
    kiXOR                      := IndexOf('XOR');
    kiYEAR                     := IndexOf('YEAR');
    kiYEAR_MONTH               := IndexOf('YEAR_MONTH');
    kiZEROFILL                 := IndexOf('ZEROFILL');

    SetLength(OperatorTypeByKeywordIndex, KeywordList.Count);
    for Index := 0 to KeywordList.Count - 1 do
      OperatorTypeByKeywordIndex[Index]  := otUnknown;
    OperatorTypeByKeywordIndex[kiAND]      := otAND;
    OperatorTypeByKeywordIndex[kiCASE]     := otCase;
    OperatorTypeByKeywordIndex[kiBETWEEN]  := otBetween;
    OperatorTypeByKeywordIndex[kiBINARY]   := otBinary;
    OperatorTypeByKeywordIndex[kiCOLLATE]  := otCollate;
    OperatorTypeByKeywordIndex[kiDISTINCT] := otDISTINCT;
    OperatorTypeByKeywordIndex[kiDIV]      := otDIV;
    OperatorTypeByKeywordIndex[kiESCAPE]   := otEscape;
    OperatorTypeByKeywordIndex[kiIS]       := otIS;
    OperatorTypeByKeywordIndex[kiIN]       := otIN;
    OperatorTypeByKeywordIndex[kiLIKE]     := otLike;
    OperatorTypeByKeywordIndex[kiMOD]      := otMOD;
    OperatorTypeByKeywordIndex[kiNOT]      := otNot;
    OperatorTypeByKeywordIndex[kiOR]       := otOR;
    OperatorTypeByKeywordIndex[kiREGEXP]   := otRegExp;
    OperatorTypeByKeywordIndex[kiRLIKE]    := otRegExp;
    OperatorTypeByKeywordIndex[kiSOUNDS]   := otSounds;
    OperatorTypeByKeywordIndex[kiXOR]      := otXOR;
  end;
end;

function TMySQLParser.StmtPtr(const Node: TOffset): PStmt;
begin
  Assert((Node = 0) or IsStmt(Node));

  if (not IsStmt(Node)) then
    Result := nil
  else
    Result := @ParsedNodes.Mem[Node];
end;

function TMySQLParser.TokenPtr(const Token: TOffset): PToken;
begin
  Assert((Token = 0) or IsToken(Token));

  if (Token = 0) then
    Result := nil
  else
    Result := PToken(@ParsedNodes.Mem[Token]);
end;

end.

