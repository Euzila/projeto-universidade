

/*------------------------------------------
  Trabalho2 de CBD realizado por:
  --- Daniel Nzila-20230106
  --- Maria   Ndua-20230107
  --- Gedeão Manuel-20230256
------------------------------------------*/

-----------------------------------------
-- 1)Passo1
---------------------------------------
USE master;
GO

DROP DATABASE IF EXISTS LIM_20230106;
GO

CREATE DATABASE LIM_20230106;
GO

USE LIM_20230106;
GO

SET LANGUAGE Portuguese;
SET DATEFIRST 1; -- Segunda-feira
GO


---------------------------------------------------------------
-- 2) Filegroups (Dimensões / Índices / Factos S1 / Factos S2)
--------------------------------------------------------------
ALTER DATABASE LIM_20230106 ADD FILEGROUP FG_DIM_LIM_20230106;
ALTER DATABASE LIM_20230106 ADD FILEGROUP FG_IDX_LIM_20230106;
ALTER DATABASE LIM_20230106 ADD FILEGROUP FG_FATO_S1_LIM_20230106;
ALTER DATABASE LIM_20230106 ADD FILEGROUP FG_FATO_S2_LIM_20230106;
GO


------------------------------------------------------------
-- 3) Files físicos (f:\ g:\ h:\ i:\)
------------------------------------------------------------
ALTER DATABASE LIM_20230106
ADD FILE (
    NAME = N'LIM_20230106_DIM',
    FILENAME = N'f:\fgf\LIM_20230106_DIM.ndf',
    SIZE = 10MB,
    MAXSIZE = 200MB,
    FILEGROWTH = 5MB
) TO FILEGROUP FG_DIM_LIM_20230106;
GO

ALTER DATABASE LIM_20230106
ADD FILE (
    NAME = N'LIM_20230106_IDX',
    FILENAME = N'g:\fgg\LIM_20230106_IDX.ndf',
    SIZE = 10MB,
    MAXSIZE = 200MB,
    FILEGROWTH = 5MB
) TO FILEGROUP FG_IDX_LIM_20230106;
GO

ALTER DATABASE LIM_20230106
ADD FILE (
    NAME = N'LIM_20230106_FATO_S1',
    FILENAME = N'h:\fgh\LIM_20230106_FATO_S1.ndf',
    SIZE = 20MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 10MB
) TO FILEGROUP FG_FATO_S1_LIM_20230106;
GO

ALTER DATABASE LIM_20230106
ADD FILE (
    NAME = N'LIM_20230106_FATO_S2',
    FILENAME = N'i:\fgi\LIM_20230106_FATO_S2.ndf',
    SIZE = 20MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 10MB
) TO FILEGROUP FG_FATO_S2_LIM_20230106;
GO


---------------------------------------------------------
-- 4) Partições por semestre de 2024
----------------------------------------------------------
CREATE PARTITION FUNCTION PF_FatoVendas_2024 (DATE)
AS RANGE RIGHT FOR VALUES ('2024-07-01');
GO

CREATE PARTITION SCHEME PS_FatoVendas_2024
AS PARTITION PF_FatoVendas_2024
TO (FG_FATO_S1_LIM_20230106, FG_FATO_S2_LIM_20230106);
GO


------------------------------------------------------------
-- 5) Dimensões (dados no FG_DIM, PK no FG_IDX)
-----------------------------------------------------------

-- DimTempo
CREATE TABLE dbo.DimTempo (
    TempoID INT IDENTITY(1,1) NOT NULL,
    Data DATE NOT NULL,
    Ano INT NOT NULL,
    Mes INT NOT NULL,
    NomeMes VARCHAR(20) NOT NULL,
    Dia INT NOT NULL,
    DiaSemana INT NOT NULL,
    NomeDiaSemana VARCHAR(20) NOT NULL,
    Semestre INT NOT NULL
) ON FG_DIM_LIM_20230106;
GO

ALTER TABLE dbo.DimTempo
ADD CONSTRAINT PK_DimTempo
PRIMARY KEY (TempoID)
ON FG_IDX_LIM_20230106;
GO


-- DimMedicamento
CREATE TABLE dbo.DimMedicamento (
    MedicamentoID INT IDENTITY(1,1) NOT NULL,
    NomeMedicamento VARCHAR(100) NOT NULL,
    PrincipioAtivo VARCHAR(100) NOT NULL
) ON FG_DIM_LIM_20230106;
GO

ALTER TABLE dbo.DimMedicamento
ADD CONSTRAINT PK_DimMedicamento
PRIMARY KEY (MedicamentoID)
ON FG_IDX_LIM_20230106;
GO


-- DimCliente
CREATE TABLE dbo.DimCliente (
    ClienteID INT IDENTITY(1,1) NOT NULL,
    NomeCliente VARCHAR(100) NULL,
    Sexo CHAR(1) NOT NULL
) ON FG_DIM_LIM_20230106;
GO

ALTER TABLE dbo.DimCliente
ADD CONSTRAINT PK_DimCliente
PRIMARY KEY (ClienteID)
ON FG_IDX_LIM_20230106;
GO


-- DimFornecedor (AIM)
CREATE TABLE dbo.DimFornecedor (
    FornecedorID INT IDENTITY(1,1) NOT NULL,
    NomeFornecedor VARCHAR(150) NOT NULL
) ON FG_DIM_LIM_20230106;
GO

ALTER TABLE dbo.DimFornecedor
ADD CONSTRAINT PK_DimFornecedor
PRIMARY KEY (FornecedorID)
ON FG_IDX_LIM_20230106;
GO


-------------------------------------------------------
-- 6) Tabela de Factos (particionada) + PK
--------------------------------------------------------
CREATE TABLE dbo.FatoVendas (
    VendaID BIGINT IDENTITY(1,1) NOT NULL,

    TempoID INT NOT NULL,
    MedicamentoID INT NOT NULL,
    ClienteID INT NOT NULL,
    FornecedorID INT NOT NULL,

    DataVenda DATE NOT NULL,
    Quantidade INT NOT NULL CHECK (Quantidade >= 0)
)
ON PS_FatoVendas_2024 (DataVenda);
GO

ALTER TABLE dbo.FatoVendas
ADD CONSTRAINT PK_FatoVendas
PRIMARY KEY NONCLUSTERED (VendaID)
ON FG_IDX_LIM_20230106;
GO


-----------------------------------------------------------
-- 7) Foreign Keys (modelo estrela)
------------------------------------------------------------
ALTER TABLE dbo.FatoVendas
ADD CONSTRAINT FK_FatoVendas_Tempo
FOREIGN KEY (TempoID) REFERENCES dbo.DimTempo(TempoID);
GO

ALTER TABLE dbo.FatoVendas
ADD CONSTRAINT FK_FatoVendas_Medicamento
FOREIGN KEY (MedicamentoID) REFERENCES dbo.DimMedicamento(MedicamentoID);
GO

ALTER TABLE dbo.FatoVendas
ADD CONSTRAINT FK_FatoVendas_Cliente
FOREIGN KEY (ClienteID) REFERENCES dbo.DimCliente(ClienteID);
GO

ALTER TABLE dbo.FatoVendas
ADD CONSTRAINT FK_FatoVendas_Fornecedor
FOREIGN KEY (FornecedorID) REFERENCES dbo.DimFornecedor(FornecedorID);
GO


--------------------------------------------------------------
-- 8) Índices 
--------------------------------------------------------------
CREATE INDEX IX_FatoVendas_Tempo       ON dbo.FatoVendas (TempoID)       ON FG_IDX_LIM_20230106;
CREATE INDEX IX_FatoVendas_Medicamento ON dbo.FatoVendas (MedicamentoID) ON FG_IDX_LIM_20230106;
CREATE INDEX IX_FatoVendas_Cliente     ON dbo.FatoVendas (ClienteID)     ON FG_IDX_LIM_20230106;
CREATE INDEX IX_FatoVendas_Fornecedor  ON dbo.FatoVendas (FornecedorID)  ON FG_IDX_LIM_20230106;
GO


---------------------------------------------------------
-- 9) População das Dimensões (caprichada)
---------------------------------------------------------

DELETE FROM dbo.DimFornecedor;
DELETE FROM dbo.DimMedicamento;
DELETE FROM dbo.DimCliente;
DELETE FROM dbo.DimTempo;
GO

-- Fornecedores (AIM)
INSERT INTO dbo.DimFornecedor (NomeFornecedor) VALUES
('A. Menarini Portugal'), ('Abbvie, Lda'), ('Accord Healthcare'),
('Bayer Portugal'), ('Pfizer Portugal'), ('Sanofi'), ('Novartis Farma'),
('GSK - GlaxoSmithKline'), ('Janssen-Cilag'), ('Teva Portugal'),
('Sandoz'), ('Laboratórios Basi'), ('Zentiva'), ('Kern Pharma'),
('Mylan'), ('AstraZeneca'), ('Roche Farmacêutica'), ('Servier Portugal'),
('Fresenius Kabi'), ('MSD Portugal');
GO

-- Medicamentos + Princípios Ativos (com repetição de princípios ativos)
INSERT INTO dbo.DimMedicamento (NomeMedicamento, PrincipioAtivo) VALUES
('EST-U-RON 1g', 'Paracetamol'),
('EST-U-RON 500mg', 'Paracetamol'),
('EST-Bru-Fen 400mg', 'Ibuprofeno'),
('EST-Bru-Fen 600mg', 'Ibuprofeno'),
('EST_Aspirina 500mg', 'Ácido Acetilsalicílico'),
('EST_Aspirina C', 'Ácido Acetilsalicílico'),
('EST-Amoxicilina 500mg', 'Amoxicilina'),
('EST-Amoxicilina 1g', 'Amoxicilina'),
('EST-Cetirizina 10mg', 'Cetirizina'),
('EST-Loratadina 10mg', 'Loratadina'),
('EST-Omeprazol 20mg', 'Omeprazol'),
('EST-Pantoprazol 40mg', 'Pantoprazol'),
('EST-Metformina 850mg', 'Metformina'),
('EST-Atorvastatina 20mg', 'Atorvastatina'),
('EST-Losartan 50mg', 'Losartan'),
('EST-Amlodipina 5mg', 'Amlodipina'),
('EST-Diclofenac 50mg', 'Diclofenac'),
('EST-Naproxeno 500mg', 'Naproxeno'),
('EST-Azitromicina 500mg', 'Azitromicina'),
('EST-Levotiroxina 100mcg', 'Levotiroxina');
GO

-- Clientes (M/F)
INSERT INTO dbo.DimCliente (NomeCliente, Sexo) VALUES
('Cliente 001','F'),('Cliente 002','M'),('Cliente 003','F'),('Cliente 004','M'),
('Cliente 005','F'),('Cliente 006','M'),('Cliente 007','F'),('Cliente 008','M'),
('Cliente 009','F'),('Cliente 010','M'),('Cliente 011','F'),('Cliente 012','M'),
('Cliente 013','F'),('Cliente 014','M'),('Cliente 015','F'),('Cliente 016','M'),
('Cliente 017','F'),('Cliente 018','M'),('Cliente 019','F'),('Cliente 020','M');
GO

-- Tempo: gerar todos os dias de 2024
DECLARE @d DATE = '2024-01-01';
WHILE @d <= '2024-12-31'
BEGIN
    INSERT INTO dbo.DimTempo (Data, Ano, Mes, NomeMes, Dia, DiaSemana, NomeDiaSemana, Semestre)
    VALUES (
        @d,
        YEAR(@d),
        MONTH(@d),
        DATENAME(MONTH, @d),
        DAY(@d),
        DATEPART(WEEKDAY, @d),
        DATENAME(WEEKDAY, @d),
        CASE WHEN MONTH(@d) <= 6 THEN 1 ELSE 2 END
    );
    SET @d = DATEADD(DAY, 1, @d);
END;
GO


---------------------------------------------------------
-- 10) População da Fact Table (WHILE + IDs aleatórios) 
--------------------------------------------------------
DELETE FROM dbo.FatoVendas;
GO

DECLARE @minTempo INT, @maxTempo INT;
DECLARE @minMed INT, @maxMed INT;
DECLARE @minCli INT, @maxCli INT;
DECLARE @minFor INT, @maxFor INT;

SELECT @minTempo = MIN(TempoID), @maxTempo = MAX(TempoID) FROM dbo.DimTempo;
SELECT @minMed   = MIN(MedicamentoID), @maxMed = MAX(MedicamentoID) FROM dbo.DimMedicamento;
SELECT @minCli   = MIN(ClienteID), @maxCli = MAX(ClienteID) FROM dbo.DimCliente;
SELECT @minFor   = MIN(FornecedorID), @maxFor = MAX(FornecedorID) FROM dbo.DimFornecedor;

DECLARE @i INT = 1;
DECLARE @nrRegistos INT = 5000;

WHILE @i <= @nrRegistos
BEGIN
    DECLARE @TempoID INT = (ABS(CHECKSUM(NEWID())) % (@maxTempo - @minTempo + 1)) + @minTempo;
    DECLARE @MedicamentoID INT = (ABS(CHECKSUM(NEWID())) % (@maxMed - @minMed + 1)) + @minMed;
    DECLARE @ClienteID INT = (ABS(CHECKSUM(NEWID())) % (@maxCli - @minCli + 1)) + @minCli;
    DECLARE @FornecedorID INT = (ABS(CHECKSUM(NEWID())) % (@maxFor - @minFor + 1)) + @minFor;

    DECLARE @DataVenda DATE = (SELECT Data FROM dbo.DimTempo WHERE TempoID = @TempoID);
    DECLARE @Quantidade INT = (ABS(CHECKSUM(NEWID())) % 3000) + 1;

    INSERT INTO dbo.FatoVendas (TempoID, MedicamentoID, ClienteID, FornecedorID, DataVenda, Quantidade)
    VALUES (@TempoID, @MedicamentoID, @ClienteID, @FornecedorID, @DataVenda, @Quantidade);

    SET @i = @i + 1;
END;
GO


--==========================================================
-- 11) Respostas SQL às 4 questões do enunciado
--==========================================================

-- 1) Nº de vendas por dia da semana e medicamento
SELECT 
    t.NomeDiaSemana,
    m.NomeMedicamento,
    COUNT(*) AS NumeroVendas
FROM dbo.FatoVendas v
JOIN dbo.DimTempo t       ON v.TempoID = t.TempoID
JOIN dbo.DimMedicamento m ON v.MedicamentoID = m.MedicamentoID
GROUP BY t.NomeDiaSemana, m.NomeMedicamento
ORDER BY t.NomeDiaSemana, m.NomeMedicamento;
GO

-- 2) Quantidade total por medicamento e mês
SELECT
    t.Mes,
    t.NomeMes,
    m.NomeMedicamento,
    SUM(v.Quantidade) AS QuantidadeTotal
FROM dbo.FatoVendas v
JOIN dbo.DimTempo t       ON v.TempoID = t.TempoID
JOIN dbo.DimMedicamento m ON v.MedicamentoID = m.MedicamentoID
GROUP BY t.Mes, t.NomeMes, m.NomeMedicamento
ORDER BY t.Mes, m.NomeMedicamento;
GO

-- 3) Quantidade por princípio ativo e sexo
SELECT
    m.PrincipioAtivo,
    c.Sexo,
    SUM(v.Quantidade) AS QuantidadeTotal
FROM dbo.FatoVendas v
JOIN dbo.DimMedicamento m ON v.MedicamentoID = m.MedicamentoID
JOIN dbo.DimCliente c     ON v.ClienteID = c.ClienteID
GROUP BY m.PrincipioAtivo, c.Sexo
ORDER BY m.PrincipioAtivo, c.Sexo;
GO

-- 4) Quantidade por princípio ativo e fornecedor (AIM)
SELECT
    f.NomeFornecedor,
    m.PrincipioAtivo,
    SUM(v.Quantidade) AS QuantidadeTotal
FROM dbo.FatoVendas v
JOIN dbo.DimFornecedor f  ON v.FornecedorID = f.FornecedorID
JOIN dbo.DimMedicamento m ON v.MedicamentoID = m.MedicamentoID
GROUP BY f.NomeFornecedor, m.PrincipioAtivo
ORDER BY f.NomeFornecedor, m.PrincipioAtivo;
GO


--==========================================================
-- 12) Verificações (opcional)
--==========================================================
SELECT name FROM sys.partition_functions WHERE name = 'PF_FatoVendas_2024';
SELECT name FROM sys.partition_schemes   WHERE name = 'PS_FatoVendas_2024';

SELECT
    CASE WHEN DataVenda < '2024-07-01' THEN 'S1' ELSE 'S2' END AS Semestre,
    COUNT(*) AS NumVendas
FROM dbo.FatoVendas
GROUP BY CASE WHEN DataVenda < '2024-07-01' THEN 'S1' ELSE 'S2' END;
GO
